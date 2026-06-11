# Bootstrap (rodar 1x por ambiente)

Cria o que a esteira precisa para funcionar **antes** de a esteira existir.
Depois disto, **nada mais e feito a mao** — tudo passa pela esteira.

Usa **Cloud Build 2nd gen** (repositories v2) para conectar ao GitHub.

## Pre-requisitos (admin)

1. `gcloud auth application-default login` com um usuario `roles/owner`
   (ou equivalente) nos projetos `gem-dados-lake-stg/-prd`.
2. **Instalar o GitHub App "Cloud Build"** na org `gem-dados`:
   Console → Cloud Build → Repositories → *Create host connection* → GitHub.
   Anote o **installation id** (vai em `*.tfvars` como `github_app_installation_id`).
3. **Criar um PAT** no GitHub (escopo `repo`) para a conexao 2nd gen.

## Higienizacao do projeto cru (config default)

Os projetos foram criados "limpos". Remova a config default antes de seguir:

```bash
for P in gem-dados-lake-stg gem-dados-lake-prd; do
  gcloud compute networks delete default --project="$P" -q || true
  N=$(gcloud projects describe "$P" --format='value(projectNumber)')
  gcloud projects remove-iam-policy-binding "$P" \
    --member="serviceAccount:${N}-compute@developer.gserviceaccount.com" \
    --role="roles/editor" -q || true
done
```

## Aplicar

Este config serve aos DOIS projetos (stg e prd). Para os states nao se
misturarem, usamos um **workspace por ambiente** (state local isolado em
`terraform.tfstate.d/<workspace>/`). A conexao 2nd gen so valida se o secret
do PAT ja tiver uma versao — por isso o apply do secret vem antes.

```bash
cd bootstrap
terraform init

# ======================= STAGING =======================
terraform workspace new stg     # (ou: terraform workspace select stg)

# 1) Cria so o secret (ainda sem o PAT dentro)
terraform apply -var-file=stg.tfvars \
  -target=google_secret_manager_secret.github_oauth

# 2) Coloca o PAT no secret (NUNCA no codigo)
printf '%s' 'SEU_PAT_DO_GITHUB' | \
  gcloud secrets versions add github-oauth-token \
  --project=gem-dados-lake-stg --data-file=-

# 3) Edite stg.tfvars: github_app_installation_id = "<id real>"

# 4) Aplica o resto
terraform apply -var-file=stg.tfvars

# ======================= PRODUCAO ======================
terraform workspace new prd     # (ou: terraform workspace select prd)

terraform apply -var-file=prd.tfvars \
  -target=google_secret_manager_secret.github_oauth
printf '%s' 'SEU_PAT_DO_GITHUB' | \
  gcloud secrets versions add github-oauth-token \
  --project=gem-dados-lake-prd --data-file=-
# edite prd.tfvars: github_app_installation_id = "<id real>"
terraform apply -var-file=prd.tfvars
```

> Os states do bootstrap ficam **locais** (`terraform.tfstate.d/`). Guarde-os
> num cofre (1Password, etc.). **Nunca** commite — o `.gitignore` ja bloqueia
> `*.tfstate` e o diretorio `.terraform/`.

## O que e criado

| Recurso | Para que |
|---|---|
| `gs://<project>-tfstate` | state remoto do Terraform (1 bucket por projeto) |
| SA `terraform-ci@...` | identidade que a esteira usa para aplicar IaC |
| IAM da SA | papeis curados (sem `owner`) — menor privilegio |
| Secret `github-oauth-token` | PAT do GitHub para a conexao 2nd gen |
| Conexao + repo (2nd gen) | liga o Cloud Build ao repo no GitHub |
| Trigger `iac-<env>-apply` | aplica no push da branch do ambiente |
| Trigger `iac-<env>-plan-pr` | `plan` + scans de seguranca em PRs |

Depois do bootstrap, va para `envs/<env>` e a esteira assume o controle.
