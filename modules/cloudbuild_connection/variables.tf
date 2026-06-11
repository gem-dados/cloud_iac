variable "project_id" {
  description = "ID do projeto onde a conexao sera criada."
  type        = string
}

variable "location" {
  description = "Regiao da conexao/repo (ex.: us-central1). Triggers 2nd gen sao regionais."
  type        = string
}

variable "connection_name" {
  description = "Nome da conexao Cloud Build (ex.: github-gem-dados)."
  type        = string
  default     = "github-gem-dados"
}

variable "app_installation_id" {
  description = "ID da instalacao do GitHub App 'Cloud Build' na org."
  type        = string
}

variable "oauth_token_secret_version" {
  description = "Resource name da versao do secret com o PAT do GitHub (projects/x/secrets/github-oauth-token/versions/latest)."
  type        = string
}

variable "repo_name" {
  description = "Nome do repo registrado na conexao (ex.: cloud_iac)."
  type        = string
}

variable "remote_uri" {
  description = "URL HTTPS .git do repo (ex.: https://github.com/gem-dados/cloud_iac.git)."
  type        = string
}
