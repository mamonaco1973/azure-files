# ==================================================================================================
# Variables for mini-ad module
# Purpose:
#   - Define all input parameters required for provisioning the Samba AD DC VM,
#     associated NIC, DNS integration, and resource group.
# ==================================================================================================

variable "location" {
  description = "Azure region where resources will be created."
  type        = string
}

variable "dns_zone" {
  description = "DNS zone for the Samba AD domain (e.g., mcloud.mikecloud.com)."
  type        = string
}

variable "realm" {
  description = "Kerberos realm (typically uppercase form of DNS zone)."
  type        = string
}

variable "netbios" {
  description = "NetBIOS short name for the domain."
  type        = string
}

variable "user_base_dn" {
  description = "Base DN for user objects in LDAP (e.g., CN=Users,DC=mcloud,DC=mikecloud,DC=com)."
  type        = string
}

variable "vm_size" {
  description = "Size of the AD DC VM."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Local admin username for the Linux VM."
  type        = string
  default     = "sysadmin"
}

variable "admin_password" {
  description = "Local admin password for the Linux VM."
  type        = string
  sensitive   = true
}

variable "ad_admin_password" {
  description = "Password for the AD Administrator account used in Samba bootstrap."
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "ID of the subnet where the NIC/VM will be attached."
  type        = string
}

variable "vnet_id" {
  description = "ID of the Virtual Network for DNS server updates."
  type        = string
}

variable "users_json" {
  description = "Pre-rendered JSON string containing user account definitions (from users.json.template)."
  type        = string
  default     = ""
}
