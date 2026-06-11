output "repository_id" {
  description = "ID do repositorio."
  value       = google_artifact_registry_repository.this.repository_id
}

output "docker_repo_url" {
  description = "Prefixo de URL para push/pull de imagens."
  value       = "${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}
