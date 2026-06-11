output "id" {
  description = "ID do trigger."
  value       = google_cloudbuild_trigger.this.id
}

output "trigger_id" {
  description = "trigger_id gerado."
  value       = google_cloudbuild_trigger.this.trigger_id
}
