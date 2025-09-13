# ==================================================================================================
# AzureRM Provider and Core Resource Group Setup
# - Configures Azure provider features
# - Defines subscription and client data sources
# - Declares input variables for RG name and location
# - Creates the primary resource group for deployment
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Configure AzureRM provider
# --------------------------------------------------------------------------------------------------
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true   # Purge Key Vault immediately on destroy
      recover_soft_deleted_key_vaults = false  # Do not auto-recover deleted Key Vaults
    }

    resource_group {
      prevent_deletion_if_contains_resources = false # Allow deletion of RG even if non-empty
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Fetch subscription details (subscription ID, display name, etc.)
# --------------------------------------------------------------------------------------------------
data "azurerm_subscription" "primary" {}

# --------------------------------------------------------------------------------------------------
# Fetch details of the authenticated client (SPN or user identity)
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
# Input variable: Resource Group location
# --------------------------------------------------------------------------------------------------
variable "resource_group_location" {
  description = "The Azure region where the Resource Group will be created"
  type        = string
  default     = "Central US"
}

# --------------------------------------------------------------------------------------------------
# Create the Resource Group
# --------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "ad" {
  name     = var.resource_group_name
  location = var.resource_group_location
}
