# cloud_iac — Infraestrutura como Código (gem-dados)

Infra **100% Terraform** dos projetos do data lake `gem-dados`, aplicada
**somente** pela esteira (Cloud Build). É o repositório-base: define projetos,
APIs, BigQuery, buckets, Cloud Run, Artifact Registry e Dataform.

> Projeto educacional, **repositórios públicos**, mantido por **estudantes**.
> Por isso a régua de segurança é alta — veja [SECURITY.md](./SECURITY.md).

---

## Visão geral

```
                      GitHub (org gem-dados, repos públicos)
                                    │
          ┌─────────────────────────┴─────────────────────────┐
          │                         │                          │
      cloud_iac                data_ingestion              data_models
   (Terraform / IaC)        (Python → Cloud Run)         (SQL → Dataform)
          │                         │                          │
          │  push/PR → Cloud Build  │  push → Cloud Build      │ Dataform
          ▼                         ▼                          ▼
  ┌───────────────────────────────────────────────────────────────────┐
  │  GCP — pasta "lake"                                                │
  │                                                                   │
  │   gem-dados-lake-stg            gem-dados-lake-prd                 │
  │   ├─ BigQuery: raw/staging/marts    (mesma estrutura)             │
  │   ├─ GCS: <proj>-raw                                              │
  │   ├─ Artifact Registry: data-ingestion                           │
  │   ├─ Cloud Run: data-ingestion                                   │
  │   └─ Dataform: data-models                                       │
  └───────────────────────────────────────────────────────────────────┘
```

| Ambiente | Projeto GCP | Branch que aplica |
|---|---|---|
| Staging | `gem-dados-lake-stg` | `stg` |
| Produção | `gem-dados-lake-prd` | `main` |

**Promoção:** abre-se PR de `stg` → `main`. Merge na `main` = deploy em produção.
**Nada** sobe a produção fora da esteira.

---

## Por que esta estrutura

- **Diretório por ambiente** (`envs/stg`, `envs/prd`) + **state em bucket por
  projeto** + **branch por ambiente**. **Não** usamos `terraform workspace`
  (1 backend compartilhado é fácil de selecionar errado e aplicar em prd sem
  querer — risco alto com alunos). Pastas separadas dão isolamento físico:
  cada ambiente tem seu próprio state, suas próprias credenciais e seu próprio
  projeto GCP.
- **Módulos reutilizáveis** (`modules/`): adicionar recurso = copiar um bloco
  `module {}` no `envs/<env>/main.tf`. Essa é a parte "fácil de add recursos".
- **Bootstrap separado**: resolve o ovo-e-galinha (cria state bucket, SA e
  triggers antes de a esteira existir). Roda 1x, à mão, por um admin.

---

## Estrutura

```
cloud_iac/
├── bootstrap/                 # rodar 1x por ambiente (state bucket + SA + triggers)
│   ├── main.tf  variables.tf  providers.tf
│   ├── stg.tfvars  prd.tfvars
│   └── README.md
├── org/                       # rodar 1x por um admin de org (tag 'environment')
├── modules/                   # blocos reutilizáveis
│   ├── project_baseline/      # habilita APIs
│   ├── gcs_bucket/            # bucket seguro (sem acesso público)
│   ├── bigquery_dataset/      # camadas raw/staging/marts
│   ├── cloud_run_service/     # serviço Cloud Run (SA dedicada + secrets)
│   ├── artifact_registry/     # repo Docker
│   ├── dataform_repository/   # repo Dataform
│   └── cloudbuild_trigger/    # wrapper de trigger
├── envs/
│   ├── stg/                   # gem-dados-lake-stg
│   └── prd/                   # gem-dados-lake-prd
├── cloudbuild.yaml            # esteira de APPLY (push na branch do env)
├── cloudbuild-pr.yaml         # esteira de PR (gitleaks + tfsec + plan)
├── .pre-commit-config.yaml    # guardrails locais
├── .gitleaks.toml             # regras anti-segredo
├── SECURITY.md
└── Makefile
```

---

## Setup (uma vez, por um admin)

1. **Higienizar os projetos crus** (remove rede default e Editor da SA default):
   ver [bootstrap/README.md](./bootstrap/README.md).
2. **Conectar** o repo ao Cloud Build de cada projeto via **2nd gen**
   (host connection + GitHub App). O bootstrap cria a conexao/repo/triggers;
   você só instala o GitHub App e gera o PAT (ver `bootstrap/README.md`).
3. **Bootstrap**:
   ```bash
   cd bootstrap
   terraform init
   terraform apply -var-file=stg.tfvars
   terraform apply -var-file=prd.tfvars
   ```
4. **Org** (tag de governança `environment`, admin de org — ver [org/README.md](./org/README.md)):
   ```bash
   cd org && terraform init && terraform apply
   ```
5. **Branch protection** em `main` e `stg` (ver [SECURITY.md](./SECURITY.md)).

A partir daqui, ninguém roda `apply` à mão — a esteira faz tudo.

---

## Fluxo de trabalho diário (aluno)

```bash
git checkout stg && git pull
git checkout -b feat/minha-mudanca

# edite envs/stg/main.tf (copie um bloco module {} e ajuste)

pre-commit run --all-files          # guardrails locais
git commit -m "feat: novo dataset X"
git push -u origin feat/minha-mudanca
# abra PR para 'stg' -> check roda plan + scans -> review -> merge
#   merge em 'stg'  => aplica em gem-dados-lake-stg
#   PR de stg->main => aplica em gem-dados-lake-prd
```

> Localmente você pode rodar `make plan ENV=stg`, mas o `apply` "de verdade"
> é sempre da esteira.

---

## Como adicionar um recurso novo

1. Existe módulo? Use-o. Não existe? Crie em `modules/<novo>/` seguindo o
   padrão `main.tf` / `variables.tf` / `outputs.tf`.
2. Instancie no `envs/stg/main.tf` (e em `envs/prd/main.tf`).
3. PR → revise o `plan` → merge em `stg` → valide → PR para `main`.

---

## Segurança

Resumo em [SECURITY.md](./SECURITY.md). Pontos-chave: sem segredo no git
(gitleaks), sem chave JSON (a esteira usa a SA direto), buckets sem acesso
público, SA da esteira sem `owner`, produção só pela esteira.
