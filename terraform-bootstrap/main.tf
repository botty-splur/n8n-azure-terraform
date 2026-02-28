terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
  # No backend block here — state stays LOCAL intentionally
  # This is the one script where local state is correct
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Resource Group for Terraform state
resource "azurerm_resource_group" "state" {
  name     = "rg-terraform-state"
  location = var.location
}

# Storage Account — globally unique name
resource "azurerm_storage_account" "state" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true # Protects state file from accidental overwrites
  }

  tags = {
    purpose    = "terraform-state"
    managed_by = "terraform"
  }
}

# Blob Container for state files
resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}