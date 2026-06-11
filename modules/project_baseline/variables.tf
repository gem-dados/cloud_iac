variable "project_id" {
  description = "ID do projeto GCP a ser preparado (ex.: gem-dados-lake-stg)."
  type        = string
}

variable "activate_apis" {
  description = "Lista de APIs (services) a habilitar no projeto."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "dataform.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}
