# Modulo: `project_baseline`

Habilita as APIs necessarias em um projeto GCP de forma declarativa.

## Uso

```hcl
module "baseline" {
  source     = "../../modules/project_baseline"
  project_id = var.project_id
  # activate_apis usa um default sensato; sobrescreva se precisar.
}
```

## Higienizacao da config default (rodar 1x no bootstrap)

Projetos GCP novos vem com uma **rede default** e com a **SA default de Compute
com papel Editor**. Como os repos sao **publicos** e usados por **alunos**,
removemos isso manualmente uma vez (o Terraform passa a ser a unica fonte de
verdade depois disso):

```bash
PROJECT_ID=gem-dados-lake-stg

# 1) remove a rede default e suas firewall rules
gcloud compute networks delete default --project="$PROJECT_ID" -q || true

# 2) remove o papel Editor da SA default de Compute (menor privilegio)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/editor" -q || true
```

> Esses comandos tambem estao no `bootstrap/` para serem rodados de forma
> guiada. Depois disso, qualquer recurso novo entra **apenas via esteira**.
