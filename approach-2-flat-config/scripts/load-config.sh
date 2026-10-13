#!/usr/bin/env bash
# Sourced by deploy.sh and destroy.sh. Exports every key in config/<target>.yml
# as BUNDLE_VAR_<key> (read by the bundle) and TF_VAR_<key> (read by Terraform).
# Requires yq v4 (https://github.com/mikefarah/yq).

config="config/${target}.yml"
if [[ ! -f "${config}" ]]; then
  echo "error: ${config} not found" >&2
  exit 1
fi

while IFS='=' read -r key value; do
  if [[ ! "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "error: invalid key '${key}' in ${config}" >&2
    exit 1
  fi
  export "BUNDLE_VAR_${key}=${value}" "TF_VAR_${key}=${value}"
  echo "    ${key} = ${value}"
done < <(yq -r 'to_entries | .[] | .key + "=" + (.value | tostring)' "${config}")
