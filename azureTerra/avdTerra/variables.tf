variable "resource_group_location" {
  default     = "centralus"
  description = "Location of the resource group."
}

variable "rg_name" {
  type        = string
  default     = "rg-avd-resources"
  description = "Name of the Resource group in which to deploy service objects"
}

variable "workspace" {
  type        = string
  description = "Name of the Azure Virtual Desktop workspace"
  default     = "AVD-TF-Workspace"
}

variable "hostpool" {
  type        = string
  description = "Name of the Azure Virtual Desktop host pool"
  default     = "AVD-TF-HP"
}


variable "prefix" {
  type        = string
  default     = "avdtf"
  description = "Prefix of the name of the AVD machine(s)"
}

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v7"
}

variable "admin_username" {
  type    = string
  default = "avdadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}