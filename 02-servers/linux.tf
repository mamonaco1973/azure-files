# --- User: ubuntu ---
# This block of resources configures a Linux VM with an 'ubuntu' account
# The VM will connect to the network, use a public IP, and have credentials stored in Azure Key Vault.

# --- Generate a strong random password for the 'ubuntu' account ---
resource "random_password" "ubuntu_password" {
  length           = 24      # Generate a 24-character password
  special          = true    # Include special characters
  override_special = "!@#$%" # Restrict special characters to these
}

# --- Store the ubuntu account credentials securely in Azure Key Vault ---
resource "azurerm_key_vault_secret" "ubuntu_secret" {
  name = "ubuntu-credentials" # Secret name
  value = jsonencode({        # Store as JSON-encoded object with username/password
    username = "ubuntu"
    password = random_password.ubuntu_password.result
  })
  key_vault_id = data.azurerm_key_vault.ad_key_vault.id # Target the existing Key Vault (data source)
  content_type = "application/json"                     # Set content type to JSON for clarity
}

# --- Create a network interface (NIC) for the Linux VM ---
resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "linux-vm-nic"                          # NIC name
  location            = data.azurerm_resource_group.ad.location # Place NIC in the same region as the resource group
  resource_group_name = data.azurerm_resource_group.ad.name     # Place NIC in the same resource group

  # --- Configure the NIC's IP settings ---
  ip_configuration {
    name                          = "internal"                       # IP configuration name
    subnet_id                     = data.azurerm_subnet.vm_subnet.id # Connect to existing subnet (data source)
    private_ip_address_allocation = "Dynamic"                        # Dynamically assign private IP
  }
}
# --- Provision the actual Linux Virtual Machine ---
resource "azurerm_linux_virtual_machine" "linux_ad_instance" {
  name                            = "linux-ad-${random_string.vm_suffix.result}" # Name the VM with a random suffix
  location                        = data.azurerm_resource_group.ad.location      # Same location as resource group
  resource_group_name             = data.azurerm_resource_group.ad.name          # Same resource group
  size                            = "Standard_B1s"                               # Small VM size (for test/dev)
  admin_username                  = "ubuntu"                                     # Admin username
  admin_password                  = random_password.ubuntu_password.result       # Use generated password
  disable_password_authentication = false                                        # Explicitly allow password auth

  # --- Attach the previously created network interface to the VM ---
  network_interface_ids = [
    azurerm_network_interface.linux_vm_nic.id
  ]

  # --- Configure the OS disk ---
  os_disk {
    caching              = "ReadWrite"    # Enable read/write caching
    storage_account_type = "Standard_LRS" # Use locally redundant standard storage
  }

  # --- Use an official Ubuntu image from the Azure Marketplace ---
  source_image_reference {
    publisher = "canonical"        # Publisher = Canonical (Ubuntu maintainers)
    offer     = "ubuntu-24_04-lts" # Offer = Ubuntu 24.04 LTS
    sku       = "server"           # SKU = Server (standard edition)
    version   = "latest"           # Use the latest version available
  }

  # --- Pass custom data (cloud-init) to the VM at creation ---
  # This template can contain any necessary setup like installing packages or configuring domain joins
  custom_data = base64encode(templatefile("./scripts/custom_data.sh", {
    vault_name  = data.azurerm_key_vault.ad_key_vault.name # Inject Key Vault name into the script
    domain_fqdn = var.dns_zone                             # Inject domain FQDN into the script
  }))

  # --- Assign a system-assigned managed identity to the VM ---
  identity {
    type = "SystemAssigned"
  }
}

# --- Grant the Linux VM's managed identity permission to read secrets from Key Vault ---
resource "azurerm_role_assignment" "vm_lnx_key_vault_secrets_user" {
  scope                = data.azurerm_key_vault.ad_key_vault.id                                   # Target the Key Vault itself
  role_definition_name = "Key Vault Secrets User"                                                 # Predefined Azure role that allows reading secrets
  principal_id         = azurerm_linux_virtual_machine.linux_ad_instance.identity[0].principal_id # Managed identity of this VM
}
