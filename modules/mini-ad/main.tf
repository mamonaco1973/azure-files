
# --------------------------------------------------------------------------------------------------
# Generate a random suffix for the mini AD resource group
# --------------------------------------------------------------------------------------------------
resource "random_string" "mini_ad_rg_suffix" {
  length  = 8     # 8-character random suffix
  special = false # Only alphanumeric
  upper   = false # Lowercase only
}

resource "azurerm_resource_group" "mini_ad_rg" {
  name     = "mini-ad-${lower(var.netbios)}-${random_string.mini_ad_rg_suffix.result}-rg"
  location = var.location
}
