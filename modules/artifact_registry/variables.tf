variable "project_id" {
  description = "ID do projeto."
  type        = string
}

variable "location" {
  description = "Regiao do Artifact Registry (ex.: us-central1)."
  type        = string
}

variable "repository_id" {
  description = "ID do repositorio (ex.: data-ingestion)."
  type        = string
}

variable "description" {
  description = "Descricao do repositorio."
  type        = string
  default     = "Imagens dos jobs de ingestao (gerido por Terraform)."
}

variable "labels" {
  description = "Labels."
  type        = map(string)
  default     = {}
}
