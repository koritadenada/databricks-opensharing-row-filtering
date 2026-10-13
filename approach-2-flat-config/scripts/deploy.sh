#!/usr/bin/env bash
# Deploys approach 2 in dependency order:
#   1. bundle: schemas, job; job run creates the base table and the shared view
#   2. Terraform: recipients, share, grants
# Both steps get their names from config/<target>.yml.
#
# Usage: scripts/deploy.sh [target]          (default target: dev)
# Auth:  export DATABRICKS_CONFIG_PROFILE=<profile>; both tools read it.
# Set AUTO_APPROVE=1 to skip the Terraform confirmation prompt (CI).
set -euo pipefail

target="${1:-dev}"
cd "$(dirname "$0")/.."

echo "==> Names from config/${target}.yml"
source scripts/load-config.sh

echo "==> Bundle: validate, deploy, build table and view (target: ${target})"
databricks bundle validate --target "${target}"
databricks bundle deploy --target "${target}"
databricks bundle run --target "${target}" orders_build

echo "==> Terraform: recipients, share, grants (workspace: ${target})"
terraform -chdir=infra init -input=false
terraform -chdir=infra workspace select -or-create "${target}"
terraform -chdir=infra apply -input=false -var-file="env/${target}.tfvars" ${AUTO_APPROVE:+-auto-approve}
