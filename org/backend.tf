# State da config de org guardado no bucket do projeto prd (ja existe apos o
# bootstrap). Aplicado por um admin com permissao de organizacao.
terraform {
  backend "gcs" {
    bucket = "gem-dados-lake-prd-tfstate"
    prefix = "cloud_iac/org"
  }
}
