# ==================================================================================================
# AzureRM Provider Configuration and Core Data Sources
# - Configures Azure provider with Key Vault options
# - Defines key input variables (Resource Group, Vault name)
# - Fetches subscription, client, resource group, VNet, subnet, and Key Vault details
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Configure AzureRM provider (required for all Azure deployments)
# --------------------------------------------------------------------------------------------------
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true   # Immediately purge deleted Key Vaults (bypass soft-delete retention)
      recover_soft_deleted_key_vaults = false  # Do not auto-recover previously deleted Key Vaults
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Fetch subscription details (ID, name, etc.)
# --------------------------------------------------------------------------------------------------
data "azurerm_subscription" "primary" {}

# --------------------------------------------------------------------------------------------------
# Fetch details about the authenticated client (SPN or user identity)
# --------------------------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

# --------------------------------------------------------------------------------------------------
# Input variable: Resource Group name
# --------------------------------------------------------------------------------------------------
variable "resource_group_name" {
  description = "The name of the Azure Resource Group"
  type        = string
  default     = "mcloud-project-rg"
}

# --------------------------------------------------------------------------------------------------
# Input variable: Key Vault name
# - Can be set via CLI, TFVARS, or overridden at apply time
# --------------------------------------------------------------------------------------------------
variable "vault_name" {
  description = "The name of the Azure Key Vault for storing secrets"
  type        = string
  # default   = "ad-key-vault-qcxu2ksw"  # Example value (commented out so it's explicitly required)
}

# --------------------------------------------------------------------------------------------------
# Fetch details about the specified Resource Group
# --------------------------------------------------------------------------------------------------
data "azurerm_resource_group" "ad" {
  name = var.resource_group_name
}

# --------------------------------------------------------------------------------------------------
# Fetch details about existing Virtual Network
# --------------------------------------------------------------------------------------------------
data "azurerm_virtual_network" "ad_vnet" {
  name                = "ad-vnet"
  resource_group_name = data.azurerm_resource_group.ad.name
}

# --------------------------------------------------------------------------------------------------
# Fetch details about existing Subnet within the VNet
# --------------------------------------------------------------------------------------------------
data "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = data.azurerm_resource_group.ad.name
  virtual_network_name = data.azurerm_virtual_network.ad_vnet.name
}

# --------------------------------------------------------------------------------------------------
# Fetch details about the existing Key Vault
# --------------------------------------------------------------------------------------------------
data "azurerm_key_vault" "ad_key_vault" {
  name                = var.vault_name
  resource_group_name = var.resource_group_name
}
