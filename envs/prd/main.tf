# =============================================================================
# Ambiente: PRD  (projeto gem-dados-lake-prd)
#
# Este arquivo "amarra" os modulos. Para adicionar um recurso novo, copie um
# bloco `module {}` abaixo e ajuste — e essa a parte "facil de add recursos".
# Mantenha prd/ em paralelo (mesma estrutura, valores via tfvars).
# =============================================================================

locals {
  labels = {
    env        = var.env
    managed_by = "terraform"
    repo       = "cloud_iac"
    org        = "gem-dados"
  }

  # Mapeia o ambiente para o value da tag de governanca 'environment'.
  environment_tag_value = var.env == "prd" ? "Production" : "Staging"

  # Branch-por-ambiente: prd usa 'main', os demais usam 'stg'.
  deploy_branch_regex = var.env == "prd" ? "^main$" : "^stg$"
  deploy_branch_name  = var.env == "prd" ? "main" : "stg"

  # SA terraform-ci (criada no bootstrap) — reusada como SA das esteiras de app.
  cicd_sa_id = "projects/${var.project_id}/serviceAccounts/terraform-ci@${var.project_id}.iam.gserviceaccount.com"

  # Service agent do Dataform (roda as transformacoes no BigQuery).
  dataform_sa = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"

  # Conexao Cloud Build 2nd gen criada no bootstrap.
  connection_id = "projects/${var.project_id}/locations/${var.region}/connections/github-gem-dados"
}

data "google_project" "current" {
  project_id = var.project_id
}

# ---------------------------------------------------------------------------
# 1) Baseline do projeto (APIs + tag de governanca). Tudo abaixo depende disto
#    (depends_on) para nao tentar criar recurso antes da API estar habilitada.
# ---------------------------------------------------------------------------
module "baseline" {
  source     = "../../modules/project_baseline"
  project_id = var.project_id

  manage_environment_tag = var.manage_environment_tag
  org_id                 = var.org_id
  environment_tag_value  = local.environment_tag_value
}

# ---------------------------------------------------------------------------
# 2) Service Account dedicada para os jobs de ingestao (menor privilegio)
# ---------------------------------------------------------------------------
resource "google_service_account" "ingestion" {
  project      = var.project_id
  account_id   = "data-ingestion"
  display_name = "Data Ingestion (Cloud Run)"

  depends_on = [module.baseline]
}

# Permissoes minimas: escrever no lake (BigQuery + bucket raw).
resource "google_project_iam_member" "ingestion_bq" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.ingestion.email}"
}

resource "google_project_iam_member" "ingestion_bq_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.ingestion.email}"
}

# Escrita no bucket raw (object admin so neste bucket — nao no projeto todo).
resource "google_storage_bucket_iam_member" "ingestion_raw" {
  bucket = module.bucket_raw.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ingestion.email}"
}

# ---------------------------------------------------------------------------
# 3) Camadas do data lake no BigQuery
# ---------------------------------------------------------------------------
module "ds_raw" {
  source                     = "../../modules/bigquery_dataset"
  project_id                 = var.project_id
  dataset_id                 = "raw"
  location                   = var.bq_location
  description                = "Camada RAW — dados crus da ingestao."
  delete_contents_on_destroy = var.env == "stg"
  labels                     = local.labels

  depends_on = [module.baseline]
}

module "ds_staging" {
  source                     = "../../modules/bigquery_dataset"
  project_id                 = var.project_id
  dataset_id                 = "staging"
  location                   = var.bq_location
  description                = "Camada STAGING — transformacoes do Dataform."
  delete_contents_on_destroy = var.env == "stg"
  labels                     = local.labels

  depends_on = [module.baseline]
}

module "ds_marts" {
  source                     = "../../modules/bigquery_dataset"
  project_id                 = var.project_id
  dataset_id                 = "marts"
  location                   = var.bq_location
  description                = "Camada MARTS — modelos finais para consumo."
  delete_contents_on_destroy = var.env == "stg"
  labels                     = local.labels

  depends_on = [module.baseline]
}

# ---------------------------------------------------------------------------
# 4) Bucket RAW (landing zone de arquivos)
# ---------------------------------------------------------------------------
module "bucket_raw" {
  source     = "../../modules/gcs_bucket"
  project_id = var.project_id
  name       = "${var.project_id}-raw"
  location   = var.bq_location
  labels     = local.labels

  depends_on = [module.baseline]
}

# ---------------------------------------------------------------------------
# 5) Artifact Registry para as imagens do data_ingestion
# ---------------------------------------------------------------------------
module "artifact_ingestion" {
  source        = "../../modules/artifact_registry"
  project_id    = var.project_id
  location      = var.region
  repository_id = "data-ingestion"
  labels        = local.labels

  depends_on = [module.baseline]
}

# ---------------------------------------------------------------------------
# 6) Cloud Run do job de ingestao
#    A imagem real e publicada pela esteira do repo data_ingestion; aqui
#    declaramos o servico com um placeholder e a esteira atualiza a imagem.
# ---------------------------------------------------------------------------
module "ingestion_service" {
  source                = "../../modules/cloud_run_service"
  project_id            = var.project_id
  name                  = "data-ingestion"
  location              = var.region
  service_account_email = google_service_account.ingestion.email

  env = {
    GCP_PROJECT = var.project_id
    ENVIRONMENT = var.env
    RAW_BUCKET  = module.bucket_raw.name
    BQ_DATASET  = module.ds_raw.dataset_id
  }

  # Exemplo de segredo (crie o secret no Secret Manager / via esteira):
  # secret_env = {
  #   API_TOKEN = { secret = "ingestion-api-token", version = "latest" }
  # }

  depends_on = [module.baseline]
}

# ---------------------------------------------------------------------------
# 7) Dataform (consome o repo data_models)
# ---------------------------------------------------------------------------
module "dataform" {
  source           = "../../modules/dataform_repository"
  project_id       = var.project_id
  location         = var.region
  name             = "data-models"
  default_database = var.project_id

  # Linka ao repo data_models (usa o mesmo secret/PAT do Cloud Build).
  git_url              = "https://github.com/gem-dados/data_models.git"
  default_branch       = local.deploy_branch_name
  token_secret_version = "projects/${var.project_id}/secrets/github-oauth-token/versions/latest"

  depends_on = [
    module.baseline,
    google_secret_manager_secret_iam_member.dataform_git,
  ]
}

# O service agent do Dataform precisa ler o secret do git (PAT) para sincronizar.
resource "google_secret_manager_secret_iam_member" "dataform_git" {
  project   = var.project_id
  secret_id = "github-oauth-token"
  role      = "roles/secretmanager.secretAccessor"
  member    = local.dataform_sa
}

# SA dedicada que EXECUTA os workflows do Dataform no BigQuery (menor privilegio).
resource "google_service_account" "dataform_runner" {
  project      = var.project_id
  account_id   = "dataform-runner"
  display_name = "Dataform workflow runner"

  depends_on = [module.baseline]
}

resource "google_project_iam_member" "dataform_runner_bq_data" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dataform_runner.email}"
}

resource "google_project_iam_member" "dataform_runner_bq_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataform_runner.email}"
}

# O service agent do Dataform precisa poder rodar workflows COMO o runner (strict actAs).
resource "google_service_account_iam_member" "dataform_agent_actas" {
  service_account_id = google_service_account.dataform_runner.id
  role               = "roles/iam.serviceAccountUser"
  member             = local.dataform_sa
}

# Agendamento GCP-nativo do Dataform (Cloud Scheduler -> Workflows -> Dataform
# API), rodando como a SA dataform-runner. Padrao recomendado pela Google para
# repos com strictActAsChecks (a SA default nao pode executar workflows).
module "dataform_orchestration" {
  source = "../../modules/dataform_orchestration"

  project_id                   = var.project_id
  region                       = var.region
  env                          = var.env
  repository_name              = module.dataform.name
  git_branch                   = local.deploy_branch_name
  runner_service_account_email = google_service_account.dataform_runner.email
  runner_service_account_id    = google_service_account.dataform_runner.id
  cron_schedule                = "0 7 * * *"
  time_zone                    = "America/Sao_Paulo"

  depends_on = [module.baseline]
}

# ---------------------------------------------------------------------------
# 8) Esteira do data_ingestion (app): build da imagem -> push AR -> deploy
#    no Cloud Run. Usa a conexao 2nd gen ja criada no bootstrap e roda como a
#    SA terraform-ci (tem AR/run/serviceAccountUser/logging). Branch-por-ambiente.
# ---------------------------------------------------------------------------
resource "google_cloudbuildv2_repository" "data_ingestion" {
  project           = var.project_id
  location          = var.region
  name              = "data_ingestion"
  parent_connection = local.connection_id
  remote_uri        = "https://github.com/gem-dados/data_ingestion.git"
}

resource "google_cloudbuild_trigger" "ingestion_deploy" {
  project         = var.project_id
  location        = var.region
  name            = "ingestion-${var.env}-deploy"
  description     = "Build e deploy do data_ingestion no Cloud Run (${var.env})."
  filename        = "cloudbuild.yaml"
  service_account = local.cicd_sa_id

  repository_event_config {
    repository = google_cloudbuildv2_repository.data_ingestion.id
    push {
      branch = local.deploy_branch_regex
    }
  }

  substitutions = {
    _ENV    = var.env
    _REGION = var.region
  }
}
