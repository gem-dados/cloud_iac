variable "project_id" {
  description = "ID do projeto onde o trigger sera criado."
  type        = string
}

variable "location" {
  description = "Regiao do trigger (2nd gen e regional, ex.: us-central1)."
  type        = string
}

variable "repository_id" {
  description = "ID do repositorio 2nd gen (output repository_id do cloudbuild_connection)."
  type        = string
}

variable "name" {
  description = "Nome do trigger."
  type        = string
}

variable "description" {
  description = "Descricao do trigger."
  type        = string
  default     = "Gerido por Terraform."
}

variable "event_type" {
  description = "Tipo de evento: push ou pull_request."
  type        = string
  default     = "push"
  validation {
    condition     = contains(["push", "pull_request"], var.event_type)
    error_message = "event_type deve ser 'push' ou 'pull_request'."
  }
}

variable "branch_regex" {
  description = "Regex da branch (ex.: ^main$, ^stg$)."
  type        = string
}

variable "pr_comment_control" {
  description = "Controle de comentario para PR (COMMENTS_ENABLED, COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY)."
  type        = string
  default     = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
}

variable "build_config_file" {
  description = "Caminho do arquivo de build no repo (ex.: cloudbuild.yaml)."
  type        = string
  default     = "cloudbuild.yaml"
}

variable "service_account_id" {
  description = "Resource name da SA que executa o build (projects/x/serviceAccounts/terraform-ci@x.iam.gserviceaccount.com)."
  type        = string
  default     = null
}

variable "included_files" {
  description = "Glob de arquivos que disparam o trigger (vazio = qualquer arquivo)."
  type        = list(string)
  default     = []
}

variable "substitutions" {
  description = "Substituicoes passadas ao build (ex.: { _ENV = \"stg\" })."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags do trigger."
  type        = list(string)
  default     = []
}
