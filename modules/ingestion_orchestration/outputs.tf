output "workflow_id" {
  description = "ID do Workflow de ingestao."
  value       = google_workflows_workflow.this.id
}

output "scheduler_job_id" {
  description = "ID do Cloud Scheduler job de ingestao."
  value       = google_cloud_scheduler_job.this.id
}

output "orchestrator_service_account" {
  description = "Email da Service Account que executa a orquestracao da ingestao."
  value       = google_service_account.orchestrator.email
}
