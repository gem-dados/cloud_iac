variable "project_id" {
  description = "ID do projeto GCP do ambiente."
  type        = string
}

variable "env" {
  description = "Nome do ambiente (stg | prd)."
  type        = string
}

variable "region" {
  description = "Regiao default dos recursos regionais."
  type        = string
  default     = "us-central1"
}

variable "bq_location" {
  description = "Localizacao dos datasets BigQuery."
  type        = string
  default     = "US"
}

variable "github_owner" {
  description = "Org no GitHub."
  type        = string
  default     = "gem-dados"
}
