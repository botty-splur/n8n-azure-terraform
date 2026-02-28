output "n8n_ip" {
  description = "Public IP address of the n8n container"
  value       = azurerm_container_group.n8n.ip_address
}

output "n8n_fqdn" {
  description = "Fully qualified domain name for n8n"
  value       = azurerm_container_group.n8n.fqdn
}

output "container_group_id" {
  description = "The ID of the container group"
  value       = azurerm_container_group.n8n.id
}