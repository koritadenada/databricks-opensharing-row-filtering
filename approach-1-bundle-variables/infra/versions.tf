terraform {
  required_version = ">= 1.5"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.137"
    }
  }

  # Use a remote backend with encryption and locking for real use. The state
  # contains recipient activation links, which are credentials.
  # backend "gcs" {
  #   bucket = "my-terraform-state"
  #   prefix = "opensharing-ex1"
  # }
}
