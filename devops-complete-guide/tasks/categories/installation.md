# Installation Tasks

> Setup: 5 VMs on Incus containers connected via Tailscale, K3s cluster + Vault + Monitoring servers
> Cluster: k3s-master (10.195.94.80), k3s-worker-1 (10.195.94.81), k3s-worker-2 (100.100.13.113)
> Dedicated: vault (10.195.94.200), monitoring (10.195.94.210)
> MetalLB Pool: 10.195.94.100-150

---

## Phase 1: Connectivity — Tailscale VPN

- [x] INST-001: Install Tailscale on PC1 (antix)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 5min | **Tags:** `tailscale` `vpn` `connectivity`
  - **Steps:** `curl -fsSL https://tailscale.com/install.sh | sh`, `sudo tailscale up`, login with GitHub/Google account
  - **Verification:** `tailscale status` shows PC1 with 100.x.x.x IP
  - **Rollback:** `sudo tailscale down`, `sudo apt remove tailscale`

- [x] INST-002: Install Tailscale on PC2 (i3 desktop)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 5min | **Tags:** `tailscale` `vpn` `connectivity`
  - **Steps:** Same as INST-001 on PC2, login with SAME account
  - **Verification:** `tailscale status` shows both PCs
  - **Rollback:** Same as INST-001

- [x] INST-003: Verify Tailscale connectivity PC1 → PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `tailscale` `ping` `verification`
  - **Steps:** `tailscale status`, `ping 100.x.x.2`
  - **Verification:** 0% packet loss
  - **Rollback:** N/A

- [x] INST-004: Verify Tailscale connectivity PC2 → PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `tailscale` `ping` `verification`
  - **Steps:** `ping 100.x.x.1` from PC2
  - **Verification:** 0% packet loss
  - **Rollback:** N/A

- [x] INST-005: Set Tailscale hostnames
  - **Priority:** P1 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `tailscale` `hostname`
  - **Steps:** `sudo tailscale set --hostname=antix` on PC1, `sudo tailscale set --hostname=pc2` on PC2
  - **Verification:** `tailscale status` shows correct hostnames
  - **Rollback:** `sudo tailscale set --hostname=` (empty)

- [x] INST-006: Advertise Incus subnet routes on PC1
  - **Priority:** P1 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `tailscale` `routes` `incus`
  - **Steps:** `sudo tailscale set --advertise-routes=10.195.94.0/24`, approve in admin console
  - **Verification:** Routes visible in `tailscale status`
  - **Rollback:** `sudo tailscale set --advertise-routes=`

- [x] INST-007: Advertise Incus subnet routes on PC2
  - **Priority:** P1 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `tailscale` `routes` `incus`
  - **Steps:** Same as INST-006 on PC2
  - **Verification:** Routes visible in `tailscale status`
  - **Rollback:** Same as INST-006

- [x] INST-008: Disable key expiry for servers
  - **Priority:** P2 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `tailscale` `security` `keys`
  - **Steps:** `sudo tailscale set --key-expires=false` on both PCs
  - **Verification:** `tailscale status` shows no expiry
  - **Rollback:** `sudo tailscale set --key-expires=true`

---

## Phase 2: SSH Setup

- [x] INST-009: Install openssh-server on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 3min | **Tags:** `ssh` `server` `pc2`
  - **Steps:** `sudo apt update && sudo apt install openssh-server -y`, `sudo systemctl enable --now ssh`
  - **Verification:** `sudo systemctl status ssh` shows active
  - **Rollback:** `sudo systemctl disable --now ssh`, `sudo apt remove openssh-server`

- [x] INST-010: Set password for antix user on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ssh` `password` `pc2`
  - **Steps:** `sudo passwd antix` (type new password)
  - **Verification:** Can login with password
  - **Rollback:** N/A

- [x] INST-011: Generate SSH key on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ssh` `key` `pc1`
  - **Steps:** `ssh-keygen -t ed25519` (press Enter for defaults)
  - **Verification:** `ls ~/.ssh/id_ed25519` exists
  - **Rollback:** `rm ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub`

- [x] INST-012: Copy SSH key to PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ssh` `key` `copy`
  - **Steps:** `ssh-copy-id antix@100.x.x.2` (enter PC2 password)
  - **Verification:** `ssh antix@100.x.x.2 "hostname"` works without password
  - **Rollback:** `ssh antix@100.x.x.2 "rm ~/.ssh/authorized_keys"`

- [x] INST-013: Test SSH PC1 → PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ssh` `test` `verification`
  - **Steps:** `ssh antix@100.x.x.2 "hostname && whoami"`
  - **Verification:** Returns "pc2" and "antix"
  - **Rollback:** N/A

- [x] INST-014: Enable NOPASSWD sudo on PC2 (optional)
  - **Priority:** P2 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ssh` `sudo` `pc2`
  - **Steps:** `echo "antix ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/antix`
  - **Verification:** `ssh antix@100.x.x.2 "sudo apt update"` works without password
  - **Rollback:** `sudo rm /etc/sudoers.d/antix`

- [x] INST-015: Test SSH PC2 → PC1
  - **Priority:** P1 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ssh` `test` `verification`
  - **Steps:** `ssh antix@100.x.x.1 "hostname"` from PC2
  - **Verification:** Returns "antix"
  - **Rollback:** N/A

---

## Phase 3: Incus Setup — PC2

- [x] INST-016: Add Zabbly repository on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `incus` `repository` `pc2`
  - **Steps:** `sudo mkdir -p /etc/apt/keyrings`, `sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc`, add source file
  - **Verification:** `ls /etc/apt/sources.list.d/zabbly-incus-stable.sources`
  - **Rollback:** `sudo rm /etc/apt/sources.list.d/zabbly-incus-stable.sources`

- [x] INST-017: Install Incus on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 3min | **Tags:** `incus` `install` `pc2`
  - **Steps:** `sudo apt update && sudo apt install incus incus-ui-canonical -y`
  - **Verification:** `incus version` shows version
  - **Rollback:** `sudo apt remove incus incus-ui-canonical`

- [x] INST-018: Add user to incus-admin group on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `incus` `permissions` `pc2`
  - **Steps:** `sudo usermod -aG incus-admin $USER`, `newgrp incus-admin`
  - **Verification:** `groups` shows incus-admin
  - **Rollback:** `sudo gpasswd -d $USER incus-admin`

- [x] INST-019: Initialize Incus on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 5min | **Tags:** `incus` `init` `pc2`
  - **Steps:** `sudo incus admin init`, answer: no clustering, yes storage (devops/dir), yes bridge (incusbr0/10.195.94.1/24), no network access, yes auto-update
  - **Verification:** `incus network list` shows incusbr0, `incus storage list` shows devops
  - **Rollback:** `sudo rm -rf /var/lib/incus/* && sudo systemctl restart incus`

- [x] INST-020: Add images remote on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `incus` `remote` `pc2`
  - **Steps:** `incus remote add images https://images.linuxcontainers.org --protocol simplestreams`
  - **Verification:** `incus remote list` shows images
  - **Rollback:** `incus remote remove images`

- [x] INST-021: Pull Ubuntu noble image on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `incus` `image` `pc2`
  - **Steps:** `incus image copy images:ubuntu/24.04/amd64 local: --alias ubuntu-noble`
  - **Verification:** `incus image list` shows ubuntu-noble
  - **Rollback:** `incus image delete ubuntu-noble`

---

## Phase 3: Incus Setup — PC1

- [x] INST-022: Add Zabbly repository on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `incus` `repository` `pc1`
  - **Steps:** Same as INST-016 on PC1
  - **Verification:** `ls /etc/apt/sources.list.d/zabbly-incus-stable.sources`
  - **Rollback:** Same as INST-016
  - **Completed:** 2026-09-07

- [x] INST-023: Install Incus on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 3min | **Tags:** `incus` `install` `pc1`
  - **Steps:** Same as INST-017 on PC1
  - **Verification:** `incus version` shows version
  - **Rollback:** Same as INST-017
  - **Completed:** 2026-09-07

- [x] INST-024: Add user to incus-admin group on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `incus` `permissions` `pc1`
  - **Steps:** Same as INST-018 on PC1
  - **Verification:** `groups` shows incus-admin
  - **Rollback:** Same as INST-018
  - **Completed:** 2026-09-07

- [x] INST-025: Initialize Incus on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 5min | **Tags:** `incus` `init` `pc1`
  - **Steps:** Same as INST-019 on PC1
  - **Verification:** `incus network list` shows incusbr0, `incus storage list` shows devops
  - **Rollback:** Same as INST-019
  - **Completed:** 2026-09-07

- [x] INST-026: Add images remote on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `incus` `remote` `pc1`
  - **Steps:** Same as INST-020 on PC1
  - **Verification:** `incus remote list` shows images
  - **Rollback:** Same as INST-020
  - **Completed:** 2026-09-07

- [x] INST-027: Pull Ubuntu noble image on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `incus` `image` `pc1`
  - **Steps:** Same as INST-021 on PC1
  - **Verification:** `incus image list` shows ubuntu-noble
  - **Rollback:** Same as INST-021
  - **Completed:** 2026-09-07

---

## Phase 4: OpenTofu — PC1

> **OpenTofu Guide:** See `ansible-opentofu/OPENTOFU-GUIDE.md` for complete documentation.

- [x] INST-028: Install OpenTofu on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 3min | **Tags:** `opentofu` `install` `pc1`
  - **Steps:** Add HashiCorp GPG key, add repo, `sudo apt install tofu`
  - **Verification:** `tofu version`
  - **Rollback:** `sudo apt remove tofu`
  - **Completed:** 2026-09-07

- [x] INST-029: OpenTofu init on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `opentofu` `init` `pc1`
  - **Steps:** `cd ansible-opentofu/terraform/pc1 && tofu init`
  - **Verification:** `.terraform/` directory created
  - **Rollback:** `rm -rf .terraform/`
  - **Completed:** 2026-09-07

- [x] INST-030: OpenTofu plan on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `opentofu` `plan` `pc1`
  - **Steps:** `tofu plan`
  - **Verification:** Shows 2 resources to create (k3s-master, k3s-worker-1)
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

- [x] INST-031: OpenTofu apply on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 5min | **Tags:** `opentofu` `apply` `pc1`
  - **Steps:** `tofu apply -auto-approve`
  - **Verification:** `incus list` shows k3s-master (10.195.94.80) and k3s-worker-1 (10.195.94.81)
  - **Rollback:** `tofu destroy -auto-approve`
  - **Completed:** 2026-09-07

- [x] INST-032: Verify k3s-master container on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `incus` `verify` `pc1`
  - **Steps:** `incus exec k3s-master -- hostname`
  - **Verification:** Returns "k3s-master"
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

- [x] INST-033: Verify k3s-worker-1 container on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `incus` `verify` `pc1`
  - **Steps:** `incus exec k3s-worker-1 -- hostname`
  - **Verification:** Returns "k3s-worker-1"
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

---

## Phase 4: OpenTofu — PC2

- [x] INST-034: Install OpenTofu on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 3min | **Tags:** `opentofu` `install` `pc2`
  - **Steps:** Same as INST-028 on PC2 (OpenTofu)
  - **Verification:** `tofu version`
  - **Rollback:** `sudo apt remove tofu`
  - **Completed:** 2026-09-07

- [x] INST-035: OpenTofu init on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `opentofu` `init` `pc2`
  - **Steps:** `cd ansible-opentofu/terraform/pc2 && tofu init`
  - **Verification:** `.terraform/` directory created
  - **Rollback:** `rm -rf .terraform/`
  - **Completed:** 2026-09-07

- [x] INST-036: OpenTofu plan on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `opentofu` `plan` `pc2`
  - **Steps:** `tofu plan`
  - **Verification:** Shows 1 resource to create (k3s-worker-2)
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

- [x] INST-037: OpenTofu apply on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 5min | **Tags:** `opentofu` `apply` `pc2`
  - **Steps:** `tofu apply -auto-approve`
  - **Verification:** `incus list` shows k3s-worker-2 (10.195.94.82)
  - **Rollback:** `tofu destroy -auto-approve`
  - **Completed:** 2026-09-07

- [x] INST-038: Verify k3s-worker-2 container on PC2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `incus` `verify` `pc2`
  - **Steps:** `incus exec k3s-worker-2 -- hostname`
  - **Verification:** Returns "k3s-worker-2"
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

---

## Phase 5: Ansible Setup

- [x] INST-039: Install Ansible on PC1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 3min | **Tags:** `ansible` `install` `pc1`
  - **Steps:** `sudo apt update && sudo apt install ansible -y`
  - **Verification:** `ansible --version`
  - **Rollback:** `sudo apt remove ansible`
  - **Completed:** 2026-09-07

- [x] INST-040: Update inventory/hosts.ini with correct IPs
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `ansible` `inventory` `config`
  - **Steps:** Edit `ansible-opentofu/ansible/inventory/hosts.ini` with correct Tailscale IPs
  - **Verification:** `cat inventory/hosts.ini` shows correct IPs
  - **Rollback:** `git checkout inventory/hosts.ini`
  - **Completed:** 2026-09-07

- [x] INST-041: Test Ansible SSH connectivity to all nodes
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 2min | **Tags:** `ansible` `ssh` `test`
  - **Steps:** `cd ansible-opentofu/ansible && ansible all -m ping`
  - **Verification:** All 3 nodes respond with SUCCESS
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

- [x] INST-042: Test Ansible SSH to k3s-master
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ansible` `ssh` `master`
  - **Steps:** `ansible k3s-master -m ping`
  - **Verification:** SUCCESS
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

- [x] INST-043: Test Ansible SSH to k3s-worker-1
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ansible` `ssh` `worker`
  - **Steps:** `ansible k3s-worker-1 -m ping`
  - **Verification:** SUCCESS
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

- [x] INST-044: Test Ansible SSH to k3s-worker-2
  - **Priority:** P0 | **Sprint:** 1 | **Status:** done
  - **Estimate:** 1min | **Tags:** `ansible` `ssh` `worker`
  - **Steps:** `ansible k3s-worker-2 -m ping`
  - **Verification:** SUCCESS
  - **Rollback:** N/A
  - **Completed:** 2026-09-07

---

## Phase 6: Ansible Playbook — K3s Cluster

- [ ] INST-045: Run Ansible playbook (full setup)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 15min | **Tags:** `ansible` `playbook` `k3s`
  - **Steps:** `ansible-playbook site.yml`
  - **Verification:** All roles complete without errors
  - **Rollback:** `ansible-playbook site.yml --tags undo` or manual cleanup

- [ ] INST-046: Ansible role — common (base packages)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `ansible` `role` `common`
  - **Steps:** Installs curl, iptables, python3, etc. on all nodes
  - **Verification:** `ansible all -m shell -a "curl --version"`
  - **Rollback:** Manual removal

- [ ] INST-047: Ansible role — k3s-master (K3s server)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `ansible` `role` `k3s-master`
  - **Steps:** Installs K3s server on master, initializes cluster
  - **Verification:** `incus exec k3s-master -- kubectl get nodes`
  - **Rollback:** `incus exec k3s-master -- /usr/local/bin/k3s-uninstall.sh`

- [ ] INST-048: Ansible role — k3s-worker (K3s agents)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `ansible` `role` `k3s-worker`
  - **Steps:** Installs K3s agent on workers, joins cluster
  - **Verification:** Workers show in `kubectl get nodes`
  - **Rollback:** `incus exec <worker> -- /usr/local/bin/k3s-agent-uninstall.sh`

- [ ] INST-049: Ansible role — tools (all K8s tools)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `ansible` `role` `tools`
  - **Steps:** Runs install-k8s-tools.sh (latest versions) + copies devopstools-guide.sh to ~/devopstools-guide.sh
  - **Verification:** `kubectl version`, `helm version`, `k9s --help`, `~/devopstools-guide.sh`
  - **Rollback:** Manual removal

- [ ] INST-050: Ansible role — metallb (LoadBalancer)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 3min | **Tags:** `ansible` `role` `metallb`
  - **Steps:** Deploys MetalLB with IP pool 10.195.94.100-150
  - **Verification:** `kubectl get ipaddresspool -A`
  - **Rollback:** `kubectl delete -f metallb-config.yaml`

- [ ] INST-051: Ansible role — nginx-ingress (HTTP router)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 3min | **Tags:** `ansible` `role` `nginx-ingress`
  - **Steps:** Deploys nginx-ingress controller
  - **Verification:** `kubectl get pods -n ingress-nginx`
  - **Rollback:** `helm uninstall ingress-nginx`

- [ ] INST-052: Ansible role — cert-manager (TLS)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 3min | **Tags:** `ansible` `role` `cert-manager`
  - **Steps:** Deploys cert-manager with Let's Encrypt
  - **Verification:** `kubectl get pods -n cert-manager`
  - **Rollback:** `helm uninstall cert-manager`

- [ ] INST-053: Ansible role — monitoring (Prometheus + Grafana)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `ansible` `role` `monitoring`
  - **Steps:** Deploys kube-prometheus-stack
  - **Verification:** `kubectl get pods -n monitoring`
  - **Rollback:** `helm uninstall kube-prometheus-stack`

- [ ] INST-054: Ansible role — vault (secrets)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 3min | **Tags:** `ansible` `role` `vault`
  - **Steps:** Deploys HashiCorp Vault
  - **Verification:** `kubectl get pods -n vault`
  - **Rollback:** `helm uninstall vault`

- [ ] INST-055: Ansible role — argocd (GitOps)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 3min | **Tags:** `ansible` `role` `argocd`
  - **Steps:** Deploys ArgoCD
  - **Verification:** `kubectl get pods -n argocd`
  - **Rollback:** `helm uninstall argocd`

---

## Phase 7: Verify Cluster

- [ ] INST-056: Verify all nodes Ready
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `k3s` `verify` `nodes`
  - **Steps:** `kubectl get nodes -o wide`
  - **Verification:** All 3 nodes show STATUS=Ready
  - **Rollback:** N/A

- [ ] INST-057: Verify k3s-master role
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `k3s` `verify` `master`
  - **Steps:** `kubectl get nodes -o wide | grep master`
  - **Verification:** Shows control-plane,master role
  - **Rollback:** N/A

- [ ] INST-058: Verify k3s-worker-1 role
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `k3s` `verify` `worker`
  - **Steps:** `kubectl get nodes -o wide | grep worker-1`
  - **Verification:** Shows worker role
  - **Rollback:** N/A

- [ ] INST-059: Verify k3s-worker-2 role
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `k3s` `verify` `worker`
  - **Steps:** `kubectl get nodes -o wide | grep worker-2`
  - **Verification:** Shows worker role
  - **Rollback:** N/A

- [ ] INST-060: Verify all system pods Running
  - **Priority:** P0 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `k3s` `verify` `pods`
  - **Steps:** `kubectl get pods -A`
  - **Verification:** All system pods show STATUS=Running
  - **Rollback:** N/A

- [ ] INST-061: Verify MetalLB pods Running
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `metallb` `verify` `pods`
  - **Steps:** `kubectl get pods -n metallb-system`
  - **Verification:** All pods Running
  - **Rollback:** N/A

- [ ] INST-062: Verify nginx-ingress pods Running
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `nginx` `verify` `pods`
  - **Steps:** `kubectl get pods -n ingress-nginx`
  - **Verification:** All pods Running
  - **Rollback:** N/A

- [ ] INST-063: Verify cert-manager pods Running
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `cert-manager` `verify` `pods`
  - **Steps:** `kubectl get pods -n cert-manager`
  - **Verification:** All pods Running
  - **Rollback:** N/A

- [ ] INST-064: Verify Prometheus pods Running
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `prometheus` `verify` `pods`
  - **Steps:** `kubectl get pods -n monitoring`
  - **Verification:** All pods Running
  - **Rollback:** N/A

- [ ] INST-065: Verify Vault pods Running
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `vault` `verify` `pods`
  - **Steps:** `kubectl get pods -n vault`
  - **Verification:** All pods Running
  - **Rollback:** N/A

- [ ] INST-066: Verify ArgoCD pods Running
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `argocd` `verify` `pods`
  - **Steps:** `kubectl get pods -n argocd`
  - **Verification:** All pods Running
  - **Rollback:** N/A

---

## Phase 8: Access Services

- [ ] INST-067: Get MetalLB external IPs
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 1min | **Tags:** `metallb` `ip` `access`
  - **Steps:** `kubectl get svc -A --field-selector spec.type=LoadBalancer`
  - **Verification:** External IPs assigned in 10.195.94.100-150 range
  - **Rollback:** N/A

- [ ] INST-068: Access Grafana dashboard
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `grafana` `access` `monitoring`
  - **Steps:** Open `http://10.195.94.100` in browser, login admin/admin
  - **Verification:** Dashboard loads, shows cluster metrics
  - **Rollback:** N/A

- [ ] INST-069: Access Prometheus
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `prometheus` `access` `monitoring`
  - **Steps:** Open `http://10.195.94.100:9090` in browser
  - **Verification:** Targets page shows all endpoints UP
  - **Rollback:** N/A

- [ ] INST-070: Access ArgoCD
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `argocd` `access` `gitops`
  - **Steps:** Open `http://10.195.94.100:443` in browser
  - **Verification:** Login page loads
  - **Rollback:** N/A

- [ ] INST-071: Access Vault
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `vault` `access` `secrets`
  - **Steps:** Open Vault UI in browser
  - **Verification:** Login page loads
  - **Rollback:** N/A

- [ ] INST-072: Verify Grafana dashboards showing data
  - **Priority:** P1 | **Sprint:** 1 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `grafana` `dashboards` `monitoring`
  - **Steps:** Navigate to dashboards, check Kubernetes cluster dashboard
  - **Verification:** Charts show CPU, memory, network data
  - **Rollback:** N/A

---

## Phase 9: CI/CD Setup

- [ ] INST-073: Install Docker on PC2
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `docker` `install` `pc2`
  - **Steps:** `curl -fsSL https://get.docker.com | sh`, `sudo usermod -aG docker $USER`
  - **Verification:** `docker --version`, `docker run hello-world`
  - **Rollback:** `sudo apt remove docker-ce docker-ce-cli containerd.io`

- [ ] INST-074: Install GitHub Actions runner on PC2
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 10min | **Tags:** `github` `runner` `ci-cd`
  - **Steps:** Download runner from GitHub repo settings, configure with token, `./run.sh`
  - **Verification:** Runner shows "Online" in GitHub Actions settings
  - **Rollback:** `./config.sh remove --token TOKEN`

- [ ] INST-075: Move github/workflows → .github/workflows
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `github` `workflows` `fix`
  - **Steps:** `mv github/workflows .github/workflows`, `rm -rf github/`
  - **Verification:** `.github/workflows/` contains all workflow files
  - **Rollback:** `mv .github/workflows github/workflows`

- [ ] INST-076: Test GitHub Actions workflow trigger
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `github` `actions` `test`
  - **Steps:** Push a commit, check Actions tab
  - **Verification:** Workflow starts, runner picks up job
  - **Rollback:** N/A

---

## Phase 10: Application Deployment

- [ ] INST-077: Deploy Contoso Pet Store via ArgoCD
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 10min | **Tags:** `argocd` `deploy` `app`
  - **Steps:** Create ArgoCD Application pointing to GitHub repo
  - **Verification:** All 8 microservices pods Running
  - **Rollback:** Delete ArgoCD Application

- [ ] INST-078: Verify store-front service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `store-front`
  - **Steps:** `kubectl get pods -l app=store-front`
  - **Verification:** Pod Running, accessible via Ingress
  - **Rollback:** N/A

- [ ] INST-079: Verify store-admin service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `store-admin`
  - **Steps:** `kubectl get pods -l app=store-admin`
  - **Verification:** Pod Running, accessible via Ingress
  - **Rollback:** N/A

- [ ] INST-080: Verify order-service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `order-service`
  - **Steps:** `kubectl get pods -l app=order-service`
  - **Verification:** Pod Running
  - **Rollback:** N/A

- [ ] INST-081: Verify product-service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `product-service`
  - **Steps:** `kubectl get pods -l app=product-service`
  - **Verification:** Pod Running
  - **Rollback:** N/A

- [ ] INST-082: Verify makeline-service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `makeline-service`
  - **Steps:** `kubectl get pods -l app=makeline-service`
  - **Verification:** Pod Running
  - **Rollback:** N/A

- [ ] INST-083: Verify ai-service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `ai-service`
  - **Steps:** `kubectl get pods -l app=ai-service`
  - **Verification:** Pod Running
  - **Rollback:** N/A

- [ ] INST-084: Verify virtual-customer
  - **Priority:** P2 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `virtual-customer`
  - **Steps:** `kubectl get pods -l app=virtual-customer`
  - **Verification:** Pod Running
  - **Rollback:** N/A

- [ ] INST-085: Verify virtual-worker
  - **Priority:** P2 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 2min | **Tags:** `app` `verify` `virtual-worker`
  - **Steps:** `kubectl get pods -l app=virtual-worker`
  - **Verification:** Pod Running
  - **Rollback:** N/A

---

## Phase 11: Security Tools

- [ ] INST-086: Run SonarQube code analysis
  - **Priority:** P2 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 10min | **Tags:** `sonarqube` `security` `code`
  - **Steps:** Access SonarQube UI, run analysis on repo
  - **Verification:** Analysis complete, quality gate passed
  - **Rollback:** N/A

- [ ] INST-087: Run Gitleaks secret scan
  - **Priority:** P2 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `gitleaks` `security` `secrets`
  - **Steps:** `gitleaks detect --source . --verbose`
  - **Verification:** No secrets found
  - **Rollback:** N/A

- [ ] INST-088: Run Hadolint Dockerfile lint
  - **Priority:** P2 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `hadolint` `security` `docker`
  - **Steps:** `hadolint src/*/Dockerfile`
  - **Verification:** No critical warnings
  - **Rollback:** N/A

- [ ] INST-089: Run Trivy container scan
  - **Priority:** P2 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `trivy` `security` `container`
  - **Steps:** `trivy image <image-name>`
  - **Verification:** No CRITICAL vulnerabilities
  - **Rollback:** N/A

- [ ] INST-090: Run Checkov Terraform scan
  - **Priority:** P2 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 5min | **Tags:** `checkov` `security` `terraform`
  - **Steps:** `checkov -d ansible-opentofu/terraform/`
  - **Verification:** No failed checks
  - **Rollback:** N/A

---

## Phase 12: Documentation

- [ ] INST-091: Create architecture diagram
  - **Priority:** P2 | **Sprint:** 3 | **Status:** todo
  - **Estimate:** 2h | **Tags:** `documentation` `architecture`
  - **Steps:** Draw diagram of 2-PC setup with Tailscale, Incus, K3s
  - **Verification:** Diagram saved as PNG/SVG
  - **Rollback:** N/A

- [ ] INST-092: Create pipeline diagram
  - **Priority:** P2 | **Sprint:** 3 | **Status:** todo
  - **Estimate:** 1h | **Tags:** `documentation` `pipeline`
  - **Steps:** Draw CI/CD pipeline flow
  - **Verification:** Diagram saved
  - **Rollback:** N/A

- [ ] INST-093: Screenshot all dashboards
  - **Priority:** P2 | **Sprint:** 3 | **Status:** todo
  - **Estimate:** 1h | **Tags:** `documentation` `screenshots`
  - **Steps:** Screenshot Grafana, Prometheus, ArgoCD, Vault
  - **Verification:** All screenshots saved
  - **Rollback:** N/A

- [ ] INST-094: Write setup README
  - **Priority:** P2 | **Sprint:** 3 | **Status:** todo
  - **Estimate:** 2h | **Tags:** `documentation` `readme`
  - **Steps:** Write comprehensive README.md for the project
  - **Verification:** README covers all steps
  - **Rollback:** N/A

- [ ] INST-095: Write troubleshooting guide
  - **Priority:** P2 | **Sprint:** 3 | **Status:** todo
  - **Estimate:** 2h | **Tags:** `documentation` `troubleshooting`
  - **Steps:** Document all errors encountered and fixes
  - **Verification:** Guide covers all 17 errors
  - **Rollback:** N/A

- [ ] INST-096: Create portfolio presentation
  - **Priority:** P3 | **Sprint:** 3 | **Status:** todo
  - **Estimate:** 3h | **Tags:** `documentation` `portfolio`
  - **Steps:** Create presentation summarizing the project
  - **Verification:** Presentation complete
  - **Rollback:** N/A

---

## ERRORS LOG

| # | Error | Cause | Fix |
|---|-------|-------|-----|
| 1 | SSH: Connection refused | SSH not installed on PC2 | Install openssh-server |
| 2 | SSH: Permission denied | No password on PC2 | `sudo passwd antix` |
| 3 | SSH: Hostname vs username | `antix-1` is hostname not user | Use `antix` as username |
| 4 | Typo: udo | Missing `s` in sudo | Type `sudo` correctly |
| 5 | Typo: cd/tmp | Missing space | Type `cd /tmp` |
| 6 | Incus: --wipe doesn't exist | Flag not supported | Manual cleanup |
| 7 | Incus: --all doesn't exist | Flag not supported | Use loop |
| 8 | Incus: bridge already exists | Previous partial init | Delete first |
| 9 | Incus: network in use | Referenced by profile | Remove from profile |
| 10 | Incus: managed field invalid | YAML field not supported | Remove from YAML |
| 11 | Incus: nictype + network conflict | Both properties on same device | Use only network |
| 12 | Incus: ubuntu remote doesn't exist | Remote not added | Use images remote |
| 13 | Incus: image not found | Wrong alias | Use images:ubuntu/24.04/amd64 |
| 14 | Incus: sudo password in SSH | No NOPASSWD configured | Set NOPASSWD sudo |
| 15 | Incus: service still active | Socket unit active | Wait or stop socket |
| 16 | Incus: storage path "yes" | Typed yes instead of Enter | Press Enter for default |
| 17 | Incus: preseed parse error | Invalid YAML fields | Remove invalid fields |
| 18 | OpenTofu: provider not found | providers.tf in parent dir | Copy into pc1/pc2 dirs |
| 19 | OpenTofu: image not found | No alias on image | `incus image alias create ubuntu-noble <fingerprint>` |
| 20 | SCP: stat local: No such file | Dest dir doesn't exist | `mkdir -p` before SCP |
| 21 | SCP: Permission denied | Wrong username (ssh@ vs antix@) | Use `antix@` |
| 22 | SCP: realpath failed | Run from wrong machine | Run from PC1 not PC2 |
| 23 | Ansible: No inventory parsed | Wrong directory or missing -i | Use `-i inventory/hosts.ini` |
| 24 | Ansible: Connection refused | SSH not installed | Install openssh-server in container |
| 25 | Ansible: Host key verification failed | Key not in known_hosts | `ssh-keyscan IP >> ~/.ssh/known_hosts` |
| 26 | Ansible: Permission denied | Key not on remote (fresh images lock root pw) | SSH keys via setup-ssh-keys.sh + direct push; password auth retired |
| 27 | Ansible: No route to host | Subnet conflict on both PCs | Install Tailscale in container |
| 28 | Ansible: Invalid group names | Hyphens in group names | Use underscores in inventory |
| 29 | Ansible: Handler 'extract k9s' not found | handlers/main.yml missing in tools role | Create handlers/main.yml with extract tasks |
| 30 | Ansible: YAML parsing failed - handlers: in tasks | handlers block embedded in tasks/main.yml | Remove handlers block from tasks file |

---

## SUMMARY

| Phase | Done | Total | Status |
|-------|------|-------|--------|
| 1. Connectivity (Tailscale) | 8 | 8 | ✅ Done |
| 2. SSH Setup | 7 | 7 | ✅ Done |
| 3. Incus PC2 | 6 | 6 | ✅ Done |
| 3. Incus PC1 | 6 | 6 | ✅ Done |
| 4. OpenTofu PC1 | 6 | 6 | ✅ Done |
| 4. OpenTofu PC2 | 5 | 5 | ✅ Done |
| 5. Ansible Setup | 6 | 6 | ✅ Done |
| 6. Ansible Playbook | 0 | 11 | ⏳ Next |
| 7. Verify Cluster | 0 | 11 | ⏳ Next |
| 8. Access Services | 0 | 6 | ⏳ Next |
| 9. CI/CD Setup | 0 | 4 | ⏳ Next |
| 10. Application Deploy | 0 | 9 | ⏳ Next |
| 11. Security Tools | 0 | 5 | ⏳ Next |
| 12. Documentation | 0 | 6 | ⏳ Next |
| **TOTAL** | **44** | **96** | **46%** |

---

*Last Updated: 2026-09-08*
