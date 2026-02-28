output "n8n_url" {
  description = "The public URL to access your n8n instance"
  value       = "http://${module.compute.n8n_ip}:5678"
}

output "n8n_ip_address" {
  description = "The raw public IP address of the n8n container"
  value       = module.compute.n8n_ip
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.storage.storage_account_name
}