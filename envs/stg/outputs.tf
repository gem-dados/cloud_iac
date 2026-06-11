output "project_id" {
  value = var.project_id
}

output "raw_bucket" {
  value = module.bucket_raw.name
}

output "datasets" {
  value = [module.ds_raw.dataset_id, module.ds_staging.dataset_id, module.ds_marts.dataset_id]
}

output "artifact_registry_url" {
  value = module.artifact_ingestion.docker_repo_url
}

output "ingestion_service_uri" {
  value = module.ingestion_service.uri
}

output "ingestion_service_account" {
  value = google_service_account.ingestion.email
}
