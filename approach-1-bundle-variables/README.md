# Approach 1: names in a bundle variables file

All names live in [`config/names.yml`](config/names.yml), written as regular
[bundle variables](https://docs.databricks.com/gcp/en/dev-tools/bundles/variables)
with per-target overrides. Both tools read that one file:

- **Bundle:** `databricks.yml` includes it, so `${var.orders_table}` and the
  other variables resolve as usual.
- **Terraform:** [`infra/main.tf`](infra/main.tf) parses the same file with
  `yamldecode()`, takes each variable's `default`, and applies the overrides
  under `targets.<target>.variables`.

```yaml
# config/names.yml (excerpt)
variables:
  orders_table:
    default: orders
  shared_view:
    default: orders_by_region
targets:
  prod:
    variables:
      catalog: prod
```

```hcl
# infra/main.tf (excerpt)
locals {
  bundle_names = yamldecode(file("${path.module}/../config/names.yml"))
  defaults     = { for key, variable in local.bundle_names.variables : key => variable.default }
  overrides    = try(local.bundle_names.targets[var.target].variables, {})
  names        = merge(local.defaults, local.overrides)
}
```

No wrapper is needed to keep the tools in sync. The deploy script only enforces
the order (bundle first, then Terraform).

## Deploy

1. Set `catalog` for your target in `config/names.yml`.
2. Set recipient names and their `region` values in `infra/env/<target>.tfvars`.
3. Authenticate (`export DATABRICKS_CONFIG_PROFILE=<profile>`) and run:

   ```bash
   scripts/deploy.sh dev
   ```

To run the steps by hand:

```bash
databricks bundle deploy -t dev
databricks bundle run -t dev orders_build
terraform -chdir=infra init
terraform -chdir=infra workspace select -or-create dev
terraform -chdir=infra apply -var-file=env/dev.tfvars
```

## Rules for this approach

- **Change names only in `config/names.yml`.** `--var` flags and `BUNDLE_VAR_*`
  environment variables override bundle variables but are invisible to
  Terraform, so the two tools would drift apart.
- **Keep variable values literal.** Terraform reads the raw YAML, so a value
  like `${workspace.current_user.short_name}` would reach Terraform
  unresolved.
- **Every Terraform target must exist under `targets`** in `names.yml`.
  Terraform fails the plan otherwise, instead of falling back to the defaults.

## Clean up

```bash
scripts/destroy.sh dev
```

See the [repository README](../README.md) for how to test as a recipient, how
to rename the base table, and things to know.
