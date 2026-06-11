# Seguranca — gem-dados

> Repos **publicos** + **alunos** = a superficie de erro mais comum e
> **segredo commitado**. Estes guardrails existem para tornar isso dificil.

## Camadas de defesa

| Camada | Onde | O que pega |
|---|---|---|
| `pre-commit` (gitleaks, detect-private-key) | maquina do aluno | segredo **antes** do commit |
| `.gitignore` | repo | `*.tfstate`, `*-key.json`, `.env`, `*.pem`... |
| Esteira PR (`cloudbuild-pr.yaml`) | Cloud Build | gitleaks + tfsec + `plan` antes do merge |
| Branch protection | GitHub | proibe push direto; exige review + check verde |
| Esteira APPLY (`cloudbuild.yaml`) | Cloud Build | unica forma de subir pra stg/prd |
| Menor privilegio | IAM (bootstrap) | SA da esteira sem `owner`; sem chaves JSON |

## Regras de ouro

1. **Nunca** commite segredo. Vai para o **Secret Manager**; o Terraform
   referencia por `secret_key_ref` / `data.google_secret_manager_secret_version`.
2. **Nunca** gere chave JSON de Service Account. A esteira usa a identidade da
   SA `terraform-ci` direto; localmente use `gcloud auth ... login`.
3. `*.tfvars` so guarda config **nao sensivel** (ids de projeto, regioes).
4. **Nada** sobe pra producao fora da esteira (`main` → prd).
5. Buckets sempre com `public_access_prevention = enforced` (repo publico!).

## Instalar os guardrails locais

```bash
pip install pre-commit
pre-commit install            # passa a rodar a cada commit
pre-commit run --all-files    # roda agora em tudo
```

## Vazou um segredo, e agora?

1. **Revogue/rotacione** o segredo no provedor (a remocao do git NAO basta —
   o historico publico ja foi lido por bots em segundos).
2. Crie um novo no Secret Manager.
3. Abra um incidente curto no PR explicando o que rotacionou.

## Branch protection (configurar 1x no GitHub)

Em cada repo → Settings → Branches → Add rule para `main` (e `stg`):

- Require a pull request before merging (1+ approval)
- Require status checks to pass (selecione o check do Cloud Build)
- Require conversation resolution
- Do not allow bypassing the above settings
- Block force pushes
