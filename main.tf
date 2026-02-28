terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ─────────────────────────────────────────
# Resource Group — the container for everything
# ─────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────
# Module: Networking
# ─────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# ─────────────────────────────────────────
# Module: Storage
# ─────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# ─────────────────────────────────────────
# Module: Compute (depends on networking)
# ─────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  # subnet_id               = module.networking.subnet_id
  n8n_image               = var.n8n_image
  n8n_basic_auth_user     = var.n8n_basic_auth_user
  n8n_basic_auth_password = var.n8n_basic_auth_password
  storage_account_name    = module.storage.storage_account_name
  storage_account_key     = module.storage.storage_account_key
  docker_username         = var.docker_username
  docker_password         = var.docker_password
}
