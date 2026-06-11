output "dataset_id" {
  description = "ID do dataset."
  value       = google_bigquery_dataset.this.dataset_id
}

output "self_link" {
  description = "Self link do dataset."
  value       = google_bigquery_dataset.this.self_link
}
