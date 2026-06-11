variable "project_id" {
  description = "ID do projeto."
  type        = string
}

variable "location" {
  description = "Regiao do Dataform (ex.: us-central1)."
  type        = string
}

variable "name" {
  description = "Nome do repositorio Dataform."
  type        = string
  default     = "data-models"
}

variable "git_url" {
  description = "URL HTTPS do repo data_models. null = repo Dataform sem git remoto (config manual depois)."
  type        = string
  default     = null
}

variable "default_branch" {
  description = "Branch default do repo git."
  type        = string
  default     = "main"
}

variable "token_secret_version" {
  description = "Resource name da versao do secret com o PAT do GitHub (ex.: projects/x/secrets/dataform-github-token/versions/latest)."
  type        = string
  default     = null
}

variable "default_database" {
  description = "Projeto GCP default onde o Dataform materializa as tabelas (normalmente o project_id do ambiente)."
  type        = string
  default     = null
}
