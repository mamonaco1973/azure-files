# ==================================================================================================
# Storage Account for Deployment Scripts
# - Creates a storage account and private container for scripts
# - Renders PowerShell domain join script from template
# - Uploads rendered script as blob and generates short-lived SAS token
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Generate a random string for use in the storage account name
# --------------------------------------------------------------------------------------------------
resource "random_string" "storage_name" {
  length  = 10     # 10 characters
  upper   = false  # Lowercase only
  special = false  # No special characters
  numeric = true   # Include numbers
}

# --------------------------------------------------------------------------------------------------
# Create storage account to host deployment scripts
# --------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "scripts_storage" {
  name                     = "vmscripts${random_string.storage_name.result}" # Ensure global uniqueness
  resource_group_name      = data.azurerm_resource_group.ad.name
  location                 = data.azurerm_resource_group.ad.location
  account_tier             = "Standard"  # Standard = cost-effective option
  account_replication_type = "LRS"       # Locally redundant storage (single region replication)
}

# --------------------------------------------------------------------------------------------------
# Create private container for storing deployment scripts
# --------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_id    = azurerm_storage_account.scripts_storage.id
  container_access_type = "private"   # No anonymous access
}

# --------------------------------------------------------------------------------------------------
# Render AD join PowerShell script from template (inject Key Vault + domain values)
# --------------------------------------------------------------------------------------------------
locals {
  ad_join_script = templatefile("./scripts/ad_join.ps1.template", {
    vault_name  = data.azurerm_key_vault.ad_key_vault.name
    domain_fqdn = "mcloud.mikecloud.com"
    nfs_gateway = azurerm_network_interface.nfs_gateway_nic.ip_configuration[0].private_ip_address
  })
}

# --------------------------------------------------------------------------------------------------
# Save the rendered script locally (ad_join.ps1)
# --------------------------------------------------------------------------------------------------
resource "local_file" "ad_join_rendered" {
  filename = "./scripts/ad_join.ps1"
  content  = local.ad_join_script
}

# --------------------------------------------------------------------------------------------------
# Upload the rendered script into Azure Storage (Blob)
# --------------------------------------------------------------------------------------------------
resource "azurerm_storage_blob" "ad_join_script" {
  name                   = "ad-join.ps1"
  storage_account_name   = azurerm_storage_account.scripts_storage.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"                          # Block blob (best for discrete files)
  source                 = local_file.ad_join_rendered.filename
  metadata = {
    force_update = "${timestamp()}" # Forces re-upload whenever timestamp changes
  }
}

# --------------------------------------------------------------------------------------------------
# Generate a short-lived SAS token for secure script access
# --------------------------------------------------------------------------------------------------
data "azurerm_storage_account_sas" "script_sas" {
  connection_string = azurerm_storage_account.scripts_storage.primary_connection_string

  resource_types {
    service   = false # No service-level access
    container = false # No container-level access
    object    = true  # Object-level (the script file itself)
  }

  services {
    blob  = true   # Enable blob access
    queue = false
    table = false
    file  = false
  }

  # Validity period: starts 24h before now (buffer) and expires 72h after now
  start  = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timeadd(timestamp(), "-24h"))
  expiry = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timeadd(timestamp(), "72h"))

  permissions {
    read    = true   # Allow read access (required to download script)
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}
