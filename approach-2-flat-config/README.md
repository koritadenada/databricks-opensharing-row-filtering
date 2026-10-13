# Approach 2: names in a flat config file

All names for a target live in a plain file, [`config/<target>.yml`](config/dev.yml),
with no tool-specific syntax:

```yaml
# config/dev.yml (excerpt)
catalog: main
orders_table: orders
shared_view: orders_by_region
share_name: opensharing_ex2_orders
```

[`scripts/load-config.sh`](scripts/load-config.sh) reads the file with `yq` and
exports every key twice:

- `BUNDLE_VAR_<key>`, which sets the bundle variable `<key>`
  ([bundle variables](https://docs.databricks.com/gcp/en/dev-tools/bundles/variables))
- `TF_VAR_<key>`, which sets the Terraform variable `<key>`

Neither `databricks.yml` nor `infra/variables.tf` defines defaults for these
variables. Running either tool without loading the config file fails with a
missing-variable error instead of deploying with stale names.

## Deploy

1. Set `catalog` in `config/<target>.yml`.
2. Set recipient names and their `region` values in `infra/env/<target>.tfvars`.
3. Authenticate (`export DATABRICKS_CONFIG_PROFILE=<profile>`) and run:

   ```bash
   scripts/deploy.sh dev
   ```

To run the steps by hand, load the config first so both tools see the names:

```bash
target=dev; source scripts/load-config.sh
databricks bundle deploy -t dev
databricks bundle run -t dev orders_build
terraform -chdir=infra init
terraform -chdir=infra workspace select -or-create dev
terraform -chdir=infra apply -var-file=env/dev.tfvars
```

## Rules for this approach

- **Change names only in `config/<target>.yml`.** When you add a key, declare
  it in `databricks.yml`, `infra/variables.tf`, or both, depending on which
  tool uses it. Each tool ignores environment variables for variables it does
  not declare.
- **Always deploy through `scripts/deploy.sh`** (locally and in CI), or source
  `scripts/load-config.sh` first when running commands by hand.
- **Other tools can read the same file.** It is plain YAML, so CI pipelines,
  tests or documentation generators can use it without knowing bundle syntax.

## Clean up

```bash
scripts/destroy.sh dev
```

See the [repository README](../README.md) for how to test as a recipient, how
to rename the base table, and things to know.
