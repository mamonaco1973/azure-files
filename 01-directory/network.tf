# ==================================================================================================
# Virtual Network, Subnets, and Network Security Group
# - Creates VNet with dedicated subnets for VMs, mini-AD, and Bastion
# - Configures NSG to allow SSH and RDP
# - Associates NSG with VM subnet
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Define the Virtual Network
# --------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "ad_vnet" {
  name                = "ad-vnet"
  address_space       = ["10.0.0.0/23"]                     # Overall VNet range
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name
}

# --------------------------------------------------------------------------------------------------
# Define VM Subnet (10.0.0.0/25)
# --------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.ad.name
  virtual_network_name = azurerm_virtual_network.ad_vnet.name
  address_prefixes     = ["10.0.0.0/25"]
}

# --------------------------------------------------------------------------------------------------
# Define Mini-AD Subnet (10.0.0.128/25)
# --------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "mini_ad_subnet" {
  name                 = "mini-ad-subnet"
  resource_group_name  = azurerm_resource_group.ad.name
  virtual_network_name = azurerm_virtual_network.ad_vnet.name
  address_prefixes     = ["10.0.0.128/25"]
}

# --------------------------------------------------------------------------------------------------
# Define Bastion Subnet (10.0.1.0/25)
# NOTE: Bastion requires subnet name to be exactly "AzureBastionSubnet"
# --------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.ad.name
  virtual_network_name = azurerm_virtual_network.ad_vnet.name
  address_prefixes     = ["10.0.1.0/25"]
}

# --------------------------------------------------------------------------------------------------
# Define Network Security Group (NSG) for VM subnet
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name

  # Allow inbound SSH (Linux admin access)
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow inbound RDP (Windows admin access)
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow inbound SMB (AD and file share access)
  security_rule {
    name                       = "Allow-SMB"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# --------------------------------------------------------------------------------------------------
# Associate NSG with VM subnet
# --------------------------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "vm_nsg_assoc" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}
