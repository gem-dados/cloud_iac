# =============================================================================
# cloud_run_service — servico Cloud Run (v2) para os jobs do data_ingestion
#   - roda com uma Service Account dedicada (menor privilegio)
#   - segredos vem do Secret Manager (NUNCA hardcoded)
#   - sem acesso publico por padrao (invoker controlado)
# =============================================================================

resource "google_cloud_run_v2_service" "this" {
  project  = var.project_id
  name     = var.name
  location = var.location
  ingress  = var.ingress

  deletion_protection = var.deletion_protection

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      resources {
        limits = var.resource_limits
      }

      # Variaveis de ambiente "simples" (nao sensiveis).
      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      # Variaveis sensiveis vindas do Secret Manager.
      dynamic "env" {
        for_each = var.secret_env
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = try(env.value.version, "latest")
            }
          }
        }
      }
    }
  }
}

# Por padrao o servico NAO e publico. Conceda invoker explicitamente.
resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = toset(var.invokers)

  project  = var.project_id
  location = var.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = each.value
}
