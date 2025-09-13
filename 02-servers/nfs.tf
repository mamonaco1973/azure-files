resource "azurerm_storage_account" "nfs_storage_account" {
  name                     = "nfs${random_string.vm_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.ad.name
  location                 = data.azurerm_resource_group.ad.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"
  public_network_access_enabled = false
  https_traffic_only_enabled = false 
}



