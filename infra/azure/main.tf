##########################
# Resource Group
##########################
resource "azurerm_resource_group" "demo" {
  name     = var.project_name
  location = var.location
}

##########################
# Network Security Group
##########################
resource "azurerm_network_security_group" "demo" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

##########################
# Virtual Network
##########################
resource "azurerm_virtual_network" "demo" {
  name                = "${var.project_name}-vn"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "subnet1"
    address_prefixes = ["10.0.1.0/24"]
  }

  subnet {
    name             = "subnet2"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = azurerm_network_security_group.demo.id
  }

  tags = local.common_tags
}


##########################
# AKS Cluster
##########################
resource "azurerm_kubernetes_cluster" "demo" {
  name                = "${var.project_name}-AKS-cluster"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  dns_prefix          = "aiops"

  default_node_pool {
    name       = "aiops"
    node_count = 2
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

##########################
# ACR Cluster
##########################
resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name}"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  sku                 = "Basic"
  admin_enabled       = false
}
