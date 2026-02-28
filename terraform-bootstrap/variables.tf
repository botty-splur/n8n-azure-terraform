variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Your Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for state storage"
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Globally unique name for the state storage account"
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters."
  }
}