# ==================================================================================================
# Network Interface and Linux VM Deployment
# Purpose:
#   - Create a dedicated NIC for the Samba-based Active Directory Domain Controller (AD DC).
#   - Provision an Ubuntu-based Linux VM configured as the AD DC.
#   - Ensure proper sequencing with Key Vault and DNS integration.
#
# Notes:
#   - Uses Ubuntu 24.04 LTS as the base image.
#   - Bootstraps Samba AD DC with a cloud-init script (`mini-ad.sh.template`).
#   - Relies on system-assigned managed identity for secure Key Vault access.
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Create Network Interface (NIC) for the Linux VM
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "mini_ad_vm_nic" {
  name                = "mini-ad-nic"                          # NIC resource name
  location            = var.location                           # Same region as resource group
  resource_group_name = azurerm_resource_group.mini_ad_rg.name # Same resource group

  # NIC IP configuration (internal/private use only)
  ip_configuration {
    name                          = "internal"    # Config label
    subnet_id                     = var.subnet_id # Attach NIC to VM subnet
    private_ip_address_allocation = "Dynamic"     # Auto-assign private IP
  }
}

# --------------------------------------------------------------------------------------------------
# Provision Linux Virtual Machine (Ubuntu 24.04 LTS)
# Acts as the Samba-based AD Domain Controller
# --------------------------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "mini_ad_instance" {
  name                            = "mini-ad-dc-${lower(var.netbios)}"     # VM name includes NetBIOS
  location                        = var.location                           # Same region
  resource_group_name             = azurerm_resource_group.mini_ad_rg.name # Same resource group
  size                            = var.vm_size                            # Small/cheap VM size (lab use)
  admin_username                  = var.admin_username                     # Local admin account
  admin_password                  = var.admin_password                     # Local admin password
  disable_password_authentication = false                                  # Allow password login (lab convenience)

  # Attach NIC to VM
  network_interface_ids = [
    azurerm_network_interface.mini_ad_vm_nic.id
  ]

  # Configure OS Disk
  os_disk {
    caching              = "ReadWrite"    # Enable RW caching for faster access
    storage_account_type = "Standard_LRS" # Low-cost standard storage (locally redundant)
  }

  # Base OS image (Ubuntu 24.04 LTS from Canonical Marketplace)
  source_image_reference {
    publisher = "canonical"        # Ubuntu publisher
    offer     = "ubuntu-24_04-lts" # Ubuntu 24.04 LTS
    sku       = "server"           # Server SKU
    version   = "latest"           # Always use latest patch version
  }

  # Bootstrap configuration (cloud-init script encoded in base64)
  # Template injects variables such as domain details and admin passwords.
  custom_data = base64encode(templatefile("${path.module}/scripts/mini-ad.sh.template", {
    HOSTNAME_DC        = "ad1"                      # Hostname for DC
    DNS_ZONE           = var.dns_zone               # DNS zone (e.g., mcloud.mikecloud.com)
    REALM              = var.realm                  # Kerberos realm
    NETBIOS            = var.netbios                # NetBIOS name
    ADMINISTRATOR_PASS = var.ad_admin_password      # AD Admin password
    ADMIN_USER_PASS    = var.ad_admin_password      # Domain user password
    USER_BASE_DN       = var.user_base_dn           # User base DN for LDAP
    USERS_JSON         = local.effective_users_json # User accounts JSON
  }))

  # Assign a managed identity 
  identity {
    type = "SystemAssigned"
  }
}

# ==================================================================================================
# DNS Integration
# Ensures the AD DC is fully operational before pointing VNet to it for DNS resolution.
# ==================================================================================================

# Wait for AD DC provisioning (Samba/DNS startup)
# Conservative 180s delay → adjust if bootstrap time differs.
resource "time_sleep" "wait_for_mini_ad" {
  depends_on      = [azurerm_linux_virtual_machine.mini_ad_instance]
  create_duration = "180s"
}

# Update Virtual Network DNS to point to the AD DC
# Required for domain joins and internal name resolution.
resource "azurerm_virtual_network_dns_servers" "mini_ad_dns_server" {
  virtual_network_id = var.vnet_id
  dns_servers        = [azurerm_network_interface.mini_ad_vm_nic.ip_configuration[0].private_ip_address]
  depends_on         = [time_sleep.wait_for_mini_ad]
}


# ==========================================================================================
# Local Variable: default_users_json
# ------------------------------------------------------------------------------------------
# - Renders a JSON file (`users.json.template`) into a single JSON blob
# - Injects unique random passwords for test/demo users
# - Template variables are replaced with real values at runtime
# - Passed into the VM bootstrap so users are created automatically
# ==========================================================================================

locals {
  default_users_json = templatefile("${path.module}/scripts/users.json.template", {
    USER_BASE_DN      = var.user_base_dn   # Base DN for placing new users in LDAP
    DNS_ZONE          = var.dns_zone       # AD-integrated DNS zone
    REALM             = var.realm          # Kerberos realm (FQDN in uppercase)
    NETBIOS           = var.netbios        # NetBIOS domain name
    sysadmin_password = var.admin_password # Sysadmin password
  })
}

# -------------------------------------------------------------------
# Local variable: effective_users_json
# - Determines which users.json definition to use
# - If the caller provides var.users_json → use that
# - Otherwise, fall back to local.default_users_json
# -------------------------------------------------------------------
locals {
  effective_users_json = coalesce(var.users_json, local.default_users_json)
}


# # --- Save the rendered script to a local file temporarily ---
# resource "local_file" "ad_join_rendered" {
#   filename = "/tmp/users.json"          # Save rendered script as 'users.json'
#   content  = local.default_users_json   # Use content from the templatefile rendered in locals
# }

