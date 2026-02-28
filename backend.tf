terraform {
  backend "azurerm" {
    # The resource group you created
    resource_group_name = "rg-terraform-state"

    # Replace with YOUR storage account name
    storage_account_name = "YOUR-STORAGE-NAME"

    # The container name you created
    container_name = "tfstate"

    # The name of the state file blob — one per project
    key = "n8n/terraform.tfstate"
  }
}