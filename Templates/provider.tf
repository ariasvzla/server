terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token    = var.proxmox_api_token
  pm_tls_insecure = var.proxmox_tls_insecure
  pm_debug        = var.proxmox_debug
  pm_timeout      = 600
}
