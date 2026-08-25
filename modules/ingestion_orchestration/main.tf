# =============================================================================
# ingestion_orchestration — agendamento GCP-nativo da esteira de ingestao via
#   Cloud Scheduler -> Cloud Workflows -> Cloud Run (data-ingestion).
#
# Encadeia os passos de ingestao (/run/ingest -> /run/load_bq ->
# /run/rotina_sem_duplicatas) antes do Dataform rodar.
# =============================================================================

locals {
  workflow_source = templatefile("${path.module}/workflow.yaml.tftpl", {
    service_uri       = var.service_uri
    project_id        = var.project_id
    region            = var.region
    dataform_workflow = var.dataform_workflow_name
  })
}

# SA que orquestra a ingestao (executa o Workflow e e acionada pelo Scheduler).
resource "google_service_account" "orchestrator" {
  project      = var.project_id
  account_id   = "ingestion-orchestrator"
  display_name = "Ingestion orchestration (Workflows + Scheduler)"
}

# Concede permissao para chamar o servico privado Cloud Run com token OIDC.
resource "google_cloud_run_v2_service_iam_member" "run_invoker" {
  project  = var.project_id
  location = var.region
  name     = var.service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.orchestrator.email}"
}

# Permissao para o Scheduler disparar execucoes do Workflow.
resource "google_project_iam_member" "workflows_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.orchestrator.email}"
}

# Workflow que executa a cadeia de ingestao no Cloud Run.
resource "google_workflows_workflow" "this" {
  project         = var.project_id
  region          = var.region
  name            = "ingestion-${var.env}"
  description     = "Orquestra o pipeline de ingestao no Cloud Run (${var.env})."
  service_account = google_service_account.orchestrator.email
  source_contents = local.workflow_source
}

# Cloud Scheduler que aciona o Workflow diariamente antes do Dataform.
resource "google_cloud_scheduler_job" "this" {
  project   = var.project_id
  region    = var.region
  name      = "ingestion-${var.env}"
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
    google_cloud_run_v2_service_iam_member.run_invoker,
  ]
}
