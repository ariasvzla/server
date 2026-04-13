# Kubernetes Control Plane on Proxmox - Terraform Configuration

This Terraform configuration deploys a Kubernetes cluster on Proxmox with customizable control plane and worker nodes.

## Prerequisites

1. **Terraform** >= 1.0 installed
2. **Proxmox** server with API access enabled
3. **VM Template** - A Proxmox VM template with:
   - Ubuntu 22.04 LTS (or compatible Linux)
   - Cloud-init pre-configured
   - SSH enabled
4. **Proxmox API Token** with appropriate permissions
5. **SSH Key Pair** for authentication to VMs

## Setup Instructions

### 1. Create Proxmox API Token

On your Proxmox server:
```bash
# Create API token for Terraform
pveum user add terraform@pve
pveum acl modify / -user terraform@pve -role Administrator  # or more restrictive role
pveum user token add terraform@pve terraform
```

Save the token ID and secret.

### 2. Prepare VM Template

Ensure you have a VM template in Proxmox with:
- Cloud-init installed: `apt-get install cloud-init`
- SSH Server enabled and in allowed interfaces
- Guest Agent installed: `apt-get install qemu-guest-agent`

### 3. Configure Variables

Copy the example configuration and customize for your environment:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
- Proxmox API credentials
- VM template name
- Network configuration
- Resource specifications
- SSH public key

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure it matches your requirements.

### 6. Apply Configuration

```bash
terraform apply tfplan
```

Wait for all VMs to be created and cloud-init to complete.

## Post-Deployment

### 1. Verify VM Creation

```bash
terraform output cluster_info
```

### 2. Connect to Control Plane Node

```bash
ssh ubuntu@<control-plane-ip>
```

### 3. Initialize Kubernetes

On the first control plane node:

```bash
# Install kubeadm, kubelet, kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubeadm kubelet kubectl

# Initialize control plane
sudo kubeadm init --control-plane-endpoint="k8s-prod.k8s.local:6443" \
  --pod-network-cidr=10.244.0.0/16 \
  --upload-certs

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 4. Install CNI Plugin

```bash
# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### 5. Join Worker Nodes

On each worker node:

```bash
# Use the join command from kubeadm init output
sudo kubeadm join k8s-prod.k8s.local:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

## Configuration Options

### Control Plane Resources
- `control_plane_count`: Number of control plane replicas (1-5 recommended)
- `control_plane_memory`: RAM in MB (minimum 2GB)
- `control_plane_cores`: CPU cores (minimum 2)
- `control_plane_disk_size`: Disk size (minimum 30GB)

### Worker Node Resources
- `worker_node_count`: Number of worker nodes
- `worker_memory`: RAM in MB
- `worker_cores`: CPU cores
- `worker_disk_size`: Disk size

### Network
- `network_subnet`: Cluster subnet (CIDR format)
- `gateway`: Default gateway
- `nameservers`: DNS servers
- `domain`: Internal domain name

## Destroy Infrastructure

To remove all created resources:

```bash
terraform destroy
```

## Troubleshooting

### Cloud-init Not Completing
Check cloud-init status on VM:
```bash
sudo cloud-init status --long
sudo tail -f /var/log/cloud-init-output.log
```

### SSH Connection Issues
- Verify SSH key in terraform.tfvars
- Check firewall rules between your host and VMs
- Verify VMs booted and received IP addresses

### Proxmox API Errors
- Verify API token credentials
- Check Proxmox API URL format
- Ensure template VM exists with correct name
- Verify node name matches

## Security Considerations

⚠️ **Production Recommendations:**
1. Use restricted Proxmox API roles instead of Administrator
2. Store API tokens securely (consider using Terraform Cloud or separate secret management)
3. Use SSH keys instead of passwords
4. Enable TLS certificate verification (`proxmox_tls_insecure = false`)
5. Use a proper ingress controller for external access
6. Implement RBAC in Kubernetes
7. Consider using a load balancer for control plane API access

## Files

- `main.tf` - VM resource definitions
- `provider.tf` - Proxmox provider configuration
- `variables.tf` - Input variables with defaults
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example variables (copy to terraform.tfvars)

## References

- [Proxmox Terraform Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubeadm Installation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
