#!/usr/bin/env bash
# Each approach folder is self-contained so it can be copied on its own. This
# check fails if the files that should be identical have drifted apart.
# Example names (ex1/ex2) are normalized before comparing.
#
# Usage: tools/check_approaches_in_sync.sh
set -euo pipefail
cd "$(dirname "$0")/.."

a=approach-1-bundle-variables
b=approach-2-flat-config
status=0

same() {
  if diff -u <(sed 's/ex1/exN/g' "$a/$1") <(sed 's/ex2/exN/g' "$b/$1"); then
    echo "ok        $1"
  else
    echo "DIFFERENT $1" >&2
    status=1
  fi
}

same src/01_create_orders.py
same src/02_create_shared_view.py
same resources/schemas.yml
same resources/orders_job.yml
same infra/providers.tf
same infra/versions.tf
same infra/outputs.tf
same infra/.terraform.lock.hcl

exit "${status}"
