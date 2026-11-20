# Ansible Setup Guide — From Zero to K3s Ready
# With All Errors and Troubleshooting

## Prerequisites
- Tailscale installed on both PCs
- SSH working between PCs
- Incus installed on both PCs
- Containers created:
  - PC1: k3s-master, k3s-worker-1, vault, monitoring, sonarqube
  - PC2: k3s-worker-2
- SSH server installed in all containers

---

## Phase 1: Install Ansible on PC1

### Step 1.1: Install Ansible
```bash
sudo apt update
sudo apt install ansible -y
```

### Step 1.2: Verify
```bash
ansible --version
```

**Expected output:**
```
ansible [core 2.20.1]
  config file = /home/antix/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible/ansible.cfg
  ...
```

---

## Phase 2: Configure Inventory

### Step 2.1: Navigate to Ansible Directory
```bash
cd ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible
```

### Step 2.2: Edit Inventory File
```bash
nano inventory/hosts.ini
```

**Content (current — SSH keys only, no passwords anywhere):**
```ini
[all:vars]
ansible_user=root
ansible_become=yes
ansible_python_interpreter=/usr/bin/python3

[k3s_master]
k3s-master ansible_host=10.195.94.80 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[k3s_workers]
k3s-worker-1 ansible_host=10.195.94.81 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
k3s-worker-2 ansible_host=100.100.13.113 ansible_ssh_common_args='-o StrictHostKeyChecking=no' k3s_server_url=https://100.119.206.35:6443 nfs_server_override=100.119.206.35

[k3s_cluster:children]
k3s_master
k3s_workers

[vault_server]
vault ansible_host=10.195.94.200 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[monitoring_server]
monitoring ansible_host=10.195.94.210 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[sonarqube_server]
sonarqube ansible_host=100.73.135.124 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[forgejo_server]
forgejo ansible_host=100.88.159.38 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[ci_runners]
ci-runner-1 ansible_host=100.113.54.77 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[production:children]
k3s_cluster
vault_server
monitoring_server
sonarqube_server
forgejo_server
ci_runners
```

> Historical password-based entries scrubbed per credential hygiene (keys since
> `setup-ssh-keys.sh`; dead PC1 sonarqube `.220` removed; PC2 hosts on Tailscale).

---

## Phase 3: Install SSH in Containers

### Step 3.1: Install SSH on PC1 Containers
```bash
incus exec k3s-master -- bash -c "apt update && apt install -y openssh-server && systemctl enable --now ssh"
incus exec k3s-worker-1 -- bash -c "apt update && apt install -y openssh-server && systemctl enable --now ssh"
incus exec vault -- bash -c "apt update && apt install -y openssh-server && systemctl enable --now ssh"
incus exec monitoring -- bash -c "apt update && apt install -y openssh-server && systemctl enable --now ssh"
incus exec sonarqube -- bash -c "apt update && apt install -y openssh-server && systemctl enable --now ssh"
```

### Step 3.2: Set Root Password on All Containers
```bash
# PC1 containers (replace RAFAA with your actual password)
incus exec k3s-master -- bash -c "echo 'root:RAFAA' | chpasswd && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
incus exec k3s-worker-1 -- bash -c "echo 'root:RAFAA' | chpasswd && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
incus exec vault -- bash -c "echo 'root:RAFAA' | chpasswd && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
incus exec monitoring -- bash -c "echo 'root:RAFAA' | chpasswd && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
incus exec sonarqube -- bash -c "echo 'root:RAFAA' | chpasswd && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
```

### Step 3.3: Install Tailscale in PC2 Container
```bash
incus exec k3s-worker-2 -- bash -c "curl -fsSL https://tailscale.com/install.sh | sh && tailscale up --hostname=k3s-worker-2"
```

### Step 3.4: Get Tailscale IP
```bash
incus exec k3s-worker-2 -- tailscale ip -4
```

**Output:** `100.100.13.113`

---

## Phase 4: Test Ansible Connectivity

### Step 4.1: Add Host Keys
```bash
ssh-keyscan 10.195.94.80 >> ~/.ssh/known_hosts
ssh-keyscan 10.195.94.81 >> ~/.ssh/known_hosts
ssh-keyscan 10.195.94.200 >> ~/.ssh/known_hosts
ssh-keyscan 10.195.94.210 >> ~/.ssh/known_hosts
ssh-keyscan 100.100.13.113 >> ~/.ssh/known_hosts
```

### Step 4.2: Test All Nodes
```bash
cd ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible
ansible all -m ping -i inventory/hosts.ini
```

**Expected output:**
```
k3s-master | SUCCESS => {"ping": "pong"}
k3s-worker-1 | SUCCESS => {"ping": "pong"}
k3s-worker-2 | SUCCESS => {"ping": "pong"}
vault | SUCCESS => {"ping": "pong"}
monitoring | SUCCESS => {"ping": "pong"}
sonarqube | SUCCESS => {"ping": "pong"}
```

---

## All Errors and Fixes

### ERROR 1: No inventory was parsed

**Error message:**
```
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available
```

**Cause:** Running `ansible` from wrong directory or without `-i` flag.

**Fix:**
```bash
# Either use -i flag with full path
ansible all -m ping -i /home/antix/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible/inventory/hosts.ini

# Or cd to ansible directory first
cd ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible
ansible all -m ping -i inventory/hosts.ini
```

**Prevention:** Always run from the `ansible/` directory and use `-i inventory/hosts.ini`.

---

### ERROR 2: Connection refused on port 22

**Error message:**
```
[ERROR]: Task failed: Failed to connect to the host via ssh: ssh: connect to host 10.195.94.80 port 22: Connection refused
k3s-master | UNREACHABLE! => {"msg": "Task failed: ... Connection refused"}
```

**Cause:** SSH server (openssh-server) is not installed in the container.

**Fix:**
```bash
# Install SSH in the container
incus exec k3s-master -- bash -c "apt update && apt install -y openssh-server && systemctl enable --now ssh"
```

**Prevention:** Install SSH in all containers during setup phase.

---

### ERROR 3: Host key verification failed

**Error message:**
```
[ERROR]: Task failed: Failed to connect to the host via ssh: ssh_askpass: exec(/usr/bin/ssh-askpass): No such file or directory
Host key verification failed.
k3s-master | UNREACHABLE! => {"msg": "... Host key verification failed."}
```

**Cause:** SSH host key is not in `~/.ssh/known_hosts`.

**Fix:**
```bash
# Add host key
ssh-keyscan 10.195.94.80 >> ~/.ssh/known_hosts
ssh-keyscan 10.195.94.81 >> ~/.ssh/known_hosts
```

**Alternative:** Use `ansible_ssh_common_args='-o StrictHostKeyChecking=no'` in inventory.

**Prevention:** Always add host keys before testing, or use StrictHostKeyChecking=no.

---

### ERROR 4: Permission denied (publickey,password)

**Error message:**
```
[ERROR]: Task failed: Failed to connect to the host via ssh: root@10.195.94.80: Permission denied (publickey,password).
k3s-master | UNREACHABLE! => {"msg": "... Permission denied (publickey,password)."}
```

**Cause:** Ansible is trying publickey auth but no SSH key is set up. It doesn't know the password.

**Fix:** Add password auth to inventory:
```ini
[k3s-master]
k3s-master ansible_host=10.195.94.80 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

**Also ensure password is set in container:**
```bash
incus exec k3s-master -- bash -c "echo 'root:RAFAA' | chpasswd"
```

---

### ERROR 5: No route to host (subnet conflict)

**Error message:**
```
[ERROR]: Task failed: Failed to connect to the host via ssh: ssh: connect to host 10.195.94.82 port 22: No route to host
k3s-worker-2 | UNREACHABLE! => {"msg": "... No route to host"}
```

**Cause:** Both PCs use the same Incus subnet (10.195.94.0/24). When PC1 tries to reach 10.195.94.82 on PC2, it thinks the destination is local and ARPs on its own bridge.

**Fix — Option A (different subnets):**
```bash
# On PC2
sudo incus network set incusbr0 ipv4.address=10.195.95.1/24
sudo incus restart --all
incus config device set k3s-worker-2 eth0 ipv4.address=10.195.95.82
incus start k3s-worker-2
```

**Fix — Option B (Tailscale in container — recommended):**
```bash
# On PC2
incus exec k3s-worker-2 -- bash -c "curl -fsSL https://tailscale.com/install.sh | sh && tailscale up --hostname=k3s-worker-2"

# Get Tailscale IP
incus exec k3s-worker-2 -- tailscale ip -4

# Use Tailscale IP in inventory instead of 10.195.94.82
```

---

### ERROR 6: Invalid characters in group names

**Error message:**
```
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details
Not replacing invalid character(s) "{'-'}" in group name (k3s-master)
```

**Cause:** Ansible group names cannot contain hyphens `-`. The group `[k3s-master]` has invalid characters.

**Fix:** Use underscores in group names:
```ini
# WRONG
[k3s-master]
[k3s-workers]

# CORRECT
[k3s_master]
[k3s_workers]
```

**Note:** This is a warning, not an error. Ansible still works, but it's better to fix.

---

### ERROR 7: Section includes undefined group

**Error message:**
```
[WARNING]: Failed to parse inventory with 'ini' plugin: Failed to parse inventory: Section [k3s_cluster:children] includes undefined group 'k3s_master'.
```

**Cause:** The children section references a group name that doesn't exist (mismatch with hyphens/underscores).

**Fix:** Ensure children references match exact group names:
```ini
[k3s_master]
k3s-master ansible_host=10.195.94.80 ...

[k3s_workers]
k3s-worker-1 ansible_host=10.195.94.81 ...

[k3s_cluster:children]
k3s_master
k3s_workers
```

---

### ERROR 8: Some peers are advertising routes but --accept-routes is false

**Error message:**
```
Some peers are advertising routes but --accept-routes is false
```

**Cause:** Tailscale in container is not accepting routes from other peers.

**Fix:**
```bash
incus exec k3s-worker-2 -- tailscale up --accept-routes --hostname=k3s-worker-2
```

---

### ERROR 9: Device IP address not within network subnet

**Error message:**
```
Error: local: The following instances failed to update state:
 - Instance: k3s-worker-2: Failed start validation for device "eth0": Device IP address "10.195.94.82" not within network "incusbr0" subnet
```

**Cause:** The container IP is on old subnet but Incus bridge was changed to new subnet.

**Fix:** Update container IP before starting:
```bash
incus config device set k3s-worker-2 eth0 ipv4.address=10.195.95.82
incus start k3s-worker-2
```

---

### ERROR 10: Connection timed out (wrong IP for worker-2)

**Error message:**
```
[ERROR]: Task failed: Data could not be sent to remote host "10.195.95.82". Make sure this host can be reached over ssh: ssh: connect to host 10.195.95.82 port 22: Connection timed out
k3s-worker-2 | UNREACHABLE! => {"msg": "Task failed: ... Connection timed out"}
```

**Cause:** Using PC2's local bridge IP (10.195.95.82) instead of Tailscale IP. PC1 cannot reach 10.195.95.x directly — it's on a different physical network.

**Fix:** Use Tailscale IP in inventory:
```ini
[k3s_cluster]
k3s-worker-2 ansible_host=100.100.13.113 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

**How to get Tailscale IP:**
```bash
incus exec k3s-worker-2 -- tailscale ip -4
# Output: 100.100.13.113
```

**Prevention:** Always use Tailscale IPs for cross-PC communication. Local bridge IPs only work within the same PC.

---

### ERROR 11: Permission denied on fresh containers (SSH installed but not configured)

**Error message:**
```
[ERROR]: Task failed: Data could not be sent to remote host "10.195.94.210". Make sure this host can be reached over ssh: Warning: Permanently added '10.195.94.210' (ED25519) to the list of known hosts.
root@10.195.94.210: Permission denied (publickey,password).
monitoring | UNREACHABLE! => {"msg": "Task failed: ... Permission denied (publickey,password)."}
```

**Cause:** SSH server is installed and running, but:
1. Root password is not set (container has no password by default)
2. `PermitRootLogin` is set to `prohibit-password` or `no` in sshd_config

**Fix:** Set password AND enable root login:
```bash
# Set root password
incus exec monitoring -- bash -c "echo 'root:RAFAA' | chpasswd"

# Enable PermitRootLogin
incus exec monitoring -- bash -c "sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
```

**Why both steps are needed:**
- `chpasswd` sets the password — without it, Ansible has nothing to authenticate with
- `PermitRootLogin yes` allows root to log in via SSH — without it, even with correct password, SSH rejects root login
- `systemctl restart ssh` applies the config changes

**Prevention:** Always run both commands on every fresh container:
```bash
incus exec <container> -- bash -c "echo 'root:RAFAA' | chpasswd && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
```

---

### ERROR 12: The role 'vault' was not found

**Error message:**
```
[ERROR]: the role 'vault' was not found in /home/antix/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible/playbooks/roles:/home/antix/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:/home/antix/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible/playbooks
Origin: /home/antix/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible/playbooks/site-vault.yml:11:7
```

**Cause:** Playbooks are in `playbooks/` subdirectory, but roles are in the parent `roles/` directory. Ansible looks for roles relative to the playbook file location, so it looks in `playbooks/roles/` which doesn't exist.

**Fix:** Add `roles_path` to `ansible.cfg`:
```ini
[defaults]
inventory = inventory/hosts.ini
remote_user = root
roles_path = roles
host_key_checking = False
```

This tells Ansible: "Look for roles in the `roles/` directory relative to where `ansible.cfg` is."

**Common mistake:** Using `roles_path = ../roles` resolves to the parent directory (`ansible-opentofu/roles/`) which doesn't exist. Use `roles_path = roles` to point to `ansible-opentofu/ansible/roles/`.

**Why this happens:**
```
ansible/
├── ansible.cfg          ← roles_path = ../roles (points to ansible/roles/)
├── inventory/
│   └── hosts.ini
├── playbooks/
│   ├── site-vault.yml   ← runs from here, looks for roles in playbooks/roles/
│   └── site-all.yml
├── roles/               ← actual roles are HERE
│   ├── vault/
│   ├── common/
│   └── ...
└── site.yml
```

**Prevention:** Always include `roles_path = roles` in `ansible.cfg` (points to `ansible-opentofu/ansible/roles/`).

---

### ERROR 13: helm: command not found (monitoring on VM)

**Error message:**
```
[ERROR]: Task failed: Module failed: Error executing command: [Errno 2] No such file or directory: b'helm'
Origin: /home/antix/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/ansible/roles/monitoring/tasks/main.yml:6:3
fatal: [monitoring]: FAILED! => {"changed": false, "cmd": "helm repo add ...", "msg": "Error executing command.", "rc": 2}
```

**Cause:** The monitoring role was trying to use `helm install kube-prometheus-stack` to deploy Prometheus + Grafana as K8s pods. But the monitoring server is a **dedicated VM**, not part of the K3s cluster — it doesn't have `helm` installed.

**Fix:** The monitoring role has been **rewritten** to install Prometheus + Grafana + Alertmanager as **native binaries** on the VM (not via helm/K3s). The new role downloads binaries directly, creates systemd services, and configures them locally.

If you see this error, you're running an old version of the monitoring role. Pull the latest code and re-run.

**Architecture:**
```
Monitoring VM (10.195.94.210) — NOT in K3s
├── Prometheus    (port 9090) — binary install
├── Grafana       (port 3000) — APT install
├── Alertmanager  (port 9093) — binary install
├── OTel Collector (port 4317/4318) — binary install
├── Jaeger        (port 16686) — binary install
└── Loki          (port 3100) — binary install
```

---

### ERROR 14: Prometheus download fails (404 or connection error)

**Error message:**
```
fatal: [monitoring]: FAILED! => {"changed": false, "msg": "HTTP Error 404: Not Found", "status_code": 404}
```

**Cause:** Prometheus version doesn't exist or URL changed.

**Fix:** Check the latest version at https://github.com/prometheus/prometheus/releases and update `prometheus_version` in `inventory/group_vars/all.yml`.

---

### ERROR 15: Vault — http: server gave HTTP response to HTTPS client

**Error message:**
```
[ERROR]: Task failed: Module failed: non-zero return code
fatal: [vault]: FAILED! => {"msg": "non-zero return code", "rc": 1,
  "stderr": "Error checking seal status: Get \"https://127.0.0.1:8200/v1/sys/seal-status\": http: server gave HTTP response to HTTPS client"}
```

**Cause:** Vault is configured with `tls_disable = 1` (HTTP mode), but the `vault status` command defaults to HTTPS. The vault CLI tries `https://127.0.0.1:8200` but the server is listening on plain HTTP.

**Fix:** Add `VAULT_ADDR` environment variable to the task:
```yaml
- name: Check if Vault is already initialized
  command: vault status -format=json
  environment:
    VAULT_ADDR: "http://127.0.0.1:8200"
  register: vault_status
  changed_when: false
  ignore_errors: yes
```

---

### ERROR 16: Loki — Failed to find handler for .zip file

**Error message:**
```
fatal: [monitoring]: FAILED! => {"msg": "Failed to find handler for \"/tmp/loki.zip\".
  Make sure the required command to extract the file is installed.
  Unable to find required 'unzip' or 'zipinfo' binary in the path."}
```

**Cause:** Loki releases download as `.zip` files, but `unzip` is not installed on the monitoring VM. Ansible's `unarchive` module needs `unzip` to extract `.zip` archives.

**Fix:** Install `unzip` before extracting Loki:
```yaml
- name: Install unzip for Loki
  ansible.builtin.apt:
    name: unzip
    state: present

- name: Extract Loki
  ansible.builtin.unarchive:
    src: /tmp/loki.zip
    dest: /usr/local/bin
    remote_src: yes
    mode: "0755"
  when: loki_download.changed
```

---

### ERROR 17: Playbooks skipped — Could not match supplied host pattern

**Error message:**
```
[WARNING]: Could not match supplied host pattern, ignoring: k3s_master
[WARNING]: Could not match supplied host pattern, ignoring: k3s_workers
PLAY [Install k3s master] ***
skipping: no hosts matched
```

**Cause:** Playbooks target groups `k3s_master` and `k3s_workers`, but the inventory only has a `k3s_cluster` group containing all 3 nodes. The child groups don't exist.

**Fix:** Add child groups to `hosts.ini`:
```ini
[k3s_master]
k3s-master ansible_host=10.195.94.80 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[k3s_workers]
k3s-worker-1 ansible_host=10.195.94.81 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
k3s-worker-2 ansible_host=100.100.13.113 ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[k3s_cluster:children]
k3s_master
k3s_workers
```

The `k3s_cluster` group becomes a parent group containing `k3s_master` and `k3s_workers`. This lets playbooks target either the full cluster or specific roles.

---

### ERROR 18: Failed to start ContainerManager — /proc/sys read-only

**Error message:**
```
E0908 k3s-master k3s[8792]: "Failed to start ContainerManager" err="open /proc/sys/kernel/panic: read-only file system"
k3s.service: Main process exited, code=exited, status=1/FAILURE
```

**Cause:** In LXC containers, `/proc/sys` is mounted read-only. K3s kubelet needs to write to `/proc/sys/kernel/panic` to start the ContainerManager. The `dev-kmsg.service` and `proc-sys-rw.service` from cloud-init only run on first boot — if containers were pre-existing (imported into OpenTofu with `tofu import`), cloud-init never executed.

**Fix:**
```bash
# Manual fix (per node):
mount -o remount,rw /proc/sys
ln -sf /dev/console /dev/kmsg
systemctl restart k3s
```

**Prevention:** The k3s-master and k3s-worker roles now automatically:
1. Create `/dev/kmsg` symlink → `/dev/console`
2. Create and enable `dev-kmsg.service` (for future boots)
3. Remount `/proc/sys` as read-write
4. Create and enable `proc-sys-rw.service` (for future boots)
5. Then install k3s

---

### ERROR 19: 'Premature end of stream waiting for become success' on token copy

**Error message:**
```
[ERROR]: Task failed: Premature end of stream waiting for become success.
>>> Standard Error
sudo: interactive authentication is required
Origin: roles/k3s-master/tasks/main.yml:123:3

fatal: [k3s-master -> localhost]: FAILED! => {"changed": false, "msg": "... sudo: interactive authentication is required"}
```

**Cause:** The task uses `copy` with `delegate_to: localhost` and `become: false`, but the play-level `become: yes` is still applied to the delegated localhost connection. The local user doesn't have passwordless sudo configured.

**Fix:** Use the `fetch` module instead of `copy` + `delegate_to`:
```yaml
# WRONG
- name: Store token for workers
  copy:
    content: "{{ k3s_token.content | b64decode }}"
    dest: /tmp/k3s-node-token
    mode: '0600'
  delegate_to: localhost
  become: false
  when: inventory_hostname == groups['k3s_master'][0]

# CORRECT
- name: Store token for workers
  fetch:
    src: /var/lib/rancher/k3s/server/node-token
    dest: /tmp/k3s-node-token
    flat: yes
    mode: '0600'
  when: inventory_hostname == groups['k3s_master'][0]
```

**Why this works:** The `fetch` module copies from remote to local without needing `delegate_to` or `become`. It runs on the remote node (where you have root) and writes the file to the local control node's filesystem.

**Prevention:** Use `fetch` when pulling files from remote nodes to local. Avoid `delegate_to: localhost` with `become: false` — it doesn't reliably override play-level become.

---

### ERROR 20: 'object of type 'dict' has no attribute 'exists'' on /dev/kmsg check

**Error message:**
```
[ERROR]: Task failed: Error while evaluating conditional: object of type 'dict' has no attribute 'exists'
Origin: roles/k3s-master/tasks/main.yml:19:9

  when: not dev_kmsg.exists
           ^ column 9

fatal: [k3s-master]: FAILED! => {"changed": false, "msg": "Task failed: Error while evaluating conditional: object of type 'dict' has no attribute 'exists'"}
```

**Cause:** The `stat` module returns a result dict where file attributes are nested under `.stat`. Accessing `dev_kmsg.exists` directly fails because the top-level result doesn't have an `exists` key — it's at `dev_kmsg.stat.exists`.

**Fix:** Use `dev_kmsg.stat.exists` instead of `dev_kmsg.exists`:
```yaml
# WRONG
- name: Create /dev/kmsg symlink
  file:
    src: /dev/console
    dest: /dev/kmsg
    state: link
  when: not dev_kmsg.exists

# CORRECT
- name: Create /dev/kmsg symlink
  file:
    src: /dev/console
    dest: /dev/kmsg
    state: link
  when: not dev_kmsg.stat.exists
```

**Why this happens:** The `stat` module registers a result like `{changed: false, stat: {exists: true, isdir: false, ...}, ...}`. The `exists` boolean is inside the `.stat` sub-dict, not at the top level. This applies to both `k3s-master` and `k3s-worker` roles.

**Prevention:** Always use `<register_var>.stat.exists` when checking file existence with the `stat` module.

---

### ERROR 21: k3s agent fails — modprobe br_netfilter/overlay exits status 1

**Error message:**
```
Process: 5346 ExecStartPre=/sbin/modprobe br_netfilter (code=exited, status=1/FAILURE)
Process: 5348 ExecStartPre=/sbin/modprobe overlay (code=exited, status=1/FAILURE)
fatal: [k3s-worker-1]: FAILED! => {"changed": true, "msg": "non-zero return code", "rc": 1}
```

**Cause:** k3s systemd service has `ExecStartPre=/sbin/modprobe br_netfilter` and `ExecStartPre=/sbin/modprobe overlay`. LXC containers don't have `/lib/modules` — kernel modules must be loaded from the host via `linux.kernel_modules` config. The `overlay` module was missing from the config.

**Fix:**
```bash
# Add overlay to running containers (on host)
incus config set k3s-master linux.kernel_modules=ip_tables,ip6_tables,iptable_nat,iptable_filter,ip6table_nat,nf_tables,br_netfilter,overlay
incus config set k3s-worker-1 linux.kernel_modules=ip_tables,ip6_tables,iptable_nat,iptable_filter,ip6table_nat,nf_tables,br_netfilter,overlay

# Restart containers to load new modules
incus restart k3s-master k3s-worker-1

# Uninstall broken k3s from workers (if previously installed)
incus exec k3s-worker-1 -- /usr/local/bin/k3s-uninstall.sh
```

**Prevention:** Always include `overlay` in `linux.kernel_modules` in `main.tf`:
```hcl
"linux.kernel_modules" = "ip_tables,ip6_tables,iptable_nat,iptable_filter,ip6table_nat,nf_tables,br_netfilter,overlay"
```

---

### ERROR 43: `Unknown configuration key: limits.disk` on tofu apply

**Error message:**
```
Error: Failed to create instance "k3s-master"
Failed creating instance record: Unknown configuration key: limits.disk
```

**Cause:** `limits.disk` is not a valid Incus instance config key. Disk size limits in Incus are set on the root disk device, not in the `config {}` block.

**Fix:** Remove `"limits.disk"` from `config {}`, add a root disk device with `size`:
```hcl
# WRONG
config = {
  "limits.disk" = "80GB"
}

# CORRECT
device {
  name = "root"
  type = "disk"
  properties = {
    path = "/"
    pool = "default"
    size = "80GB"
  }
}
```

**Prevention:** Never use `limits.disk` in Incus OpenTofu configs. Always set disk size via root device.

---

### ERROR 44: `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` on ssh-copy-id

**Error message:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
root@10.195.94.80: Permission denied (publickey,password).
```

**Cause:** Containers were destroyed and recreated with new SSH host keys, but old keys remain in `~/.ssh/known_hosts`.

**Fix:**
```bash
ssh-keygen -f ~/.ssh/known_hosts -R 10.195.94.80
# Repeat for each recreated container
```

**Prevention:** The `setup-ssh-keys.sh` script now clears stale keys automatically before copying.

---

### ERROR 45: `Permission denied: '/var/cache/ansible'` on ansible run

**Error message:**
```
[WARNING]: Error in 'jsonfile' cache plugin while trying to create cache dir '/var/cache/ansible/facts': [Errno 13] Permission denied
```

**Cause:** `ansible.cfg` sets `fact_caching_connection = /var/cache/ansible/facts` which is only writable by root.

**Fix:** Change to user-writable path in `ansible.cfg`:
```ini
fact_caching_connection = ~/.cache/ansible/facts
```

---

### ERROR 46: Tailscale unreachable when ProtonVPN connected

**Error message:**
```
ping "100.110.171.119" timed out / no reply
tailscale status shows peers but tx>0 rx=0
```

**Cause:** ProtonVPN routes ALL traffic through its tunnel + kill-switch blocks non-VPN traffic, killing Tailscale's UDP (port 41641) and DERP relay connections. Symptoms: `tailscale status` shows peers with `tx>0 rx=0`, PC1 shows `offline`, error `could not connect to relay server`.

**Fix (verified):** Disable kill-switch in ProtonVPN GUI:
```
ProtonVPN → Settings → Kill Switch → Off
```
VPN still encrypts all traffic, but Tailscale UDP can pass through. Verified working with ProtonVPN 4.18.1 (Snap) + Tailscale 1.102.3.

**Why not split tunneling:** ProtonVPN Linux split tunneling (Settings → Features → Split tunneling) is only available on native .deb/.rpm for Ubuntu/Fedora — NOT on Snap or Flatpak versions. App-based only (cannot exclude IPs). If on Snap: either switch to .deb or use kill-switch off.

**Alternative (iptables, may not work with nftables kill-switch):**
```bash
sudo ./ansible-opentofu/ansible/protonvpn-tailscale-fix.sh
```

**Prevention:** Keep kill-switch off during cluster work. Re-enable when done if desired (will break Tailscale again).

---

### ERROR 47: `modprobe: FATAL: Module br_netfilter not found` inside LXC container

**Error message:**
```
fatal: [k3s-master]: FAILED! => {"msg": "non-zero return code", "rc": 1,
  "stderr": "modprobe: FATAL: Module br_netfilter not found in directory /lib/modules/7.0.0-31-generic"}
```

**Cause:** LXC containers share the host kernel and have no `/lib/modules` directory. Running `modprobe` inside a container always fails. Kernel modules must be loaded on the HOST via Incus `linux.kernel_modules` config (applied at container start).

**Fix:** Don't run modprobe in containers — verify the module is already loaded via `/sys/module/`:
```yaml
- name: Check br_netfilter module is loaded (via host kernel)
  stat:
    path: /sys/module/br_netfilter
  register: br_netfilter_loaded

- name: Verify br_netfilter is available
  assert:
    that: br_netfilter_loaded.stat.exists
    fail_msg: "br_netfilter not loaded. On host: incus config set <c> linux.kernel_modules=<existing>,br_netfilter && incus restart <c>"
```

**Prevention:** Ensure `linux.kernel_modules` in `main.tf` includes `br_netfilter,overlay,ip_tables,...` for all K3s containers.

---

### ERROR 48: k3s agent fails — `failed to bootstrap cluster data: etcd disabled`

**Error message:**
```
k3s[6971]: level=fatal msg="Error: preparing server: failed to bootstrap cluster data: etcd disabled"
k3s.service: Main process exited, code=exited, status=1/FAILURE
```

**Cause:** The k3s installer created `k3s.service` (server mode) instead of `k3s-agent.service`. CLI flags `--server --token` passed via `sh -s -` don't reliably trigger agent mode. The agent then tries to bootstrap as a server and fails (etcd disabled on agents).

**Fix:**
1. Uninstall broken k3s: `incus exec <worker> -- /usr/local/bin/k3s-uninstall.sh`
2. Use env vars instead of CLI flags (forces agent mode):
```yaml
environment:
  K3S_URL: "https://{{ master_ip }}:6443"
  K3S_TOKEN: "{{ k3s_token }}"
```
3. Remove modprobe ExecStartPre lines from service file (fail in LXC):
```yaml
- name: Remove modprobe ExecStartPre
  lineinfile:
    path: /etc/systemd/system/k3s-agent.service
    regexp: '^ExecStartPre=.*modprobe.*$'
    state: absent
```

**Prevention:** Always use K3S_URL/K3S_TOKEN env vars for agent installs, never CLI flags.

---

### ERROR 49: USB HDD vanishes — `Input/output error` on all writes, `/dev/sda: not a block device`

**Error message:**
```
failed: [k3s-master] => {"msg": "chown failed: [Errno 5] Input/output error"}
lsblk: /dev/sda: not a block device
touch: cannot touch '/srv/efs/shared/testfile': Input/output error
```

**Cause:** Old external USB HDD disconnected under I/O load and reappeared as `/dev/sdb` (Linux reassigns sdX names on reconnect). Host mounts still point to gone `/dev/sda` (stale), container disk devices inherit stale mounts. All writes return EIO while reads (`ls`, `df`) still work from cache.

**Fix:**
```bash
# 1. Lazy-unmount stale mounts
sudo umount -l /srv/efs/shared /srv/efs/k3s-volumes /srv/efs/backups /srv/efs/logs

# 2. Find current device name + UUIDs
sudo blkid /dev/sdb1 /dev/sdb2 /dev/sdb3 /dev/sdb4

# 3. Remount by current name
sudo mount /dev/sdb1 /srv/efs/shared
# ... etc for each partition

# 4. Add permanent UUID entries to /etc/fstab (survives renames + reboots)
UUID=<uuid1> /srv/efs/shared     ext4 defaults,nofail 0 2
UUID=<uuid2> /srv/efs/k3s-volumes ext4 defaults,nofail 0 2
# ... etc

# 5. Restart containers to refresh their mounts
incus restart k3s-master
```

**Prevention:**
- NEVER use `/dev/sdX` in fstab or scripts — always UUID= or LABEL=
- Use `nofail` option so boot doesn't hang if USB is unplugged
- Consider a powered USB hub (old drives brown out under load)
- For production: use internal disk or NAS instead of USB HDD

---

### ERROR 50: Cross-PC worker cannot reach master — `failed to get CA certs: context deadline exceeded`

**Error message:**
```
k3s-worker-2 k3s: level=error msg="Failed to validate connection to cluster at https://10.195.94.80:6443: failed to get CA certs: context deadline exceeded"
```

**Cause:** worker-2 runs on PC2 (different physical network). Master's local Incus bridge IP `10.195.94.80` is not routable from PC2 (same-subnet conflict resolved via Tailscale, but K3s URL still points to local IP).

**Fix:**
1. Install Tailscale inside master container:
```bash
incus exec k3s-master -- bash -c "curl -fsSL https://tailscale.com/install.sh | sh"
incus exec k3s-master -- tailscale up --hostname=k3s-master
# Authenticate via browser URL, then:
incus exec k3s-master -- tailscale ip -4  # e.g. 100.119.206.35
```
2. Set per-worker server URL in `hosts.ini`:
```ini
k3s-worker-2 ansible_host=100.100.13.113 ... k3s_server_url=https://100.119.206.35:6443
```
3. Role uses override with fallback to local IP:
```yaml
k3s_url: "{{ k3s_server_url | default('https://' + hostvars[groups['k3s_master'][0]]['ansible_host'] + ':6443') }}"
```
4. Uninstall broken agent on worker-2, re-run playbook.

**Prevention:** Any K3s node on a different physical network than master must use master's Tailscale IP as server URL.

---

### ERROR 57: Vault sealed at KV-enable time though earlier check said unsealed

**Error message:**
```
URL: POST https://127.0.0.1:8200/v1/sys/mounts/kv — Code: 503, * Vault is sealed
```
(debug task just printed "Unsealed and ready"; Unseal task "skipping").

**Cause (two bugs):**
1. The API-wait task used `until: vault_status.rc in [0, 1, 2]`. `vault status` returns **1 on connection errors** (vault still starting / TLS race) — accepted as success on first try, so init + unseal (gated on `rc == 2`) were skipped while Vault was never actually contacted.
2. Even with a correct early check, Vault **re-seals on every restart** — including the config-change handler restart at the end of the same run. The KV tasks trusted the stale early `vault_status` instead of re-checking.

**Fix:**
- `until: vault_status.rc == 0 or vault_status.rc == 2` — real errors keep retrying.
- Fresh seal re-check + conditional unseal immediately before privileged KV ops.
- Follow-up: removed `ignore_errors` from the wait task — it printed `[ERROR]...ignoring` cosmetics on the legitimate sealed (rc=2) path; persistent failure now fails loudly instead of limping on.

**Live recovery (no re-run needed):** unseal once — KV mounts persist across seals:
```bash
incus exec k3s-vault -- bash -c 'export VAULT_ADDR=https://127.0.0.1:8200 VAULT_SKIP_VERIFY=true; vault operator unseal $(jq -r .unseal_keys_b64[0] /root/vault-init.json)'
```

---

### ERROR 58: Role gets 404 reading a Vault secret that `vault kv get` shows exists

**Error message:** role's fail task ("Vault has no Cloudflare token…") triggers although manual `vault kv get kv/cloudflare` returns the secret.

**Cause:** KV v1 and v2 expose different HTTP APIs. The role used the v1-shaped path `/v1/<mount>/<name>`; the mount is v2, which serves reads only at `/v1/<mount>/data/<name>` (→ 404 on the v1 path) and nests the value at `.data.data.<field>` instead of `.data.<field>`. The `vault` CLI auto-negotiates the version, which is why manual reads worked — raw API calls must pick the path explicitly.

**Fix:** query `/v1/sys/mounts/<mount>` first, read `options.version`, then use the matching read path + JSON pointer (role now handles both).

**Rule:** never hardcode a KV API path — always branch on the mounted engine version.

---

### ERROR 60: `unknown profile k3s` + half-installed Istio never converges

**Error message:**
```
Error: INSTALLATION FAILED: execution error at (istiod/templates/zzz_profile.yaml:31:3): unknown profile k3s
```

**Cause (two bugs):**
1. `--set profile=k3s` — no such profile exists (valid: default, demo, minimal, remote, empty). The repo's `profile-platform-k3s.yaml` is a *values file*, not a selectable profile. K3s is conformant; `default` works.
2. One shared `when: 'istio-base' not in ...` guard gated both releases — after base installed and istiod failed, every re-run skipped istiod forever.

**Fix:** drop the profile flag; check each helm release independently (`'istiod' not in ...` for istiod, etc.).

**Follow-up trap (same ERROR):** the install task kept the old shared guard while only the wait task got the new one — base installed meant istiod install skipped with zero pods present (`helm list` showed just `istio-base`, wait then failed "no matching resources"). Rule: when splitting idempotency guards, change **every** task gated by the old condition (install AND wait), not just one.

---

### ERROR 61: Control-plane pods scheduled cross-PC never become Ready (stretched cluster)

**Symptoms:**
- istiod `0/1 Running`, readiness `503` for many minutes; `kubectl wait` times out.
- `kubectl logs/exec` on that pod: `502 Bad Gateway ... dialing <worker-tailscale-ip>:10250`.
- From the remote worker: `ping 10.43.0.1` (API ClusterIP) 100% loss.
- `bridge fdb show dev flannel.1` lists peer VTEPs as bridge IPs (`10.195.94.x`) unroutable from the other PC (plus stale entries from old subnets).

**Cause:** flannel binds the default interface (`eth0`) and announces bridge IPs as VXLAN VTEPs. Cross-PC, those destinations are blackholes, so all pod-to-pod / pod-to-ClusterIP traffic to/from the remote node fails — including the pod's own init (istiod needs API + webhook paths) and the API server's kubelet proxy. A flapping Tailscale relay (host VPN interference) makes the kubelet link flap on top.

**Immediate mitigation (implemented):** `nodeSelector: kubernetes.io/hostname=k3s-master` patches on istiod + ingress-gateway deployments — control plane and ingress stay on the PC1-local stable network and never depend on the inter-PC link.

**Durable fix (separate maintenance op, needs k3s restarts):**
1. Install + `tailscale up` inside k3s-worker-1 (master and worker-2 already have it).
2. Add `--flannel-iface=tailscale0` to k3s server (master) and both agents' ExecStart (or `/etc/rancher/k3s/config.yaml`), so VTEPs are Tailscale-routable everywhere.
3. Restart k3s on all nodes (master first), verify `bridge fdb` shows `100.x` VTEPs and `ping 10.43.0.1` works from worker-2.
4. Keep the host VPN off (or properly split-tunneled) — VXLAN over a flapping relay stays flaky.

---

### ERROR 62: Pod Pending `Insufficient memory` on a node showing 7% usage

**Error message:**
```
0/3 nodes are available: 1 Insufficient memory, 2 node(s) didn't match Pod's node affinity/selector
```
while `kubectl describe node` shows `memory 140Mi (7%)` requested.

**Cause:** reported usage ≠ schedulable capacity. k3s kubelet carves ~2GB off a 4GB node (system/kube reservations + eviction threshold): capacity 3.8GB but **allocatable only ~1.77GB**. Stock istiod requests 2Gi → 140Mi + 2048Mi > 1766Mi → correctly unschedulable. The scheduler is right; the dashboard percentage misleads.

**Fix:** size requests to the node (`pilot.resources.requests.memory=512Mi`, cpu `250m` — istiod idles ~200–400MB in a lab mesh). After changing values, `helm uninstall <release>` the broken install first — helm won't re-render values on a skipped (already-present) release; the next playbook run then installs fresh and converges.

**Rule:** on small nodes, check `allocatable`, never `capacity` or usage %.

---

### ERROR 63: `kubectl wait` on pod selector poisoned by dying ReplicaSet pods

**Error message:**
```
timed out waiting for the condition on pods/istiod-67d8dc8967-q9nmr
timed out waiting for the condition on pods/istiod-696689cfdb-7dqjq
```
although the new pod (`...-7dqjq`) was `1/1 Running`.

**Cause:** `kubectl wait --for=condition=ready pod --selector=...` watches **every** pod matching the selector — including the Terminating/unready pods of the previous ReplicaSet during/after a rollout. One stale never-Ready pod fails the entire wait even though the deployment itself converged (old RS later scaled to 0 on its own).

**Fix:** after any patch/upgrade that triggers a rollout, wait on the deployment, not the pods:
```bash
kubectl -n <ns> rollout status deployment/<name> --timeout=300s
```
`kubectl wait` on pod selectors remains fine for fresh installs with no predecessor pods.

---

### ERROR 68: Community Branch Plugin JAR 404 — derived tag doesn't exist

**Error message:**
```
fatal: ... "msg": "Request failed", "response": "HTTP Error 404: Not Found",
"url": "https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/26.9.0/..."
```

**Cause:** playbook derived the plugin tag from the SQ version (`<major>.<minor>.0` → `26.9.0`), but the plugin project lags SonarQube by months — latest published is `26.5.0`. Same trap class as the Istio chart lag (#59): release announcements upstream outpace the artifacts you actually download.

**Fix:** pin `sonarqube_plugin_version` explicitly in `group_vars/all.yml`, verified against the GitHub releases API (both JAR + webapp assets exist under the tag). Playbook now uses the pin directly, no derivation.

**Open risk (explicitly accepted):** plugin 26.5.0 on SQ 26.9.0.129388 may fail SQ's plugin version check at startup. The playbook now greps `web.log`/`sonar.log` after startup and prints the evidence. If rejected → set `sonarqube_version: 26.5.0.122743` (newest mutually-supported pair) with a fresh DB and re-run. DB is still virgin (service never started), so switching costs nothing today.

**Rule:** for coupled third-party artifacts, verify BOTH ends exist before pinning — never derive one version from the other.

---

### ERROR 69: sonarqube.service fails `203/EXEC` — nothing in app logs

**Error message:**
```
sonarqube.service: Control process exited, code=exited, status=203/EXEC
```
with zero output in `/opt/sonarqube/logs/`.

**Cause:** systemd `203/EXEC` means the kernel refused to execute the start command itself — SonarQube never ran. Here `bin/linux-x86-64/sonar.sh` was `-rw-r--r--` (unarchive/chown chain dropped `+x`).

**Fix:** `chmod 755` the starter + all bin scripts (playbook task now does this permanently before service creation).

**Rule:** `203/EXEC` ⇒ check the executable bit and shebang *before* reading app logs — there won't be any.

---

### ERROR 73: Cross-PC service migration checklist (SonarQube PC1→PC2 template)

**Context:** moving a service to the other PC. PC2 bridge (`10.195.95.x`) is invisible from PC1 — every consumer (Ansible, Prometheus, browsers, DNS) must be re-pointed, and state must be deliberately moved or abandoned.

**Checklist:**
1. New `incus_instance` resource + vars in `pc2/` (mirror worker2 pattern: privileged as needed, root disk sized, static `.95.x` IP).
2. `tofu apply` **on PC2** (state files are per-PC; never apply pc2/ from PC1).
3. Install openssh in the container, copy controller SSH key (`ssh-copy-id` via PC2 host or Tailscale).
4. Install + `tailscale up` **inside** the container (operator auths the URL); record the `100.x` IP.
5. Point `hosts.ini` `ansible_host` at the `100.x` IP — never the `.95.x` bridge IP.
6. Stateful data: migrate (`pg_dump`/restore) or consciously abandon (virgin DBs: just redeploy).
7. Run the service playbook; verify serving (HTTP/API) before touching the old instance (blue-green).
8. Update DNS records to the new reachable IP; update `group_vars` display/reference IPs.
9. Only then destroy the PC1 instance + clean host leftovers (disk dirs, fstab if dedicated).

---

### ERROR 75: Install gates trust download state, break on fresh/aborted targets

**Error message:**
```
fatal: ... "msg": "Path /opt/sonarqube/conf/sonar.properties does not exist !"
```
with all downloads green (`ok`) and extract/install tasks `skipping`.

**Cause:** gates used only `<download>.changed`. On a fresh container, `/tmp` artifacts can pre-exist from an aborted run (downloads report `ok`), while `/opt/<app>` contains only the empty skeleton the `file` task creates — no code. Every install step skips, then the config step fails on the empty tree.

**Fix:** `stat` the installed artifact (here `bin/linux-x86-64/sonar.sh`) and OR `not <stat>.exists` into every install gate (extract, install, plugin copy, webapp extract). Converged runs are unaffected (stat exists → old behavior).

**Rule:** idempotency gates must check the *destination* state, never just the *source* (download) state.

---

### ERROR 76: HTTPS name points at the app instead of the Gateway ("Unable to connect")

**Symptoms:** browser HTTPS-Only Mode → "Unable to connect" on `https://sonar.<domain>`; `curl -k https://<gateway-ip>/` → `000`.

**Cause (two layers):**
1. DNS aimed at the backend container directly (`100.73.135.124`), where SonarQube serves HTTP on :9000 and nothing listens on 443. TLS termination exists **only** at the Istio Gateway — a name must resolve to the gateway IP (`.100`) for HTTPS to work.
2. The `000` on the bare gateway IP is a red herring: Envoy drops SNI-less connections (IP literal matches no Gateway host). With SNI (`--resolve name:443:ip`) the same gateway returns routed responses (verified: `s3.*` → 200).

**Fix:** DNS name → gateway `.100`; add ServiceEntry (external backend IP, must itself be reachable from the gateway pod — Tailscale, not PC2 bridge) + VirtualService; re-run networking play. Verify with SNI: `curl -sk --resolve sonar.<domain>:443:.100 https://sonar.<domain>/`.

**Post-fix trap:** system resolver can lag authoritative (`1.1.1.1` shows new IP, plain `nslookup` shows old) — a `000` then means stale cache, not a broken route. Split the two with `--resolve` (bypasses DNS entirely): 200 = cluster fine, wait out the cache. Firefox keeps its own DNS cache — restart it after the flip.

---

### ERROR 77: kubectl on K3s workers fails `localhost:8080 refused`

**Error message:**
```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

**Cause:** `k3s agent` installs the `kubectl` binary but **no kubeconfig** — only the server writes `/etc/rancher/k3s/k3s.yaml`. Bare `kubectl` then defaults to `localhost:8080`. (Also note: the `k` alias and friends live only on master via the tools role.)

**Fix:** role slurps master's admin kubeconfig (`delegate_to: master`), rewrites the `server:` line per worker (`k3s_server_url` Tailscale override for cross-PC, LAN IP otherwise), writes `/etc/rancher/k3s/k3s.yaml` + `/root/.kube/config` (0600). Unconditional — pre-existing workers never got one.

**Follow-up trap:** `k3s-agent` (unlike the server install) creates **neither** destination dir — the copy fails with `Destination directory does not exist`. The role now creates both dirs first.

**Follow-up trap 2:** worker-2's kubectl then fails `x509: certificate is valid for
10.195.94.80, ... not 100.119.206.35` — the API serving cert lacks the Tailscale
SAN. Fix: `/etc/rancher/k3s/config.yaml` with `tls-san: [<master-tailscale-ip>]`
(role task, restarts k3s to regenerate serving certs; cluster CA untouched so
agents keep working). If the Tailscale IP ever changes, update
`k3s_master_tailscale_ip` and re-run. **Verified 2026-09-09:** worker-2 `kubectl
get nodes` lists 3/3 after restart; all workloads (istiod, gateway, cert-manager)
healthy post-restart.

---

### ERROR 78: ArgoCD never Ready — missing Secret + pods on wrong node

**Error message:**
```
Warning Failed ... Error: secret "argocd-redis" not found
```
(all of server/repo-server/controller in `CreateContainerConfigError`, everything scheduled on the remote worker).

**Cause (two independent bugs):**
1. Upstream `install.yaml` (verified v2.12.5: 21 references, zero `kind: Secret`) never creates the Secret every workload's `REDIS_PASSWORD` requires. Stock installs hit this whenever the secret wasn't hand-created first.
2. The scheduler spread ArgoCD onto worker-2, where Gateway→pod traffic crosses the flannel blackhole (ERROR 61) — even Ready pods would be unreachable.

**Fix:**
- `create secret generic argocd-redis --from-literal=auth=<random>` guarded by a prior `get` (create-if-missing: stable across re-runs, never rotates).
- `kubectl taint nodes k3s-worker-2 dedicated=remote:NoSchedule --overwrite` (role task) + delete only pods still on that node (replacements land PC1-local; healthy pods untouched).
- Wait on `rollout status deployment/argocd-server` (ERROR 63 lesson), 300s.

**Rule:** infra/control-plane tier defaults to PC1-local nodes; the remote worker is for explicitly-placed workloads only.

**Verified 2026-09-09:** after taint + recycle, all 7 pods 1/1 (3 master + 4 worker-1,
zero remote); `argocd.*` via Gateway → 307 login redirect. Architecture decision
recorded: in-cluster ArgoCD is the production pattern (hub-spoke only at fleet
scale; bastion-VM servers rejected — no install path, worse credential hygiene).

**Follow-up trap:** redis `secret-init` (`argocd admin redis-initial-password`) kept
CrashLooping *after* the Secret existed — because it calls the K8s API **from
inside the pod**, and worker-2 pods can't reach ClusterIPs at all (ERROR 61).
Any in-pod API client fails the same way there. The taint + PC1 reschedule (not
another Secret tweak) is the fix; the pre-created Secret is compatible either way
(redis auth is internal — its value never matters to operators).

---

### ERROR 79: Jaeger restart loop — `bind: address already in use :4317`

**Error message (journal):**
```
could not start OTLP receiver: listen tcp :4317: bind: address already in use
```
(`systemctl`: `activating`, restart counter in the thousands.)

**Cause:** Jaeger all-in-one ≥1.62 ships a built-in OTLP receiver (gRPC :4317 + HTTP :4318) enabled by default. Co-located with the OTel Collector — which owns those industry-standard app-facing ports — the second binder crashes in a 5s restart loop forever.

**Fix:** `--collector.otlp.enabled=false` on Jaeger. Correct pipeline stays: apps → OTel Collector (:4317/:4318) → Jaeger via native gRPC (`:14250`, already the configured exporter endpoint) → UI (:16686).

**Rule:** one OTLP receiver per host. The Collector owns 4317/4318; backends receive via their native protocols.

---

### ERROR 80: MetalLB speaker CrashLoopBackOff on the cross-PC worker

**Error message:** `speaker-xxx 0/1 CrashLoopBackOff (100+ restarts)`, node worker-2.

**Cause:** L2-mode speakers ARP-announce the pool IPs on their local broadcast domain. PC2's LAN is a different broadcast domain — the announcement can never serve the PC1-bridge pool, and the speaker's health path fails in ways that crash-loop it.

**Fix:** `nodeAffinity` (hostname In [master, worker-1]) patch on the speaker DaemonSet. Runs unconditionally in the role because manifest re-applies reset affinity. Same stretched-cluster rule as istiod/gateway/ArgoCD: infra stays PC1-local.

**Follow-up trap:** hand-written merge-patch JSON with one brace too many →
`error decoding patch: invalid character '}' after top-level value`. Validate
inline JSON with `python3 -c "import json; json.loads('...')"` before committing.

---

### ERROR 81: Cosmetic `AlreadyExists` failures pollute every run

**Error message (×4-5 per networking/argocd run):**
```
fatal: ... "stderr": "Error from server (AlreadyExists): namespaces \"X\" already exists"
...ignoring
```

**Cause:** bare `kubectl create namespace` returns rc=1 when the namespace exists. `ignore_errors: yes` keeps the play alive but prints full ERROR blocks, training operators to ignore real failures hiding among them.

**Fix (all 5 occurrences: cert-manager, istio ×3, argocd):**
```yaml
shell: kubectl create namespace X --dry-run=client -o yaml | kubectl apply -f -
changed_when: "'created' in stdout"
```
Exit 0 always; `changed` only on real creation. Verified: speaker pin live (2 fresh Running speakers, CrashLoop gone).

**Rule:** `ignore_errors` on expected states is a smell — restructure to a truly idempotent operation instead.

---

### ERROR 82: ArgoCD `ERR_TOO_MANY_REDIRECTS` behind TLS-terminating Gateway

**Error message (browser):** `argocd.<domain> redirected you too many times` (DNS + TLS + route all healthy).

**Cause:** stock `argocd-server` serves HTTPS and redirects any plain-HTTP request to HTTPS. The Gateway terminates TLS and forwards HTTP — the server redirects, the Gateway forwards again, forever. Verified preconditions: empty `argocd-cmd-params-cm` data + deployment without `--insecure`.

**Fix:**
- Merge-patch `argocd-cmd-params-cm`: `server.insecure=true`, `url=https://argocd.<domain>` (merge preserves other keys; `rollout restart` after).
- VirtualService destination port **80** (the insecure HTTP listener), not 443.
- General rule for any backend behind a terminating Gateway: TLS in exactly one place.

**Verified 2026-09-09:** `https://argocd.<domain>/` → HTTP 200 serving the Argo CD
login HTML via Envoy (earlier 307s were mid-rollout transients, not the loop).

---

### ERROR 83: ArgoCD still accepts only the initial password after writing Vault

**Symptom:** `vault kv put kv/argocd admin_password=...` succeeds (new version), but
login with the new value fails with "Invalid username or password" — only the
initial value works.

**Cause:** nothing reads `kv/argocd` back into ArgoCD. The live credential is the
bcrypt hash in Secret `argocd-secret` (`admin.password` + `admin.passwordMtime`).
Vault is the record, not the mechanism — the rotation must happen inside ArgoCD
first, then the record is updated to match. (Same split-brain lesson as SonarQube.)

**Fix (order matters):**
1. Login with the initial value → user menu → Update password → set the final value.
2. Log out → log back in with the final value (unverified rotations are rumors).
3. Only then overwrite `kv/argocd` with the verified value.
4. Hygiene: service passwords must be unique — never reuse a host/system login;
   destroy superseded Vault versions (`kv destroy` / `metadata delete`) and clear
   shell history that captured plaintext values.

**Why the reverse (ArgoCD → Vault auto-sync) is impossible:** ArgoCD stores only a
one-way bcrypt hash — the plaintext exists solely at the human's fingertips during
rotation, then is gone forever. No watcher can recover it. Automation can only flow
Vault → cluster (Vault as source of truth + External Secrets Operator syncing the
pre-minted bcrypt hash into `argocd-secret`), never the reverse. Proposed as TASK-261.

---

### ERROR 54: nginx-ingress helm install times out, partial release blocks retry

**Error message:**
```
Error: INSTALLATION FAILED: failed pre-install: 1 error occurred:
  * timed out waiting for the condition
```

**Cause:** ingress-nginx pre-install hooks (admission webhook jobs) take longer than Helm's default wait in constrained LXC K3s. Release left in pending/partial state.

**Fix:** Project decision: replace nginx-ingress with Istio Gateway. Clean up leftovers:
```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete ns ingress-nginx --ignore-not-found
kubectl get svc -A | grep LoadBalancer  # confirm .100 is free
```

---

### ERROR 55: cert-manager HTTP-01 challenges never complete (private cluster IPs)

**Symptoms:** `Certificate` stays `Issuing`, `kubectl describe challenge` shows pending HTTP-01 self-checks failing.

**Cause:** HTTP-01 requires Let's Encrypt to fetch `http://<domain>/.well-known/acme-challenge/...` over the public internet. Cluster IPs are RFC-1918 (`10.195.94.x`) — unreachable, so validation can never succeed. Affects any ingress type (nginx or Istio).

**Fix:** DNS-01 via Cloudflare (ownership proven through DNS API, works with private IPs):
- ClusterIssuer solver `dns01.cloudflre.apiTokenSecretRef`
- Token stored in Vault `kv/cloudflare` (field `api_token`), read at playbook runtime
- Wildcard `Certificate` (`*.devops-devsecops.kdns.fr`) consumed by Istio Gateway `credentialName`

---

### ERROR 56: Playbook fails — Cloudflare token not in Vault

**Error message:** role fails with seeding instructions for `kv/cloudflare`.

**Cause:** First run before operator seeds the token. By design: token value never lives in git.

**Fix (once):**
```bash
export VAULT_ADDR='https://10.195.94.200:8200' VAULT_SKIP_VERIFY=true
vault login  # root token from /root/vault-init.json on vault host
vault kv put kv/cloudflare api_token=<token-from-cloudflare-dashboard>
```
Re-run `site-networking.yml`. Token: Cloudflare → My Profile → API Tokens → Create (Edit zone DNS, zone devops-devsecops.kdns.fr).

---

## Summary: All Errors Encountered

| # | Error | Cause | Fix |
|---|-------|-------|-----|
| 1 | `No inventory was parsed` | Wrong directory or missing `-i` | Use `-i inventory/hosts.ini` |
| 2 | `Connection refused` | SSH not installed | `apt install openssh-server` |
| 3 | `Host key verification failed` | Key not in known_hosts | `ssh-keyscan` or StrictHostKeyChecking=no |
| 4 | `Permission denied (publickey,password)` | Key not on remote (fresh images lock root pw) | SSH keys via `setup-ssh-keys.sh` + direct push for fresh images (ERROR 87). Password auth retired — see ERROR 28 |
| 5 | `No route to host` | Same subnet on both PCs | Use Tailscale or different subnets |
| 6 | `Invalid characters in group names` | Hyphens in group names | Use underscores |
| 7 | `Section includes undefined group` | Group name mismatch | Match children to exact group names |
| 8 | `--accept-routes is false` | Tailscale not accepting routes | `tailscale up --accept-routes` |
| 9 | `Device IP not within subnet` | IP on wrong subnet | Update container IP |
| 10 | `Connection timed out` | Wrong IP (local vs Tailscale) | Use Tailscale IP for cross-PC |
| 11 | `Permission denied on fresh containers` | Password not set + PermitRootLogin disabled | Set password + enable PermitRootLogin + restart ssh |
| 12 | `The role 'vault' was not found` | roles_path not configured in ansible.cfg | Add `roles_path = roles` to `[defaults]` |
| 13 | `helm: command not found` | Monitoring role tried to use helm on a VM | Role rewritten to use native binaries |
| 14 | `Prometheus download fails` | Version doesn't exist | Check latest version at github.com/prometheus/prometheus/releases |
| 15 | `http: server gave HTTP response to HTTPS client` | Vault CLI defaults to HTTPS but server is HTTP | Add `VAULT_ADDR: "http://127.0.0.1:8200"` env var |
| 16 | `Failed to find handler for .zip file` | `unzip` not installed on monitoring VM | Install `unzip` before extracting Loki |
| 17 | `Could not match host pattern: k3s_master` | Playbook targets `k3s_master`/`k3s_workers` but inventory only has `k3s_cluster` | Add child groups to hosts.ini |
| 18 | `Failed to start ContainerManager: open /proc/sys/kernel/panic: read-only file system` | `/proc/sys` is read-only in LXC containers; cloud-init services (dev-kmsg, proc-sys-rw) never ran because containers were pre-existing | Manually remount `/proc/sys` + create services + restart k3s. k3s roles now include these tasks automatically. |
| 19 | `Premature end of stream waiting for become success` | `delegate_to: localhost` with `become: false` doesn't override play-level `become: yes` | Use `fetch` module instead of `copy` + `delegate_to` |
| 20 | `object of type 'dict' has no attribute 'exists'` | `stat` module result accessed as `dev_kmsg.exists` instead of `dev_kmsg.stat.exists` | Use `<register_var>.stat.exists` in when conditions |
| 21 | `modprobe br_netfilter/overlay: status 1` | `overlay` module missing from `linux.kernel_modules` in LXC config | Add `overlay` to `linux.kernel_modules` + restart containers |
| 22 | `sysctl: bridge-nf-call-iptables: No such file` | `br_netfilter` module not loaded before sysctl task | Add `modprobe br_netfilter` task before sysctl |
| 23 | `apt_key: command not found` (or deprecated) | Grafana GPG key using deprecated `apt_key` module | Use `get_url` + `apt_repository` with signed-by |
| 24 | MetalLB IPAddressPool never created | Condition `metallb_pool.rc != 0` is false on fresh install (empty output = rc 0) | Change to `metallb_pool.rc != 0 or metallb_pool.stdout == ""` |
| 25 | OTel Collector crashes: `unknown exporter type "loki"` | Standard otelcol binary doesn't include `lokiexporter` | Use `otlphttp/loki` exporter pointing at Loki OTLP endpoint |
| 26 | Vault crashes: `mkdir /opt/vault/data: no such file` | `/opt/vault/data` directory not created before service start | Add `file:` task to create directory |
| 27 | Jaeger fails: `unknown flag --memory.max-traces` | Flag only valid in Jaeger v2.x, not v1.x | Remove `--memory.max-traces` flag |
| 28 | Plaintext passwords in hosts.ini (security) | `ansible_password` stored in git-committed inventory | Remove passwords, use SSH keys + `setup-ssh-keys.sh` |
| 29 | Vault sealed, secrets unavailable | Role installs Vault but never runs `operator init`/`unseal` | Auto-init + auto-unseal tasks added, keys in `/root/vault-init.json` |
| 30 | NFS accessible from any host | Exports use `*` wildcard + `no_root_squash` | Restrict to `10.195.94.0/24` + `100.100.0.0/16` with `root_squash` |
| 31 | Prometheus node-exporter targets down | No role installs node_exporter on K3s nodes | New `node-exporter` role + `site-node-exporter.yml` playbook |
| 32 | `postgresql 16` apt install fails | Invalid syntax `postgresql "{{ pg_version }}"` | Fixed to `postgresql-{{ pg_version }}` |
| 33 | SonarQube DB auth fails on re-run | Password regenerated every run via `openssl rand` | Password stored in `/root/sonarqube-db-password`, reused on re-runs |
| 34 | MetalLB pool gets wrong addresses | `register: metallb_pool` overwrites the IP range variable | Renamed to `metallb_pool_check` |
| 35 | Version skew: master/workers on old K3s | Fallback `default('v1.36.2+k3s1')` mismatches `v1.36.4+k3s1` | Removed fallback, use `{{ k3s_version }}` directly |
| 36 | ArgoCD version changes between runs | Installed from `stable` branch (unpinned) | Pinned to `{{ argocd_version }}` (v2.12.5) in group_vars |
| 37 | MinIO binary changes between runs | Downloaded from `latest` URL (unpinned) | Pinned to `{{ minio_version }}` in group_vars |
| 38 | MinIO health check always fails | Checks console port 9001 (returns 302/403) | Changed to API health endpoint `http://localhost:9000/minio/health/live` |
| 39 | cert-manager/MetalLB/nginx-ingress versions scattered | Versions hardcoded in role tasks | All moved to `group_vars/all.yml` (centralized) |
| 40 | Jaeger runs as root | `User=root` in systemd service | Created `jaeger` system user, service runs as `jaeger:jaeger` |
| 41 | K3s token left in /tmp after playbook | `/tmp/k3s-node-token` persists (world-readable secret) | Added cleanup reminder; delete manually after workers join |
| 42 | LXC fixes duplicated in 2 roles | dev-kmsg + proc-sys-rw copy-pasted in k3s-master and k3s-worker | Extracted to shared `lxc-prerequisites` role |
| 43 | `Unknown configuration key: limits.disk` on tofu apply | `limits.disk` is not a valid Incus config key | Remove from `config {}`, add root disk device with `size` instead |
| 44 | `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` on ssh-copy-id | Containers recreated with new SSH host keys, old keys stale in known_hosts | Run `ssh-keygen -R <ip>` for each container before copying keys |
| 45 | `Permission denied: '/var/cache/ansible'` on ansible run | fact_caching dir not writable by non-root user | Change to `~/.cache/ansible/facts` in ansible.cfg |
| 46 | Tailscale unreachable when ProtonVPN connected (tx>0 rx=0, peers offline) | ProtonVPN kill-switch blocks Tailscale UDP/DERP; Snap v4.18.1 has no split tunneling | ProtonVPN GUI → Settings → Kill Switch → Off (verified fix). VPN still encrypts, Tailscale passes through |
| 47 | `modprobe: FATAL: Module br_netfilter not found` in LXC container | LXC containers share host kernel, have no /lib/modules; modprobe always fails inside | Check /sys/module/<name> exists instead of modprobe; modules load via Incus linux.kernel_modules on host |
| 48 | k3s agent starts as server: `failed to bootstrap cluster data: etcd disabled` | CLI flags `--server --token` didn't trigger agent mode; installer created k3s.service instead of k3s-agent.service | Use K3S_URL + K3S_TOKEN env vars (forces agent mode); uninstall broken k3s first; remove modprobe ExecStartPre from service file |
| 49 | USB HDD disconnects, `chown/touch: Input/output error`, `/dev/sda not a block device` | Old USB drive drops under load, reappears as different device (sda→sdb); host + container mounts go stale; all writes return EIO | Remount by current name, add UUID-based /etc/fstab entries with nofail, restart containers; always use UUID/LABEL never /dev/sdX |
| 50 | worker-2 (PC2) cannot reach master: `failed to get CA certs: context deadline exceeded` | worker-2 on different physical network; master's local bridge IP 10.195.94.80 not routable from PC2 | Install Tailscale in master container, set per-worker `k3s_server_url=https://<master-tailscale-ip>:6443` in hosts.ini for worker-2 |
| 51 | NFS mount fails in unprivileged containers: `mount.nfs: Operation not permitted` | vault/monitoring/sonarqube are unprivileged LXC (no CAP_SYS_ADMIN for NFS mounts); only privileged (master/workers) can NFS mount | Limit nfs-client role to k3s_workers; give unprivileged VMs /srv/efs/* via Incus disk devices (host paths) instead of NFS |
| 52 | K8s tools never install: script skipped, only kubectl present | Role uses `creates: /usr/local/bin/kubectl` but k3s already ships kubectl symlink → whole script skipped, helm/k9s/stern never installed | Remove `creates` guard (script is idempotent via check_tool); use `changed_when` on output instead |
| 53 | worker-2 NFS mounts hang/fail (long timeout) | nfs-client uses `nfs_server_ip` (10.195.94.80, unroutable from PC2) for all workers | Per-host `nfs_server_override=100.119.206.35` (master Tailscale IP) for worker-2, same pattern as k3s_server_url |
| 54 | nginx-ingress helm install times out, partial release left | Pre-install hooks (admission webhook) never become ready in LXC; release stuck pending | `helm uninstall ingress-nginx -n ingress-nginx`; project switched to Istio Gateway instead |
| 55 | cert-manager HTTP-01 never issues certs (private IPs) | Let's Encrypt must reach domain over internet; 10.195.94.x unreachable → challenges pending forever | Use DNS-01 with Cloudflare (token in Vault kv/cloudflare); wildcard cert for Gateway |
| 56 | cert-manager fails: Vault token missing at kv/cloudflare | Token never seeded; role fails fast with instructions | Seed once: `vault kv put kv/cloudflare api_token=<token>` (Vault UI/CLI on vault host), re-run |
| 57 | Vault 503 sealed on KV enable despite "Unsealed" earlier | `until: rc in [0,1,2]` accepts rc=1 (connection error) as success → init+unseal skipped; config-handler restart re-seals after the early status check, KV tasks trust stale state | `until: rc == 0 or rc == 2` (retry real errors); fresh re-check + conditional unseal immediately before privileged KV ops |
| 58 | Vault token "missing" though `vault kv get` shows it (404 from role) | Role hardcoded v1-style API path `/v1/kv/cloudflare`; mount is KV v2 (reads live at `/v1/kv/data/cloudflare`, value at `.data.data`) | Detect engine version via `/v1/sys/mounts/<mount>` (`options.version`), build v1 vs v2 read path + parse shape accordingly |
| 59 | `chart "base" matching 1.31.0 not found in istio index` | Istio 1.31 announced but charts not yet published to Helm repo (latest chart 1.30.4); role pinned a nonexistent version | Pin `istio_version` to latest actually published chart (1.30.4); verify with `helm search repo istio/base --versions` before pinning |
| 60 | `unknown profile k3s` on istiod install + base-ok/istiod-missing never converges | No `k3s` profile exists in istiod chart (vendored profile-platform-k3s.yaml is values, not a profile); shared one-shot guard skipped istiod once base existed | Drop the profile flag (default works on conformant K3s); gate each helm release on its own presence check |
| 61 | Infra pods stuck Unready on cross-PC worker (istiod 503, kubelet 502s) | Flannel bound eth0 → VXLAN VTEPs are unroutable bridge IPs (10.195.94.x); cross-PC pod traffic (incl. ClusterIPs) blackholed; Tailscale relay flaps worsen it | Immediate: nodeSelector-pin control/gateway pods to PC1-local master. Durable (separate op): `--flannel-iface=tailscale0` cluster-wide + Tailscale in worker-1 + stable VPN-off host link |
| 62 | Pinned pod Pending: `Insufficient memory` on a "7% used" node | k3s kubelet reserves ~2GB on 4GB nodes (allocatable ~1.77GB); stock istiod requests 2Gi → never schedules despite low reported usage | Lower requests via helm values (`pilot.resources.requests.memory=512Mi,cpu=250m`); `helm uninstall` the broken release so re-run installs fresh |
| 63 | `kubectl wait pod --selector` times out though new pod is Ready | Selector matches dying pods from the old ReplicaSet too; one never-Ready stale pod poisons the whole wait | After patch/rollout changes, wait on `kubectl rollout status deployment/<name>` (tracks the deployment, immune to stale pods) |
| 64 | Gateway returns 503 for a fresh hostname (TLS + route OK) | 503 = Gateway accepted + VirtualService matched, but backend Service has no endpoints (app not installed yet, or all pods down) | Check backend namespace has Running pods + Service endpoints; 503 with empty namespace is correct behavior, not a mesh fault |
| 65 | Grafana repo `NO_PUBKEY` despite key download task passing | `apt.grafana.com/gpg.key` is ASCII-armored; `signed-by` needs binary (dearmored) keyring — same trap as any apt repo with .gpg path | `curl ... \| gpg --dearmor -o <keyring.gpg>` (vault-role pattern); delete any previously-downloaded armored file first |
| 66 | OTel template `jaeger_grpc_port is undefined` | Role defaults cleanup dropped port vars the template still references | Restore exactly the vars templates consume (`jaeger_grpc_port: 14250`); rule: grep templates before trimming defaults |
| 67 | `chown failed: EPERM` on Incus disk device in unprivileged container | Idmap-shifted mounts deny chown to arbitrary UIDs; same container would also fail sysctl (Elasticsearch needs vm.max_map_count) | Set `security.privileged=true`, then `incus restart` (tofu apply alone completes in 0s without restarting — live uid_map stays shifted until restart); verify with `/proc/self/uid_map` showing `0 0 4294967295` |
| 68 | Plugin JAR 404: derived version doesn't exist upstream | Playbook built plugin tag as `<sq_major>.<sq_minor>.0` (26.9.0) but latest published plugin is 26.5.0 — plugin lags SQ by months | Pin `sonarqube_plugin_version` explicitly in group_vars (verified against GitHub releases API); never derive it from the SQ version |
| 69 | sonarqube.service `203/EXEC`, never starts (no app logs at all) | `sonar.sh` lost its +x through download/extract/chown chain; systemd can't exec it | `chmod 755 bin/linux-x86-64/sonar.sh` (+ all bin .sh); playbook task added permanently |
| 70 | Downgrading SQ (26.9→26.5): new version refuses DB + plugin files vanish | SQ never downgrades schemas (DB migrated by 26.9 boot); version switch rm-rfs /opt/sonarqube but plugin-install tasks gated only on plugin-download change | DROP+CREATE the virgin DB; gate plugin install/extract on `sq_download.changed` too; settled on matched pair SQ 26.5.0.122743 + plugin 26.5.0 |
| 71 | Version switch silently kept old code: download `ok`, install skipped | Fixed dest filename (`/tmp/sonarqube.zip`) reused across versions + a 946MB mangled artifact; get_url reported ok instead of re-downloading | On version changes: delete stale `/tmp` artifacts first (zip/jar), stop the service, wipe the virgin DB; verify with `unzip -l` top-level dir + lib jar names, not task colors |
| 72 | SonarQube HTTP timeouts on 2GB box despite green playbook | Fresh SQ 26.5 + ES + PG idles ~1885/1907MB (JVM thrashing, 8s GC pauses); usage-% looks "fine" until requests queue behind GC | Raise `sonarqube_memory` to 2.5GB (operator decision; ~600MB headroom, re-measure under load); limit changes need container restart; verify with fast HTTP 200 + `free` headroom, not just service active |
| 73 | Migrating a service PC1→PC2: unreachable, DNS stale, state lost | PC2 bridge (10.195.95.x) invisible from PC1; DNS points at old IP; stateful data lives on PC1 disks | Checklist: new pc2 resource + vars → tofu apply on PC2 → SSH + keys + in-container Tailscale → ansible_host=new 100.x → fresh deploy (or pg_dump migrate if state matters) → verify serving → update DNS → destroy old |
| 74 | PC2 tofu apply: `Invalid value: 2.5GB` + `Cannot update root disk pool to default` | Older Incus rejects fractional sizes (use integer MB); adding explicit root device conflicts with profile-provided disk (pool rewrite refused) | Memory `2560MB` (=2.5GiB) in both pc1/pc2 vars; no explicit root block on pre-existing containers (only on new resources) |
| 75 | `sonar.properties does not exist` on fresh container despite green downloads | Gates assumed download-unchanged ⟹ installed; but /tmp artifacts survived an aborted run while /opt held only the empty skeleton dirs | Stat the installed artifact (`sonar.sh`) and OR it into every install gate (extract, install, plugin copy/extract) |
| 76 | Browser "Unable to connect" on `sonar.*:443` though DNS resolves | DNS pointed at the app container's Tailscale IP, where nothing listens on 443 (SonarQube is :9000 HTTP); TLS lives only at the Istio Gateway | Point the name at the gateway IP (.100) + add ServiceEntry/VirtualService for the external backend; SNI-less IP-literal curl 000 from Envoy is normal |
| 77 | `kubectl` on workers: `localhost:8080 refused` | K3s agents ship no kubeconfig (only the server has one); kubectl defaults to localhost | Distribute master's admin `k3s.yaml` to workers with per-worker server URL rewritten (Tailscale URL for cross-PC via `k3s_server_url`); runs unconditionally (old workers lack it) |
| 78 | ArgoCD pods `CreateContainerConfigError`: `secret argocd-redis not found` + all pods on cross-PC node | Upstream manifests reference the Secret 21x but never create it; scheduler spread infra pods onto the flaky remote worker | Create-if-missing `argocd-redis` (random auth, stable); taint remote node `dedicated=remote:NoSchedule` + recycle misplaced pods; wait via `rollout status` |
| 79 | Jaeger restart loop (#2738): `bind: address already in use :4317` | Jaeger ≥1.62 enables a built-in OTLP receiver by default, colliding with the OTel Collector on the same host | `--collector.otlp.enabled=false` on Jaeger; pipeline stays apps → OTel (:4317) → Jaeger gRPC (:14250) → UI |
| 80 | MetalLB speaker CrashLoop on cross-PC worker (100+ restarts) | L2 ARP announcements can't cross PCs; the remote speaker can never serve PC1-bridge IPs | nodeAffinity-pin speaker DaemonSet to PC1-local nodes (re-applied manifests reset it, so patch runs unconditionally) |
| 81 | Recurring `AlreadyExists` ERROR noise on `kubectl create namespace` | Bare create fails rc=1 when ns exists; `ignore_errors` hides it but prints scary ERROR blocks every run | `kubectl create ns X --dry-run=client -o yaml \| kubectl apply -f -` with `changed_when: 'created' in stdout` — true idempotency, honest changed flags (also applied to `site-apps.yml` application ns) |
| 82 | ArgoCD `ERR_TOO_MANY_REDIRECTS` behind Istio Gateway | Gateway terminates TLS but server still HTTPS-only: per-request http→https redirect loops through the Gateway | `server.insecure=true` + `url` in `argocd-cmd-params-cm` (merge patch); VirtualService targets port **80**; rollout restart |
| 83 | ArgoCD still accepts only the initial password after `vault kv put kv/argocd` | Vault is a documentation store, not wired to ArgoCD: writing `kv/argocd` changes nothing inside the cluster; the live hash stays in Secret `argocd-secret` until rotated via UI/API | Rotate in ArgoCD first (login with initial → Update password → verify new login), THEN overwrite `kv/argocd`; never reuse a host/system password for service accounts; destroy superseded Vault versions |
| 84 | Convergence run fails at "Get ArgoCD initial password" (NotFound) | Task hard-gets a secret the operator correctly deleted post-rotation; the correct end state breaks the run | Check-first pattern (`failed_when: false` + rc-gated message — `ignore_errors` still prints a scary block): report the password when present, report "rotation done" when absent |
| 85 | PC2 `tofu plan` from PC1 shows "4 to add" incl. existing worker2/sonarqube | Incus provider talks to the LOCAL daemon + local state: PC1 knows nothing of PC2's instances, so it plans duplicates (wrong bridge, IP conflicts, phantom creates) | NEVER apply cross-PC plans. Sync files to PC2, run `tofu plan` THERE (state knows existing → only true creates). `tofu test` takes no `-out` flag — that error is just a typo, ignore it |
| 86 | Vault `Sealed true` after Incus memory-limit change + wait task dies on rc=2 (`attempts: 1`, unseal never runs) | Any container restart re-seals Vault (seal is in-memory); then the wait task's `until` misfired on the sealed state and killed the play before the unseal task | Wait task uses `failed_when: false` + explicit fail gate (rc not in 0/2 = API truly down); sealed flows into the existing unseal task. Lesson: every Incus config apply on the Vault host is followed by a seal check |
| 87 | Fresh ubuntu-noble container: SSH "Connection refused" + `ssh-copy-id` impossible | Image ships NO openssh-server (nothing listens on :22) and locks root's password (any password prompt can never succeed) | `incus exec`: apt install openssh-server + enable --now ssh; push key directly to /root/.ssh/authorized_keys (0700/0600), never ssh-copy-id on fresh images |
| 88 | `cat ~/.ssh/id_ed25519.pub` → "No such file" on PC2 controller | PC2's user never generated a keypair (only PC1 has one); key push from PC2 is impossible without the public key present | `scp` PC1's `id_ed25519.pub` to PC2 /tmp first, then `incus exec` push per container, then `rm` the temp copy. Companion rule: `incus exec <pc2-name>` on PC1 → "Instance not found" is proof of wrong PC, not a bug |
| 89 | Ansible `user:` fails "Group git does not exist" | The `user` module never creates a named primary group — `group:` must pre-exist | Explicit `group:` task (system: yes) before the `user:` task, every role, every time |
| 90 | GPG verify fails: `"&&" not a key ID: skipping` (key imports, verify never runs) | `command:` runs NO shell — `&&` and everything after it became key-ID arguments to the first gpg | One shell operator per task: split recv-key and verify into two `command:` tasks (or use `shell:` deliberately) |
| 91 | git user gets `stat app.ini: permission denied` right after locking it | Jinja binds filters tighter than `==`: `item == '/x' \| ternary(a,b)` evaluates the ternary FIRST (always truthy→a), comparison second — dir/file bits silently mis-assigned, dir lost group-x | Never compute modes in ternaries: explicit `file:` task per path with literal modes |
| 92 | Forgejo CLI `CreateUser: name is reserved [name: admin]` | Forgejo 16 reserves `admin` as a username for CLI creation | Admin username is a visible var (`forgejo_admin_user: sysadmin`); check/create/debug tasks all reference it, never hardcoded |
| 93 | Runner version resolves empty → all downloads silently skip (`forgejo-runner--linux-amd64`) | Missing `jq` + no `pipefail` (dead curl exits 0 via cut) + truthiness gate on `is changed` masks the failure | Install curl+jq; `set -o pipefail` + `failed_when` on empty stdout (fail loud); gate downloads on `stdout length > 0`. pipefail needs `executable: /bin/bash` — default `/bin/sh` is dash (`Illegal option -o pipefail`) |
| 94 | Register fails `token is empty` though the file has content (`cat: Permission denied`) | Token staged root-only under `/root` (0700 dir): the `runner` user can't traverse, let alone read — `$(cat)` yields empty | Stage a runner-owned copy (`/home/runner/.runner-token`, 0400) as root, register against the copy; original stays untouched |
| 95 | Register fails `runner registration token not found` (server ping OK) | Pasted value isn't a runner registration token: API token, UUID, stale token, or partial copy — server reached fine, credential rejected | Token must come from Admin → Actions → Runners → Create new runner dialog (Token field, not UUID); shape-test without exposing it: `grep -Eq '^[0-9a-f]{40}$' file && echo SHAPE-OK \|\| echo SHAPE-BAD` (genuine secrets are 40-char hex; a 20-char mixed-case value is proof of wrong field/fragment — re-copy exactly, recreate dialog if unsure) |
| 96 | Register fails `token is empty` though verification showed content minutes before | A later aborted `cat >` re-hollowed the source AFTER the check; staging faithfully copies the new emptiness | Verify-then-run with nothing in between; role now gates with `test -s` (plain failure) before the binary's cryptic one |
| 97 | UI token copy-paste fails 5 rounds (wrong fields, stale tokens, hollow files) — unfixable by retrying | Browser→clipboard→terminal chain has no verification until registration; every failure mode looks identical server-side (`token not found`) | Eliminate the chain: server mints global tokens via `forgejo-cli actions generate-runner-token` (empty scope); runners fetch via slurp+copy with `no_log`; UI path retired to fallback. Secrets never touch chat/clipboards |
| 98 | Alloy crash-loop: `unrecognized block stage.label_allow` + `loki.source.kubernetes missing targets` | Invented a River stage name; log source needs explicit discovery targets (no implicit pod discovery) | No `stage.label_allow` (use `labeldrop` later if needed); wire `targets = discovery.kubernetes.pods.targets` into the source. ConfigMap edits need `rollout restart` — pods never pick up config changes alone |
| 99 | Alloy remote-write 404: `remote write receiver needs to be enabled` (KSM data never lands) | VM Prometheus ships without `--web.enable-remote-write-receiver` (receive path is opt-in) | Flag in `prometheus.service.j2`; re-run site-monitoring (30s metrics gap on restart, accepted) |
| 100 | Alloy tails/scrapes cross-PC pods → kubelet 502 + wasted retries (worker-2 unreachable via PC1 API proxy) | Cluster-wide pod discovery on a stretched cluster: every Alloy attempts every pod incl. unroutable ones (ERROR 61 family in observability) | Node-scope discovery: `discovery.relabel` keep `__meta_kubernetes_pod_node_name == sys.env(NODE_NAME)` (downward API); both log source and annotated scrape consume the filtered output |
| 101 | Alert rules template dies: `unexpected char '$'` (Prometheus `{{ $labels }}` vs Jinja `{{ }}`) | Both languages claim double-braces; Jinja wins the parse and chokes on `$` | Wrap Prometheus annotations in `{% raw %}…{% endraw %}` — audit every template mixing both syntaxes. FOLLOW-ON: end-of-line `%}` gets its newline eaten by Ansible's `trim_blocks` (72-restart crash loop, joined summary+runbook lines) — wrap MID-LINE only (`"…{% raw %}…{% endraw %}"`), never end a line with `%}`. Local render tests must use `trim_blocks=True` or they prove nothing |
| 102 | Blackbox probes catch 2 bad targets on first run (`:8888/metrics`, Vault `http://:8200`) | Assumed exporter ports from memory; probed a TLS-only port with plain HTTP | Read exporter ports from the role config (OTel pipeline metrics live on :8889, not :8888); TLS-only origins get an `https_insecure` module (verify skipped, LAN hop). Probes earning their keep: design targets from configs, not memory |
| 103 | Vault play fails apt cache update (empty error) though network + `apt-get update` task pass | HashiCorp rotated signing key (old 798A → FC9CA9); `creates:`-guarded key download froze the stale keyring; apt module fails the run on the unsigned repo while bare apt-get only warns | Check-then-remove pattern (grep key id, delete on mismatch — ERROR 65 family) before the guarded download; verify with `promtool`-style direct evidence (`apt-get update` output + `gpg --show-keys`) |
| 104 | Grafana local `admin` login fails though `grafana_password` looks right | `admin_password` in grafana.ini applies ONLY at first DB init — later file changes never touch the live hash; the group_vars value drifted from reality long ago (pre-existing debt, not caused by OAuth) | Reset truthfully: `grafana-cli --homepath /usr/share/grafana admin reset-admin-password` on the VM (homepath flag mandatory — without it: "Could not find config defaults"; omit the value for an interactive prompt, keeps it out of shell history), store the real value in Vault `kv/grafana`, never trust the ini value again. FOLLOW-ON: rejected values change NOTHING (live hash untouched) — yet the same value still got recorded to Vault v1, manufacturing split-brain (ERROR 83 again). Rule: UI-verify FIRST, `kv put` SECOND, destroy dead versions; value must satisfy Grafana policy (long, mixed classes, non-dictionary) |
| 105 | First SSO login dies: `Failed to create user, signup is not allowed` (handshake itself 302-OK) | Two stacked causes: (1) my own provider block carried `allow_sign_up = false`; (2) in v13 ONLY the provider-level flag governs OAuth creation — the global `[users]` setting does NOT cascade (docs-verified) | `allow_sign_up = true` INSIDE `[auth.generic_oauth]` (+ `auto_assign_org_role = Viewer` for read-only landing). Server log (`user.sync ... signup-disabled`) distinguishes this from bad-credential failures |
| 106 | ArgoCD SSO button dead: `/api/dex/*` 404s though dex configured+restarted | argocd-server builds dex proxy routes at BOOT; patching dex.config later leaves them 404ing (server pod predated connector by 28h — proven by pod ages) | Restart argocd-server whenever dex config changes (gated on same patch condition); verify with direct ClusterIP `http://:80/api/dex/login` (bypasses Gateway) before touching anything else |
| 107 | Same 404 AFTER restart: server boots `url: ` EMPTY + dex "not configured" though both ConfigMaps hold content | v2.12.5 does not merge `url` from argocd-cmd-params-cm into settings; empty URL fails IsDexConfigured first AND nils dex's generated config (test file proves URL-required) — one invisible string starved both daemons | Write `url` into argocd-cm directly (belt+suspenders); extend restart gate to url changes; verify via boot line (`sso: true`) — the single ground truth, not ConfigMap dumps |
| 108 | SonarQube SSO init fails `Connection timed out` (browser path works, server path dead) | Stretched cluster: IdP discovery/token/userinfo are SERVER-to-server calls from the PC2 box to a PC1-LAN URL (unroutable bridge blackhole, ERROR 61/73 family). Browser reaching Forgejo proves nothing about server reachability | Tailscale subnet routes: PC1 advertises LAN (`--advertise-routes` + admin-console approval), PC2 containers `--accept-routes`; verify FROM the SonarQube box (`curl` discovery URL → 200) before retrying login |
| 109 | Forgejo rejects with Unregistered Redirect URI though registered URI "matches" | `context.getCallbackUrl()` returned an IdP-host URL (forgejo host, not sonar host — proven by Forgejo's rejection log echoing the sent redirect_uri); core-derived value untrusted on 26.x, mechanism unconfirmed | Build callback explicitly: `sonar.core.serverBaseURL` (trimmed) + `/oauth2/callback/<key>`; verify by reading the IdP-side log's echoed redirect_uri, not by eyeballing two strings |
| 110 | Fixed plugin code has zero effect after redeploy (old behavior persists, no errors) | SonarQube skips same-name/same-version JARs ("No plugin change detected") and serves stale classes indefinitely | Bump `<version>` on EVERY redeploy (1.0.0 → 1.0.1-SNAPSHOT …); verify the new Deploy line + version in logs before testing behavior |
| 111 | OAuth callback points at the IdP itself though code builds it "correctly" | `sonar.core.serverBaseURL` field held the FORGEJO url (cross-wired while filling two similar URLs); every derived callback inherited it — invisible in code review, only runtime values tell | Self-logging inputs at init (URLs only, never secrets); read them before theorizing. Verify base URL reads the SONAR host; screenshots of "set" fields prove nothing about their content |
| 112 | Vault OIDC `Invalid role` in UI while server log says issuer mismatch (trailing slash) | `oidc_discovery_url` had a trailing `/`; Go-OIDC byte-compares against the provider-advertised issuer (no slash) — one character kills provider creation. UI text misleads; server log tells truth | No trailing slash on discovery/issuer URLs, ever; diagnose OIDC from server logs, never UI wording |

---

## Quick Reference Commands

### Test Connectivity
```bash
# Test all nodes
ansible all -m ping -i inventory/hosts.ini

# Test specific group
ansible k3s_master -m ping -i inventory/hosts.ini
ansible k3s_workers -m ping -i inventory/hosts.ini
ansible k3s_cluster -m ping -i inventory/hosts.ini
ansible vault_server -m ping -i inventory/hosts.ini
ansible monitoring_server -m ping -i inventory/hosts.ini
ansible sonarqube_server -m ping -i inventory/hosts.ini

# Verbose output
ansible all -m ping -i inventory/hosts.ini -vvvv
```

### Run Commands on All Nodes
```bash
ansible all -m shell -a "hostname" -i inventory/hosts.ini
ansible all -m shell -a "apt update" -i inventory/hosts.ini
```

### Check Inventory
```bash
ansible-inventory --list -i inventory/hosts.ini
ansible-inventory --graph -i inventory/hosts.ini
```

### Install SSH on Fresh Container
```bash
incus exec <container> -- bash -c "apt update && apt install -y openssh-server && systemctl enable --now ssh"
incus exec <container> -- bash -c "echo 'root:RAFAA' | chpasswd && sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && systemctl restart ssh"
```

---

## Container Final State

| Container | PC | IP | Method | CPU | RAM | Status |
|-----------|----|-----|--------|-----|-----|--------|
| k3s-master | PC1 | 10.195.94.80 | Direct Incus bridge | 4 | 4GB | RUNNING |
| k3s-worker-1 | PC1 | 10.195.94.81 | Direct Incus bridge | 3 | 4GB | RUNNING |
| vault | PC1 | 10.195.94.200 | Direct Incus bridge | 2 | 750MB (trimmed 2026-09-09) | RUNNING, unsealed |
| monitoring | PC1 | 10.195.94.210 | Direct Incus bridge | 2 | 4GB | RUNNING |
| k3s-worker-2 | PC2 | 100.100.13.113 | Tailscale in container | 2 | 4GB | RUNNING |
| sonarqube | PC2 | 100.73.135.124 | Tailscale in container (migrated PC1→PC2) | 2 | 2560MB | RUNNING |
| forgejo-ci | PC2 | 100.88.159.38 | Tailscale in container (TASK-262) | 2 | 4GB | RUNNING (Forgejo 16.0.3 + ci-light registered) |
| runner-1 | PC2 | 100.113.54.77 | Tailscale in container (TASK-262) | 2 | 3GB | RUNNING (runner v13.1.0 ci-heavy registered) |

---

## Sync Rule

After ANY update to files in `~/Videos/Store-App_Soruce_Code-GitHub/`, run:

```bash
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

This keeps PC1 and PC2 in sync. Always sync before running `ansible` on PC2.

---

*Troubleshooting guide created from actual errors encountered during setup.*
*Last Updated: 2026-09-12 — 113 errors (+ duplicate plugin JARs abort startup disguised as stops). Networking play verified zero-ERROR output (failed=0 ignored=0). Speaker pin verified live (2 Running, CrashLoop gone). SonarQube migration PC1→PC2 DONE (PC1 instance destroyed via tofu; survivor 100.73.135.124 serves HTTP 200 + plugin loaded). Leftover: host /srv/rds-data holds orphaned postgres data (archive or delete); sonar.* DNS → gateway .100 DONE and verified 200; SonarQube ServiceEntry/VS live. Component homes: `../sonarqube/`, `../vault/`, `../monitoring/`, `../networking/`, `../storage/`, `../k3s/`, `../argocd/` (each: state, flow, verify, error catalog). TASK-257 closed: sonar.* live, admin password rotated + confirmed + in Vault. Next: TASK-258 ArgoCD.*
