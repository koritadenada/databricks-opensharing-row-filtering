variable "target" {
  description = "Bundle target whose names to use (a key under `targets` in config/names.yml)."
  type        = string
}

variable "recipients" {
  description = "Open sharing (token) recipients to create, mapped to the value of their recipient property."
  type        = map(string)

  validation {
    condition     = alltrue([for name in keys(var.recipients) : can(regex("^[A-Za-z0-9_-]+$", name))])
    error_message = "Recipient names may contain only letters, digits, underscores and hyphens."
  }
}
