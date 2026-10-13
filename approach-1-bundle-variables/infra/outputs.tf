output "share_name" {
  description = "Share that recipients read from."
  value       = databricks_share.this.name
}

output "shared_table" {
  description = "Table name recipients query inside the share."
  value       = "${databricks_share.this.name}.${local.names.shared_as}"
}

output "activation_urls" {
  description = "One-time activation links. Send each one to its recipient over a secure channel."
  value       = { for name, recipient in databricks_recipient.this : name => recipient.tokens[0].activation_url }
  sensitive   = true
}
