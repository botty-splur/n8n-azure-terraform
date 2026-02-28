# 🚀 n8n on Azure with Terraform

> A production-grade, modular Infrastructure as Code project that deploys a self-hosted [n8n](https://n8n.io) workflow automation instance on Microsoft Azure using Terraform.

[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-7B42BC?logo=terraform)](https://www.terraform.io)
[![Azure](https://img.shields.io/badge/Azure-ACI-0078D4?logo=microsoftazure)](https://azure.microsoft.com)
[![n8n](https://img.shields.io/badge/n8n-latest-EA4B71?logo=n8n)](https://n8n.io)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Detailed Deployment Guide](#-detailed-deployment-guide)
  - [Phase 1 — Bootstrap Remote State](#phase-1--bootstrap-remote-state)
  - [Phase 2 — Authenticate to Azure](#phase-2--authenticate-to-azure)
  - [Phase 3 — Configure Variables](#phase-3--configure-variables)
  - [Phase 4 — Deploy Infrastructure](#phase-4--deploy-infrastructure)
- [Module Reference](#-module-reference)
- [Variables Reference](#-variables-reference)
- [Outputs Reference](#-outputs-reference)
- [Accessing n8n](#-accessing-n8n)
- [Common Issues & Fixes](#-common-issues--fixes)
- [Cleanup](#-cleanup)
- [Next Steps](#-next-steps)

---

## 🌐 Overview

This project provisions a complete Azure infrastructure stack to host a self-managed n8n automation instance. It is built with **modular Terraform** following professional DevOps conventions, including:

- **Remote state management** stored in Azure Blob Storage
- **Modular architecture** with separated networking, compute, and storage concerns
- **Persistent data storage** via Azure File Share mounted into the container
- **Network security** via Network Security Groups with locked-down inbound rules
- **Public accessibility** via Azure Container Instance with a static public IP

### What Gets Deployed

| Resource | Purpose |
|---|---|
| Azure Resource Group | Logical container for all application resources |
| Virtual Network + Subnet | Private network isolation |
| Network Security Group | Firewall rules (ports 5678 and 443) |
| Storage Account | Persistent data and workflow backup storage |
| Blob Container | n8n workflow backup storage |
| Azure File Share | Persistent n8n data mounted into container |
| Azure Container Instance | Runs the n8n Docker container |
| Remote State Storage | Separate resource group storing Terraform state |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    rg-n8n-dev                               │
│                                                             │
│   ┌──────────────────────────────────────────────────────┐  │
│   │           Virtual Network (10.0.0.0/16)              │  │
│   │   ┌────────────────────────────────────────────────┐ │  │
│   │   │         Subnet (10.0.1.0/24)                   │ │  │
│   │   │   + Network Security Group                     │ │  │
│   │   │     • Allow :5678 inbound (n8n UI)             │ │  │
│   │   │     • Allow :443 inbound (HTTPS)               │ │  │
│   │   └────────────────────────────────────────────────┘ │  │
│   └──────────────────────────────────────────────────────┘  │
│                                                             │
│   ┌──────────────────┐     ┌──────────────────────────┐    │
│   │  Container Group │     │    Storage Account       │    │
│   │  (Public IP)     │────▶│    ├── n8n-backups       │    │
│   │                  │     │    │   (Blob Container)  │    │
│   │  n8n:latest      │     │    └── n8n-data          │    │
│   │  Port: 5678      │     │        (File Share 10GB) │    │
│   └──────────────────┘     └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              rg-terraform-state (Bootstrap)                 │
│   Storage Account → Blob Container → terraform.tfstate      │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

**ACI with Public IP (not VNet-injected):** Azure Container Instances placed inside a VNet subnet lose outbound internet access by default, which prevents Docker image pulls. Using `ip_address_type = "Public"` gives the container direct internet routing while the NSG still controls inbound traffic.

**GitHub Container Registry:** The n8n image is pulled from `ghcr.io/n8n-io/n8n:latest` instead of Docker Hub. This avoids Docker Hub's aggressive rate limiting on cloud provider IP ranges and requires no registry credentials.

**Explicit `depends_on`:** The container group explicitly depends on the file share resource. Without this, Terraform may attempt to create both simultaneously, causing the container group to fail because its volume mount target doesn't exist yet.

---

## 📁 Project Structure

```
terraform-azure-n8n/
├── main.tf                    # Root config — calls all modules
├── variables.tf               # Input variable declarations
├── outputs.tf                 # Exposes IP address and URLs
├── terraform.tfvars           # Your actual values (gitignored)
├── terraform.tfvars.example   # Safe template to commit to Git
├── backend.tf                 # Remote state configuration
├── .gitignore                 # Excludes state, secrets, .terraform/
├── README.md                  # This file
│
└── modules/
    ├── networking/
    │   ├── main.tf            # VNet, Subnet, NSG, NSG Association
    │   ├── variables.tf
    │   └── outputs.tf         # Exports subnet_id, vnet_id, nsg_id
    │
    ├── compute/
    │   ├── main.tf            # File Share + Container Group
    │   ├── variables.tf
    │   └── outputs.tf         # Exports n8n_ip, n8n_fqdn
    │
    └── storage/
        ├── main.tf            # Storage Account + Blob Container
        ├── variables.tf
        └── outputs.tf         # Exports storage_account_name, key

terraform-bootstrap/           # Separate project — creates remote state storage
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars           # Bootstrap-specific values (gitignored)
```

---

## ✅ Prerequisites

### Required Tools

| Tool | Minimum Version | Install |
|---|---|---|
| Terraform | 1.5.0+ | [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads) |
| Azure CLI | 2.50.0+ | [learn.microsoft.com](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Git | Any | [git-scm.com](https://git-scm.com) |

### Required Accounts

- **Microsoft Azure account** with an active subscription ([free tier available](https://azure.microsoft.com/free))
- **Docker Hub account** (optional — only needed if switching back to Docker Hub registry)

### Required Information

Before starting, have these values ready:

| Value | How to Find It |
|---|---|
| Azure Subscription ID | `az account show --query id --output tsv` |
| Azure Tenant ID | `az account show --query tenantId --output tsv` |
| Preferred Azure region | `az account list-locations --output table` |

### If Using GitHub Codespaces

Standard `az login` opens a browser which Codespaces cannot display. Use device code login instead:

```bash
az login --use-device-code
```

For Terraform authentication in Codespaces, store credentials as **Codespaces Secrets** at `github.com/settings/codespaces`:

| Secret Name | Value |
|---|---|
| `ARM_SUBSCRIPTION_ID` | Your Azure subscription ID |
| `ARM_CLIENT_ID` | Service principal `appId` |
| `ARM_CLIENT_SECRET` | Service principal `password` |
| `ARM_TENANT_ID` | Service principal `tenant` |

Create a service principal with:
```bash
az ad sp create-for-rbac \
  --name "sp-terraform-n8n" \
  --role Contributor \
  --scopes /subscriptions/YOUR-SUBSCRIPTION-ID
```

> ⚠️ Restart your Codespace completely after adding secrets — they do not load until the environment is fully restarted.

---

## ⚡ Quick Start

For experienced users who just need the commands:

```bash
# 1. Clone the repository
git clone https://github.com/YOUR-USERNAME/terraform-azure-n8n.git
cd terraform-azure-n8n

# 2. Deploy bootstrap state storage (first time only)
cd terraform-bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform apply
cd ..

# 3. Configure main project
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values + storage account name from step 2
# Edit backend.tf with your bootstrap storage account name

# 4. Deploy
terraform init
terraform plan -var-file="terraform.tfvars" -out=tfplan
terraform apply "tfplan"

# 5. Access n8n
terraform output n8n_url
```

---

## 📖 Detailed Deployment Guide

### Phase 1 — Bootstrap Remote State

Terraform needs an Azure Storage Account to store its state file before it can manage any resources. This is a one-time setup.

**Navigate to the bootstrap directory:**
```bash
cd terraform-bootstrap
cp terraform.tfvars.example terraform.tfvars
```

**Edit `terraform.tfvars`:**
```hcl
subscription_id      = "YOUR-SUBSCRIPTION-ID"
tenant_id            = "YOUR-TENANT-ID"
location             = "eastus"
storage_account_name = "tfstaten8nprod001"  # Must be globally unique, 3-24 chars, lowercase only
```

**Deploy bootstrap resources:**
```bash
terraform init
terraform plan
terraform apply
```

**Copy the output values** — you will need them in the next step:
```
storage_account_name = "tfstaten8nprod001"
resource_group_name  = "rg-terraform-state"
container_name       = "tfstate"
```

> 💡 The bootstrap folder keeps its own **local** state file intentionally. Never delete this folder — it is how you manage the bootstrap resources going forward.

---

### Phase 2 — Authenticate to Azure

**Standard login (local machine):**
```bash
az login
az account set --subscription "YOUR-SUBSCRIPTION-ID"
az account show  # Confirm correct subscription is active
```

**Device code login (GitHub Codespaces):**
```bash
az login --use-device-code
# Open the printed URL in any browser and enter the displayed code
```

**Verify authentication:**
```bash
az account show --query "{Name:name, State:state, SubscriptionId:id}"
```

---

### Phase 3 — Configure Variables

**Copy the example file:**
```bash
cd terraform-azure-n8n   # Back in the root project directory
cp terraform.tfvars.example terraform.tfvars
```

**Edit `terraform.tfvars`** with all your real values:
```hcl
# Azure identity
subscription_id      = "YOUR-SUBSCRIPTION-ID"
tenant_id            = "YOUR-TENANT-ID"

# Infrastructure settings
location             = "eastus"
project_name         = "n8n"
environment          = "dev"

# Storage — use the name from Phase 1 bootstrap output
storage_account_name = "tfstaten8nprod001"

# n8n application credentials
n8n_basic_auth_user     = "admin"
n8n_basic_auth_password = "YourStrongPassword123!"

# Docker image — ghcr.io recommended (no rate limits, no credentials needed)
n8n_image       = "ghcr.io/n8n-io/n8n:latest"
docker_username  = ""
docker_password  = ""
```

**Update `backend.tf`** with your bootstrap storage account name:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstaten8nprod001"   # ← your exact bootstrap name
    container_name       = "tfstate"
    key                  = "n8n/terraform.tfstate"
  }
}
```

> ⚠️ `terraform.tfvars` is listed in `.gitignore` and must never be committed to Git. Commit only `terraform.tfvars.example` with placeholder values.

---

### Phase 4 — Deploy Infrastructure

**Initialize Terraform:**
```bash
terraform init
```

Expected output: `Terraform has been successfully initialized!`

**Validate configuration:**
```bash
terraform validate
```

Expected output: `Success! The configuration is valid.`

**Format code:**
```bash
terraform fmt -recursive
```

**Plan the deployment:**
```bash
terraform plan -var-file="terraform.tfvars" -out=tfplan
```

Review the plan output carefully. You should see approximately 10–12 resources to be created with `0 to destroy`.

**Apply the plan:**
```bash
terraform apply "tfplan"
```

Deployment takes approximately **3–7 minutes**. Successful completion looks like:

```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:
n8n_ip_address      = "XX.XX.XX.XX"
n8n_url             = "http://XX.XX.XX.XX:5678"
resource_group_name = "rg-n8n-dev"
storage_account_name = "stn8ndevXXXXXX"
```

---

## 📦 Module Reference

### `modules/networking`

Provisions all network infrastructure.

| Resource | Name Pattern | Purpose |
|---|---|---|
| `azurerm_virtual_network` | `vnet-{project}-{env}` | Private network space |
| `azurerm_subnet` | `subnet-{project}-{env}` | Subdivided address range |
| `azurerm_network_security_group` | `nsg-{project}-{env}` | Inbound/outbound firewall rules |
| `azurerm_subnet_network_security_group_association` | — | Binds NSG to subnet |

**NSG Rules:**

| Rule | Priority | Direction | Port | Action |
|---|---|---|---|---|
| allow-n8n | 100 | Inbound | 5678 | Allow |
| allow-https | 110 | Inbound | 443 | Allow |
| deny-all-inbound | 4096 | Inbound | * | Deny |

---

### `modules/storage`

Provisions all storage resources.

| Resource | Name Pattern | Purpose |
|---|---|---|
| `azurerm_storage_account` | `st{project}{env}{random}` | Parent storage account |
| `azurerm_storage_container` | `n8n-backups` | Private blob container for backups |
| `random_string` | — | Generates unique 6-char suffix |

---

### `modules/compute`

Provisions the container and its persistent storage.

| Resource | Name Pattern | Purpose |
|---|---|---|
| `azurerm_storage_share` | `n8n-data` | 10GB file share mounted into container |
| `azurerm_container_group` | `aci-{project}-{env}` | ACI running n8n Docker image |

**Container Configuration:**

| Setting | Value |
|---|---|
| Image | `ghcr.io/n8n-io/n8n:latest` |
| CPU | 1 core |
| Memory | 2 GB |
| Port | 5678 (TCP) |
| Restart Policy | Always |
| Volume Mount | `/home/node/.n8n` |

---

## 🔧 Variables Reference

### Root Variables (`variables.tf`)

| Variable | Type | Required | Default | Description |
|---|---|---|---|---|
| `subscription_id` | string | ✅ | — | Azure subscription ID |
| `tenant_id` | string | ✅ | — | Azure tenant ID |
| `location` | string | ✅ | `eastus` | Azure deployment region |
| `project_name` | string | ✅ | `n8n` | Resource name prefix |
| `environment` | string | ✅ | `dev` | Environment label |
| `storage_account_name` | string | ✅ | — | Globally unique storage name |
| `n8n_image` | string | ✅ | `ghcr.io/n8n-io/n8n:latest` | Docker image for n8n |
| `n8n_basic_auth_user` | string | ✅ | `admin` | n8n login username |
| `n8n_basic_auth_password` | string | ✅ | — | n8n login password (sensitive) |
| `docker_username` | string | ❌ | `""` | Docker Hub username (optional) |
| `docker_password` | string | ❌ | `""` | Docker Hub token (optional, sensitive) |

---

## 📤 Outputs Reference

After a successful `terraform apply`, these values are printed:

| Output | Example Value | Description |
|---|---|---|
| `n8n_url` | `http://20.62.212.142:5678` | Direct link to n8n web UI |
| `n8n_ip_address` | `20.62.212.142` | Raw public IP of the container |
| `resource_group_name` | `rg-n8n-dev` | Application resource group name |
| `storage_account_name` | `stn8ndevea89dd` | Storage account name |

Retrieve outputs at any time with:
```bash
terraform output
terraform output n8n_url   # Single output
```

---

## 🖥️ Accessing n8n

After deployment, open the URL from `terraform output n8n_url` in your browser.

**First-time setup:**
1. n8n will prompt you to create an **owner account** (name, email, password)
2. This is separate from the basic auth credentials in `terraform.tfvars`
3. Complete setup and you will land on the n8n dashboard

**Login credentials for the web UI:**
- Username: value of `n8n_basic_auth_user` in `terraform.tfvars`
- Password: value of `n8n_basic_auth_password` in `terraform.tfvars`

> 💡 If you see a **"secure cookie"** error in the browser, your `N8N_SECURE_COOKIE=false` environment variable may not be set in `modules/compute/main.tf`. Add it to the `environment_variables` block and run `terraform apply` again.

---

## 🔧 Common Issues & Fixes

### State Lock Error
```
Error: state blob is already locked
```
**Cause:** A previous Terraform operation was killed without releasing the lock (e.g., Codespaces restart).  
**Fix:**
```bash
terraform force-unlock LOCK-ID-FROM-ERROR-MESSAGE
```

---

### SubscriptionNotFound
```
(SubscriptionNotFound) Subscription xxx was not found
```
**Cause:** Azure CLI is authenticated to a different tenant that doesn't contain your subscription.  
**Fix:**
```bash
az logout && az account clear
az login --use-device-code --tenant "YOUR-TENANT-ID"
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```

---

### InaccessibleImage / 400 Bad Request
```
InaccessibleImage: The image is not accessible
```
**Cause:** Either Docker Hub rate limiting or ACI cannot reach the registry.  
**Fix:** Switch to GitHub Container Registry in `terraform.tfvars`:
```hcl
n8n_image = "ghcr.io/n8n-io/n8n:latest"
```

---

### Interactive Variable Prompts During Plan
```
var.storage_account_name — Enter a value:
```
**Cause:** `terraform plan` was run without the `-var-file` flag.  
**Fix:** Always include the flag explicitly:
```bash
terraform plan -var-file="terraform.tfvars" -out=tfplan
```

---

### n8n Secure Cookie Error in Browser
```
Your n8n server is configured to use a secure cookie
```
**Cause:** n8n v1.0+ defaults to `N8N_SECURE_COOKIE=true`, blocking plain HTTP access.  
**Fix:** Add to `environment_variables` in `modules/compute/main.tf`:
```hcl
N8N_SECURE_COOKIE = "false"
```
Then run `terraform apply`.

---

### Check Container Logs
If n8n is deployed but the UI isn't loading:
```bash
az container logs \
  --resource-group rg-n8n-dev \
  --name aci-n8n-dev
```

---

## 🗑️ Cleanup

To destroy all application infrastructure and stop Azure charges:

```bash
terraform destroy -var-file="terraform.tfvars"
```

Type `yes` when prompted. This destroys everything in `rg-n8n-dev`.

To also remove the bootstrap state storage:
```bash
cd terraform-bootstrap
terraform destroy
```

> ⚠️ Destroying the bootstrap storage deletes the Terraform state file. Only do this if you are completely done with the project and have no intention of re-deploying.

---

## 🔮 Next Steps

### Immediate
- [ ] Push this project to GitHub — it is portfolio-ready as-is
- [ ] Add a GitHub Actions workflow to run `terraform plan` on pull requests

### Intermediate
- [ ] Add a custom domain with Azure DNS
- [ ] Add HTTPS with a TLS certificate (removes need for `N8N_SECURE_COOKIE=false`)
- [ ] Add Azure Monitor alerts for container health
- [ ] Add Azure Budget alerts to track spending

### Advanced
- [ ] Replace ACI with Azure Kubernetes Service (AKS)
- [ ] Add Azure PostgreSQL as n8n's database backend (required for production scale)
- [ ] Add Azure Key Vault to replace sensitive values in `terraform.tfvars`
- [ ] Implement Terraform workspaces for `dev/staging/prod` environment separation

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgements

- [n8n](https://n8n.io) — the open-source workflow automation tool this project hosts
- [HashiCorp Terraform](https://www.terraform.io) — Infrastructure as Code tooling
- [Microsoft Azure](https://azure.microsoft.com) — cloud infrastructure platform

---

*Built with Terraform · Hosted on Azure · Developed in GitHub Codespaces*