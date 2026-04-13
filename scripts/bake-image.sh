#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <path-to-qcow2-image> [--output TEMPLATE_NAME]"
  exit 2
fi

IMAGE_PATH="$1"
TEMPLATE_NAME="debian-k8s-template"
if [ "${2-}" = "--output" ] && [ -n "${3-}" ]; then
  TEMPLATE_NAME="$3"
fi

if ! command -v virt-customize >/dev/null 2>&1; then
  echo "virt-customize not found. Install libguestfs-tools (apt install libguestfs-tools)."
  exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
  echo "Image not found: $IMAGE_PATH"
  exit 1
fi

echo "Baking image: $IMAGE_PATH -> template name: $TEMPLATE_NAME"

TMP_PROV=$(mktemp /tmp/packer-provision.XXXX.sh)
cat > "$TMP_PROV" <<'EOF'
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends cloud-init qemu-guest-agent openssh-server curl wget ca-certificates gnupg

# Install containerd
apt-get install -y software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install -y containerd.io

# Setup containerd default config
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml || true
systemctl enable containerd || true

# Install kubeadm, kubelet, kubectl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOT >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOT
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

chmod +x "$TMP_PROV"

virt-customize -a "$IMAGE_PATH" --upload "$TMP_PROV":/tmp/provision.sh --run /tmp/provision.sh

rm -f "$TMP_PROV"

echo "Image baked successfully. You can now upload $IMAGE_PATH to Proxmox and convert to a template named: $TEMPLATE_NAME"

exit 0
