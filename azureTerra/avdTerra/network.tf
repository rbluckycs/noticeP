resource "azurerm_virtual_network" "avd" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.sh.location
  resource_group_name = azurerm_resource_group.sh.name
}

resource "azurerm_subnet" "avd" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.sh.name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = ["10.20.1.0/24"]
}