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

# ID da pasta do Google Drive (datasets_csv_brutos)
google_drive_folder_id = "1RfxrbceHMx8W4jSlTsmq09KNa4eR7iCg"

# ---------------------------------------------------------------------------
# COMO DAR ACESSO A ALGUEM
#
# Escolha a lista pelo papel da pessoa — sao publicos diferentes:
#
#   lake_readers  -> quem CONSTROI o lake. Le as 4 camadas (raw, staging,
#                    secure, marts), porque precisa investigar do dado cru ate
#                    o mart para debugar transformacao.
#
#   bi_principals -> quem CONSOME o resultado (Looker Studio, analista). Le
#                    SOMENTE marts. Nunca raw/staging/secure — e isso que
#                    mantem PII fora do alcance de quem nao precisa dela.
#
# Prefira GRUPO a usuario solto: entrada e saida de pessoa vira gestao no
# Google Workspace, sem precisar de PR de Terraform para cada uma.
#
# Exemplo (descomente e ajuste quando o BI existir):
#
# bi_principals = ["group:bi@gemdados.net"]
#
# Para uma pessoa especifica, o formato e "user:":
#
# bi_principals = ["group:bi@gemdados.net", "user:fulano@gemdados.net"]
#
# NUNCA conceda papel de BigQuery a pessoas no nivel do PROJETO: um
# roles/bigquery.dataViewer no projeto enxerga TODOS os datasets e anula esta
# separacao inteira, sem aparecer no IAM de dataset nenhum.
# ---------------------------------------------------------------------------
