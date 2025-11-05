# Simple Azure AI Foundry Deployment

A minimal, single-file Terraform configuration to deploy Azure AI Foundry with one command.

## 🎯 What Gets Deployed

This Terraform configuration deploys a complete Azure AI Foundry environment:

- **Resource Group** - Container for all resources
- **Storage Account** - Data and artifact storage (using azapi to handle policy restrictions)
- **Key Vault** - Secrets and key management
- **Container Registry** - Container image storage
- **Log Analytics Workspace** - Centralized logging
- **Application Insights** - Telemetry and monitoring
- **Azure OpenAI** - Cognitive Services with GPT-4o-mini model (10K TPM)
- **AI Foundry Hub** - Main workspace for AI projects
- **AI Foundry Project** - Default project environment

**Default Region**: East US
**Total Resources**: 11

## 📋 Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- [Terraform](https://www.terraform.io/downloads.html) >= 1.13 installed
- Azure subscription with appropriate permissions
- Contributor or Owner role on the subscription

## 🚀 Quick Start

### 1. Authenticate with Azure

```bash
az login
```

If you have multiple subscriptions, set the active one:

```bash
az account list --output table
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
```

### 2. Verify Your Subscription

```bash
az account show --output table
```

### 3. Initialize Terraform

```bash
cd simple
terraform init
```

### 4. Deploy

You set these environment variables to customize the deployment:

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
```

Then initiate the deployment:

```bash
terraform apply -auto-approve
```

**Deployment time**: ~4 minutes

## 📊 Outputs

After deployment, Terraform will display:

- `resource_group_name` - Name of the created resource group
- `ai_foundry_name` - Name of the AI Foundry Hub
- `ai_project_name` - Name of the AI Foundry Project
- `openai_endpoint` - Azure OpenAI service endpoint
- `portal_url` - Direct link to AI Foundry in Azure Portal

### Access the AI Foundry

1. Copy the `portal_url` from the Terraform output

1. Open it in the browser

## 🗑️ Clean Up

To delete all resources:

```bash
terraform destroy
```

Or without confirmation:

```bash
terraform destroy -auto-approve
```

## 📝 License

This configuration is provided as-is for demonstration purposes.
