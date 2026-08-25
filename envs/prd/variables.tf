variable "project_id" {
  description = "ID do projeto GCP do ambiente."
  type        = string
}

variable "env" {
  description = "Nome do ambiente (stg | prd)."
  type        = string
}

variable "region" {
  description = "Regiao default dos recursos regionais."
  type        = string
  default     = "us-central1"
}

variable "bq_location" {
  description = "Localizacao dos datasets BigQuery."
  type        = string
  default     = "US"
}

variable "github_owner" {
  description = "Org no GitHub."
  type        = string
  default     = "gem-dados"
}

variable "org_id" {
  description = "ID numerico da organizacao GCP (para a tag de governanca 'environment')."
  type        = string
}

variable "manage_environment_tag" {
  description = "Liga o binding da tag 'environment'. Requer o state org/ aplicado antes."
  type        = bool
  default     = true
}

variable "bi_principals" {
  description = <<-EOT
    Principals do BI (Looker Studio, analistas) que leem o lake.
    Formato IAM, ex.: ["group:bi@gemdados.net"]. Preferir GRUPO a usuario solto:
    entrada/saida de pessoa vira gestao no Workspace, sem PR de Terraform.

    Estes principals recebem roles/bigquery.dataViewer SOMENTE no dataset marts.
    NUNCA conceda papel de BigQuery a eles no nivel do projeto: isso enxerga
    todos os datasets e anula o isolamento das camadas raw/staging/secure.

    Vazio (default) = nenhum acesso concedido; a esteira nao quebra.
  EOT
  type        = list(string)
  default     = []
}

variable "lake_readers" {
  description = <<-EOT
    Time de dados: le TODAS as camadas do lake (raw, staging, secure, marts).
    Formato IAM, ex.: ["group:data_team@gemdados.net"].

    Diferente de bi_principals, que le so marts. Sao publicos distintos:
    quem CONSTROI o lake precisa investigar do raw ao mart; quem CONSOME
    enxerga so o produto final.
  EOT
  type        = list(string)
  default     = []
}

variable "google_drive_folder_id" {
  description = "ID da pasta no Google Drive contendo os CSVs de relatorios do DataCamp."
  type        = string
  default     = ""
}
