# =============================================================================
# BOOTSTRAP — rodar UMA vez por ambiente, manualmente, por um admin.
#
# Resolve o "ovo e a galinha": cria o que a esteira precisa para existir antes
# de a esteira existir:
#   - bucket de state do Terraform (1 por projeto)
#   - Service Account que a esteira usa para aplicar IaC (menor privilegio)
#   - conexao Cloud Build 2nd gen ao GitHub + repo registrado
#   - triggers (apply por branch + plan no PR)
#
# Usa state LOCAL de proposito. Depois do bootstrap, guarde o terraform.tfstate
# num lugar seguro (NUNCA commitar).
#
#   cd bootstrap
#   terraform init
#   terraform apply -var-file=stg.tfvars      # depois prd.tfvars
# =============================================================================

locals {
  state_bucket = "${var.project_id}-tfstate"

  # branch-per-env: stg aplica no push da branch 'stg'; prd no push da 'main'.
  apply_branch = var.env == "prd" ? "^main$" : "^stg$"

  remote_uri = "https://github.com/${var.github_owner}/${var.github_repo}.git"

  bootstrap_apis = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ]

  # Papeis da SA que aplica IaC.
  #
  # roles/editor cobre o CREATE/UPDATE/DELETE da maioria dos servicos GCP — entao
  # servicos novos "so criar" funcionam de primeira (sem caca ao papel). NAO e um
  # upgrade real de privilegio: a SA ja tem projectIamAdmin (pode se auto-conceder
  # qualquer papel). Os *.admin abaixo ficam para os casos que o editor NAO cobre:
  # setIamPolicy em recurso (bucket/secret/SA), conexoes Cloud Build 2nd gen, etc.
  terraform_sa_roles = [
    "roles/editor",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/bigquery.admin",
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/secretmanager.admin",
    "roles/dataform.admin",
    "roles/cloudbuild.builds.editor",
    "roles/cloudbuild.connectionAdmin",
    "roles/workflows.admin",
    "roles/cloudscheduler.admin",
    "roles/logging.logWriter",
  ]
}

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_project_service" "bootstrap" {
  for_each = toset(local.bootstrap_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

locals {
  # Service agent (P4SA) do Cloud Build — e ELE que a conexao 2nd gen usa para
  # ler o secret do PAT. NAO confundir com a SA legada de build
  # (<num>@cloudbuild.gserviceaccount.com), que e outra coisa.
  cloudbuild_p4sa = "service-${data.google_project.this.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# --- State bucket -----------------------------------------------------------
resource "google_storage_bucket" "tfstate" {
  project  = var.project_id
  name     = local.state_bucket
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.bootstrap]
}

# --- Service Account da esteira ---------------------------------------------
resource "google_service_account" "terraform" {
  project      = var.project_id
  account_id   = "terraform-ci"
  display_name = "Terraform CI (Cloud Build)"

  depends_on = [google_project_service.bootstrap]
}

resource "google_project_iam_member" "terraform_sa" {
  for_each = toset(local.terraform_sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

# A SA precisa ler/escrever o proprio state.
resource "google_storage_bucket_iam_member" "terraform_state" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform.email}"
}

# --- Secret com o PAT do GitHub (para a conexao 2nd gen) --------------------
# O secret e criado vazio; o admin adiciona a VERSAO com o PAT a mao (assim o
# token nunca entra no codigo). Veja bootstrap/README.md.
resource "google_secret_manager_secret" "github_oauth" {
  project   = var.project_id
  secret_id = "github-oauth-token"

  replication {
    auto {}
  }

  depends_on = [google_project_service.bootstrap]
}

# O service agent (P4SA) do Cloud Build precisa ler o secret do PAT.
resource "google_secret_manager_secret_iam_member" "cloudbuild_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.github_oauth.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.cloudbuild_p4sa}"

  depends_on = [google_project_service.bootstrap]
}

# --- Conexao Cloud Build 2nd gen + repo ------------------------------------
module "github" {
  source = "../modules/cloudbuild_connection"

  project_id                 = var.project_id
  location                   = var.region
  connection_name            = "github-${var.github_owner}"
  app_installation_id        = var.github_app_installation_id
  oauth_token_secret_version = "${google_secret_manager_secret.github_oauth.id}/versions/latest"
  repo_name                  = var.github_repo
  remote_uri                 = local.remote_uri

  depends_on = [google_secret_manager_secret_iam_member.cloudbuild_access]
}

# --- Triggers do Cloud Build (2nd gen) -------------------------------------
module "trigger_apply" {
  source = "../modules/cloudbuild_trigger"

  project_id         = var.project_id
  location           = var.region
  repository_id      = module.github.repository_id
  name               = "iac-${var.env}-apply"
  description        = "Aplica Terraform em ${var.env} no push da branch ${local.apply_branch}."
  event_type         = "push"
  branch_regex       = local.apply_branch
  build_config_file  = "cloudbuild.yaml"
  service_account_id = google_service_account.terraform.id
  substitutions      = { _ENV = var.env }

  depends_on = [google_project_iam_member.terraform_sa]
}

module "trigger_plan_pr" {
  source = "../modules/cloudbuild_trigger"

  project_id         = var.project_id
  location           = var.region
  repository_id      = module.github.repository_id
  name               = "iac-${var.env}-plan-pr"
  description        = "Roda plan + scans de seguranca em PRs para ${local.apply_branch}."
  event_type         = "pull_request"
  branch_regex       = local.apply_branch
  build_config_file  = "cloudbuild-pr.yaml"
  service_account_id = google_service_account.terraform.id
  substitutions      = { _ENV = var.env }

  depends_on = [google_project_iam_member.terraform_sa]
}
