# Fails at plan time if the bundle has not created the view yet, so the share
# is never pointed at an object that does not exist.
data "databricks_table" "shared_view" {
  name = join(".", [var.catalog, var.shared_schema, var.shared_view])
}

resource "databricks_recipient" "this" {
  for_each = var.recipients

  name                = each.key
  comment             = "Reads ${var.shared_as} rows for ${var.recipient_property} = ${each.value}. Managed by Terraform."
  authentication_type = "TOKEN"

  properties_kvpairs {
    properties = {
      (var.recipient_property) = each.value
    }
  }
}

resource "databricks_share" "this" {
  name    = var.share_name
  comment = "Recipient-filtered orders. Managed by Terraform."

  object {
    name             = data.databricks_table.shared_view.name
    data_object_type = "VIEW"
    shared_as        = var.shared_as
    comment          = "Each recipient sees only rows for its ${var.recipient_property} property."
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
