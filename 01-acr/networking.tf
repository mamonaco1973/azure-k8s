# ---------------------------------------------------------
# Virtual Network Definition for AKS Cluster
# ---------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"                                        # Name of the Virtual Network
  address_space       = ["10.0.0.0/8"]                                    # Large IP address space for future subnets
  location            = azurerm_resource_group.aks_flaskapp_rg.location   # Match location with AKS and resource group
  resource_group_name = azurerm_resource_group.aks_flaskapp_rg.name       # Deploy into shared RG for consistency

  # ✅ This VNet will host AKS system and user node pools, plus other services like Application Gateway or CosmosDB if needed.
}

# ---------------------------------------------------------
# Subnet Definition for AKS Nodes
# ---------------------------------------------------------

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"                                     # Subnet name within the VNet
  resource_group_name  = azurerm_resource_group.aks_flaskapp_rg.name      # Same resource group as the VNet
  virtual_network_name = azurerm_virtual_network.vnet.name                # Associate with the VNet created above
  address_prefixes     = ["10.240.0.0/16"]                                # IP range reserved for AKS nodes and pods

  # ✅ Used by the default AKS node pool — must be delegated to AKS during cluster creation.
}

# ---------------------------------------------------------
# Network Security Group for Flask App Traffic
# ---------------------------------------------------------

resource "azurerm_network_security_group" "flask_lb_nsg" {
  name                = "flask_lb_nsg"                                   # Name of the NSG
  location            = azurerm_resource_group.aks_flaskapp_rg.location  # Azure region
  resource_group_name = azurerm_resource_group.aks_flaskapp_rg.name      # Same RG as the VNet and subnet

  # Inbound rule to allow standard HTTP traffic (port 80)
  security_rule {
    name                       = "Allow-HTTP"                      # Rule name
    priority                   = 1002                              # Lower number = higher priority
    direction                  = "Inbound"                         # Only handle incoming traffic
    access                     = "Allow"                           # Explicitly allow traffic
    protocol                   = "Tcp"                             # TCP traffic only
    source_port_range          = "*"                               # Any source port
    destination_port_range     = "80"                              # Port used by HTTP
    source_address_prefix      = "*"                               # Allow traffic from anywhere (0.0.0.0/0)
    destination_address_prefix = "*"                               # Apply to all resources in subnet
  }

  # Inbound rule to allow Flask app traffic on port 8000
  security_rule {
    name                       = "Allow-Flask-Ingress-8000"        # Custom rule for app port
    priority                   = 1003                              # Slightly lower priority than HTTP rule
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"                            # Port used by the Flask app (typically via LoadBalancer)
    source_address_prefix      = "*"                               # Open to all (restrict to known ingress IPs in production)
    destination_address_prefix = "*"
  }

  # ✅ These rules ensure external access to both standard web and custom Flask service endpoints.
}

# ---------------------------------------------------------
# Associate NSG with AKS Subnet
# ---------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "flask-lb-nsg-assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id                      # Target the AKS subnet
  network_security_group_id = azurerm_network_security_group.flask_lb_nsg.id   # Attach the NSG to enforce inbound rules

  # ✅ Required to allow traffic through ports 80 and 8000 to reach AKS workloads.
  # Without this association, the NSG rules won't apply to the subnet.
}

# ---------------------------------------------------------
# NAT Gateway Setup for Outbound Internet Connectivity
# ---------------------------------------------------------

# Public IP Address for NAT Gateway (Standard SKU, static)
resource "azurerm_public_ip" "nat_ip" {
  name                = "nat-public-ip"                                 # Name of the public IP resource
  location            = azurerm_resource_group.aks_flaskapp_rg.location # Same region as VNet
  resource_group_name = azurerm_resource_group.aks_flaskapp_rg.name     # Same RG as networking resources
  allocation_method   = "Static"                                        # Allocate a static public IP
  sku                 = "Standard"                                      # Required SKU for NAT Gateway use
}

# NAT Gateway resource for secure outbound access
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "aks-nat-gateway"                               # Name of the NAT Gateway
  location            = azurerm_resource_group.aks_flaskapp_rg.location
  resource_group_name = azurerm_resource_group.aks_flaskapp_rg.name
  sku_name            = "Standard"                                      # Standard SKU for production workloads
}

# Associate the NAT Gateway with the public IP
resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id      = azurerm_nat_gateway.nat_gateway.id             # Link to NAT Gateway
  public_ip_address_id = azurerm_public_ip.nat_ip.id                   # Attach the static public IP

  # ✅ Required to enable outbound traffic through NAT Gateway
}

# Associate NAT Gateway with AKS subnet
resource "azurerm_subnet_nat_gateway_association" "aks_nat_assoc" {
  subnet_id      = azurerm_subnet.aks_subnet.id                         # Target the AKS subnet
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id                   # Link the NAT Gateway

  # ✅ Ensures AKS nodes can reach external resources securely without public IPs.
}
