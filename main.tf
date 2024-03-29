variable "app_service_name" {
  description = "Name of the Azure App Service"
  type        = string
}

variable "runtime" {
  description = "Runtime for the App Service (e.g., JAVA|11 or DOTNETCORE|3.1)"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Azure Storage Account for Terraform state"
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the Subnet"
  type        = string
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]  # Corrected address space
}


variable "location" {
  description = "Resource group location"
  type        = string
}

variable "container" {
  description = "Container name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

# Output the container name
output "container_name" {
  value = "test_container"
}

# Output the storage account name
output "storage_account_name" {
  value = var.storage_account_name
}

# Azure provider
provider "azurerm" {
  features {}
}

# Configure Terraform backend for Azure Storage
terraform {
  backend "azurerm" {
    resource_group_name   = "american-tf-1-lines-resources"
    storage_account_name   = "chirustorageaccount"
    container_name         = "chiru-test-storage-container"
    key                    = "terraform.tfstate"
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Create Subnet within the Virtual Network
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# Create a resource group
resource "azurerm_resource_group" "american_airlines" {
  name     = "american-tf-1-lines-resources"
  location = "East US"
}

# Create an App Service Plan
resource "azurerm_service_plan" "american_airlines" {
  name                = "american-airlines-app-serviceplan"
  location            = azurerm_resource_group.american_airlines.location
  resource_group_name = azurerm_resource_group.american_airlines.name

  os_type   = "Linux"
  sku_name  = "B1"
}

# Create an App Service
resource "azurerm_app_service" "american_airlines" {
  name                = var.app_service_name
  location            = azurerm_resource_group.american_airlines.location
  resource_group_name = azurerm_resource_group.american_airlines.name
  app_service_plan_id = azurerm_service_plan.american_airlines.id

  site_config {
    # Use conditional logic based on the specified runtime
    linux_fx_version = var.runtime == "JAVA|11" ? "JAVA|11" : "DOTNETCORE|3.1"
  }

  # Connect the App Service to the Subnet
  depends_on = [azurerm_subnet.subnet]

  # Associate with the Subnet in the Virtual Network
  app_settings = {
    WEBSITES_SUBNET_ID = azurerm_subnet.subnet.id
  }
}

# Output the resource group name
output "resource_group_name" {
  value = azurerm_resource_group.american_airlines.name
}

output "app_service_url" {
  value = azurerm_app_service.american_airlines.default_site_hostname
}
