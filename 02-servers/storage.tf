# --- Storage account to hold deployment scripts ---
resource "azurerm_storage_account" "scripts_storage" {
  name                     = "vmscripts${random_string.storage_name.result}" # Storage account name with random suffix to ensure uniqueness
  resource_group_name      = data.azurerm_resource_group.ad.name             # Place it in the existing resource group
  location                 = data.azurerm_resource_group.ad.location         # Use the same location as the resource group
  account_tier             = "Standard"                                      # Standard tier (cost-effective option)
  account_replication_type = "LRS"                                           # Locally redundant storage (replicated within a single region)
}

# --- Container inside the storage account to hold the actual scripts ---
resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"                                  # Container name
  storage_account_id    = azurerm_storage_account.scripts_storage.id # Link to the storage account
  container_access_type = "private"                                  # Private container (no anonymous access)
}

# --- Local variable block for injecting values into the PowerShell script template ---
locals {
  ad_join_script = templatefile("./scripts/ad_join.ps1.template", { # Rendered script content (local variable)
    vault_name  = data.azurerm_key_vault.ad_key_vault.name          # Inject Key Vault name into the script
    domain_fqdn = "mcloud.mikecloud.com"                            # Inject domain name into the script
  })
}

# --- Save the rendered PowerShell script to a local file ---
resource "local_file" "ad_join_rendered" {
  filename = "./scripts/ad_join.ps1" # Save rendered script as 'ad_join.ps1'
  content  = local.ad_join_script    # Use content from the templatefile rendered in locals
}

# --- Upload the rendered PowerShell script into the storage container ---
resource "azurerm_storage_blob" "ad_join_script" {
  name                   = "ad-join.ps1"                                # Name of the blob (file name in storage)
  storage_account_name   = azurerm_storage_account.scripts_storage.name # Link to storage account by name
  storage_container_name = azurerm_storage_container.scripts.name       # Place in the 'scripts' container
  type                   = "Block"                                      # Blob type (most common type for files)
  source                 = local_file.ad_join_rendered.filename         # Source file to upload (rendered script)
  metadata = {
    force_update = "${timestamp()}" # This forces re-upload every time
  }
}

# --- Generate a random string for use in the storage account name ---
resource "random_string" "storage_name" {
  length  = 10    # 10 characters long
  upper   = false # No uppercase letters
  special = false # No special characters
  numeric = true  # Include numbers
}

# --- Generate a short-lived SAS token for accessing the uploaded script ---
data "azurerm_storage_account_sas" "script_sas" {
  connection_string = azurerm_storage_account.scripts_storage.primary_connection_string
  # Use the primary connection string to generate the SAS token

  resource_types {
    service   = false # Not granting service-level permissions
    container = false # Not granting container-level permissions
    object    = true  # Grant object-level permissions (this is the script itself)
  }

  services {
    blob  = true  # This is a blob (file), so allow blob-level service access
    queue = false # No queue access needed
    table = false # No table access needed
    file  = false # No file share access needed
  }

  start  = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timeadd(timestamp(), "-24h"))
  expiry = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timeadd(timestamp(), "72h"))

  #start  = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timestamp())                 # Start time (now)
  #expiry = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timeadd(timestamp(), "24h")) # Expire after 24 hours

  permissions {
    read    = true  # Allow read access (needed to download the script)
    write   = false # Do not allow writing
    delete  = false # Do not allow deletion
    list    = false # Do not allow listing
    add     = false # Do not allow adding files
    create  = false # Do not allow file creation
    update  = false # Do not allow updating existing files
    process = false # Not applicable to blobs
    filter  = false # Not applicable to blobs
    tag     = false # No need for tagging permissions
  }
}
