# Common tags applied to all resources.
# Using locals ensures a single source of truth — update here, propagates everywhere.
locals {
  common_tags = {
    Project = var.project_name
    ID      = var.project_id
  }
}
