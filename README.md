# n8n on Azure with Terraform

A production-grade Infrastructure as Code project that deploys a self-hosted
n8n automation instance on Microsoft Azure using Terraform.

## Architecture

- **Azure Container Instance** running n8n Docker container
- **Virtual Network + Subnet** for network isolation
- **Network Security Group** with locked-down firewall rules
- **Azure Storage** for persistent n8n data and workflow backups
- **Remote Terraform State** stored in Azure Blob Storage

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Terraform >= 1.5.0
- An Azure subscription

## Quick Start

1. Clone this repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values
3. Run `terraform init`
4. Run `terraform plan`
5. Run `terraform apply`

## Module Structure

| Module | Purpose |
|--------|---------|
| `modules/networking` | VNet, Subnet, NSG |
| `modules/compute` | Azure Container Instance running n8n |
| `modules/storage` | Storage Account + Blob Containers |

## Accessing n8n

After deployment, the n8n URL is shown in Terraform outputs:
```
terraform output n8n_url
```