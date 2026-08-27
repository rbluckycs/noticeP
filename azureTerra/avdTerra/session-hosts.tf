resource "azurerm_network_interface" "avd" {
  name                = "${var.prefix}-nic-0"
  location            = azurerm_resource_group.sh.location
  resource_group_name = azurerm_resource_group.sh.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "avd" {
  name                   = "${var.prefix}-vm-0"
  location               = azurerm_resource_group.sh.location
  resource_group_name    = azurerm_resource_group.sh.name
  size                   = var.vm_size
  admin_username         = var.admin_username
  admin_password         = var.admin_password
  network_interface_ids  = [azurerm_network_interface.avd.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-23h2-avd"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "aad_join" {
  name                        = "AADLoginForWindows"
  virtual_machine_id          = azurerm_windows_virtual_machine.avd.id
  publisher                   = "Microsoft.Azure.ActiveDirectory"
  type                        = "AADLoginForWindows"
  type_handler_version        = "2.0"
  auto_upgrade_minor_version  = true
}

resource "azurerm_virtual_machine_extension" "dsc" {
  name                        = "Microsoft.PowerShell.DSC"
  virtual_machine_id          = azurerm_windows_virtual_machine.avd.id
  publisher                   = "Microsoft.Powershell"
  type                        = "DSC"
  type_handler_version        = "2.83"
  auto_upgrade_minor_version  = true

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.421.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName = azurerm_virtual_desktop_host_pool.hostpool.name
    }
  })

  protected_settings = jsonencode({
    properties = {
      registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
    }
  })

  depends_on = [azurerm_virtual_machine_extension.aad_join]
}