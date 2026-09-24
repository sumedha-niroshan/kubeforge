terraform {
    required_version = ">=1.6.0"

  required_providers {
    proxmox = {
      source  = "Terraform-for-Proxmox/proxmox"
      version = ">=0.0.1"
    }

    local = {
        source = "hashicorp/local"
        version = ">=2.9.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint_url
  api_token = var.proxmox_api_token
}
