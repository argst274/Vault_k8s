#Setup needed variables
variable "auth_url" {}
variable "k8s_POC_key" {}
variable "k8s_POC_key_path" {}
variable "jump_box_fixed_ip" {}
variable "anisble_POC_key" {}
variable "anisble_POC_key_path" {}
variable "public_ip_address" {}
variable "ssh_port" {}
variable "dmz_network_id" {}
variable "dmz_subnet_id" {}
variable "dmz_fixed_ip" {}

#Authentication  
provider "openstack" {
  auth_url = "${var.auth_url}"
}

#Keypair
resource "openstack_compute_keypair_v2" "k8s_POC_key" {
  name       = "k8s_POC_key"
  public_key = "${var.k8s_POC_key}"
}

resource "openstack_compute_keypair_v2" "k8s_POC_anisble_key" {
  name       = "k8s_POC_anisble_key"
  public_key = "${var.anisble_POC_key}"
}

#Set script location
data "template_file" "jbcloudinit" {
  template = "${file("jbcloudinit.sh")}"
}

data "template_file" "cloudinit" {
  template = "${file("cloudinit.sh")}"
}

#Security Groups
#default security group
resource "openstack_networking_secgroup_v2" "k8s_POC_secgrp" {
  name        = "k8s_POC_secgrp"
  description = "k8s POC Security Group"
}

resource "openstack_networking_secgroup_rule_v2" "ssh-from-jumpbox" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "172.16.0.207/32"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "ssh-from-group" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp-from-firewall" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "172.16.0.2/32"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp-from-jumpbox" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "172.16.0.207/32"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "icmp-from-group" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
}


resource "openstack_networking_secgroup_rule_v2" "ipip-from-group" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "4"
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "BGP-from-group" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "etcd" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_master_secgrp.id}"
}

#Master nodes Security Group
resource "openstack_networking_secgroup_v2" "k8s_master_secgrp" {
  name        = "k8s_master_secgrp"
  description = "k8s master nodes Security Group"
}

# resource "openstack_networking_secgroup_rule_v2" "api_server" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 8080
#   port_range_max    = 8080
#   remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
#   security_group_id = "${openstack_networking_secgroup_v2.k8s_master_secgrp.id}"
# }

resource "openstack_networking_secgroup_rule_v2" "api_server_tls" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_master_secgrp.id}"
}

resource "openstack_networking_secgroup_rule_v2" "kublet_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10252
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_master_secgrp.id}"
}

# resource "openstack_networking_secgroup_rule_v2" "kublet_api_RO" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 10255
#   port_range_max    = 10255
#   remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
#   security_group_id = "${openstack_networking_secgroup_v2.k8s_master_secgrp.id}"
# }

#Worker nodes Security Group
resource "openstack_networking_secgroup_v2" "k8s_worker_secgrp" {
  name        = "k8s_worker_secgrp"
  description = "k8s worker nodes Security Group"
}

resource "openstack_networking_secgroup_rule_v2" "kublet_api_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_worker_secgrp.id}"
}

# resource "openstack_networking_secgroup_rule_v2" "kublet_api_worker_RO" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 10255
#   port_range_max    = 10255
#   remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
#   security_group_id = "${openstack_networking_secgroup_v2.k8s_worker_secgrp.id}"
# }

resource "openstack_networking_secgroup_rule_v2" "NodePort" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_group_id   = "${openstack_networking_secgroup_v2.k8s_POC_secgrp.id}"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_worker_secgrp.id}"
}

#Jump box Security Group
resource "openstack_networking_secgroup_v2" "k8s_jump_secgrp" {
  name        = "k8s_jump_secgrp"
  description = "k8s jump Security Group"
}

resource "openstack_networking_secgroup_rule_v2" "ssh-from-world" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_jump_secgrp.id}"
}

#Network, subnet and router
resource "openstack_networking_network_v2" "k8s_POC_network" {
  name           = "k8s_POC_network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "k8s_POC_subnet" {
  name            = "k8s_POC_subnet"
  network_id      = "${openstack_networking_network_v2.k8s_POC_network.id}"
  cidr            = "192.168.207.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_networking_router_v2" "k8s_POC_router" {
  name = "k8s_POC_router"
}

resource "openstack_networking_port_v2" "k8s_dev_port1" {
  network_id = "${var.dmz_network_id}" 

  fixed_ip {
    subnet_id  = "${var.dmz_subnet_id}" 
    ip_address = "${var.dmz_fixed_ip}"                       
  }

  admin_state_up = "true"
}

resource "openstack_networking_router_interface_v2" "k8s_port1" {
  router_id = "${openstack_networking_router_v2.k8s_POC_router.id}"
  port_id   = "${openstack_networking_port_v2.k8s_dev_port1.id}"
}

resource "openstack_networking_router_interface_v2" "k8s_subnet_port1" {
  router_id = "${openstack_networking_router_v2.k8s_POC_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.k8s_POC_subnet.id}"
}

resource "openstack_networking_router_route_v2" "k8s_POC_route_1" {
  router_id        = "${openstack_networking_router_v2.k8s_POC_router.id}"
  destination_cidr = "0.0.0.0/0"
  next_hop         = "172.16.0.2"
  depends_on       = ["openstack_networking_router_interface_v2.k8s_port1"]
}

#Compute

#master-nodes 
resource "openstack_compute_instance_v2" "k8s-master-node" {
  name            = "k8s-master-node-${count.index + 1}"
  image_name      = "Ubuntu 16.04"
  flavor_name     = "2C8R32D"
  key_pair        = "k8s_POC_anisble_key"
  security_groups = ["${openstack_networking_secgroup_v2.k8s_POC_secgrp.name}", "${openstack_networking_secgroup_v2.k8s_master_secgrp.name}"]
  depends_on      = ["openstack_networking_subnet_v2.k8s_POC_subnet"]
  count           = 2

  network {
    name        = "k8s_POC_network"
    fixed_ip_v4 = "192.168.207.2${count.index + 1}"
  }

  lifecycle {
    ignore_changes = ["image_name"]
  }

  user_data = "${data.template_file.cloudinit.rendered}"
}

#worker-nodes 1-3
resource "openstack_compute_instance_v2" "k8s-worker-node" {
  name            = "k8s-worker-node-${count.index + 1}"
  image_name      = "Ubuntu 16.04"
  flavor_name     = "2C8R32D"
  key_pair        = "k8s_POC_anisble_key"
  security_groups = ["${openstack_networking_secgroup_v2.k8s_POC_secgrp.name}", "${openstack_networking_secgroup_v2.k8s_worker_secgrp.name}"]
  depends_on      = ["openstack_networking_subnet_v2.k8s_POC_subnet"]
  count           = 3

  network {
    name        = "k8s_POC_network"
    fixed_ip_v4 = "192.168.207.3${count.index + 1}"
  }

  lifecycle {
    ignore_changes = ["image_name"]
  }

  user_data = "${data.template_file.cloudinit.rendered}"
}

#k8s-jump
resource "openstack_compute_instance_v2" "k8s-jump" {
  name            = "k8s-jump"
  image_name      = "Ubuntu 16.04"
  flavor_name     = "1C4R16D"
  key_pair        = "k8s_POC_key"
  security_groups = ["${openstack_networking_secgroup_v2.k8s_jump_secgrp.name}"]
  depends_on      = ["openstack_compute_instance_v2.k8s-master-node"]

  network {
    uuid        = "${var.dmz_network_id}"
    fixed_ip_v4 = "${var.jump_box_fixed_ip}"
  }

  lifecycle {
    ignore_changes = ["image_name"]
  }

  #copy the anisble key onto the jumpbox

  provisioner "file" {
    source      = "${var.anisble_POC_key_path}"
    destination = "~/.ssh/anisble_POC_key"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = "${var.public_ip_address}"
      port        = "${var.ssh_port}"
      private_key = "${file("${var.k8s_POC_key_path}")}"
    }
  }
  provisioner "file" {
    source      = "./hosts.ini"
    destination = "~/hosts.ini"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = "${var.public_ip_address}"
      port        = "${var.ssh_port}"
      private_key = "${file("${var.k8s_POC_key_path}")}"
    }
  }
  user_data = "${data.template_file.jbcloudinit.rendered}"
}
