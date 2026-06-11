output "environment_tag_key_id" {
  description = "ID da tag key environment (tagKeys/NNN)."
  value       = google_tags_tag_key.environment.id
}

output "environment_tag_values" {
  description = "Mapa short_name => id dos values criados."
  value       = { for k, v in google_tags_tag_value.values : k => v.id }
}
