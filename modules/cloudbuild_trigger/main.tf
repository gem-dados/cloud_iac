# =============================================================================
# cloudbuild_trigger — trigger Cloud Build 2nd gen (repositories v2).
#   Usa repository_event_config apontando para um repo registrado por
#   cloudbuild_connection. Triggers 2nd gen sao REGIONAIS (exigem location).
# =============================================================================

resource "google_cloudbuild_trigger" "this" {
  project         = var.project_id
  location        = var.location
  name            = var.name
  description     = var.description
  filename        = var.build_config_file
  service_account = var.service_account_id
  included_files  = var.included_files
  tags            = var.tags
  substitutions   = var.substitutions

  repository_event_config {
    repository = var.repository_id

    dynamic "push" {
      for_each = var.event_type == "push" ? [1] : []
      content {
        branch = var.branch_regex
      }
    }

    dynamic "pull_request" {
      for_each = var.event_type == "pull_request" ? [1] : []
      content {
        branch          = var.branch_regex
        comment_control = var.pr_comment_control
      }
    }
  }
}
