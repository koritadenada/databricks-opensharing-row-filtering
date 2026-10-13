# Names come from config/<target>.yml through TF_VAR_* environment variables
# (see scripts/load-config.sh). They have no defaults on purpose. Keys that
# only the bundle uses (core_schema, orders_table) are not declared here;
# Terraform ignores TF_VAR_* values for undeclared variables.

variable "catalog" {
  description = "Catalog that holds the shared view."
  type        = string
}

variable "shared_schema" {
  description = "Schema that holds the shared view."
  type        = string
}

variable "shared_view" {
  description = "Recipient-filtered view created by the bundle."
  type        = string
}

variable "recipient_property" {
  description = "Recipient property key that the view compares with the region column."
  type        = string
}

variable "share_name" {
  description = "OpenSharing share that exposes the view."
  type        = string
}

variable "shared_as" {
  description = "Name recipients see inside the share (<schema>.<table>). Set once; changing it recreates the share object."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_]+\\.[A-Za-z0-9_]+$", var.shared_as))
    error_message = "shared_as must be a two-part name <schema>.<table> with letters, digits and underscores."
  }
}

variable "recipients" {
  description = "Open sharing (token) recipients to create, mapped to the value of their recipient property."
  type        = map(string)

  validation {
    condition     = alltrue([for name in keys(var.recipients) : can(regex("^[A-Za-z0-9_-]+$", name))])
    error_message = "Recipient names may contain only letters, digits, underscores and hyphens."
  }
}
