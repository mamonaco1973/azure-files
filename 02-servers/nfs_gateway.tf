# ==================================================================================================
# Linux VM Deployment with Ubuntu Account (NFS Gateway)
# - Generates secure credentials for the 'ubuntu' account
# - Stores credentials in Azure Key Vault
# - Provisions a NIC, Linux VM, and assigns permissions
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Generate a secure random password for the 'ubuntu' account
# --------------------------------------------------------------------------------------------------
resource "random_password" "ubuntu_password" {
  length           = 24        # 24-character password
  special          = true      # Include special characters
  override_special = "!@#$%"   # Restrict allowed special characters
}

# --------------------------------------------------------------------------------------------------
# Store 'ubuntu' credentials securely in Azure Key Vault as a JSON object
# --------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "ubuntu_secret" {
  name         = "ubuntu-credentials"                         # Secret name
  value        = jsonencode({ username = "ubuntu", password = random_password.ubuntu_password.result })
  key_vault_id = data.azurerm_key_vault.ad_key_vault.id        # Target existing Key Vault
  content_type = "application/json"                           # Mark content as JSON
}

# --------------------------------------------------------------------------------------------------
# Create a Network Interface (NIC) for the NFS Gateway VM
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "nfs_gateway_nic" {
  name                = "nfs-gateway-nic"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name

  ip_configuration {
    name                          = "internal"                        # IP configuration label
    subnet_id                     = data.azurerm_subnet.vm_subnet.id  # Connect to existing subnet
    private_ip_address_allocation = "Dynamic"                         # Dynamic private IP assignment
  }
}

# --------------------------------------------------------------------------------------------------
# Provision the NFS Gateway Linux Virtual Machine
# --------------------------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "nfs_gateway" {
  name                            = "nfs-gateway-${random_string.vm_suffix.result}" # VM name with suffix
  location                        = data.azurerm_resource_group.ad.location
  resource_group_name             = data.azurerm_resource_group.ad.name
  size                            = "Standard_B1s"                  # Small VM size (dev/test)
  admin_username                  = "ubuntu"                        # Admin username
  admin_password                  = random_password.ubuntu_password.result
  disable_password_authentication = false                           # Allow password login

  # Attach NIC
  network_interface_ids = [ azurerm_network_interface.nfs_gateway_nic.id ]

  # Configure OS disk
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Base image: Ubuntu 24.04 LTS from Azure Marketplace
  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Inject cloud-init script (custom_data)
  custom_data = base64encode(templatefile("./scripts/custom_data.sh", {
    vault_name      = data.azurerm_key_vault.ad_key_vault.name
    domain_fqdn     = var.dns_zone
    netbios         = var.netbios
    force_group     = "mcloud-users"
    realm           = var.realm
    storage_account = azurerm_storage_account.nfs_storage_account.name
  }))

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }
}

# --------------------------------------------------------------------------------------------------
# Grant VM's managed identity permission to read Key Vault secrets
# --------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "vm_lnx_key_vault_secrets_user" {
  scope                = data.azurerm_key_vault.ad_key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.nfs_gateway.identity[0].principal_id
}
