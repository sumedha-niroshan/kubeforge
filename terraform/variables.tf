
variable "proxmox_api_url" {
  description = "Proxmox API endpoint, e.g. https://192.168.1.10:8006/api2/json"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token, format user@realm!tokenid=uuid"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (true for self-signed certs)"
  type        = bool
  default     = true
}

variable "proxmox_ssh_user" {
  description = "SSH user Terraform uses to talk to the Proxmox host itself (for file uploads)"
  type        = string
  default     = "root"
}

variable "proxmox_node" {
  description = "Name of the Proxmox node (as shown in the UI) to deploy VMs on"
  type        = string
}

variable "template_vmid" {
  description = "VMID of the cloud-init-ready VM template to clone (see README prerequisites)"
  type        = number
}

variable "storage_pool" {
  description = "Proxmox storage pool for VM disks, e.g. local-lvm"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Proxmox network bridge, e.g. vmbr0"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Gateway IP for the VM network"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers for the VMs"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "ssh_user" {
  description = "Non-root user created via cloud-init on every VM (Ansible connects as this user)"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "Public SSH key injected into every VM via cloud-init"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the matching private key, written into the generated Ansible inventory"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "nodes" {
  description = "List of cluster nodes to create"
  type = list(object({
    name      = string
    vmid      = number
    role      = string # "control_plane" or "worker"
    ip        = string
    cores     = number
    memory    = number
    disk_size = number
  }))
}
