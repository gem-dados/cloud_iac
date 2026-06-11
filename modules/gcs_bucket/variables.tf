variable "project_id" {
  description = "ID do projeto onde o bucket sera criado."
  type        = string
}

variable "name" {
  description = "Nome global do bucket (precisa ser unico no GCS)."
  type        = string
}

variable "location" {
  description = "Localizacao do bucket (regiao ou multi-regiao, ex.: US, us-central1)."
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Classe de armazenamento."
  type        = string
  default     = "STANDARD"
}

variable "versioning" {
  description = "Habilita versionamento de objetos."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Permite destruir o bucket mesmo com objetos (use com cuidado fora de stg)."
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Regras de ciclo de vida. Ex.: [{ action_type = \"Delete\", age = 90 }]"
  type = list(object({
    action_type   = string
    age           = optional(number)
    storage_class = optional(string)
  }))
  default = []
}

variable "labels" {
  description = "Labels do bucket."
  type        = map(string)
  default     = {}
}
