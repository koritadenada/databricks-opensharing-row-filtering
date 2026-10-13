#!/usr/bin/env bash
# Removes approach 1 in reverse dependency order: Terraform first (share,
# grants, recipients), then the bundle (job, schemas and their tables/views).
#
# Usage: scripts/destroy.sh [target]         (default target: dev)
set -euo pipefail

target="${1:-dev}"
cd "$(dirname "$0")/.."

echo "==> Terraform destroy (workspace: ${target})"
terraform -chdir=infra init -input=false
terraform -chdir=infra workspace select -or-create "${target}"
terraform -chdir=infra destroy -input=false -var-file="env/${target}.tfvars" ${AUTO_APPROVE:+-auto-approve}

echo "==> Bundle destroy (target: ${target})"
databricks bundle destroy --target "${target}" ${AUTO_APPROVE:+--auto-approve}
