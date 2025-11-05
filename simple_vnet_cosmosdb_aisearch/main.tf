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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
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
  location      = "westus"
  base_name     = "aifoundry"
  unique_suffix = random_string.suffix.result
  tags = {
    Environment = "Demo"
    Purpose     = "Simple AI Foundry with VNet and Search and CosmosDB"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.base_name}-vnet-${local.unique_suffix}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.base_name}-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.base_name}-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_private_dns_zone" "cognitive" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "ai_services" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "cosmos_sql" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_link" {
  name                  = "cognitive-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai_services_link" {
  name                  = "ai-services-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_services.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_link" {
  name                  = "openai-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  name                  = "blob-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_link" {
  name                  = "file-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue_link" {
  name                  = "queue-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "table_link" {
  name                  = "table-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_sql_link" {
  name                  = "cosmos-sql-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_sql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "search_link" {
  name                  = "search-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  tags                  = local.tags
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
      publicNetworkAccess      = "Disabled"
    }
  }
}

resource "azurerm_private_endpoint" "sa_blob_pe" {
  name                = "pe-sa-blob-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-sa-blob-conn"
    private_connection_resource_id = azapi_resource.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

resource "azurerm_private_endpoint" "sa_file_pe" {
  name                = "pe-sa-file-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-sa-file-conn"
    private_connection_resource_id = azapi_resource.sa.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}

resource "azurerm_private_endpoint" "sa_queue_pe" {
  name                = "pe-sa-queue-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-sa-queue-conn"
    private_connection_resource_id = azapi_resource.sa.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue.id]
  }
}

resource "azurerm_private_endpoint" "sa_table_pe" {
  name                = "pe-sa-table-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-sa-table-conn"
    private_connection_resource_id = azapi_resource.sa.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-${local.base_name}-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  kind              = "GlobalDocumentDB"
  offer_type        = "Standard"
  free_tier_enabled = false

  local_authentication_disabled = true
  public_network_access_enabled = false

  automatic_failover_enabled       = false
  multiple_write_locations_enabled = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
    zone_redundant    = false
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_private_endpoint" "cosmos_sql_pe" {
  name                = "pe-cosmos-sql-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-cosmos-sql-conn"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_sql.id]
  }
}

resource "azapi_resource" "search" {
  type                      = "Microsoft.Search/searchServices@2025-05-01"
  name                      = "search-${local.base_name}-${local.unique_suffix}"
  parent_id                 = azurerm_resource_group.rg.id
  location                  = azurerm_resource_group.rg.location
  schema_validation_enabled = true
  tags                      = local.tags

  body = {
    sku = {
      name = "standard"
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      replicaCount        = 1
      partitionCount      = 1
      hostingMode         = "default"
      semanticSearch      = "disabled"
      disableLocalAuth    = true
      publicNetworkAccess = "Disabled"
    }
  }
}

resource "azurerm_private_endpoint" "search_pe" {
  name                = "pe-search-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-search-conn"
    private_connection_resource_id = azapi_resource.search.id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.search.id]
  }
}

resource "azapi_resource" "ai_foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = "hub-${local.base_name}-${local.unique_suffix}"
  location                  = azurerm_resource_group.rg.location
  parent_id                 = azurerm_resource_group.rg.id
  schema_validation_enabled = false
  tags                      = local.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      disableLocalAuth = true

      allowProjectManagement = true

      customSubDomainName = "hub-${local.base_name}-${local.unique_suffix}"

      publicNetworkAccess = "Enabled"

      restore = false
    }
  }

  depends_on = [
    azapi_resource.sa,
    azurerm_application_insights.ai
  ]
}

resource "azurerm_private_endpoint" "ai_foundry_pe" {
  name                = "pe-hub-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-hub-conn"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cognitive.id,
      azurerm_private_dns_zone.ai_services.id,
      azurerm_private_dns_zone.openai.id
    ]
  }
}

resource "time_sleep" "wait_for_hub" {
  depends_on = [
    azapi_resource.ai_foundry,
    azurerm_private_endpoint.ai_foundry_pe
  ]

  create_duration = "60s"
}

resource "azapi_resource" "ai_project" {
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = "proj-${local.base_name}-${local.unique_suffix}"
  parent_id                 = azapi_resource.ai_foundry.id
  location                  = azurerm_resource_group.rg.location
  schema_validation_enabled = false
  tags                      = local.tags

  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      displayName = "Default Project"
      description = "Default AI Foundry Project"
    }
  }

  depends_on = [
    time_sleep.wait_for_hub
  ]
}

resource "azapi_resource_action" "ai_foundry_disable_public_access" {
  type        = "Microsoft.CognitiveServices/accounts@2025-06-01"
  resource_id = azapi_resource.ai_foundry.id
  action      = ""
  method      = "PATCH"

  body = {
    properties = {
      publicNetworkAccess = "Disabled"
    }
  }

  depends_on = [
    azapi_resource.ai_project
  ]
}

resource "azurerm_cognitive_account" "openai" {
  name                          = "oai-${local.base_name}-${local.unique_suffix}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = "oai-${local.base_name}-${local.unique_suffix}"
  public_network_access_enabled = false
  tags                          = local.tags
}

resource "azurerm_private_endpoint" "openai_pe" {
  name                = "pe-oai-${local.unique_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "pe-oai-conn"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cognitive.id,
      azurerm_private_dns_zone.openai.id
    ]
  }
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

  depends_on = [
    azurerm_private_endpoint.openai_pe
  ]
}

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the virtual network"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the virtual network"
}

output "subnet_id" {
  value       = azurerm_subnet.private_endpoints.id
  description = "ID of the private endpoints subnet"
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

output "storage_account_name" {
  value       = azapi_resource.sa.name
  description = "Name of the storage account"
}

output "cosmosdb_account_name" {
  value       = azurerm_cosmosdb_account.cosmos.name
  description = "Name of the Cosmos DB account"
}

output "search_service_name" {
  value       = azapi_resource.search.name
  description = "Name of the AI Search service"
}
