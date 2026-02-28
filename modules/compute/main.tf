# Azure File Share for persistent n8n data
resource "azurerm_storage_share" "n8n_data" {
  name                 = "n8n-data"
  storage_account_name = var.storage_account_name
  quota                = 10
}

# Azure Container Instance
resource "azurerm_container_group" "n8n" {
  name                = "aci-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "${var.project_name}-${var.environment}-n8n"
  restart_policy      = "Always"

  depends_on = [azurerm_storage_share.n8n_data]

  # No credential block needed — ghcr.io is public and requires no authentication

  container {
    name   = "n8n"
    image  = var.n8n_image
    cpu    = var.cpu_cores
    memory = var.memory_gb

    ports {
      port     = 5678
      protocol = "TCP"
    }

    environment_variables = {
      N8N_BASIC_AUTH_ACTIVE = "true"
      N8N_BASIC_AUTH_USER   = var.n8n_basic_auth_user
      N8N_HOST              = "${var.project_name}-${var.environment}-n8n.${var.location}.azurecontainer.io"
      N8N_PORT              = "5678"
      N8N_PROTOCOL          = "http"
      GENERIC_TIMEZONE      = "UTC"
      N8N_LOG_LEVEL         = "info"
      N8N_SECURE_COOKIE     = "false"
    }

    secure_environment_variables = {
      N8N_BASIC_AUTH_PASSWORD = var.n8n_basic_auth_password
    }

    volume {
      name                 = "n8n-data"
      mount_path           = "/home/node/.n8n"
      read_only            = false
      storage_account_name = var.storage_account_name
      storage_account_key  = var.storage_account_key
      share_name           = "n8n-data"
    }
  }

  tags = {
    environment = var.environment
  }
}