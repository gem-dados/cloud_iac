variable "org_id" {
  description = "ID numerico da organizacao GCP."
  type        = string
}

variable "region" {
  description = "Regiao default do provider."
  type        = string
  default     = "us-central1"
}

variable "environment_values" {
  description = "Values da tag environment a criar."
  type        = list(string)
  default     = ["Production", "Staging", "Development", "Test"]
}

variable "terraform_sa_emails" {
  description = "E-mails das SAs da esteira que recebem roles/resourcemanager.tagUser na org."
  type        = list(string)
  default = [
    "terraform-ci@gem-dados-lake-stg.iam.gserviceaccount.com",
    "terraform-ci@gem-dados-lake-prd.iam.gserviceaccount.com",
  ]
}
