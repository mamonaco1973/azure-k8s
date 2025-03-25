resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.aks_flaskapp_rg.location
  resource_group_name = azurerm_resource_group.aks_flaskapp_rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.aks_flaskapp_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}

resource "azurerm_network_security_group" "flask_lb_nsg" {
  name                = "flask_lb_nsg"                                   # Name of the NSG
  location            = azurerm_resource_group.aks_flaskapp_rg.location  # Azure region
  resource_group_name = azurerm_resource_group.aks_flaskapp_rg.name      # Resource group for the NSG

  security_rule {
    name                       = "Allow-HTTP"                         # Rule name: Allow HTTP traffic
    priority                   = 1002                                 # Rule priority
    direction                  = "Inbound"                            # Traffic direction
    access                     = "Allow"                              # Allow or deny rule
    protocol                   = "Tcp"                                # Protocol type
    source_port_range          = "*"                                  # Source port range
    destination_port_range     = "80"                                 # Destination port
    source_address_prefix      = "*"                                  # Source address range
    destination_address_prefix = "*"                                  # Destination address range
  }
}

resource "azurerm_subnet_network_security_group_association" "flask-lb-nsg-assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.flask_lb_nsg.id
}