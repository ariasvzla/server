# Proxmox Provider Configuration
variable "proxmox_api_url" {
  description = "Proxmox API endpoint URL (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (format: user@realm!token_name)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS certificate verification (not recommended for production)"
  type        = bool
  default     = true
}

variable "proxmox_debug" {
  description = "Enable Proxmox provider debug logging"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node name where VMs will be created"
  type        = string
}

variable "proxmox_resource_pool" {
  description = "Proxmox resource pool for VMs"
  type        = string
  default     = "Kubernetes"
}

# Kubernetes Cluster Configuration
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "k8s-cluster"
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
  validation {
    condition     = var.control_plane_count > 0 && var.control_plane_count <= 5
    error_message = "Control plane count must be between 1 and 5."
  }
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
  validation {
    condition     = var.worker_node_count >= 0
    error_message = "Worker node count must be >= 0."
  }
}

# VM Template Configuration
variable "vm_template_name" {
  description = "Name of the VM template to clone from (should have cloud-init configured)"
  type        = string
  default     = "ubuntu-22.04-template"
}

variable "base_vmid" {
  description = "Base VMID for generated VMs"
  type        = number
  default     = 100
}

# Control Plane VM Resources
variable "control_plane_memory" {
  description = "Memory in MB for control plane VMs"
  type        = number
  default     = 4096
}

variable "control_plane_cores" {
  description = "CPU cores for control plane VMs"
  type        = number
  default     = 4
}

variable "control_plane_disk_size" {
  description = "Disk size for control plane VMs (e.g., '50G')"
  type        = string
  default     = "50G"
}

# Worker Node VM Resources
variable "worker_memory" {
  description = "Memory in MB for worker nodes"
  type        = number
  default     = 4096
}

variable "worker_cores" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 4
}

variable "worker_disk_size" {
  description = "Disk size for worker nodes (e.g., '50G')"
  type        = string
  default     = "50G"
}

# Network Configuration
variable "network_bridge" {
  description = "Proxmox network bridge (e.g., 'vmbr0')"
  type        = string
  default     = "vmbr0"
}

variable "network_subnet" {
  description = "Network subnet in CIDR format (e.g., '192.168.1.0/24')"
  type        = string
  default     = "192.168.1.0/24"
}

variable "gateway" {
  description = "Default gateway IP address"
  type        = string
  default     = "192.168.1.1"
}

variable "nameservers" {
  description = "List of DNS nameservers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "domain" {
  description = "Domain name for the cluster"
  type        = string
  default     = "k8s.local"
}

# Storage Configuration
variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

# Cloud-init Configuration
variable "cloud_init_user" {
  description = "Default cloud-init user"
  type        = string
  default     = "ubuntu"
}

variable "cloud_init_password" {
  description = "Default cloud-init password (optional, SSH keys recommended)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_keys" {
  description = "SSH public keys for cloud-init"
  type        = list(string)
  default     = []
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for remote provisioning"
  type        = string
  default     = "~/.ssh/id_rsa"
}
