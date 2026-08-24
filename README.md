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

## As três esteiras (todas branch-por-ambiente: `stg`→stg, `main`→prd)

| Esteira | Repo | Dispara em | Faz |
|---|---|---|---|
| **IaC** | `cloud_iac` | push na branch | `terraform apply` do `envs/<env>` (este repo) |
| **App** | `data_ingestion` | push na branch | build imagem → Artifact Registry → deploy Cloud Run |
| **Dataform** | `data_models` | **push na branch** (imediato) + **Cloud Scheduler** (cron diário, backstop) | Cloud Build dispara o Workflow → compila o repo → executa no BigQuery como `dataform-runner` |

- As esteiras de **App** e **Dataform** são **definidas aqui** (no `cloud_iac`):
  o trigger do `data_ingestion` e o do `data_models` (Cloud Build → Workflow),
  além da orquestração agendada do Dataform (Cloud Scheduler + Cloud Workflows),
  ficam em `envs/<env>/main.tf`. O código de cada uma vive no seu repo
  (`data_ingestion`, `data_models`).
- **Dataform — deploy no push (imediato):** um Cloud Build trigger no push da
  branch do ambiente aciona o mesmo Cloud Workflow `dataform-<env>` (via
  `gcloud workflows run`), materializando na hora em vez de esperar o cron. A SA
  `terraform-ci` que roda o trigger recebe `roles/workflows.invoker`; o Workflow
  segue executando como a SA orquestradora → `dataform-runner`. O Cloud Scheduler
  continua como **backstop diário**.
- **Dataform — por que Scheduler+Workflows e não o agendador nativo:** os repos
  Dataform têm `strictActAsChecks` ligado (padrão seguro), o que exige uma SA
  de execução explícita (`dataform-runner`) e bloqueia o autorelease nativo.
  O provider Terraform não expõe esse campo, então usamos o padrão **GCP-nativo
  recomendado pela Google**: Cloud Scheduler → Cloud Workflows → Dataform API.
- **Cloud Run** tem `ignore_changes` na imagem: o Terraform cria o serviço, mas
  quem publica a imagem real é a esteira de App (sem os dois brigarem).

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
│   ├── dataform_repository/   # repo Dataform (git-linkado)
│   ├── dataform_orchestration/# Scheduler + Workflows → Dataform API (agendamento)
│   ├── cloudbuild_connection/ # conexão 2nd gen + repo (GitHub App)
│   └── cloudbuild_trigger/    # wrapper de trigger
├── envs/                      # amarra os módulos + esteiras de app/dataform
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
3. **Bootstrap** de cada ambiente — usa **um workspace por ambiente** (state
   local isolado) e o PAT entra à mão no Secret Manager. Passo a passo completo
   em [bootstrap/README.md](./bootstrap/README.md).
4. **Org** (tag de governança `environment`) — roda **depois dos dois
   bootstraps** (state no bucket do prd; concede `tagUser` às duas SAs). Precisa
   de admin de organização. Ver [org/README.md](./org/README.md).
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

## Camadas do BigQuery e quem enxerga o quê

O lake tem quatro datasets, e o acesso é concedido **por dataset**, nunca no
nível do projeto:

| Camada | Conteúdo | `lake_readers` (time de dados) | `bi_principals` (BI) |
|---|---|---|---|
| `raw` | dado cru da ingestão, ainda com PII | lê | **não** |
| `staging` | intermediário, não é contrato com ninguém | lê | **não** |
| `secure` | dado sensível/identificável (o cofre de anonimização) | lê | **não** |
| `marts` | modelos finais | lê | lê |

São **dois públicos diferentes**, e a distinção é o coração do desenho:

- **`lake_readers`** — quem *constrói* o lake. Precisa investigar do `raw` ao
  `mart` para debugar uma transformação, então lê todas as camadas. Hoje:
  `group:data_team@gemdados.net`.
- **`bi_principals`** — quem *consome* o resultado (Looker Studio, analistas).
  Lê só `marts`, que é a única superfície pública do lake.

Confundir os dois é o erro que essa separação existe para evitar: dar acesso de
construtor a quem só consome espalha PII sem necessidade.

### Bloquear é não conceder

Não existe regra de negação aqui. O BI recebe `roles/bigquery.dataViewer`
apenas em `marts`, e mais nada — as outras camadas ficam invisíveis porque
ninguém deu acesso, não porque alguém proibiu. É mais simples de auditar: para
saber quem lê `raw`, basta olhar o IAM de `raw`.

Isso tem **uma condição que não pode ser quebrada**:

> Nunca conceda papel de BigQuery a uma pessoa ou grupo no nível do **projeto**.

Um `roles/bigquery.dataViewer` no projeto enxerga *todos* os datasets e anula
o isolamento inteiro, sem aviso e sem aparecer no IAM do dataset. Se alguém
pedir acesso "ao BigQuery", a resposta é adicionar em `bi_principals`, não um
grant no projeto.

### Como dar acesso a alguém

Edite o `terraform.tfvars` do ambiente. Escolha a lista pelo papel da pessoa:

```hcl
lake_readers  = ["group:data_team@gemdados.net"]  # constrói o lake: lê tudo
bi_principals = ["group:bi@gemdados.net"]         # consome: lê só marts
```

Prefira **grupo** a usuário solto: entrada e saída de pessoa vira gestão no
Google Workspace, sem precisar de PR de Terraform para cada uma.

### Por que também existe `jobUser` no projeto

`dataViewer` por dataset diz *o que* você pode ler. Mas rodar qualquer query
exige `roles/bigquery.jobUser` no **projeto** — sem ele o BigQuery devolve
`bigquery.jobs.create denied` e a pessoa não consegue nem começar.

Isso não fura o isolamento: `jobUser` não dá acesso a dado nenhum, só autoriza
criar o job. O que a pessoa consegue ler continua definido dataset a dataset.
A combinação (`jobUser` amplo + `dataViewer` estreito) é o menor privilégio que
de fato funciona no BigQuery.

### E as service accounts?

`data-ingestion` e `dataform-runner` têm `roles/bigquery.dataEditor` no
**projeto** — precisam escrever em várias camadas. Elas são identidades de
máquina da própria esteira, não gente. Estreitar isso para grants por dataset
é uma melhoria válida de defesa em profundidade, mas não é o que a separação
BI ↔ lake resolve.

---

## Segurança

Resumo em [SECURITY.md](./SECURITY.md). Pontos-chave: sem segredo no git
(gitleaks), sem chave JSON (a esteira usa a SA direto), buckets sem acesso
público, SA da esteira sem `owner`, produção só pela esteira.
