variable "project_id" {
  description = "ID do projeto."
  type        = string
}

variable "region" {
  description = "Regiao (Workflows/Scheduler/Dataform)."
  type        = string
}

variable "env" {
  description = "Nome do ambiente (stg | prd)."
  type        = string
}

variable "repository_name" {
  description = "Nome do repositorio Dataform (ex.: data-models)."
  type        = string
}

variable "git_branch" {
  description = "Branch/commitish a compilar (stg | main)."
  type        = string
}

variable "runner_service_account_email" {
  description = "E-mail da SA que EXECUTA o workflow no BigQuery (dataform-runner)."
  type        = string
}

variable "runner_service_account_id" {
  description = "Resource id da SA runner (para o grant de actAs)."
  type        = string
}

variable "cron_schedule" {
  description = "Agendamento (cron)."
  type        = string
  default     = "0 7 * * *"
}

variable "time_zone" {
  description = "Fuso do agendamento."
  type        = string
  default     = "America/Sao_Paulo"
}
