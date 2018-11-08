provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  environment     = "${var.cloud_name}"
}

terraform {
  required_version = "< 0.12.0"
}

module "infra" {
  source = "../modules/infra"

  env_name                    = "${var.env_name}"
  env_short_name              = "${var.env_short_name}"
  location                    = "${var.location}"
  dns_subdomain               = "${var.dns_subdomain}"
  dns_suffix                  = "${var.dns_suffix}"
  infrastructure_subnet_name  = "${var.pcf_infrastructure_subnet_name}"

  virtual_network_resource_group_name = "${var.pcf_virtual_network_resource_group_name}"
  virtual_network_name                = "${var.pcf_virtual_network_name}"
}

module "ops_manager" {
  source = "../modules/ops_manager"

  env_name       = "${var.env_name}"
  env_short_name = "${var.env_short_name}"
  location       = "${var.location}"

  ops_manager_image_uri  = "${var.ops_manager_image_uri}"
  ops_manager_vm_size    = "${var.ops_manager_vm_size}"
  ops_manager_private_ip = "${var.ops_manager_private_ip}"

  optional_ops_manager_image_uri = "${var.optional_ops_manager_image_uri}"

  resource_group_name = "${module.infra.resource_group_name}"
  dns_zone_name       = "${module.infra.dns_zone_name}"
  security_group_id   = "${module.infra.security_group_id}"
  subnet_id           = "${module.infra.infrastructure_subnet_id}"
}

module "pas_network" {
  source = "../modules/pas_network"

  pas_subnet_name              = "${var.pcf_pas_subnet_name}"
  services_subnet_name         = "${var.pcf_services_subnet_name}"
  dynamic_services_subnet_name = "${var.pcf_dynamic_services_subnet_name}"

  virtual_network_resource_group_name  = "${var.pcf_virtual_network_resource_group_name}"
  virtual_network_name                 = "${module.infra.network_name}"
}

module "pas" {
  source = "../modules/pas"

  env_name       = "${var.env_name}"
  location       = "${var.location}"
  env_short_name = "${var.env_short_name}"

  pas_subnet              = "${module.pas_network.pas_subnet}"
  services_subnet         = "${module.pas_network.services_subnet}"
  dynamic_services_subnet = "${module.pas_network.dynamic_services_subnet}"

  cf_storage_account_name              = "${var.cf_storage_account_name}"
  cf_buildpacks_storage_container_name = "${var.cf_buildpacks_storage_container_name}"
  cf_droplets_storage_container_name   = "${var.cf_droplets_storage_container_name}"
  cf_packages_storage_container_name   = "${var.cf_packages_storage_container_name}"
  cf_resources_storage_container_name  = "${var.cf_resources_storage_container_name}"

  resource_group_name                 = "${module.infra.resource_group_name}"
  dns_zone_name                       = "${module.infra.dns_zone_name}"
  network_name                        = "${module.infra.network_name}"
  bosh_deployed_vms_security_group_id = "${module.infra.bosh_deployed_vms_security_group_id}"
}

module "certs" {
  source = "../modules/certs"

  env_name           = "${var.env_name}"
  dns_suffix         = "${var.dns_suffix}"
  ssl_ca_cert        = "${var.ssl_ca_cert}"
  ssl_ca_private_key = "${var.ssl_ca_private_key}"
}

module "isolation_segment" {
  source = "../modules/isolation_segment"

  count = "${var.isolation_segment ? 1 : 0}"

  environment = "${var.env_name}"
  location    = "${var.location}"

  ssl_cert           = "${var.iso_seg_ssl_cert}"
  ssl_private_key    = "${var.iso_seg_ssl_private_key}"
  ssl_ca_cert        = "${var.iso_seg_ssl_ca_cert}"
  ssl_ca_private_key = "${var.iso_seg_ssl_ca_private_key}"

  resource_group_name = "${module.infra.resource_group_name}"
  dns_zone            = "${module.infra.dns_zone_name}"
}
