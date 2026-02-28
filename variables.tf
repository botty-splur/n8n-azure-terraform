variable "location" {
  description = "The Azure region where all resources will be deployed"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "A short name for the project, used as a prefix for all resource names"
  type        = string
  default     = "n8n"
}

variable "environment" {
  description = "The environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "subscription_id" {
  description = "Your Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "n8n_image" {
  description = "The Docker image to use for n8n"
  type        = string
  default     = "n8nio/n8n:latest"
}

variable "n8n_basic_auth_user" {
  description = "Username to protect n8n web UI"
  type        = string
  default     = "admin"
}

variable "n8n_basic_auth_password" {
  description = "Password to protect n8n web UI — set this in terraform.tfvars"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Your Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "docker_username" {
  type      = string
  sensitive = true
}

variable "docker_password" {
  type      = string
  sensitive = true
}

variable "storage_account_name" {
  description = "Globally unique name for the state storage account"
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters."
  }
}