output "resource_group_name" {
  description = "Copy this into your main project backend.tf"
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Copy this into your main project backend.tf"
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Copy this into your main project backend.tf"
  value       = azurerm_storage_container.state.name
}

output "backend_config_block" {
  description = "Ready-to-paste backend block for your main project"
  value       = <<-EOT

    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.state.name}"
      storage_account_name = "${azurerm_storage_account.state.name}"
      container_name       = "${azurerm_storage_container.state.name}"
      key                  = "n8n/terraform.tfstate"
    }

  EOT
}