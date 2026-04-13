# Optional: Advanced configurations and helpers

# Locals for common values
locals {
  k8s_version = "1.29"
  labels = {
    environment = var.cluster_name
    terraform   = "true"
    purpose     = "kubernetes"
  }
}

# Data source to get template information (optional validation)
data "proxmox_vm_qemu" "template" {
  vmid = 0
  name = var.vm_template_name
}

# Local file to save kubeadm join command after initialization
resource "local_file" "kubeadm_join_script" {
  filename = "${path.module}/kubeadm-join.sh"
  content = templatefile("${path.module}/templates/kubeadm-join.tpl", {
    control_plane_ip = cidrhost(var.network_subnet, 20)
    domain           = var.domain
  })
  file_permission = "0755"
}

# Optional: Generate inventory file for Ansible
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.yaml"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    control_planes = [
      for i, vm in proxmox_vm_qemu.k8s_control_plane : {
        name = vm.name
        ip   = cidrhost(var.network_subnet, 20 + i)
      }
    ]
    workers = [
      for i, vm in proxmox_vm_qemu.k8s_worker : {
        name = vm.name
        ip   = cidrhost(var.network_subnet, 30 + var.control_plane_count + i)
      }
    ]
    ansible_user = var.cloud_init_user
  })
  file_permission = "0644"
}

# State outputs for reference
output "terraform_state_info" {
  description = "Information about deployed resources"
  value = {
    total_vms         = var.control_plane_count + var.worker_node_count
    control_plane_vms = [for vm in proxmox_vm_qemu.k8s_control_plane : vm.name]
    worker_vms        = [for vm in proxmox_vm_qemu.k8s_worker : vm.name]
    proxmox_node      = var.proxmox_node
  }
  sensitive = false
}
