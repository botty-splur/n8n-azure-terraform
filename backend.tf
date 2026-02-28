terraform {
  backend "azurerm" {
    # The resource group you created in Phase 1
    resource_group_name = "rg-terraform-state"

    # Replace with YOUR storage account name from Phase 1
    storage_account_name = "a296806f661f499ebdcd333f"

    # The container name you created
    container_name = "tfstate"

    # The name of the state file blob — one per project
    key = "n8n/terraform.tfstate"
  }
}