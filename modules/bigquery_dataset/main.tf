# =============================================================================
# bigquery_dataset — dataset do data lake (camadas raw / staging / marts)
# =============================================================================

resource "google_bigquery_dataset" "this" {
  project    = var.project_id
  dataset_id = var.dataset_id
  location   = var.location

  friendly_name = var.friendly_name
  description   = var.description

  delete_contents_on_destroy = var.delete_contents_on_destroy

  default_table_expiration_ms = var.default_table_expiration_ms

  labels = var.labels
}

# ---------------------------------------------------------------------------
# Acesso de leitura POR DATASET (least privilege).
#
# Usa google_bigquery_dataset_iam_member (aditivo) de proposito, e nao o bloco
# `access` dentro do dataset: o bloco `access` e AUTORITATIVO e substituiria as
# entradas que o BigQuery cria sozinho (owner do projeto, etc.), o que poderia
# tirar acesso de quem ja usa o dataset. O _iam_member so acrescenta.
#
# ATENCAO: isto so isola de verdade se ninguem tiver papel de BigQuery no nivel
# do PROJETO. Um roles/bigquery.dataViewer no projeto enxerga TODOS os datasets
# e anula esta configuracao. Ver README.
# ---------------------------------------------------------------------------
resource "google_bigquery_dataset_iam_member" "viewers" {
  for_each = toset(var.viewers)

  project    = var.project_id
  dataset_id = google_bigquery_dataset.this.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = each.value
}
