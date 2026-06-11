# =============================================================================
# project_baseline
# Prepara um projeto GCP "cru" para ser gerido 100% por IaC:
#   - habilita as APIs necessarias de forma declarativa
#   - (opcional) faz o binding da tag de governanca 'environment'
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

# ---------------------------------------------------------------------------
# Tag de governanca 'environment' (opcional)
# A tag key + values sao criadas no state `org/` (admin). Aqui so amarramos o
# projeto ao value certo (Staging/Production). Requer que a esteira (SA
# terraform-ci) tenha roles/resourcemanager.tagUser — concedido no `org/`.
# ---------------------------------------------------------------------------
data "google_project" "this" {
  count      = var.manage_environment_tag ? 1 : 0
  project_id = var.project_id
}

data "google_tags_tag_key" "environment" {
  count      = var.manage_environment_tag ? 1 : 0
  parent     = "organizations/${var.org_id}"
  short_name = "environment"
}

data "google_tags_tag_value" "environment" {
  count      = var.manage_environment_tag ? 1 : 0
  parent     = data.google_tags_tag_key.environment[0].id
  short_name = var.environment_tag_value
}

resource "google_tags_tag_binding" "environment" {
  count = var.manage_environment_tag ? 1 : 0

  parent    = "//cloudresourcemanager.googleapis.com/projects/${data.google_project.this[0].number}"
  tag_value = data.google_tags_tag_value.environment[0].id
}
