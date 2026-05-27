#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -euo pipefail

echo "=========================================================="
echo "    Orbit-Cloud: Automated End-to-End Cluster Deploy"
echo "=========================================================="

# 1. Install Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "[*] Installing Ansible on the control VM..."
    sudo apt-get update
    sudo apt-get install -y ansible
else
    echo "[+] Ansible is already installed."
fi

# 2. Copy and secure SSH keys from shared Windows mount to bypass 777 permissions
echo "[*] Copying and securing Vagrant private keys..."
mkdir -p ~/.ssh/orbit_keys
chmod 700 ~/.ssh/orbit_keys

for node in orbit-control-01 orbit-control-02 orbit-control-03; do
    KEY_SRC="/vagrant/vagrant/.vagrant/machines/${node}/virtualbox/private_key"
    KEY_DEST="${HOME}/.ssh/orbit_keys/${node}_key"
    
    if [ -f "$KEY_SRC" ]; then
        cp "$KEY_SRC" "$KEY_DEST"
        chmod 600 "$KEY_DEST"
        echo "[+] Secured key for ${node}"
    else
        echo "[!] Warning: Vagrant key for ${node} not found at ${KEY_SRC}."
        echo "    If you are running on custom hardware/VMs, ensure SSH keys are set up manually."
    fi
done

# Define the common variables for local key authentication
ANSIBLE_EXTRA_VARS="ansible_ssh_private_key_file=~/.ssh/orbit_keys/{{ inventory_hostname }}_key"

# 3. Run Step 2: Base OS Bootstrapping
echo ""
echo "[*] RUNNING PHASE 1: Base OS Bootstrapping..."
ansible-playbook -i inventory.ini bootstrap.yml --extra-vars "$ANSIBLE_EXTRA_VARS"

# 4. Run Step 3: Highly Available Control Plane Installation (k3s)
echo ""
echo "[*] RUNNING PHASE 2: HA k3s Control Plane Deployment..."
ansible-playbook -i inventory.ini deploy-k3s.yml --extra-vars "$ANSIBLE_EXTRA_VARS"

# 5. Run Step 4 & 5: Networking, Load Balancers, Ingress, and Storage (MinIO)
echo ""
echo "[*] RUNNING PHASE 3: Core Services Deployment (Cilium, MetalLB, Ingress-Nginx, MinIO)..."
ansible-playbook -i inventory.ini deploy-services.yml --extra-vars "$ANSIBLE_EXTRA_VARS"

echo ""
echo "=========================================================="
echo "    [SUCCESS] Orbit-Cloud Deployment Completed!"
echo "=========================================================="
echo "To verify the cluster state, run:"
echo "    kubectl get nodes -o wide"
echo "    kubectl get pods -A"
echo "    kubectl get svc -n minio"
echo "=========================================================="
