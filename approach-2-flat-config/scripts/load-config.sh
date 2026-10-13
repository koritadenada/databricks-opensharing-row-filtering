#!/usr/bin/env bash
# Exports every key in config/<target>.yml as BUNDLE_VAR_<key> (read by the
# bundle) and TF_VAR_<key> (read by Terraform). Requires yq v4
# (https://github.com/mikefarah/yq).
#
# Sourced by deploy.sh and destroy.sh. To run commands by hand (bash or zsh):
#   target=dev; source scripts/load-config.sh
#
# Clears all existing BUNDLE_VAR_* and TF_VAR_* variables first, so values from
# an earlier target or a removed key cannot leak into this deployment.

load_config() {
  local config="config/${target:?set target, for example: target=dev}.yml"
  if [[ ! -f "${config}" ]]; then
    echo "error: ${config} not found" >&2
    return 1
  fi

  local entries
  if ! entries="$(yq -r 'to_entries | .[] | .key + "=" + (.value | tostring)' "${config}")"; then
    echo "error: could not read ${config} with yq v4" >&2
    return 1
  fi
  if [[ -z "${entries}" ]]; then
    echo "error: ${config} is empty" >&2
    return 1
  fi

  # Portable across bash and zsh, so the file can be sourced from either.
  local name
  for name in $(env | awk -F= '/^(BUNDLE_VAR_|TF_VAR_)/ { print $1 }'); do
    unset "${name}"
  done

  local key value
  while IFS='=' read -r key value; do
    if [[ ! "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      echo "error: invalid key '${key}' in ${config}" >&2
      return 1
    fi
    export "BUNDLE_VAR_${key}=${value}" "TF_VAR_${key}=${value}"
    echo "    ${key} = ${value}"
  done <<< "${entries}"
}

# `return` keeps an interactive shell open when this file is sourced by hand.
load_config || return 1 2>/dev/null || exit 1
