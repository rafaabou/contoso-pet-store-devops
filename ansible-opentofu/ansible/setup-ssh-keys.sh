#!/bin/bash
# ============================================
# Setup SSH keys for Ansible (run once)
# Copies your SSH public key to all containers
# so Ansible can connect without passwords.
# ============================================
set -e

ANSIBLE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ANSIBLE_DIR"

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_ed25519 ]; then
  echo "Generating SSH key..."
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "ansible@pc1"
fi

echo "Removing stale host keys (containers were recreated)..."
# 10.195.94.220 removed (dead PC1 sonarqube, destroyed 2026-09-09); Tailscale
# IPs for all PC2 containers (bridge invisible from PC1). Fresh ubuntu images
# need openssh-server + direct key push first (root password locked) — see
# troubleshooting ERROR 87. PC2 controller has no keypair: scp PC1's
# id_ed25519.pub to PC2 first (ERROR 88).
for host in 10.195.94.80 10.195.94.81 10.195.94.200 10.195.94.210 100.100.13.113 100.73.135.124 100.88.159.38 100.113.54.77; do
  ssh-keygen -f ~/.ssh/known_hosts -R "$host" 2>/dev/null
done

echo "Copying SSH key to all containers..."
echo "You will be prompted for the root password once per container."
echo ""

for host in 10.195.94.80 10.195.94.81 10.195.94.200 10.195.94.210 100.100.13.113 100.73.135.124 100.88.159.38 100.113.54.77; do
  echo "--- $host ---"
  ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519.pub "root@$host" || echo "FAILED: $host (check if container is running and SSH is installed)"
done

echo ""
echo "Testing connectivity (no password should be needed)..."
ansible all -m ping -i inventory/hosts.ini
