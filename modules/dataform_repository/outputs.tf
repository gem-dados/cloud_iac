output "name" {
  description = "Nome do repositorio Dataform."
  value       = google_dataform_repository.this.name
}

output "id" {
  description = "ID completo do repositorio Dataform."
  value       = google_dataform_repository.this.id
}
