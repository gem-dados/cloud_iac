# =============================================================================
# ORG — config a nivel de ORGANIZACAO. Roda 1x, por um ADMIN com permissao de
# org (roles/resourcemanager.tagAdmin + organizationAdmin). NAO roda pela
# esteira por-ambiente (que so tem permissao no projeto).
#
# Cria a tag de governanca 'environment' (key + values) e libera as SAs da
# esteira a criar bindings nos seus projetos.
#
#   cd org
#   terraform init
#   terraform apply
# =============================================================================

# Tag key compartilhada por toda a org.
resource "google_tags_tag_key" "environment" {
  parent      = "organizations/${var.org_id}"
  short_name  = "environment"
  description = "Designacao de ambiente do projeto (governanca)."
}

# Values padrao sugeridos pelo GCP.
resource "google_tags_tag_value" "values" {
  for_each = toset(var.environment_values)

  parent      = google_tags_tag_key.environment.id
  short_name  = each.value
  description = "Ambiente: ${each.value}."
}

# Permite que cada SA da esteira (terraform-ci de cada projeto) crie o binding
# da tag no seu proprio projeto.
resource "google_organization_iam_member" "tag_user" {
  for_each = toset(var.terraform_sa_emails)

  org_id = var.org_id
  role   = "roles/resourcemanager.tagUser"
  member = "serviceAccount:${each.value}"
}
