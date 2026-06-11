# org/ — config a nivel de organizacao (admin, 1x)

Cria a tag de governanca `environment` (que o GCP recomenda em cada projeto) e
libera as SAs da esteira a aplicar o binding nos seus projetos.

## Quem roda

Um **admin com permissao de organizacao**:
- `roles/resourcemanager.tagAdmin` (criar tag key/values)
- `roles/resourcemanager.organizationAdmin` ou `iam.organizationRoleAdmin`
  para conceder `tagUser` na org

**Nao** roda pela esteira por-ambiente (que so tem permissao no projeto).

## Ordem

Depois do `bootstrap/` (precisa do bucket `gem-dados-lake-prd-tfstate` e das
SAs `terraform-ci`), e **antes** do primeiro apply dos `envs/` com a tag ligada.

```
bootstrap/  ->  org/  ->  envs/ (esteira)
```

## Aplicar

```bash
cd org
terraform init
terraform apply        # usa terraform.tfvars (org_id)
```

## O que cria

| Recurso | Para que |
|---|---|
| tag key `environment` | designacao de ambiente (org-wide) |
| tag values `Production/Staging/Development/Test` | valores possiveis |
| `tagUser` na org para as SAs `terraform-ci` | esteira pode bindar a tag no projeto |

Depois disto, cada `envs/<env>` (com `manage_environment_tag = true`, ja o
default) amarra seu projeto ao value certo: `stg`→Staging, `prd`→Production.

> Se preferir **nao** usar a tag, ponha `manage_environment_tag = false` nos
> `terraform.tfvars` de `envs/stg` e `envs/prd` e pule este state.
