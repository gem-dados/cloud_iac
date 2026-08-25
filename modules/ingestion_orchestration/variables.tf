variable "project_id" {
  description = "ID do projeto GCP."
  type        = string
}

variable "region" {
  description = "Regiao dos recursos (ex.: us-central1)."
  type        = string
}

variable "env" {
  description = "Ambiente (stg | prd)."
  type        = string
}

variable "service_name" {
  description = "Nome do servico Cloud Run data-ingestion."
  type        = string
}

variable "service_uri" {
  description = "URI base do servico Cloud Run data-ingestion."
  type        = string
}

variable "dataform_workflow_name" {
  description = "Nome do Workflow do Dataform a ser disparado no final da ingestao."
  type        = string
}

variable "cron_schedule" {
  description = "Expressao cron do agendamento diario da ingestao."
  type        = string
  default     = "0 6 * * *"
}

variable "time_zone" {
  description = "Fuso horario do Scheduler."
  type        = string
  default     = "America/Sao_Paulo"
}
