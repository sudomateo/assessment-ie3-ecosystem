terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.67.0"
    }
  }
}

# Credentials come from environment variables.
provider "azurerm" {
  features {}
}

# Resource group to place all the resources in.
resource "azurerm_resource_group" "taskly" {
  name     = "taskly"
  location = "East US"
}

# This virtual network will be used by Kubernetes and the Application Gateway.
resource "azurerm_virtual_network" "taskly" {
  name                = "taskly"
  resource_group_name = azurerm_resource_group.taskly.name
  location            = azurerm_resource_group.taskly.location
  address_space       = ["10.99.0.0/16"]
}

# Subnet for Kubernetes.
resource "azurerm_subnet" "kubernetes" {
  name                 = "kubernetes"
  resource_group_name  = azurerm_resource_group.taskly.name
  virtual_network_name = azurerm_virtual_network.taskly.name
  address_prefixes     = ["10.99.100.0/24"]
}

# Subnet for the Application Gateway.
resource "azurerm_subnet" "ingress" {
  name                 = "ingress"
  resource_group_name  = azurerm_resource_group.taskly.name
  virtual_network_name = azurerm_virtual_network.taskly.name
  address_prefixes     = ["10.99.200.0/24"]
}

# Kubernetes cluster whose API is publicly available and integrates with an
# Azure Application Gateway.
resource "azurerm_kubernetes_cluster" "taskly" {
  name                = "taskly"
  resource_group_name = azurerm_resource_group.taskly.name
  location            = azurerm_resource_group.taskly.location

  dns_prefix = "taskly"
  sku_tier   = "Standard"

  default_node_pool {
    name                = "taskly"
    vm_size             = "Standard_DS2_v2"
    node_count          = 1
    enable_auto_scaling = false
    vnet_subnet_id      = azurerm_subnet.kubernetes.id
  }

  identity {
    type = "SystemAssigned"
  }

  # Integrate with the Azure Application Gateway to provide ingress
  # functionality.
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.taskly.id
  }

  # Use Azure networking.
  network_profile {
    network_plugin = "azure"
  }
}

# Public IP address for the Application Gateway.
resource "azurerm_public_ip" "taskly" {
  name                = "taskly"
  resource_group_name = azurerm_resource_group.taskly.name
  location            = azurerm_resource_group.taskly.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway to be integrated with Kubernetes as its Ingress
# Controller. We create this via Terraform but once we integrate it with
# Kubernetes Kubernetes will assume management of this resource. To account for
# that, we use the lifecycle block to ignore changes to certain attributes.
resource "azurerm_application_gateway" "taskly" {
  name                = "taskly"
  resource_group_name = azurerm_resource_group.taskly.name
  location            = azurerm_resource_group.taskly.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      tags,
      url_path_map,
    ]
  }

  gateway_ip_configuration {
    name      = "gateway_ip_configuration"
    subnet_id = azurerm_subnet.ingress.id
  }

  frontend_port {
    name = "frontend_port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend_ip_configuration"
    public_ip_address_id = azurerm_public_ip.taskly.id
  }

  backend_address_pool {
    name = "backend_address_pool"
  }

  backend_http_settings {
    name                  = "backend_http_settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http_listener"
    frontend_ip_configuration_name = "frontend_ip_configuration"
    frontend_port_name             = "frontend_port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "request_routing_rule"
    rule_type                  = "Basic"
    priority                   = 1
    http_listener_name         = "http_listener"
    backend_address_pool_name  = "backend_address_pool"
    backend_http_settings_name = "backend_http_settings"
  }
}

# Read the managed identity that the Kubernetes cluster created for its ingress
# controller.
data "azurerm_user_assigned_identity" "ingress" {
  name                = "ingressapplicationgateway-${azurerm_kubernetes_cluster.taskly.name}"
  resource_group_name = azurerm_kubernetes_cluster.taskly.node_resource_group
}

# Allow the ingress controller managed identity to read the resource group.
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.taskly.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
}

# Allow the ingress controller managed identity to read/write the virtual
# network.
resource "azurerm_role_assignment" "network_contributor" {
  scope                = azurerm_virtual_network.taskly.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
}

# Allow the ingress controller managed identity to read/write to the
# application gateway.
resource "azurerm_role_assignment" "contributor" {
  scope                = azurerm_application_gateway.taskly.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.ingress.principal_id
}

output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.taskly.kube_config
  sensitive = true
}
