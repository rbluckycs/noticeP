resource "azurerm_resource_group" "rg" {
  name     = "rb-avd-demo"
  location = "Central India"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "rb-avd-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "rb-sessionhost-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_virtual_desktop_host_pool" "hp" {
  name                = "rb-avd-hostpool"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type               = "Pooled"
  load_balancer_type = "BreadthFirst"

  friendly_name      = "AVD Host Pool - Test"
  start_vm_on_connect = true
}

resource "azurerm_virtual_desktop_application_group" "dag" {
  name                = "rb-avd-desktop-group"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type         = "Desktop"
  host_pool_id = azurerm_virtual_desktop_host_pool.hp.id
}

resource "azurerm_virtual_desktop_workspace" "ws" {
  name                = "rb-avd-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  friendly_name = "AVD Workspace"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "assoc" {
  workspace_id         = azurerm_virtual_desktop_workspace.ws.id
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
}

resource "azurerm_network_interface" "nic" {
  name                = "rb-avd-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "rb-internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "rizwan-avd-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  size = "Standard_D2s_v5"

  admin_username = "azureadmin"
  admin_password = "Password1234!"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-25h2-avd"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "time_offset" "reg_expiry" {
  offset_hours = 24
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "reg" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hp.id
  expiration_date = time_offset.reg_expiry.rfc3339
}

resource "azurerm_virtual_machine_extension" "aadlogin" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.2"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "avd_dsc" {
  name                       = "Microsoft.PowerShell.DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.83"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip"
    configurationFunction  = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName = azurerm_virtual_desktop_host_pool.hp.name
    }
  })

  protected_settings = jsonencode({
    properties = {
      registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.reg.token
    }
  })

  depends_on = [azurerm_virtual_machine_extension.aadlogin]
}