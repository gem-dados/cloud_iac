# ==========================================================================
# Valores NAO sensiveis do ambiente PRD.
# NUNCA coloque segredos aqui (este arquivo vai para o repo PUBLICO).
# Segredos -> Secret Manager. Veja SECURITY.md.
# ==========================================================================
project_id   = "gem-dados-lake-prd"
env          = "prd"
region       = "us-central1"
bq_location  = "US"
github_owner = "gem-dados"
org_id       = "809669352691"

# Time de dados. Em prd fica VAZIO de proposito: producao so libera leitura
# com decisao explicita. Para liberar, descomente a linha abaixo.
# lake_readers = ["group:data_team@gemdados.net"]
