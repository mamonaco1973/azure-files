# Define a virtual network for the project
resource "azurerm_virtual_network" "ad_vnet" {
  name                = "ad-vnet"                          # Name of the VNet
  address_space       = ["10.0.0.0/23"]                    # IP address range for the VNet
  location            = azurerm_resource_group.ad.location # VNet location matches the resource group
  resource_group_name = azurerm_resource_group.ad.name     # Links to the resource group
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"                          # Name of the subnet
  resource_group_name  = azurerm_resource_group.ad.name       # Links to the resource group
  virtual_network_name = azurerm_virtual_network.ad_vnet.name # Links to the VNet
  address_prefixes     = ["10.0.0.0/25"]                      # IP range for the subnet
}

resource "azurerm_subnet" "mini_ad_subnet" {
  name                 = "mini-ad-subnet"                     # Name of the subnet
  resource_group_name  = azurerm_resource_group.ad.name       # Links to the resource group
  virtual_network_name = azurerm_virtual_network.ad_vnet.name # Links to the VNet
  address_prefixes     = ["10.0.0.128/25"]                    # IP range for the subnet
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"                 # Name of the subnet
  resource_group_name  = azurerm_resource_group.ad.name       # Links to the resource group
  virtual_network_name = azurerm_virtual_network.ad_vnet.name # Links to the VNet
  address_prefixes     = ["10.0.1.0/25"]                      # IP range for the subnet
}

# Define a network security group (NSG) for controlling traffic
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"                           # Name of the NSG
  location            = azurerm_resource_group.ad.location # NSG location matches the resource group
  resource_group_name = azurerm_resource_group.ad.name     # Links to the resource group

  # Security rule to allow SSH traffic
  security_rule {
    name                       = "Allow-SSH" # Rule name
    priority                   = 1001        # Priority of the rule
    direction                  = "Inbound"   # Inbound traffic
    access                     = "Allow"     # Allow traffic
    protocol                   = "Tcp"       # TCP protocol
    source_port_range          = "*"         # Any source port
    destination_port_range     = "22"        # Destination port for SSH
    source_address_prefix      = "*"         # Allow traffic from all IPs
    destination_address_prefix = "*"         # Applies to all destinations
  }

  # Security rule to allo RDP traffic
  security_rule {
    name                       = "Allow-RDP" # Rule name
    priority                   = 1002        # Priority of the rule
    direction                  = "Inbound"   # Inbound traffic
    access                     = "Allow"     # Allow traffic
    protocol                   = "Tcp"       # TCP protocol
    source_port_range          = "*"         # Any source port
    destination_port_range     = "3389"      # Destination port for HTTP
    source_address_prefix      = "*"         # Allow traffic from all IPs
    destination_address_prefix = "*"         # Applies to all destinations
  }
}

# Associate NSG with Application Gateway subnet
resource "azurerm_subnet_network_security_group_association" "vm-nsg-assoc" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}
