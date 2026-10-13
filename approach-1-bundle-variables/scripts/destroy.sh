#!/usr/bin/env bash
# Removes approach 1 in reverse dependency order: Terraform first (share,
# grants, recipients), then the bundle (job, schemas and their tables/views).
#
# Usage: scripts/destroy.sh [target]         (default target: dev)
# Set AUTO_APPROVE=1 to skip both confirmation prompts (CI).
set -euo pipefail

target="${1:-dev}"
cd "$(dirname "$0")/.."

tf_approve=""
bundle_approve=""
if [[ "${AUTO_APPROVE:-0}" == "1" ]]; then
  tf_approve="-auto-approve"
  bundle_approve="--auto-approve"
fi

echo "==> Terraform destroy (workspace: ${target})"
terraform -chdir=infra init -input=false
terraform -chdir=infra workspace select -or-create "${target}"
# Skip when Terraform manages nothing, for example after a deploy that failed
# before the Terraform step. Planning would fail on the missing view lookup.
if [[ -n "$(terraform -chdir=infra state list)" ]]; then
  terraform -chdir=infra destroy -input=false -var-file="env/${target}.tfvars" ${tf_approve}
else
  echo "    No Terraform-managed resources in workspace ${target}; skipping."
fi

echo "==> Bundle destroy (target: ${target})"
databricks bundle destroy --target "${target}" ${bundle_approve}
