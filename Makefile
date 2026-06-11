ENV ?= stg

.PHONY: help init plan apply fmt validate security precommit

help:
	@echo "Uso: make <alvo> ENV=stg|prd"
	@echo "  init      terraform init no ambiente"
	@echo "  plan      terraform plan"
	@echo "  apply     terraform apply (prefira a esteira!)"
	@echo "  fmt       terraform fmt -recursive"
	@echo "  validate  terraform validate"
	@echo "  security  gitleaks + tfsec local"
	@echo "  precommit instala e roda os hooks"

init:
	cd envs/$(ENV) && terraform init

plan:
	cd envs/$(ENV) && terraform plan

apply:
	cd envs/$(ENV) && terraform apply

fmt:
	terraform fmt -recursive

validate:
	cd envs/$(ENV) && terraform validate

security:
	gitleaks detect --source=. --no-banner --redact || true
	tfsec . --minimum-severity MEDIUM || true

precommit:
	pre-commit install
	pre-commit run --all-files
