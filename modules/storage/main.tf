# Storage Account — globally unique name required
resource "azurerm_storage_account" "main" {
  # Storage account names must be 3-24 chars, lowercase, alphanumeric only
  name                     = "st${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage — cheapest option

  tags = {
    environment = var.environment
  }
}

# Random suffix to ensure globally unique storage account name
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Blob container for n8n workflow backups
resource "azurerm_storage_container" "n8n_backups" {
  name                  = "n8n-backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private" # No public access — security best practice
}