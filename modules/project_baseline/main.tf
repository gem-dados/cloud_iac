# =============================================================================
# project_baseline
# Prepara um projeto GCP "cru" para ser gerido 100% por IaC:
#   - habilita as APIs necessarias de forma declarativa
#   - (opcional) higieniza a config default do projeto (ver README do modulo)
#
# A SA default de Compute vem com o papel Editor "de brinde". Em projeto
# publico/educacional isso e um risco. A remocao desse grant e feita uma vez
# no bootstrap (gcloud) e documentada — nao gerimos aqui para evitar que um
# `google_project_iam_member` acabe RE-CONCEDENDO o papel por engano.
# =============================================================================

locals {
  apis = toset(var.activate_apis)
}

resource "google_project_service" "this" {
  for_each = local.apis

  project = var.project_id
  service = each.value

  # Nao desabilita a API (nem dependentes) ao destruir — evita quebrar
  # recursos que dependam dela.
  disable_dependent_services = false
  disable_on_destroy         = false
}
