output "project_id" {
  description = "ID do projeto preparado."
  value       = var.project_id
}

output "enabled_apis" {
  description = "APIs habilitadas por este modulo."
  value       = [for s in google_project_service.this : s.service]
}
