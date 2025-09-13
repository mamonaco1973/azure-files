# ==================================================================================================
# Active Directory naming inputs
# - dns_zone : FQDN for the AD DNS zone / domain (e.g., mcloud.mikecloud.com)
# - realm    : Kerberos realm (typically the DNS zone in UPPERCASE)
# - netbios  : Short (pre-Windows 2000) domain name used by legacy/NetBIOS-aware systems
# ==================================================================================================

# --------------------------------------------------------------------------------
# DNS zone / AD domain (FQDN)
# Used by Samba AD DC for DNS namespace and domain identity
# --------------------------------------------------------------------------------
variable "dns_zone" {
  description = "AD DNS zone / domain (e.g., mcloud.mikecloud.com)"
  type        = string
  default     = "mcloud.mikecloud.com"
}

# --------------------------------------------------------------------------------
# Kerberos realm (UPPERCASE)
# Convention: match dns_zone but uppercase; required by Kerberos config
# --------------------------------------------------------------------------------
variable "realm" {
  description = "Kerberos realm (usually DNS zone in UPPERCASE, e.g., MCLOUD.MIKECLOUD.COM)"
  type        = string
  default     = "MCLOUD.MIKECLOUD.COM"
}

# --------------------------------------------------------------------------------
# NetBIOS short domain name
# Typically <= 15 characters, uppercase alphanumerics; used by legacy clients and some SMB flows
# --------------------------------------------------------------------------------
variable "netbios" {
  description = "NetBIOS short domain name (e.g., MCLOUD)"
  type        = string
  default     = "MCLOUD"
}

# --------------------------------------------------------------------------------
# User base DN for LDAP
# --------------------------------------------------------------------------------

variable "user_base_dn" {
  description = "User base DN for LDAP (e.g., CN=Users,DC=mcloud,DC=mikecloud,DC=com)"
  type        = string
  default     = "CN=Users,DC=mcloud,DC=mikecloud,DC=com"
}
