variable "env_name" {}
variable "resource_group_name" {}
variable "network_name" {}

variable "bosh_deployed_vms_security_group_id" {
  default = ""
}

variable "pas_subnet_cidr" {
  default = ""
}

variable "services_subnet_cidr" {
  default = ""
}

variable "dynamic_services_subnet_cidr" {
  default = ""
}

locals {
  pas_subnet_name              = "${var.env_name}-pas-subnet"
  services_subnet_name         = "${var.env_name}-services-subnet"
  dynamic_services_subnet_name = "${var.env_name}-dynamic-services-subnet"
}

# ================================= Subnets ====================================

resource "azurerm_subnet" "pas_subnet" {
  name = "${local.pas_subnet_name}"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.pas_subnet_cidr}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet" "services_subnet" {
  name = "${local.services_subnet_name}"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.services_subnet_cidr}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet" "dynamic_services_subnet" {
  name = "${local.dynamic_services_subnet_name}"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.dynamic_services_subnet_cidr}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

# ================================= Outputs ====================================

output "pas_subnet" {
  value = {
    "id"   = "${azurerm_subnet.pas_subnet.id}"
    "name" = "${azurerm_subnet.pas_subnet.name}"
    "cidr" = "${azurerm_subnet.pas_subnet.address_prefix}"
  }
}

output "services_subnet" {
  value = {
    "id"   = "${azurerm_subnet.services_subnet.id}"
    "name" = "${azurerm_subnet.services_subnet.name}"
    "cidr" = "${azurerm_subnet.services_subnet.address_prefix}"
  }
}

output "dynamic_services_subnet" {
  value = {
    "id"   = "${azurerm_subnet.dynamic_services_subnet.id}"
    "name" = "${azurerm_subnet.dynamic_services_subnet.name}"
    "cidr" = "${azurerm_subnet.dynamic_services_subnet.address_prefix}"
  }
}
