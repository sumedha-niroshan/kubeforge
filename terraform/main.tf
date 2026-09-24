# Uploads a small cloud-init "extra config" snippet (packages + qemu-guest-agent).
# The base user/network/SSH-key config is handled natively by the proxmox
# provider's `initialization` block below, per node.
resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data      = file("${path.module}/files/user-data.yaml")
    file_name = "k8s-cloud-init-user-data.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "k8s_node" {
  for_each = { for node in var.nodes : node.name => node }

  name      = each.value.name
  node_name = var.proxmox_node
  vm_id     = each.value.vmid

  clone {
    vm_id = var.template_vmid
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  network_device {
    bridge = var.network_bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    vendor_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.network_gateway
      }
    }

    user_account {
      username = var.ssh_user
      keys     = [var.ssh_public_key]
    }

    dns {
      servers = var.dns_servers
    }
  }
}

# Auto-generates the Ansible inventory from the same node list, so Terraform
# and Ansible always agree on IPs/roles.
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    control_plane_nodes  = [for n in var.nodes : n if n.role == "control_plane"]
    worker_nodes         = [for n in var.nodes : n if n.role == "worker"]
    ssh_user             = var.ssh_user
    ssh_private_key_path = var.ssh_private_key_path
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"

  depends_on = [proxmox_virtual_environment_vm.k8s_node]
}
