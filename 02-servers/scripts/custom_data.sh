#!/bin/bash

# This script automates the process of updating the OS, installing required packages,
# joining an Active Directory (AD) domain, configuring system settings, and cleaning
# up permissions.

# ---------------------------------------------------------------------------------
# Section 1: Update the OS and Install Required Packages
# ---------------------------------------------------------------------------------

# Update the package list to ensure the latest versions of packages are available.
apt-get update -y

# Set the environment variable to prevent interactive prompts during installation.
export DEBIAN_FRONTEND=noninteractive

# Install necessary packages for AD integration, system management, and utilities.
# - realmd, sssd-ad, sssd-tools: Tools for AD integration and authentication.
# - libnss-sss, libpam-sss: Libraries for integrating SSSD with the system.
# - adcli, samba-common-bin, samba-libs: Tools for AD and Samba integration.
# - oddjob, oddjob-mkhomedir: Automatically create home directories for AD users.
# - packagekit: Package management toolkit.
# - krb5-user: Kerberos authentication tools.
# - nano, vim: Text editors for configuration file editing.
apt-get install less unzip realmd sssd-ad sssd-tools libnss-sss \
    libpam-sss adcli samba-common-bin samba-libs oddjob \
    oddjob-mkhomedir packagekit krb5-user nano vim -y

# ---------------------------------------------------------------------------------
# Section 2: Install AZ CLI
# ---------------------------------------------------------------------------------

curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft-azure-cli-archive-keyring.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [signed-by=/etc/apt/keyrings/microsoft-azure-cli-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" \
    | tee /etc/apt/sources.list.d/azure-cli.list
apt-get update -y
apt-get install -y azure-cli

# ---------------------------------------------------------------------------------
# Section 3: Install AZ NFS Helper
# ---------------------------------------------------------------------------------

curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor \
  -o /etc/apt/keyrings/microsoft.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/ubuntu/22.04/prod jammy main" \
  | sudo tee /etc/apt/sources.list.d/aznfs.list

sudo apt-get update -y
sudo apt-get install -y aznfs

# ---------------------------------------------------------------------------------
# Section 4: Mount NFS file system
# ---------------------------------------------------------------------------------

mkdir -p /nfs
echo "${storage_account}.file.core.windows.net:/nfs /nfs aznfs defaults 0 0" | \
  sudo tee -a /etc/fstab > /dev/null
systemctl daemon-reload
mount /nfs

mkdir -p /nfs/home
mkdir -p /nfs/data
echo "${storage_account}.file.core.windows.net:/nfs/home /home aznfs defaults 0 0" | \
  sudo tee -a /etc/fstab > /dev/null
systemctl daemon-reload
mount /home

# ---------------------------------------------------------------------------------
# Section 5: Configure AD as the identity provider
# ---------------------------------------------------------------------------------

az login --identity --allow-no-subscriptions
secretsJson=$(az keyvault secret show --name admin-ad-credentials --vault-name ${vault_name} --query value -o tsv)
admin_password=$(echo "$secretsJson" | jq -r '.password')
admin_username="Admin"

# Join the Active Directory domain using the `realm` command.
# - ${domain_fqdn}: The fully qualified domain name (FQDN) of the AD domain.
# - Log the output and errors to /tmp/join.log for debugging.
echo -e "$admin_password" | sudo /usr/sbin/realm join -U "$admin_username" \
    ${domain_fqdn} --verbose \
    >> /tmp/join.log 2>> /tmp/join.log

# ---------------------------------------------------------------------------------
# Section 6: Configure SSSD for AD Integration
# ---------------------------------------------------------------------------------

# Modify the SSSD configuration file to simplify user login and home directory creation.
# - Disable fully qualified names (use only usernames instead of user@domain).
sudo sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' \
    /etc/sssd/sssd.conf

# Disable LDAP ID mapping to use UIDs and GIDs from AD.
sudo sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False/g' \
    /etc/sssd/sssd.conf

# Change the fallback home directory path to a simpler format (/home/%u).
sudo sed -i 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|' \
    /etc/sssd/sssd.conf

# Stop XAuthority warning 

touch /etc/skel/.Xauthority
chmod 600 /etc/skel/.Xauthority

# Restart the SSSD and SSH services to apply the changes.

sudo pam-auth-update --enable mkhomedir
sudo systemctl restart sssd
sudo systemctl restart ssh

# ---------------------------------------------------------------------------------
# Section 7: Grant Sudo Privileges to AD Linux Admins
# ---------------------------------------------------------------------------------

# Add a sudoers rule to grant passwordless sudo access to members of the
# "linux-admins" AD group.
sudo echo "%linux-admins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/10-linux-admins

# ---------------------------------------------------------------------------------
# Section 9: Enforce Home Directory Permissions
# ---------------------------------------------------------------------------------
# Force new home directories to have mode 0700 (private)
sudo sed -i 's/^\(\s*HOME_MODE\s*\)[0-9]\+/\10700/' /etc/login.defs

# Trigger home directory creation for specific test accounts

su -c "exit" rpatel
su -c "exit" jsmith
su -c "exit" akumar
su -c "exit" edavis

# Set NFS directory ownership and permissions
chgrp mcloud-users /nfs
chgrp mcloud-users /nfs/data
chmod 770 /nfs
chmod 770 /nfs/data
chmod 700 /home/*

cd /nfs
git clone https://github.com/mamonaco1973/azure-files.git
chmod -R 775 azure-files
chgrp -R mcloud-users azure-files
