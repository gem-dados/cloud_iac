output "workflow_id" {
  description = "ID do Cloud Workflow."
  value       = google_workflows_workflow.this.id
}

output "scheduler_job" {
  description = "Nome do job do Cloud Scheduler."
  value       = google_cloud_scheduler_job.this.name
}

output "orchestrator_sa" {
  description = "E-mail da SA orquestradora."
  value       = google_service_account.orchestrator.email
}
