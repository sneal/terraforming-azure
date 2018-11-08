variable "virtual_network_resource_group_name" {}
variable "virtual_network_name" {}

variable "pas_subnet_name" {
  default = ""
}

variable "services_subnet_name" {
  default = ""
}

variable "dynamic_services_subnet_name" {
  default = ""
}

# ================================= Subnets ====================================

data "azurerm_subnet" "pas_subnet" {
  name                 = "${var.pas_subnet_name}"
  resource_group_name  = "${var.virtual_network_resource_group_name}"
  virtual_network_name = "${var.virtual_network_name}"
}

data "azurerm_subnet" "services_subnet" {
  name                 = "${var.services_subnet_name}"
  resource_group_name  = "${var.virtual_network_resource_group_name}"
  virtual_network_name = "${var.virtual_network_name}"
}

data "azurerm_subnet" "dynamic_services_subnet" {
  name                 = "${var.dynamic_services_subnet_name}"
  resource_group_name  = "${var.virtual_network_resource_group_name}"
  virtual_network_name = "${var.virtual_network_name}"
}

# ================================= Outputs ====================================

output "pas_subnet" {
  value = {
    "id"   = "${data.azurerm_subnet.pas_subnet.id}"
    "name" = "${data.azurerm_subnet.pas_subnet.name}"
    "cidr" = "${data.azurerm_subnet.pas_subnet.address_prefix}"
  }
}

output "services_subnet" {
  value = {
    "id"   = "${data.azurerm_subnet.services_subnet.id}"
    "name" = "${data.azurerm_subnet.services_subnet.name}"
    "cidr" = "${data.azurerm_subnet.services_subnet.address_prefix}"
  }
}

output "dynamic_services_subnet" {
  value = {
    "id"   = "${data.azurerm_subnet.dynamic_services_subnet.id}"
    "name" = "${data.azurerm_subnet.dynamic_services_subnet.name}"
    "cidr" = "${data.azurerm_subnet.dynamic_services_subnet.address_prefix}"
  }
}
