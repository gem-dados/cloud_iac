# State remoto no proprio projeto do ambiente (1 bucket por projeto).
# O bucket e criado pelo bootstrap/ antes do primeiro `terraform init` aqui.
terraform {
  backend "gcs" {
    bucket = "gem-dados-lake-prd-tfstate"
    prefix = "cloud_iac/envs/prd"
  }
}
