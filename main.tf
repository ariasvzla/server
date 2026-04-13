# Kubernetes Control Plane Deployment on Proxmox

resource "proxmox_vm_qemu" "k8s_control_plane" {
  count       = var.control_plane_count
  name        = "${var.cluster_name}-cp-${count.index + 1}"
  vmid        = var.base_vmid + count.index
  target_node = var.proxmox_node

  # VM Specifications
  machine       = "pc"
  memory        = var.control_plane_memory
  cores         = var.control_plane_cores
  sockets       = 1
  cpu           = "host"
  onboot        = true
  startup       = "order=1,up=5"

  # Network Configuration
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  # Storage Configuration
  disk {
    type     = "scsi"
    storage  = var.storage_pool
    size     = var.control_plane_disk_size
    discard  = true
  }

  # Boot from clone
  clone = var.vm_template_name

  # Cloud-init Configuration
  ciuser            = var.cloud_init_user
  cipassword        = var.cloud_init_password
  sshkeys           = var.ssh_public_keys
  ipconfig0         = "ip=${cidrhost(var.network_subnet, 20 + count.index)}/24,gw=${var.gateway}"
  nameserver        = var.nameservers
  searchdomain      = var.domain

  # Resource pool
  pool = var.proxmox_resource_pool

  # Cloudinit script for Kubernetes installation
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update",
      "sudo apt-get install -y curl wget"
    ]

    connection {
      type        = "ssh"
      user        = var.cloud_init_user
      private_key = file(var.ssh_private_key_path)
      host        = cidrhost(var.network_subnet, 20 + count.index)
      timeout     = "5m"
    }
  }

  # Wait for cloud-init to complete
  depends_on = [proxmox_vm_qemu.k8s_control_plane]

  lifecycle {
    ignore_changes = [
      ciuser,
      cipassword,
      sshkeys,
      ipconfig0,
      nameserver,
      searchdomain
    ]
  }

  tags = "kubernetes,control-plane"
}

# Optional: Worker Nodes Configuration
resource "proxmox_vm_qemu" "k8s_worker" {
  count       = var.worker_node_count
  name        = "${var.cluster_name}-worker-${count.index + 1}"
  vmid        = var.base_vmid + var.control_plane_count + count.index
  target_node = var.proxmox_node

  # VM Specifications
  machine    = "pc"
  memory     = var.worker_memory
  cores      = var.worker_cores
  sockets    = 1
  cpu        = "host"
  onboot     = true
  startup    = "order=2,up=10"

  # Network Configuration
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  # Storage Configuration
  disk {
    type     = "scsi"
    storage  = var.storage_pool
    size     = var.worker_disk_size
    discard  = true
  }

  # Boot from clone
  clone = var.vm_template_name

  # Cloud-init Configuration
  ciuser     = var.cloud_init_user
  cipassword = var.cloud_init_password
  sshkeys    = var.ssh_public_keys
  ipconfig0  = "ip=${cidrhost(var.network_subnet, 30 + var.control_plane_count + count.index)}/24,gw=${var.gateway}"
  nameserver = var.nameservers
  searchdomain = var.domain

  # Resource pool
  pool = var.proxmox_resource_pool

  tags = "kubernetes,worker-node"
}
