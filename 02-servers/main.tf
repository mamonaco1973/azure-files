# --- Configure the AzureRM provider (required for all Azure deployments) ---
provider "azurerm" {
  # Enables provider-specific features (can be empty if defaults are fine)
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true  # When a Key Vault is destroyed, purge it immediately (bypass soft-delete retention)
      recover_soft_deleted_key_vaults = false # Do NOT auto-recover soft-deleted Key Vaults
    }
  }
}

# --- Data source to retrieve details about the subscription being used ---
data "azurerm_subscription" "primary" {}
# This fetches the metadata (like subscription ID and name) for the subscription currently being used by the provider.

# --- Data source to retrieve information about the currently authenticated client ---
data "azurerm_client_config" "current" {}
# This gets information about the identity Terraform is authenticated as (the Service Principal or User doing the deployment).

# --- Variable to define the Azure Resource Group name ---
variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
  default     = "mcloud-project-rg"
}

# --- Variable for Key Vault name (can be overridden at apply time) ---
variable "vault_name" {
  description = "The name of the secrets vault"
  type        = string
  #  default     = "ad-key-vault-qcxu2ksw"  # Example default (commented out, so it's explicitly required unless set via CLI or TFVARS)
}

# --- Data source to fetch details about the resource group ---
data "azurerm_resource_group" "ad" {
  name = var.resource_group_name # Use the resource group name from the variable
}
# This allows other resources to refer to the location, ID, etc., of this resource group.

# --- Data source to fetch details about a specific subnet ---
data "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"                         # Name of the subnet
  resource_group_name  = data.azurerm_resource_group.ad.name # Subnet's resource group (same as main RG)
  virtual_network_name = "ad-vnet"                           # Name of the virtual network the subnet belongs to
}
# This lets Terraform reference the subnet for VM network interfaces, etc.

# --- Data source to fetch details about the existing Key Vault ---
data "azurerm_key_vault" "ad_key_vault" {
  name                = var.vault_name          # Key Vault name provided via variable
  resource_group_name = var.resource_group_name # Key Vault must be in the same resource group
}
# This allows other resources (like secrets) to link to this Key Vault.


