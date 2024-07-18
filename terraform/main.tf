provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_image" {
  name   = "ubuntu-18.04-minimal-cloudimg-amd64"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_network" "k8s_network" {
  name      = "k8s_network"
  mode      = "nat"
  addresses = ["192.168.122.0/24"]
}

resource "libvirt_domain" "k8s_node" {
  count  = 3
  name   = "k8s-node-${count.index + 1}"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.common.id

  network_interface {
    network_name = libvirt_network.k8s_network.name
    hostname     = "k8s-node-${count.index + 1}"
  }

  disk {
    volume_id = libvirt_volume.ubuntu_image.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }
}

resource "libvirt_cloudinit_disk" "common" {
  name      = "common-init.iso"
  user_data = data.template_file.user_data.rendered
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

output "k8s_node_ips" {
  value = {
    for i in libvirt_domain.k8s_node : i.name => i.network_interface[0].addresses[0]
  }
}
