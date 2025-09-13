resource "azurerm_storage_account" "nfs_storage_account" {
  name                     = "nfs${random_string.vm_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.ad.name
  location                 = data.azurerm_resource_group.ad.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"
  public_network_access_enabled = false
}

# ----------------------------
# NFS File Share
# ----------------------------
resource "azurerm_storage_share" "nfs" {
  name                 = "nfsfileshare"
  storage_account_id   = azurerm_storage_account.nfs_storage_account.id
  enabled_protocol     = "NFS"
  quota                = 100  
}

# ----------------------------
# Private DNS for Azure Files
# ----------------------------
resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.azurerm_resource_group.ad.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_link" {
  name                  = "vnet-link"
  resource_group_name   = data.azurerm_resource_group.ad.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = data.azurerm_virtual_network.ad.id
}


# ----------------------------
# Private Endpoint -> "file" subresource
# ----------------------------
resource "azurerm_private_endpoint" "pe_file" {
  name                = "pe-st-file"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name
  subnet_id           = data.azurerm_subnet.vm_subnet.id

  private_service_connection {
    name                           = "sc-st-file"
    private_connection_resource_id = azurerm_storage_account.nfs_storage_account.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}

output "nfs_mount_command" {
  value = <<EOT
sudo apt-get -y install nfs-common
sudo mkdir -p /mnt/azurefiles
sudo mount -t nfs -o vers=4.1,sec=sys \
  ${azurerm_storage_account.nfs_storage_account.name}.file.core.windows.net:/${azurerm_storage_share.nfs.name} /mnt/azurefiles
EOT
}

