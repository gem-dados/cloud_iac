# Documentação Oficial — GEM Dados

Este diretório contém os códigos-fonte em LaTeX, arquivos de estilo, ativos visuais,
documentos de referência e scripts de compilação da plataforma de dados GEM Dados.

Todos os documentos utilizam a identidade visual definida no **Manual de Identidade Visual GEM Dados (2026)**:
- Fontes tipográficas: **Chakra Petch** (Regular, Medium, SemiBold, Bold)
- Paleta institucional: `#153B58` (primária) e `#2769B2` (secundária)

---

## Estrutura de Arquivos

```text
docs/
├── GEMDados_Documentacao_Tecnica.pdf # Documentação Técnica oficial compilada
├── GEMDados_Documentacao_Negocio.pdf # Documentação de Negócio oficial compilada
├── build.ps1                         # Script PowerShell para compilação automatizada
├── README.md                         # Guia de compilação e governança
├── latex/
   ├── assets/                       # Logotipo oficial e fontes Chakra Petch
   ├── gemdados.sty                  # Pacote de estilo e identidade visual compartilhado
   ├── documentacao_tecnica.tex      # Fonte LaTeX da Documentação Técnica (v1.4)
   └── documentacao_negocio.tex      # Fonte LaTeX da Documentação de Negócio (v1.6)
```

---

## Documentos Produzidos

| Documento | Versão | Código-Fonte | PDF Compilado | Escopo e Conteúdo |
|---|---|---|---|---|
| **Documentação Técnica** | v1.4 | [`latex/documentacao_tecnica.tex`](./latex/documentacao_tecnica.tex) | [`GEMDados_Documentacao_Tecnica.pdf`](./GEMDados_Documentacao_Tecnica.pdf) | Arquitetura GCP, 10 módulos Terraform, ingestão Python/Cloud Run, Dataform, views analíticas SQL (`vw_program_activity`), conexões Looker Studio, esteiras CI/CD e segurança. |
| **Documentação de Negócio** | v1.6 | [`latex/documentacao_negocio.tex`](./latex/documentacao_negocio.tex) | [`GEMDados_Documentacao_Negocio.pdf`](./GEMDados_Documentacao_Negocio.pdf) | Propósito, Squad de Dados, 6 perguntas de negócio atendidas, estrutura das 3 páginas do Dashboard Looker Studio, 3 filtros dinâmicos, governança e catálogo de 7 limitações técnicas. |

---

## Como Compilar os Documentos

A compilação pode ser executada através do script [`build.ps1`](./build.ps1), que gerencia automaticamente as passadas de compilação e a higienização de artefatos intermediários (`.aux`, `.log`, `.out`, `.toc`, `.synctex.gz`).

### 1. Compilação com XeLaTeX (Padrão com MiKTeX)

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\docs\build.ps1 -Engine xelatex
```

### 2. Compilação com Tectonic

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\docs\build.ps1 -Engine tectonic
```

### 3. Modo Automático (Detecta compilador disponível)

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\docs\build.ps1 -Engine auto
```

Os arquivos finais são gerados e atualizados diretamente dentro de `docs/`.
