output "name" {
  description = "Nome do servico."
  value       = google_cloud_run_v2_service.this.name
}

output "uri" {
  description = "URL do servico Cloud Run."
  value       = google_cloud_run_v2_service.this.uri
}
