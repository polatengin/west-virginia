terraform {
  required_version = ">= 1.13, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  location      = "eastus"
  base_name     = "aifoundry"
  unique_suffix = random_string.suffix.result
  tags = {
    Environment = "Demo"
    Purpose     = "Simple AI Foundry"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.base_name}-${local.unique_suffix}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-${local.base_name}-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "ai" {
  name                = "appi-${local.base_name}-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = local.tags
}

resource "azapi_resource" "sa" {
  type      = "Microsoft.Storage/storageAccounts@2023-01-01"
  name      = "st${replace(local.base_name, "-", "")}${local.unique_suffix}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  tags      = local.tags

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_LRS"
    }
    properties = {
      accessTier               = "Hot"
      allowSharedKeyAccess     = true
      minimumTlsVersion        = "TLS1_2"
      supportsHttpsTrafficOnly = true
      publicNetworkAccess      = "Enabled"
    }
  }
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv${replace(local.base_name, "-", "")}${local.unique_suffix}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = local.tags
}

resource "azurerm_container_registry" "acr" {
  name                = "cr${replace(local.base_name, "-", "")}${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  admin_enabled       = true
  tags                = local.tags
}

data "azurerm_client_config" "current" {}

resource "azapi_resource" "ai_foundry" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-10-01"
  name      = "hub-${local.base_name}-${local.unique_suffix}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  tags      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "Hub"
    properties = {
      description         = "Simple AI Foundry Hub"
      friendlyName        = "Simple AI Foundry"
      publicNetworkAccess = "Enabled"

      keyVault            = azurerm_key_vault.kv.id
      storageAccount      = azapi_resource.sa.id
      containerRegistry   = azurerm_container_registry.acr.id
      applicationInsights = azurerm_application_insights.ai.id
    }
    sku = {
      name = "Basic"
      tier = "Basic"
    }
  }
}

resource "azapi_resource" "ai_project" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-10-01"
  name      = "proj-${local.base_name}-${local.unique_suffix}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  tags      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "Project"
    properties = {
      description   = "Default AI Foundry Project"
      friendlyName  = "Default Project"
      hubResourceId = azapi_resource.ai_foundry.id
    }
  }
}

resource "azurerm_cognitive_account" "openai" {
  name                = "oai-${local.base_name}-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"
  tags                = local.tags
}

resource "azurerm_cognitive_deployment" "gpt4o_mini" {
  name                 = "gpt-4o-mini"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 10
  }
}

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}

output "ai_foundry_name" {
  value       = azapi_resource.ai_foundry.name
  description = "Name of the AI Foundry Hub"
}

output "ai_project_name" {
  value       = azapi_resource.ai_project.name
  description = "Name of the AI Foundry Project"
}

output "openai_endpoint" {
  value       = azurerm_cognitive_account.openai.endpoint
  description = "OpenAI endpoint URL"
}

output "portal_url" {
  value       = "https://ai.azure.com/resource/overview/${azapi_resource.ai_foundry.id}"
  description = "Azure AI Foundry portal URL"
}
