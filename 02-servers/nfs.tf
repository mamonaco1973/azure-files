# ================================================================================================
# Azure Files (NFS 4.1) with Private Endpoint
# ================================================================================================
# Provisions a Premium FileStorage account with an NFS-enabled file share,
# and exposes it securely inside a virtual network via a private endpoint.
#
# Key Points:
#   - Storage Account is Premium FileStorage (required for NFS 4.1).
#   - NFS File Share is created with a minimum quota of 100 GiB.
#   - Public access is disabled; access flows through a Private Endpoint.
#   - Private DNS Zone (privatelink.file.core.windows.net) provides name resolution.
#   - Linux VMs in the linked VNet can mount the share via NFS or AZNFS (TLS).
# ================================================================================================
resource "azurerm_storage_account" "nfs_storage_account" {

  # ----------------------------------------------------------------------------------------------
  # Storage Account Configuration
  # ----------------------------------------------------------------------------------------------
  # - Name must be globally unique, lowercase, and between 3–24 characters.
  # - Premium FileStorage SKU is required for NFS file shares.
  # - Replication set to Locally Redundant (LRS) for lab/demo use.
  # - Public access disabled to enforce traffic through the private endpoint.
  name                         = "nfs${random_string.vm_suffix.result}"
  resource_group_name          = data.azurerm_resource_group.ad.name
  location                     = data.azurerm_resource_group.ad.location
  account_kind                 = "FileStorage"   # Enables Premium File shares
  account_tier                 = "Premium"       # Required for NFS support
  account_replication_type     = "LRS"           # Locally-redundant replication
  public_network_access_enabled = false          # Block public endpoint access
}

# ================================================================================================
# NFS File Share
# ================================================================================================
# Creates a file share inside the Premium FileStorage account and enables the NFS 4.1 protocol.
#
# Key Points:
#   - NFS protocol must be explicitly enabled.
#   - Minimum quota for Premium FileStorage NFS = 100 GiB.
#   - Share is mounted on Linux via "<storageaccount>.file.core.windows.net:/<sharename>".
# ================================================================================================
resource "azurerm_storage_share" "nfs" {
  name               = "nfs"
  storage_account_id = azurerm_storage_account.nfs_storage_account.id
  enabled_protocol   = "NFS"
  quota              = 100
}

# ================================================================================================
# Private DNS Zone for Azure Files
# ================================================================================================
# Creates a private DNS zone to resolve Azure Files endpoints within the VNet.
#
# Key Points:
#   - Zone: privatelink.file.core.windows.net
#   - Ensures that <account>.file.core.windows.net resolves to the private IP
#     associated with the Private Endpoint.
# ================================================================================================
resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.azurerm_resource_group.ad.name
}

# ----------------------------------------------------------------------------------------------
# VNet Link for Private DNS Zone
# ----------------------------------------------------------------------------------------------
# Links the private DNS zone to the Active Directory VNet, so that Linux VMs
# in the subnet resolve Azure Files names to private IPs.
resource "azurerm_private_dns_zone_virtual_network_link" "file_link" {
  name                  = "vnet-link"
  resource_group_name   = data.azurerm_resource_group.ad.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = data.azurerm_virtual_network.ad_vnet.id
}

# ================================================================================================
# Private Endpoint (File Service Subresource)
# ================================================================================================
# Establishes a Private Endpoint to the storage account’s "file" subresource.
#
# Key Points:
#   - Provides secure, private connectivity from VMs in the subnet to the file share.
#   - Private DNS Zone Group binds the endpoint to the private DNS zone.
#   - Ensures no public exposure; all traffic remains inside the VNet.
# ================================================================================================
resource "azurerm_private_endpoint" "pe_file" {
  name                = "pe-st-file"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name
  subnet_id           = data.azurerm_subnet.vm_subnet.id

  # --------------------------------------------------------------------------------------------
  # Private Service Connection
  # --------------------------------------------------------------------------------------------
  # - Connects the private endpoint to the storage account’s "file" subresource.
  # - Connection is automatic (is_manual_connection = false).
  private_service_connection {
    name                           = "sc-st-file"
    private_connection_resource_id = azurerm_storage_account.nfs_storage_account.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  # --------------------------------------------------------------------------------------------
  # Private DNS Zone Group
  # --------------------------------------------------------------------------------------------
  # - Attaches the private endpoint to the private DNS zone defined above.
  # - Ensures DNS records are automatically registered for the endpoint.
  private_dns_zone_group {
    name                 = "pdzg-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }
}

# ================================================================================================
# (Optional) Output: Linux Mount Command
# ================================================================================================
# Provides copy/paste instructions for mounting the NFS file share from a Linux VM.
# Commented out to avoid clutter in Terraform output unless explicitly required.
# ================================================================================================
# output "nfs_mount_command" {
#   value = <<EOT
# sudo apt-get -y install nfs-common
# sudo mkdir -p /mnt/azurefiles
# sudo mount -t nfs -o vers=4.1,sec=sys \
#   ${azurerm_storage_account.nfs_storage_account.name}.file.core.windows.net:/${azurerm_storage_share.nfs.name} /mnt/azurefiles
# EOT
# }
