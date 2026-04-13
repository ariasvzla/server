output "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  value = [
    for vm in proxmox_vm_qemu.k8s_control_plane : {
      name = vm.name
      vmid = vm.vmid
      ip   = cidrhost(var.network_subnet, 20 + index(proxmox_vm_qemu.k8s_control_plane, vm))
    }
  ]
}

output "worker_node_ips" {
  description = "IP addresses of worker nodes"
  value = [
    for vm in proxmox_vm_qemu.k8s_worker : {
      name = vm.name
      vmid = vm.vmid
      ip   = cidrhost(var.network_subnet, 30 + var.control_plane_count + index(proxmox_vm_qemu.k8s_worker, vm))
    }
  ]
}

output "cluster_info" {
  description = "Kubernetes cluster information"
  value = {
    cluster_name           = var.cluster_name
    control_plane_count    = var.control_plane_count
    worker_node_count      = var.worker_node_count
    control_plane_resources = {
      memory = var.control_plane_memory
      cores  = var.control_plane_cores
      disk   = var.control_plane_disk_size
    }
    worker_resources = {
      memory = var.worker_memory
      cores  = var.worker_cores
      disk   = var.worker_disk_size
    }
    network = {
      subnet  = var.network_subnet
      gateway = var.gateway
      domain  = var.domain
    }
  }
}

output "next_steps" {
  description = "Next steps for Kubernetes setup"
  value = <<-EOT
    1. Wait for all VMs to boot and cloud-init to complete
    2. SSH into the first control plane node
    3. Initialize Kubernetes on the control plane:
       kubeadm init --control-plane-endpoint="${var.cluster_name}.${var.domain}:6443" --pod-network-cidr=10.244.0.0/16
    4. Join worker nodes to the cluster
    5. Install a CNI plugin (e.g., Flannel, Calico)
    
    Control plane nodes: ${join(", ", [for vm in proxmox_vm_qemu.k8s_control_plane : vm.name])}
    Worker nodes: ${join(", ", [for vm in proxmox_vm_qemu.k8s_worker : vm.name])}
  EOT
}
