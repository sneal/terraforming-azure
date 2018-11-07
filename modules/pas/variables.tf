variable "env_name" {}
variable "env_short_name" {}
variable "location" {}
variable "resource_group_name" {}
variable "dns_zone_name" {}

variable "cf_buildpacks_storage_container_name" {}
variable "cf_droplets_storage_container_name" {}
variable "cf_packages_storage_container_name" {}
variable "cf_resources_storage_container_name" {}
variable "cf_storage_account_name" {}

variable "network_name" {}
variable "pas_subnet" {
  type = "map"
  default = {
    "id"   = ""
    "name" = ""
    "cidr" = ""
  }
}
variable "services_subnet" {
  type = "map"
  default = {
    "id"   = ""
    "name" = ""
    "cidr" = ""
  }
}
variable "dynamic_services_subnet" {
  type = "map"
  default = {
    "id"   = ""
    "name" = ""
    "cidr" = ""
  }
}

variable "bosh_deployed_vms_security_group_id" {}
