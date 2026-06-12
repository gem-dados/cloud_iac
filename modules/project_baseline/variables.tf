variable "project_id" {
  description = "ID do projeto GCP a ser preparado (ex.: gem-dados-lake-stg)."
  type        = string
}

variable "manage_environment_tag" {
  description = "Se true, faz o binding da tag de governanca 'environment' no projeto (a tag key/values vem do state org/)."
  type        = bool
  default     = false
}

variable "org_id" {
  description = "ID numerico da organizacao (necessario quando manage_environment_tag = true)."
  type        = string
  default     = ""
}

variable "environment_tag_value" {
  description = "Short name do value da tag environment (ex.: Staging, Production)."
  type        = string
  default     = ""
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
    "workflows.googleapis.com",
    "workflowexecutions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}
