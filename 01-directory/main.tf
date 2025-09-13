# Configure the AzureRM provider
provider "azurerm" {
  # Enables the default features of the provider
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data source to fetch details of the primary subscription
data "azurerm_subscription" "primary" {}

# Data source to fetch the details of the current Azure client
data "azurerm_client_config" "current" {}

# Define variables for resource group name and location

variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
  default     = "mcloud-project-rg"
}

variable "resource_group_location" {
  description = "The Azure region where the resource group will be created"
  type        = string
  default     = "Central US"
}

# Define a resource group for all resources
resource "azurerm_resource_group" "ad" {
  name     = var.resource_group_name     # Name of the resource group from variable
  location = var.resource_group_location # Location from variable
}


