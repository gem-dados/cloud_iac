variable "project_id" {
  description = "ID do projeto."
  type        = string
}

variable "name" {
  description = "Nome do servico Cloud Run."
  type        = string
}

variable "location" {
  description = "Regiao do servico (ex.: us-central1)."
  type        = string
}

variable "image" {
  description = "Imagem do container (ex.: us-central1-docker.pkg.dev/proj/repo/app:tag). Use um placeholder no primeiro apply; o deploy real vem da esteira do data_ingestion."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "service_account_email" {
  description = "E-mail da SA dedicada com que o servico roda."
  type        = string
}

variable "ingress" {
  description = "Controle de ingress (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY...)."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "deletion_protection" {
  description = "Protecao contra delecao do servico."
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Min de instancias (0 = scale to zero)."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Max de instancias."
  type        = number
  default     = 2
}

variable "resource_limits" {
  description = "Limites de CPU/memoria do container."
  type        = map(string)
  default = {
    cpu    = "1"
    memory = "512Mi"
  }
}

variable "env" {
  description = "Variaveis de ambiente NAO sensiveis (chave => valor)."
  type        = map(string)
  default     = {}
}

variable "secret_env" {
  description = "Variaveis sensiveis vindas do Secret Manager (chave => { secret, version })."
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))
  default = {}
}

variable "invokers" {
  description = "Membros que recebem roles/run.invoker. Vazio = ninguem (servico fechado)."
  type        = list(string)
  default     = []
}
