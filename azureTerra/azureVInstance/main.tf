terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "0ba41c03-9b40-4e5d-83e3-d12b07feafc6"
}

resource "azurerm_resource_group" "app-grp-RB"{
  name = "app-grp123"
  location = "East US"
}