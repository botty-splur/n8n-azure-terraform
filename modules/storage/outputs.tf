output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true # Hides this value in terminal output
}

output "backup_container_name" {
  description = "The name of the n8n backup blob container"
  value       = azurerm_storage_container.n8n_backups.name
}