locals {
  # Read the bundle's variables file: defaults first, then the target's overrides.
  bundle_names = yamldecode(file("${path.module}/../config/names.yml"))
  defaults     = { for key, variable in local.bundle_names.variables : key => variable.default }
  overrides    = try(local.bundle_names.targets[var.target].variables, {})
  names        = merge(local.defaults, local.overrides)

  shared_view_full_name = join(".", [local.names.catalog, local.names.shared_schema, local.names.shared_view])
}

# Fails at plan time if the bundle has not created the view yet, so the share
# is never pointed at an object that does not exist.
data "databricks_table" "shared_view" {
  name = local.shared_view_full_name

  lifecycle {
    precondition {
      condition     = contains(keys(local.bundle_names.targets), var.target)
      error_message = "Target '${var.target}' is not defined under `targets` in config/names.yml."
    }
  }
}

resource "databricks_recipient" "this" {
  for_each = var.recipients

  name                = each.key
  comment             = "Reads ${local.names.shared_as} rows for ${local.names.recipient_property} = ${each.value}. Managed by Terraform."
  authentication_type = "TOKEN"

  properties_kvpairs {
    properties = {
      (local.names.recipient_property) = each.value
    }
  }
}

resource "databricks_share" "this" {
  name    = local.names.share_name
  comment = "Recipient-filtered orders. Managed by Terraform."

  lifecycle {
    precondition {
      condition     = can(regex("^[A-Za-z0-9_]+\\.[A-Za-z0-9_]+$", local.names.shared_as))
      error_message = "shared_as in config/names.yml must be a two-part name <schema>.<table> with letters, digits and underscores."
    }
  }

  object {
    name             = data.databricks_table.shared_view.name
    data_object_type = "VIEW"
    shared_as        = local.names.shared_as
    comment          = "Each recipient sees only rows for its ${local.names.recipient_property} property."
  }
}

resource "databricks_grants" "share" {
  share = databricks_share.this.name

  dynamic "grant" {
    for_each = databricks_recipient.this
    content {
      principal  = grant.value.name
      privileges = ["SELECT"]
    }
  }
}
