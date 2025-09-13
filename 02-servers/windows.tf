# --- User: adminuser ---

# --- Generate a strong random password for the Windows VM's 'adminuser' account ---
resource "random_password" "win_adminuser_password" {
  length           = 24      # 24-character long password
  special          = true    # Include special characters in the password
  override_special = "!@#$%" # Limit special characters to this specific set
}

# --- Generate a random string to use as a suffix for resource names ---
resource "random_string" "vm_suffix" {
  length  = 6     # 6-character suffix
  special = false # Exclude special characters
  upper   = false # Lowercase only
}

# --- Store the generated admin credentials in Azure Key Vault as a secret ---
resource "azurerm_key_vault_secret" "win_adminuser_secret" {
  name = "win-adminuser-credentials"                         # Secret name in Key Vault
  value = jsonencode({                                       # JSON-encoded username and password
    username = "adminuser"                                   # Admin username (local Windows user)
    password = random_password.win_adminuser_password.result # Admin password from random_password resource
  })
  key_vault_id = data.azurerm_key_vault.ad_key_vault.id # ID of the existing Key Vault (data source)
  content_type = "application/json"                     # Set content type for secret
}

# --- Define a network interface for the Windows VM to connect to the subnet ---
resource "azurerm_network_interface" "windows_vm_nic" {
  name                = "windows-vm-nic"                        # NIC name
  location            = data.azurerm_resource_group.ad.location # Use the same location as the resource group
  resource_group_name = data.azurerm_resource_group.ad.name     # Place NIC in the same resource group

  # --- IP Configuration for the network interface ---
  ip_configuration {
    name                          = "internal"                       # Name the IP config block
    subnet_id                     = data.azurerm_subnet.vm_subnet.id # Reference the existing subnet (data source)
    private_ip_address_allocation = "Dynamic"                        # Dynamically allocate private IP
  }
}

# --- Deploy the actual Windows Virtual Machine ---
resource "azurerm_windows_virtual_machine" "windows_ad_instance" {
  name                = "win-ad-${random_string.vm_suffix.result}"    # VM name includes random suffix
  location            = data.azurerm_resource_group.ad.location       # Same location as resource group
  resource_group_name = data.azurerm_resource_group.ad.name           # Same resource group
  size                = "Standard_DS1_v2"                             # VM size (small instance for demo/testing)
  admin_username      = "adminuser"                                   # Set admin username
  admin_password      = random_password.win_adminuser_password.result # Use generated password

  # --- Link the VM to the previously created network interface ---
  network_interface_ids = [
    azurerm_network_interface.windows_vm_nic.id
  ]

  # --- Configure the OS disk for the VM ---
  os_disk {
    caching              = "ReadWrite"    # Enable read-write caching for faster disk performance
    storage_account_type = "Standard_LRS" # Use locally redundant storage (cheapest option)
  }

  # --- Use a predefined Windows Server 2022 image from the Azure Marketplace ---
  source_image_reference {
    publisher = "MicrosoftWindowsServer" # Official Microsoft publisher
    offer     = "WindowsServer"          # Product offer - Windows Server
    sku       = "2022-Datacenter"        # Specific version - 2022 Datacenter Edition
    version   = "latest"                 # Always use the latest available version
  }

  # --- Set Windows Update behavior ---
  patch_mode               = "AutomaticByOS" # Let the OS manage updates
  enable_automatic_updates = true            # Enable automatic Windows updates

  # --- Assign a system-managed identity to the VM (needed for Key Vault access) ---
  identity {
    type = "SystemAssigned"
  }
}

# --- Grant the VM's system-managed identity permission to read secrets from Key Vault ---
resource "azurerm_role_assignment" "vm_win_key_vault_secrets_user" {
  scope                = data.azurerm_key_vault.ad_key_vault.id                                       # Target the Key Vault itself
  role_definition_name = "Key Vault Secrets User"                                                     # Predefined Azure RBAC role
  principal_id         = azurerm_windows_virtual_machine.windows_ad_instance.identity[0].principal_id # Identity of the VM
}

# --- Run a custom script to join the Windows VM to a domain (or other setup tasks) ---
resource "azurerm_virtual_machine_extension" "join_script" {
  name                 = "customScript"                                         # Extension name
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_ad_instance.id # Target VM
  publisher            = "Microsoft.Compute"                                    # Extension publisher
  type                 = "CustomScriptExtension"                                # Extension type
  type_handler_version = "1.10"                                                 # Specific handler version

  # --- Script settings - download script from storage account and execute it ---
  settings = <<SETTINGS
  {
    "fileUris": ["https://${azurerm_storage_account.scripts_storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.ad_join_script.name}?${data.azurerm_storage_account_sas.script_sas.sas}"],
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ad-join.ps1 *>> C:\\WindowsAzure\\Logs\\ad-join.log"
  }
  SETTINGS

  depends_on = [azurerm_role_assignment.vm_win_key_vault_secrets_user]
}


# output "ad_join_script_url" {
#   value       = "https://${azurerm_storage_account.scripts_storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.ad_join_script.name}?${data.azurerm_storage_account_sas.script_sas.sas}"
#   description = "URL to the AD join script with SAS token."
# }
