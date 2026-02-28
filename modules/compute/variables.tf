variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

# variable "subnet_id" {
#   description = "The subnet ID where the container will run"
#   type        = string
# }

variable "n8n_image" {
  description = "Docker image for n8n"
  type        = string
  default     = "n8nio/n8n:latest"
}

variable "n8n_basic_auth_user" {
  type = string
}

variable "n8n_basic_auth_password" {
  type      = string
  sensitive = true
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_key" {
  type      = string
  sensitive = true
}

variable "cpu_cores" {
  description = "Number of CPU cores for the container"
  type        = number
  default     = 1
}

variable "memory_gb" {
  description = "Memory in GB for the container"
  type        = number
  default     = 2
}

variable "docker_username" {
  description = "Docker Hub username to avoid pull rate limits"
  type        = string
  sensitive   = true
}

variable "docker_password" {
  description = "Docker Hub password or access token"
  type        = string
  sensitive   = true
}