# ==================== Variables

variable "nat_subnet_cidr" {}
variable "env_name" {}
variable "resource_group_name" {}
variable "network_name" {}
variable "location" {}

variable "nat_vm_size" {
  default = "Standard_DS1_v2"
}
variable "nat_instance_count" {
  default = 1
}

# ==================== Networking

resource "azurerm_network_security_group" "nat_security_group" {
  name                = "${var.env_name}-nat-security-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "AllowAnyOutBoundInnerSubnet"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_subnet" "nat_subnet" {
  name = "${var.env_name}-nat-subnet"

  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.nat_subnet_cidr}"
  network_security_group_id = "${azurerm_network_security_group.nat_security_group.id}"
}

resource "azurerm_subnet_network_security_group_association" "nat_subnet" {
  subnet_id                 = "${azurerm_subnet.nat_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.nat_security_group.id}"
}

resource "azurerm_public_ip" "nat_public_ip" {
  name                         = "nat-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  sku                          = "Standard"
}

resource "azurerm_network_interface" "nat_instance_nic" {
  name                      = "${var.env_name}-nat-instance-nic"
  depends_on                = ["azurerm_public_ip.nat_public_ip"]
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${azurerm_network_security_group.nat_security_group.id}"

  ip_configuration {
    name                          = "${var.env_name}-nat-instance-ip-config"
    subnet_id                     = "${azurerm_subnet.nat_subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.nat_subnet.address_prefix, 5)}"
    public_ip_address_id          = "${azurerm_public_ip.nat_public_ip.id}"
  }
}

resource "azurerm_route_table" "nat_table" {
  name                 = "${var.env_name}-nat-table"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
}

resource "azurerm_route" "nat_rule1" {
  name                   = "${var.env_name}-nat-rule1"
  resource_group_name    = "${var.resource_group_name}"
  route_table_name       = "${azurerm_route_table.nat_table.name}"
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "${azurerm_network_interface.nat_instance_nic.private_ip_address}"
}

# ==================== NAT Instance(s)

resource "azurerm_virtual_machine" "nat_instance_vm" {
  name                          = "${var.env_name}-nat-instance-vm"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  network_interface_ids         = ["${azurerm_network_interface.nat_instance_nic.id}"]
  vm_size                       = "${var.nat_vm_size}"
  delete_os_disk_on_termination = "true"
  #count                         = "${var.nat_instance_count}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "nat-instance-disk.vhd"
    caching           = "ReadWrite"
    os_type           = "linux"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    #computer_name  = "${var.env_name}-nat${count.index}"
    computer_name  = "${var.env_name}-nat1"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${tls_private_key.nat_instance.public_key_openssh}"
    }
  }
}

resource "tls_private_key" "nat_instance" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_virtual_machine_extension" "nat_instance" {
  name                 = "${var.env_name}-nat-instance-vm-ext"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_machine_name = "${azurerm_virtual_machine.nat_instance_vm.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "script": "cHY0LmlwX2ZvcndhcmQgPSAxCmNwIC9ldGMvc3lzY3RsLmNvbmYgL3RtcC9zeXNjdGwuY29uZgplY2hvICJuZXQuaXB2NC5pcF9mb3J3YXJkID0gMSIgPj4gL3RtcC9zeXNjdGwuY29uZgpzdWRvIGNwIC90bXAvc3lzY3RsLmNvbmYgL2V0Yy9zeXNjdGwuY29uZgoKIyBmaXJld2FsbGQKc3VkbyAvZXRjL2luaXQuZC9uZXR3b3JraW5nIHJlc3RhcnQKc3VkbyBhcHQtZ2V0IGluc3RhbGwgLXkgZmlyZXdhbGxkCnN1ZG8gc3lzdGVtY3RsIGVuYWJsZSBmaXJld2FsbGQKc3VkbyBzeXN0ZW1jdGwgc3RhcnQgZmlyZXdhbGxkCnN1ZG8gZmlyZXdhbGwtY21kIC0tc3RhdGUKc3VkbyBmaXJld2FsbC1jbWQgLS1zZXQtZGVmYXVsdC16b25lPWV4dGVybmFsCnN1ZG8gZmlyZXdhbGwtY21kIC0tcmVsb2FkCg=="
    }
    SETTINGS
}

# ==================== Outputs

output "public_ip" {
  value = "${azurerm_public_ip.nat_public_ip.ip_address}"
}

output "private_ip" {
  value = "${azurerm_network_interface.nat_instance_nic.private_ip_address}"
}

output "ssh_public_key" {
  sensitive = true
  value     = "${tls_private_key.nat_instance.public_key_openssh}"
}

output "ssh_private_key" {
  sensitive = true
  value     = "${tls_private_key.nat_instance.private_key_pem}"
}

output "subnet_id" {
  value = "${azurerm_subnet.nat_subnet.id}"
}

output "route_table_id" {
  value = "${azurerm_route_table.nat_table.id}"
}