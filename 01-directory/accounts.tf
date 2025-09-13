# ==================================================================================================
# User Credential Management
# Purpose:
#   - Automatically generate strong random passwords for Active Directory (AD) users.
#   - Store those credentials securely in Azure Key Vault as JSON objects.
#
# Notes:
#   - Each user gets a unique random password (24 characters by default).
#   - Passwords are stored in Key Vault under structured secrets, making retrieval easy for automation.
#   - "override_special" restricts special characters to avoid compatibility issues with AD and scripts.
#   - All secrets depend on the Key Vault access role assignment to ensure permissions are applied first.
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# User: John Smith (jsmith)
# Generates a password and stores AD credentials in Key Vault.
# --------------------------------------------------------------------------------------------------
resource "random_password" "jsmith_password" {
  length           = 24     # Secure 24-char password
  special          = true   # Include special characters
  override_special = "!@#%" # Restrict to safe AD-compatible characters
}

resource "azurerm_key_vault_secret" "jsmith_secret" {
  name = "jsmith-ad-credentials" # Key Vault secret name
  value = jsonencode({           # Store as JSON (username + password)
    username = "jsmith@${var.dns_zone}"
    password = random_password.jsmith_password.result
  })
  key_vault_id = azurerm_key_vault.ad_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json" # Marks secret type as JSON
}

# --------------------------------------------------------------------------------------------------
# User: Emily Davis (edavis)
# --------------------------------------------------------------------------------------------------
resource "random_password" "edavis_password" {
  length           = 24
  special          = true
  override_special = "!@#%"
}

resource "azurerm_key_vault_secret" "edavis_secret" {
  name = "edavis-ad-credentials"
  value = jsonencode({
    username = "edavis@${var.dns_zone}"
    password = random_password.edavis_password.result
  })
  key_vault_id = azurerm_key_vault.ad_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}

# --------------------------------------------------------------------------------------------------
# User: Raj Patel (rpatel)
# --------------------------------------------------------------------------------------------------
resource "random_password" "rpatel_password" {
  length           = 24
  special          = true
  override_special = "!@#%"
}

resource "azurerm_key_vault_secret" "rpatel_secret" {
  name = "rpatel-ad-credentials"
  value = jsonencode({
    username = "rpatel@${var.dns_zone}"
    password = random_password.rpatel_password.result
  })
  key_vault_id = azurerm_key_vault.ad_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}

# --------------------------------------------------------------------------------------------------
# User: Amit Kumar (akumar)
# --------------------------------------------------------------------------------------------------
resource "random_password" "akumar_password" {
  length           = 24
  special          = true
  override_special = "!@#%"
}

resource "azurerm_key_vault_secret" "akumar_secret" {
  name = "akumar-ad-credentials"
  value = jsonencode({
    username = "akumar@${var.dns_zone}"
    password = random_password.akumar_password.result
  })
  key_vault_id = azurerm_key_vault.ad_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}

# --------------------------------------------------------------------------------------------------
# User: sysadmin (local AD service account)
# Purpose:
#   - Generic sysadmin account for automation and non-user-specific tasks.
#   - Stored without domain suffix since it’s intended as a local account.
# --------------------------------------------------------------------------------------------------
resource "random_password" "sysadmin_password" {
  length           = 24
  special          = true
  override_special = "!@#%"
}

resource "azurerm_key_vault_secret" "sysadmin_secret" {
  name = "sysadmin-credentials"
  value = jsonencode({
    username = "sysadmin"
    password = random_password.sysadmin_password.result
  })
  key_vault_id = azurerm_key_vault.ad_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}

# --------------------------------------------------------------------------------------------------
# User: Admin (AD Domain Administrator)
# Purpose:
#   - Special account for AD domain administration.
#   - Uses slightly different special characters to align with AD domain password policies.
# --------------------------------------------------------------------------------------------------
resource "random_password" "admin_password" {
  length           = 24
  special          = true
  override_special = "-_." # Different set of allowed special characters
}

resource "azurerm_key_vault_secret" "admin_secret" {
  name = "admin-ad-credentials"
  value = jsonencode({
    username = "Admin@${var.dns_zone}"
    password = random_password.admin_password.result
  })
  key_vault_id = azurerm_key_vault.ad_key_vault.id
  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}
