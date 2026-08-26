terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

provider "azurerm" {

}

resource "azurerm_resource_group" "app-grp-RB"{
  name = "app-grp"
  location = "East US"
}