# =============================================================================
# cloudbuild_connection — conexao Cloud Build 2nd gen (repositories v2) ao GitHub
#
#   google_cloudbuildv2_connection  -> liga o projeto a org no GitHub
#   google_cloudbuildv2_repository  -> registra o repo (cloud_iac, etc.)
#
# Pre-requisitos (feitos pelo admin, ver bootstrap/README.md):
#   1. Instalar o "Cloud Build" GitHub App na org gem-dados (pega-se o
#      app_installation_id).
#   2. Criar um PAT do GitHub e guardar no Secret Manager; passar a versao
#      do secret em oauth_token_secret_version.
# =============================================================================

resource "google_cloudbuildv2_connection" "this" {
  project  = var.project_id
  location = var.location
  name     = var.connection_name

  github_config {
    app_installation_id = var.app_installation_id

    authorizer_credential {
      oauth_token_secret_version = var.oauth_token_secret_version
    }
  }
}

resource "google_cloudbuildv2_repository" "this" {
  project           = var.project_id
  location          = var.location
  name              = var.repo_name
  parent_connection = google_cloudbuildv2_connection.this.id
  remote_uri        = var.remote_uri
}
