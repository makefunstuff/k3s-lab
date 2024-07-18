provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "plan9_image" {
  name   = "plan9-image"
  pool   = "default"
  source = "/path/to/plan9.iso"
  format = "raw"
}

resource "libvirt_network" "plan9_network" {
  name = "plan9-network"
  mode = "nat"
  addresses = ["192.168.123.0/24"]
}

resource "libvirt_domain" "plan9_node" {
  count  = 3
  name   = "plan9-node-${count.index + 1}"
  memory = "512"
  vcpu   = 1

  network_interface {
    network_name = libvirt_network.plan9_network.name
  }

  disk {
    volume_id = libvirt_volume.plan9_image.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    listen_address = "127.0.0.1"
  }

  # Cloud-init is not applicable for Plan 9; manual configuration will be required
}

output "plan9_node_ips" {
  value = {
    for i in libvirt_domain.plan9_node: i.name => i.network_interface[0].addresses[0]
  }
}

