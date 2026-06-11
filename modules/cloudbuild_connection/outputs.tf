output "connection_id" {
  description = "ID da conexao Cloud Build 2nd gen."
  value       = google_cloudbuildv2_connection.this.id
}

output "repository_id" {
  description = "ID do repositorio 2nd gen (usado em repository_event_config dos triggers)."
  value       = google_cloudbuildv2_repository.this.id
}
