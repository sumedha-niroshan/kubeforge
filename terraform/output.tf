output "node_ips" {
  description = "Map of node name to assigned IP address"
  value       = { for k, v in proxmox_virtual_environment_vm.k8s_node : k => v.initialization[0].ip_config[0].ipv4[0].address }
}

output "control_plane_ip" {
  description = "IP of the first control-plane node"
  value       = [for n in var.nodes : n.ip if n.role == "control_plane"][0]
}
