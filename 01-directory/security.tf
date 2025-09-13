# # ==================================================================================================
# # Resource: Network Security Group (mini-ad-nsg)
# # Purpose:
# #   Defines inbound and outbound firewall rules required for a Samba-based
# #   Active Directory Domain Controller (AD DC) hosted on Azure.
# #
# # Notes:
# #   - Current rules allow traffic from any IPv4 source (0.0.0.0/0).
# #     This is acceptable for prototyping and labs but **not secure for production**.
# #   - In production, restrict source_address_prefix to known IP ranges,
# #     corporate VPNs, or peered VNets.
# # ==================================================================================================

# resource "azurerm_network_security_group" "mini_ad_nsg" {
#   name                = "mini-ad-nsg"
#   location            = azurerm_resource_group.ad.location
#   resource_group_name = azurerm_resource_group.ad.name

#   # ------------------------------------------------------------------------------------------------
#   # DNS (TCP/UDP 53)
#   # Required for name resolution within the Active Directory domain.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "DNS-TCP"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "53"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "DNS-UDP"
#     priority                   = 101
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Udp"
#     source_port_range          = "*"
#     destination_port_range     = "53"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # Kerberos Authentication (TCP/UDP 88)
#   # Core authentication protocol for Active Directory (used by domain logins).
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "Kerberos-TCP"
#     priority                   = 110
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "88"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Kerberos-UDP"
#     priority                   = 111
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Udp"
#     source_port_range          = "*"
#     destination_port_range     = "88"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # LDAP (TCP/UDP 389)
#   # Used for directory queries (binds, searches, authentication lookups).
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "LDAP-TCP"
#     priority                   = 120
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "389"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "LDAP-UDP"
#     priority                   = 121
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Udp"
#     source_port_range          = "*"
#     destination_port_range     = "389"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # SMB / CIFS (TCP 445)
#   # Required for file shares, SYSVOL/NETLOGON replication, and domain logon scripts.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "SMB"
#     priority                   = 130
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "445"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # Kerberos Password Change (TCP/UDP 464)
#   # Required for domain users to change or reset their passwords.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "KerberosPwd-TCP"
#     priority                   = 140
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "464"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "KerberosPwd-UDP"
#     priority                   = 141
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Udp"
#     source_port_range          = "*"
#     destination_port_range     = "464"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # RPC Endpoint Mapper (TCP 135)
#   # Enables RPC-based services such as AD replication, Group Policy, and management tools.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "RPC-135"
#     priority                   = 150
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "135"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # HTTPS (TCP 443)
#   # Provides secure communication for web-based management and LDAPS fallback.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "HTTPS"
#     priority                   = 160
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "443"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # LDAPS (TCP 636)
#   # Encrypted LDAP (TLS/SSL) – required for secure directory queries.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "LDAPS"
#     priority                   = 170
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "636"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # Global Catalog (TCP 3268, 3269)
#   # Facilitates forest-wide searches across multiple domains.
#   #  - 3268: Unencrypted Global Catalog
#   #  - 3269: Encrypted Global Catalog (TLS/SSL)
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "GC-3268"
#     priority                   = 180
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "3268"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "GC-3269"
#     priority                   = 181
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "3269"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # Ephemeral RPC Ports (TCP 49152–65535)
#   # Dynamic high ports required by Active Directory for RPC communication.
#   # Without this range, AD replication and GPO processing may fail.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "Ephemeral-RPC"
#     priority                   = 190
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_ranges    = ["49152-65535"]
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # NTP (UDP 123)
#   # Time synchronization required for Kerberos authentication to function properly.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "NTP"
#     priority                   = 200
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Udp"
#     source_port_range          = "*"
#     destination_port_range     = "123"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   # ------------------------------------------------------------------------------------------------
#   # Outbound Rules
#   # Allow all outbound traffic (simplifies AD services which often initiate connections).
#   # In production, refine to required destinations only.
#   # ------------------------------------------------------------------------------------------------
#   security_rule {
#     name                       = "AllowAllOutbound"
#     priority                   = 1000
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   tags = {
#     Name = "mini-ad-nsg"
#   }
# }

# # ==================================================================================================
# # Resource: Subnet → NSG Association
# # Purpose:
# #   Binds the defined NSG to the subnet hosting the mini Active Directory controller.
# # ==================================================================================================
# resource "azurerm_subnet_network_security_group_association" "mini_ad_subnet_assoc" {
#   subnet_id                 = azurerm_subnet.mini_ad_subnet.id
#   network_security_group_id = azurerm_network_security_group.mini_ad_nsg.id
# }
