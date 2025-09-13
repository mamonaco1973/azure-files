#!/bin/bash
# ==================================================================================================
# Destroy Script for Mini Active Directory Deployment (Azure)
# Purpose:
#   - Tears down the Mini Active Directory environment in reverse order of deployment.
#   - Ensures servers (AD VM + supporting resources) are destroyed before the directory layer (Key Vault).
#   - Automates discovery of the Key Vault name to cleanly remove all resources.
#
# Notes:
#   - Use with caution: This script will **permanently delete all deployed resources**.
#   - Order matters:
#       1. Server layer destroyed first (VM, networking, role assignments).
#       2. Directory layer destroyed last (Key Vault, base infra).
#   - Assumes `az` (Azure CLI) and `terraform` are installed and authenticated.
# ==================================================================================================

set -e  # Exit immediately if any command fails

# --------------------------------------------------------------------------------------------------
# Phase 1: Destroy Server Layer
# - Destroys the Samba-based AD Domain Controller VM and dependent resources.
# - Retrieves the Key Vault name created in Phase 1 of deployment to ensure Terraform
#   can clean up associated secrets and references.
# --------------------------------------------------------------------------------------------------
cd 02-servers

vault=$(az keyvault list \
  --resource-group mcloud-project-rg \
  --query "[?starts_with(name, 'ad-key-vault')].name | [0]" \
  --output tsv)

echo "NOTE: Key vault for secrets is $vault"

terraform init   # Initialize Terraform working directory (re-download providers/modules if needed)
terraform destroy -var="vault_name=$vault" -auto-approve   # Destroy VM and dependent resources

cd ..

# --------------------------------------------------------------------------------------------------
# Phase 2: Destroy Directory Layer
# - Removes foundational resources such as Key Vault and resource group–scoped roles.
# - This must run after servers are removed, since they may depend on secrets stored in Key Vault.
# --------------------------------------------------------------------------------------------------
cd 01-directory

terraform init
terraform destroy -auto-approve   # Destroy Key Vault and supporting resources

cd ..
