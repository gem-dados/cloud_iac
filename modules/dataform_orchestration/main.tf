# =============================================================================
# dataform_orchestration — agendamento GCP-nativo do Dataform via
#   Cloud Scheduler -> Cloud Workflows -> Dataform API, rodando como a SA
#   custom (runner). Padrao recomendado pela Google para repos com
#   strictActAsChecks (onde a SA default nao pode executar workflows).
# =============================================================================

locals {
  repository = "projects/${var.project_id}/locations/${var.region}/repositories/${var.repository_name}"

  workflow_source = templatefile("${path.module}/workflow.yaml.tftpl", {
    repository = local.repository
    git_branch = var.git_branch
    runner_sa  = var.runner_service_account_email
  })
}

# SA que orquestra (roda o Workflow e e acionada pelo Scheduler).
resource "google_service_account" "orchestrator" {
  project      = var.project_id
  account_id   = "dataform-orchestrator"
  display_name = "Dataform orchestration (Workflows + Scheduler)"
}

# Pode gerenciar compilacoes/execucoes no Dataform.
resource "google_project_iam_member" "dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.orchestrator.email}"
}

# Pode rodar a execucao COMO a SA runner (invocationConfig.serviceAccount).
resource "google_service_account_iam_member" "actas_runner" {
  service_account_id = var.runner_service_account_id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.orchestrator.email}"
}

# Pode acionar a execucao do Workflow (chamado pelo Scheduler).
resource "google_project_iam_member" "workflows_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.orchestrator.email}"
}

resource "google_workflows_workflow" "this" {
  project         = var.project_id
  region          = var.region
  name            = "dataform-${var.env}"
  description     = "Compila e executa o Dataform (${var.env})."
  service_account = google_service_account.orchestrator.email
  source_contents = local.workflow_source
}

resource "google_cloud_scheduler_job" "this" {
  project   = var.project_id
  region    = var.region
  name      = "dataform-${var.env}"
  schedule  = var.cron_schedule
  time_zone = var.time_zone

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.this.id}/executions"

    oauth_token {
      service_account_email = google_service_account.orchestrator.email
    }
  }

  depends_on = [
    google_project_iam_member.workflows_invoker,
    google_project_iam_member.dataform_editor,
    google_service_account_iam_member.actas_runner,
  ]
}
