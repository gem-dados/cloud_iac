variable "project_id" {
  description = "ID do projeto."
  type        = string
}

variable "dataset_id" {
  description = "ID do dataset (ex.: raw, staging, marts)."
  type        = string
}

variable "location" {
  description = "Localizacao do dataset (ex.: US, southamerica-east1)."
  type        = string
  default     = "US"
}

variable "friendly_name" {
  description = "Nome amigavel do dataset."
  type        = string
  default     = null
}

variable "description" {
  description = "Descricao do dataset."
  type        = string
  default     = "Gerido por Terraform (gem-dados / cloud_iac)."
}

variable "delete_contents_on_destroy" {
  description = "Apaga tabelas ao destruir o dataset. Use true apenas em stg."
  type        = bool
  default     = false
}

variable "default_table_expiration_ms" {
  description = "Expiracao default de tabelas em ms (null = sem expiracao)."
  type        = number
  default     = null
}

variable "labels" {
  description = "Labels do dataset."
  type        = map(string)
  default     = {}
}
