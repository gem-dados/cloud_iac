# =============================================================================
# Ambiente: STG  (projeto gem-dados-lake-stg)
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

  # Para ligar ao GitHub, crie o secret com o PAT e descomente:
  # git_url              = "https://github.com/gem-dados/data_models.git"
  # token_secret_version = "projects/${var.project_id}/secrets/dataform-github-token/versions/latest"

  depends_on = [module.baseline]
}
