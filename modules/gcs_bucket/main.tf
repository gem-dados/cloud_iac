# =============================================================================
# gcs_bucket — bucket GCS seguro por padrao
#   - acesso uniforme (sem ACLs por objeto)
#   - bloqueio total de acesso publico (importante: org/repo publicos!)
#   - versionamento e lifecycle configuraveis
# =============================================================================

resource "google_storage_bucket" "this" {
  project  = var.project_id
  name     = var.name
  location = var.location

  storage_class               = var.storage_class
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = try(lifecycle_rule.value.storage_class, null)
      }
      condition {
        age = try(lifecycle_rule.value.age, null)
      }
    }
  }

  labels = var.labels
}
