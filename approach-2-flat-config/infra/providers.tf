# Workspace-level provider. Authentication follows the standard Databricks
# unified auth chain: DATABRICKS_CONFIG_PROFILE, DATABRICKS_HOST plus a
# credential, or the DEFAULT profile in ~/.databrickscfg.
provider "databricks" {}
