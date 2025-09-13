# ==================================================================================================
# Azure Bastion Deployment
# - Creates Network Security Group (NSG) for Bastion
# - Allocates a public IP for Bastion
# - Deploys the Bastion Host in its own subnet
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Define a Network Security Group (NSG) for the Bastion host
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "bastion-nsg"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name

  # Allow inbound traffic from Azure Gateway Manager (required for Bastion service)
  security_rule {
    name                       = "GatewayManager"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Allow inbound HTTPS traffic from Internet (used to connect via Bastion public IP)
  security_rule {
    name                       = "Internet-Bastion-PublicIP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound RDP (3389) and SSH (22) to internal virtual network
  security_rule {
    name                       = "OutboundVirtualNetwork"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow outbound HTTPS to Azure Cloud (required for Bastion management/control plane)
  security_rule {
    name                       = "OutboundToAzureCloud"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}

# --------------------------------------------------------------------------------------------------
# Allocate a Public IP for the Bastion host
# --------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-public-ip"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name
  allocation_method   = "Static"     # Bastion requires static IP
  sku                 = "Standard"   # Bastion requires Standard SKU
}

# --------------------------------------------------------------------------------------------------
# Deploy the Azure Bastion host
# --------------------------------------------------------------------------------------------------
resource "azurerm_bastion_host" "bastion_host" {
  name                = "bastion-host"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}
