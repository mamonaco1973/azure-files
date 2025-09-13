# ==================================================================================================
# Windows VM Deployment with Admin User (Active Directory Instance)
# - Generates secure credentials for the 'adminuser' account
# - Stores credentials in Azure Key Vault
# - Provisions NIC, Windows VM, assigns permissions, and runs domain join script
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Generate a secure random password for the Windows VM 'adminuser' account
# --------------------------------------------------------------------------------------------------
resource "random_password" "win_adminuser_password" {
  length           = 24        # 24-character password
  special          = true      # Include special characters
  override_special = "!@#$%"   # Limit special characters to this set
}

# --------------------------------------------------------------------------------------------------
# Generate a random suffix for resource names
# --------------------------------------------------------------------------------------------------
resource "random_string" "vm_suffix" {
  length  = 6     # 6-character suffix
  special = false # Exclude special characters
  upper   = false # Lowercase only
}

# --------------------------------------------------------------------------------------------------
# Store 'adminuser' credentials in Azure Key Vault as JSON
# --------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "win_adminuser_secret" {
  name         = "win-adminuser-credentials"
  value        = jsonencode({ username = "adminuser", password = random_password.win_adminuser_password.result })
  key_vault_id = data.azurerm_key_vault.ad_key_vault.id
  content_type = "application/json"
}

# --------------------------------------------------------------------------------------------------
# Create a Network Interface (NIC) for the Windows VM
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "windows_vm_nic" {
  name                = "windows-vm-nic"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name

  ip_configuration {
    name                          = "internal"                       # Label for NIC config
    subnet_id                     = data.azurerm_subnet.vm_subnet.id # Attach to existing subnet
    private_ip_address_allocation = "Dynamic"                        # Dynamic private IP
  }
}

# --------------------------------------------------------------------------------------------------
# Provision the Windows Server Virtual Machine
# --------------------------------------------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "windows_ad_instance" {
  name                = "win-ad-${random_string.vm_suffix.result}"   # VM name includes suffix
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name
  size                = "Standard_DS1_v2"                            # Small VM for demo/testing
  admin_username      = "adminuser"
  admin_password      = random_password.win_adminuser_password.result

  # Attach NIC
  network_interface_ids = [ azurerm_network_interface.windows_vm_nic.id ]

  # Configure OS disk
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Windows Server 2022 Datacenter image
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Assign system-managed identity (needed for Key Vault access)
  identity {
    type = "SystemAssigned"
  }
}

# --------------------------------------------------------------------------------------------------
# Grant VM's system-managed identity permission to read Key Vault secrets
# --------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "vm_win_key_vault_secrets_user" {
  scope                = data.azurerm_key_vault.ad_key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.windows_ad_instance.identity[0].principal_id
}

# --------------------------------------------------------------------------------------------------
# Run a custom script extension to join Windows VM to AD domain
# - Script is pulled from Azure Storage and executed via PowerShell
# --------------------------------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "join_script" {
  name                 = "customScript"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_ad_instance.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "fileUris": [
      "https://${azurerm_storage_account.scripts_storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.ad_join_script.name}?${data.azurerm_storage_account_sas.script_sas.sas}"
    ],
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ad-join.ps1 *>> C:\\WindowsAzure\\Logs\\ad-join.log"
  }
  SETTINGS

  depends_on = [
    azurerm_role_assignment.vm_win_key_vault_secrets_user,
    azurerm_linux_virtual_machine.nfs_gateway
  ]
}

# --------------------------------------------------------------------------------------------------
# (Optional) Output the AD join script URL (with SAS token)
# --------------------------------------------------------------------------------------------------
# output "ad_join_script_url" {
#   value       = "https://${azurerm_storage_account.scripts_storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.ad_join_script.name}?${data.azurerm_storage_account_sas.script_sas.sas}"
#   description = "URL to the AD join script with SAS token."
# }
