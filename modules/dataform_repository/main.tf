# =============================================================================
# dataform_repository — repositorio Dataform ligado ao repo data_models
#   Dataform executa as transformacoes SQL dentro do BigQuery.
#   A autenticacao com o GitHub usa um token guardado no Secret Manager.
# =============================================================================

resource "google_dataform_repository" "this" {
  provider = google-beta

  project = var.project_id
  region  = var.location
  name    = var.name

  dynamic "git_remote_settings" {
    for_each = var.git_url == null ? [] : [1]
    content {
      url                                 = var.git_url
      default_branch                      = var.default_branch
      authentication_token_secret_version = var.token_secret_version
    }
  }

  dynamic "workspace_compilation_overrides" {
    for_each = var.default_database == null ? [] : [1]
    content {
      default_database = var.default_database
    }
  }
}
