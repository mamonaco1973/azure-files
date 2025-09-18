# ==================================================================================================
# Azure Key Vault Setup for AD Credentials
# Purpose:
#   - Create a dedicated Key Vault for storing AD-related secrets (user credentials, admin passwords).
#   - Use a random suffix for uniqueness (Key Vault names must be globally unique).
#   - Assign RBAC permissions so the current Terraform client can manage secrets.
#
# Notes:
#   - purge_protection_enabled = false → secrets can be permanently deleted (lab convenience).
#     In production, set purge_protection_enabled = true to prevent accidental deletion.
#   - enable_rbac_authorization = true → Key Vault access is governed by Azure RBAC instead of
#     legacy access policies. This provides better control and auditing.
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Generate a random suffix for the Key Vault name
# Ensures uniqueness across subscriptions/regions since Key Vault names must be globally unique.
# --------------------------------------------------------------------------------------------------
resource "random_string" "key_vault_suffix" {
  length  = 8     # 8-character random suffix
  special = false # Only alphanumeric
  upper   = false # Lowercase only
}

# --------------------------------------------------------------------------------------------------
# Create the Key Vault resource
# --------------------------------------------------------------------------------------------------
resource "azurerm_key_vault" "ad_key_vault" {
  name                      = "ad-key-vault-${random_string.key_vault_suffix.result}" # Vault name
  resource_group_name       = azurerm_resource_group.ad.name                          # Place in same RG as AD infra
  location                  = azurerm_resource_group.ad.location                      # Same region
  sku_name                  = "standard"                                              # Standard SKU (sufficient for secrets)
  tenant_id                 = data.azurerm_client_config.current.tenant_id            # Azure AD tenant ID
  purge_protection_enabled  = false                                                   # Allow permanent delete (lab use only)           
  rbac_authorization_enabled = true                                                   # rbac authorization enabled
}

# --------------------------------------------------------------------------------------------------
# Role Assignment: Grant current client permission to manage secrets
# Role: "Key Vault Secrets Officer" → can read/write/delete secrets but not manage policies or RBAC.
# This ensures Terraform (running under the current identity) can populate user credentials into Key Vault.
# --------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "kv_role_assignment" {
  scope                = azurerm_key_vault.ad_key_vault.id            # Scope = Key Vault
  role_definition_name = "Key Vault Secrets Officer"                  # Predefined Azure RBAC role
  principal_id         = data.azurerm_client_config.current.object_id # Current client identity
}
