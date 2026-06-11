variable "project_id" {
  description = "ID do projeto GCP do ambiente (gem-dados-lake-stg | gem-dados-lake-prd)."
  type        = string
}

variable "env" {
  description = "Nome do ambiente (stg | prd)."
  type        = string
}

variable "region" {
  description = "Regiao para o bucket de state e triggers."
  type        = string
  default     = "us-central1"
}

variable "github_owner" {
  description = "Org no GitHub."
  type        = string
  default     = "gem-dados"
}

variable "github_repo" {
  description = "Nome do repo de IaC."
  type        = string
  default     = "cloud_iac"
}

variable "github_app_installation_id" {
  description = "ID da instalacao do GitHub App 'Cloud Build' na org gem-dados (obtido ao instalar o app)."
  type        = string
}
