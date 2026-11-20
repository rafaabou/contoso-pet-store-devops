# Ansible Complete Guide

## Table of Contents

1. [What Is Ansible](#1-what-is-ansible)
2. [Why Use Ansible](#2-why-use-ansible)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide (Step-by-Step)](#6-usage-guide-step-by-step)
7. [Custom Modules and Plugins](#7-custom-modules-and-plugins)
8. [Integration](#8-integration)
9. [Security](#9-security)
10. [Troubleshooting (20 Issues)](#10-troubleshooting)
11. [Tips and Best Practices (20 Tips)](#11-tips-and-best-practices)
12. [Command Reference](#12-command-reference)
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

# 1. What Is Ansible

Ansible is an open-source automation platform for configuration management, application deployment, and infrastructure orchestration. Created by Michael DeHaan in 2012 and acquired by Red Hat in 2015, Ansible uses agentless SSH-based communication and YAML playbooks to automate IT tasks.

## 1.1 History

- **2012**: Created by Michael DeHaan (also created Cobbler)
- **2013**: First public release (v0.9)
- **2015**: Acquired by Red Hat
- **2016**: Ansible 2.0 (modern architecture)
- **2019**: Ansible 2.9 (collection framework)
- **2020**: Ansible 2.10 (collections split from core)
- **2021**: Ansible Core 2.11+ (ansible-core separate package)
- **2023**: Ansible Core 2.15+ (Python 3.9+ only)

## 1.2 Architecture

```
┌─────────────────────────────────────────────┐
│              Control Node                    │
│  ┌────────────┐  ┌──────────────────────┐   │
│  │  ansible   │  │  ansible-core        │   │
│  │  command   │  │  (python library)    │   │
│  └─────┬──────┘  └──────────┬───────────┘   │
│        │                    │                │
│  ┌─────┴────────────────────┴───────────┐   │
│  │     Connection Methods               │   │
│  │  SSH / WinRM / Local / Local SSH     │   │
│  └──┬────────┬────────┬────────┬────────┘   │
│     │        │        │        │            │
│   target  target  target  target           │
│   host_1  host_2  host_3  host_4           │
└─────────────────────────────────────────────┘
```

Key architectural points:
- **No agent required** on managed nodes
- **Push-based** execution model
- **Idempotent** operations (safe to re-run)
- **Declarative** (describe desired state) and **procedural** (execute tasks in order)
- **Extensible** via modules, plugins, and collections

## 1.3 Key Features

- **Agentless**: Only requires SSH and Python on target hosts
- **Idempotent**: Running the same playbook twice produces the same result
- **YAML Playbooks**: Human-readable automation definitions
- **Vast Module Library**: 3,500+ modules covering cloud, networking, databases, etc.
- **Role Architecture**: Reusable, shareable automation components
- **Inventory Management**: Dynamic and static host inventories
- **Variables and Facts**: Runtime data collection and manipulation
- **Templates**: Jinja2-based templating for configuration files
- **Handlers**: Conditional task execution based on state changes
- **Vault**: Built-in secrets encryption

---

# 2. Why Use Ansible

## 2.1 The Problem Ansible Solves

Modern IT environments face:
- **Snowflake servers**: Every server configured differently
- **Configuration drift**: Manual changes accumulate over time
- **Scaling challenges**: Can't manually configure 100+ servers
- **Cross-platform complexity**: Windows, Linux, cloud, on-prem
- **Orchestration needs**: Multi-tier application deployments

## 2.2 Benefits

| Benefit | Description |
|---------|-------------|
| **No Agent** | Only SSH + Python required on targets |
| **Low Learning Curve** | YAML is human-readable |
| **Idempotent** | Safe to re-run without side effects |
| **Extensible** | Modules for everything (cloud, DB, network) |
| **Low Overhead** | No daemons, no databases, no infrastructure |
| **Multi-Platform** | Linux, Windows, network devices |
| **Agentless** | No software to install/maintain on targets |
| **Push-Based** | Immediate execution, no pull intervals |
| **Community** | 6,000+ modules, thousands of roles |

## 2.3 When to Use Ansible

**Good fit:**
- Configuration management of servers
- Application deployment
- Compliance and security hardening
- Network automation
- Cloud provisioning (complementary to Terraform)
- Orchestration of multi-step processes

**Not ideal:**
- High-frequency data streaming
- Real-time monitoring
- Complex state machines
- Environments without SSH/WinRM access

## 2.4 Ansible vs. Other Tools

| Tool | Agent | Language | State | Best For |
|------|-------|----------|-------|----------|
| Ansible | Agentless | YAML | None (idempotent) | Config management, orchestration |
| Chef | Agent (chef-client) | Ruby DSL | Chef Server | Large-scale, programmatic |
| Puppet | Agent (puppetd) | Puppet DSL | Puppet Server | Enterprise, compliance |
| SaltStack | Agent (minion) | YAML/Python | Salt Master | Event-driven, large scale |
| Terraform | N/A | HCL | State file | Resource provisioning |

---

# 3. Installation

## 3.1 Prerequisites

- **Python**: 3.9 or later (on control node)
- **SSH**: OpenSSH client with key-based auth
- **Target hosts**: Python 2.7+ or 3.5+ (for most modules)

## 3.2 Install on Linux

### Using pip (Recommended)

```bash
# Install Ansible
pip install ansible

# Or install with specific version
pip install ansible-core==2.16.0

# Install extras
pip install ansible[extra]
```

### Using Package Manager (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

### Using Package Manager (RHEL/CentOS/Fedora)

```bash
# Fedora
sudo dnf install ansible

# RHEL/CentOS 8+
sudo dnf install epel-release
sudo dnf install ansible
```

### Using pipx (Isolated Environment)

```bash
pipx install ansible-core
```

## 3.3 Install on macOS

```bash
# Homebrew
brew install ansible

# Or via pip
pip install ansible
```

## 3.4 Install on Windows

```powershell
# WSL2 (recommended)
wsl --install
pip install ansible-core

# Or native Windows (limited functionality)
pip install ansible-core
```

## 3.5 Install via Docker

```bash
# Pull the official image
docker pull quay.io/ansible/ansible-runner:latest

# Run ad-hoc command
docker run --rm -it quay.io/ansible/ansible-runner:latest \
  ansible all -m ping -i "myhost,"

# Mount playbooks
docker run --rm -it \
  -v $(pwd)/playbooks:/playbooks \
  quay.io/ansible/ansible-runner:latest \
  ansible-playbook /playbooks/site.yml -i "myhost,"
```

## 3.6 Verify Installation

```bash
ansible --version
# ansible [core 2.16.0]
#   config file = /etc/ansible/ansible.cfg
#   configured module search path = ['/home/user/.ansible/plugins/modules']
#   ansible python module location = /usr/lib/python3.11/site-packages/ansible
#   python version = 3.11.0

pip show ansible-core
```

## 3.7 Install Collections

```bash
# Install a collection
ansible-galaxy collection install community.general

# Install from requirements file
ansible-galaxy collection install -r requirements.yml

# List installed collections
ansible-galaxy collection list
```

## 3.8 Shell Completion

```bash
# Bash
echo "complete -C /usr/local/bin/ansible-console ansible-console" >> ~/.bashrc

# Zsh - add to ~/.zshrc
autoload -U +X bashcompinit && bashcompinit
```

---

# 4. Configuration

## 4.1 Configuration File Locations (Priority Order)

1. `ANSIBLE_CONFIG` environment variable
2. `./ansible.cfg` (current directory)
3. `~/.ansible.cfg` (home directory)
4. `/etc/ansible/ansible.cfg` (system-wide)

## 4.2 Basic ansible.cfg

```ini
[defaults]
inventory = ./inventory
remote_user = ansible
private_key_file = ~/.ssh/ansible_key
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600
log_path = /var/log/ansible.log
timeout = 30
forks = 20
nocows = 1
stdout_callback = yaml
callback_whitelist = timer, profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null
```

## 4.3 Inventory Configuration

### Static Inventory (INI)

```ini
# inventory/hosts.ini

[webservers]
web1 ansible_host=10.0.1.10
web2 ansible_host=10.0.1.11

[dbservers]
db1 ansible_host=10.0.2.10

[all:vars]
ansible_user=deploy
ansible_ssh_private_key_file=~/.ssh/deploy_key

[webservers:vars]
http_port=80
max_clients=200

[dbservers:vars]
db_port=5432
db_name=production
```

### Static Inventory (YAML)

```yaml
# inventory/hosts.yml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 10.0.1.10
        web2:
          ansible_host: 10.0.1.11
      vars:
        http_port: 80
    dbservers:
      hosts:
        db1:
          ansible_host: 10.0.2.10
      vars:
        db_port: 5432
  vars:
    ansible_user: deploy
```

### Dynamic Inventory Script

```python
#!/usr/bin/env python3
# inventory/aws_ec2.py

import json
import boto3

ec2 = boto3.client('ec2')

def get_inventory():
    response = ec2.describe_instances()
    hosts = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            if instance['State']['Name'] == 'running':
                hosts.append(instance['PrivateIpAddress'])
    return {"_meta": {"hostvars": {}}}

print(json.dumps(get_inventory()))
```

## 4.4 Group Variables

```
inventory/
  hosts.yml
  group_vars/
    all.yml
    webservers.yml
    dbservers.yml
  host_vars/
    web1.yml
    db1.yml
```

```yaml
# group_vars/all.yml
ansible_user: deploy
ntp_server: ntp.example.com

# group_vars/webservers.yml
http_port: 80
nginx_worker_processes: 4

# host_vars/web1.yml
ansible_host: 10.0.1.10
http_port: 8080
```

---

# 5. Core Concepts

## 5.1 Ad-Hoc Commands

Run one-off tasks against hosts:

```bash
# Test connectivity
ansible all -m ping -i inventory/hosts.ini

# Run a command
ansible webservers -m shell -a "uptime" -i inventory/hosts.ini

# Install a package
ansible webservers -m apt -a "name=nginx state=present" -i inventory/hosts.ini --become

# Copy a file
ansible webservers -m copy -a "src=app.conf dest=/etc/nginx/app.conf" --become

# Gather facts
ansible webservers -m setup -i inventory/hosts.ini
```

## 5.2 Playbooks

Playbooks are YAML files defining automation tasks:

```yaml
# playbook.yml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    max_clients: 200

  tasks:
    - name: Ensure nginx is installed
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Copy nginx configuration
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
      notify: Restart nginx

    - name: Ensure nginx is running
      service:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

## 5.3 Roles

Roles organize playbooks into reusable components:

```
roles/
  nginx/
    tasks/
      main.yml
    handlers/
      main.yml
    templates/
      nginx.conf.j2
    files/
      index.html
    vars/
      main.yml
    defaults/
      main.yml
    meta/
      main.yml
```

```yaml
# roles/nginx/tasks/main.yml
---
- name: Install nginx
  apt:
    name: nginx
    state: present

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Restart nginx

- name: Ensure nginx is running
  service:
    name: nginx
    state: started
    enabled: yes
```

```yaml
# playbook.yml using role
---
- hosts: webservers
  become: yes
  roles:
    - nginx
    - { role: monitoring, tags: ['monitoring'] }
```

## 5.4 Variables

```yaml
# Variable precedence (lowest to highest):
# 1. Role defaults (roles/x/defaults/main.yml)
# 2. Inventory vars
# 3. Inventory group_vars
# 4. Inventory host_vars
# 5. Playbook group_vars
# 6. Playbook host_vars
# 7. Host facts
# 8. Registered vars
# 9. Set_facts
# 10. Play vars
# 11. Play vars_prompt
# 12. Play vars_files
# 13. Role vars (roles/x/vars/main.yml)
# 14. Block vars
# 15. Task vars
# 16. Include vars
# 17. Role (as include)
# 18. Include params
# 19. Extra vars (-e "key=value") [highest]
```

```yaml
---
# Using variables
- name: Install packages
  apt:
    name: "{{ package_name }}"
    state: present

# Registered variables
- name: Check disk space
  shell: df -h / | tail -1 | awk '{print $5}'
  register: disk_usage

- name: Alert if disk full
  debug:
    msg: "Disk is {{ disk_usage.stdout }}% full"
  when: disk_usage.stdout | int > 80
```

## 5.5 Conditionals

```yaml
---
- name: Install packages
  apt:
    name: nginx
    state: present
  when: ansible_os_family == "Debian"

- name: Install packages
  yum:
    name: nginx
    state: present
  when: ansible_os_family == "RedHat"

- name: Run on specific hosts
  command: /opt/upgrade.sh
  when:
    - ansible_hostname in groups['dbservers']
    - upgrade_available | bool
```

## 5.6 Loops

```yaml
---
# Simple list
- name: Install multiple packages
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - htop
    - vim

# List of hashes
- name: Create users
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
    state: present
  loop:
    - { name: alice, groups: "admin" }
    - { name: bob, groups: "dev" }

# With index
- name: Template with index
  template:
    src: server.conf.j2
    dest: "/etc/nginx/conf.d/server-{{ idx }}.conf"
  loop: "{{ servers }}"
  loop_control:
    index_var: idx
```

## 5.7 Handlers

```yaml
---
- name: Restart services
  service:
    name: "{{ item }}"
    state: restarted
  loop:
    - nginx
    - php-fpm
  when: config_changed | bool
```

```yaml
# In a playbook
  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
      listen: "restart web services"

    - name: Restart database
      service:
        name: postgresql
        state: restarted
      listen: "restart web services"
```

## 5.8 Templates (Jinja2)

```jinja2
{# templates/nginx.conf.j2 #}
worker_processes {{ nginx_worker_processes | default('auto') }};
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

events {
    worker_connections {{ max_clients | default(1024) }};
}

http {
    server {
        listen {{ http_port | default(80) }};
        server_name {{ ansible_fqdn }};

        location / {
            proxy_pass http://127.0.0.1:{{ app_port }};
        }
    }
}
```

## 5.9 Ansible Vault

Encrypt sensitive data:

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Encrypt existing file
ansible-vault encrypt group_vars/production/secrets.yml

# Decrypt
ansible-vault decrypt secrets.yml

# View encrypted content
ansible-vault view secrets.yml

# Encrypt a string
ansible-vault encrypt_string 'secret_password' --name 'db_password'
```

```yaml
# Encrypted vars file
---
db_password: "{{ vault_db_password }}"
api_key: "{{ vault_api_key }}"
```

```bash
# Run playbook with vault
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --vault-password-file=~/.vault_pass
```

## 5.10 Callback Plugins

```ini
# ansible.cfg
[defaults]
callback_whitelist = timer, profile_tasks, json

[callback_timer]
```

```yaml
# Enable in playbook
- hosts: all
  callbacks:
    - timer
    - profile_tasks
  tasks:
    # ...
```

---

# 6. Usage Guide (Step-by-Step)

## 6.1 Step 1: Plan and Design

Before writing playbooks:

1. **Inventory design**: How are hosts organized?
2. **Variable hierarchy**: What goes where?
3. **Role decomposition**: What are the reusable components?
4. **Secrets management**: Where do credentials live?

## 6.2 Step 2: Set Up Project Structure

```
ansible-project/
  ansible.cfg
  inventory/
    production/
      hosts.yml
      group_vars/
        all.yml
        webservers.yml
      host_vars/
    staging/
      hosts.yml
      group_vars/
  roles/
    common/
    nginx/
    app/
  playbooks/
    site.yml
    webservers.yml
    dbservers.yml
  templates/
  files/
  requirements.yml
```

## 6.3 Step 3: Create Inventory

```yaml
# inventory/production/hosts.yml
---
all:
  children:
    webservers:
      hosts:
        web-prod-01:
          ansible_host: 10.0.1.10
        web-prod-02:
          ansible_host: 10.0.1.11
    dbservers:
      hosts:
        db-prod-01:
          ansible_host: 10.0.2.10
    loadbalancers:
      hosts:
        lb-prod-01:
          ansible_host: 10.0.0.10

  vars:
    ansible_user: deploy
    ansible_ssh_private_key_file: ~/.ssh/deploy_key
    ansible_become: yes
```

## 6.4 Step 4: Write Base Role

```yaml
# roles/common/tasks/main.yml
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Install common packages
  apt:
    name:
      - vim
      - htop
      - curl
      - wget
      - git
      - unzip
    state: present

- name: Configure timezone
  timezone:
    name: "{{ timezone }}"

- name: Set up NTP
  package:
    name: ntp
    state: present
  notify: Restart ntp

- name: Configure NTP
  template:
    src: ntp.conf.j2
    dest: /etc/ntp.conf
  notify: Restart ntp

- name: Ensure services are running
  service:
    name: "{{ item }}"
    state: started
    enabled: yes
  loop:
    - ntp
    - sshd
```

## 6.5 Step 5: Write Web Server Role

```yaml
# roles/nginx/tasks/main.yml
---
- name: Install nginx
  apt:
    name: nginx
    state: present

- name: Ensure nginx configuration directory exists
  file:
    path: /etc/nginx/conf.d
    state: directory

- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: "nginx -t -c %s"
  notify: Restart nginx

- name: Deploy site configuration
  template:
    src: site.conf.j2
    dest: "/etc/nginx/conf.d/{{ site_name }}.conf"
    validate: "nginx -t -c /etc/nginx/nginx.conf"
  notify: Restart nginx

- name: Ensure nginx is running
  service:
    name: nginx
    state: started
    enabled: yes

- name: Open firewall port
  ufw:
    rule: allow
    port: "{{ http_port }}"
    proto: tcp
```

## 6.6 Step 6: Write Playbook

```yaml
# playbooks/site.yml
---
- name: Apply common configuration
  hosts: all
  become: yes
  roles:
    - common

- name: Configure web servers
  hosts: webservers
  become: yes
  roles:
    - nginx
    - app

- name: Configure databases
  hosts: dbservers
  become: yes
  roles:
    - postgresql
```

## 6.7 Step 7: Test and Validate

```bash
# Syntax check
ansible-playbook playbooks/site.yml --syntax-check

# Dry run
ansible-playbook playbooks/site.yml --check

# Diff mode
ansible-playbook playbooks/site.yml --diff

# Limit to specific hosts
ansible-playbook playbooks/site.yml --limit webservers

# Verbose output
ansible-playbook playbooks/site.yml -vvv
```

## 6.8 Step 8: Run the Playbook

```bash
# Production deployment
ansible-playbook playbooks/site.yml -i inventory/production/hosts.yml --ask-vault-pass

# Staging deployment
ansible-playbook playbooks/site.yml -i inventory/staging/hosts.yml

# With tags
ansible-playbook playbooks/site.yml --tags "nginx,deploy"

# Skip tags
ansible-playbook playbooks/site.yml --skip-tags "test"

# Limit to specific host
ansible-playbook playbooks/site.yml --limit web-prod-01
```

## 6.9 Step 9: Verify Deployment

```bash
# Check nginx is running
ansible webservers -m shell -a "systemctl status nginx"

# Check application
ansible webservers -m uri -a "url=http://localhost status_code=200"

# Gather facts
ansible webservers -m setup -a "filter=ansible_distribution"
```

---

# 7. Custom Modules and Plugins

## 7.1 Writing a Custom Module

```python
#!/usr/bin/python
# library/my_module.py

from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            state=dict(type='str', choices=['present', 'absent'], default='present'),
            value=dict(type='str', default=''),
        ),
        supports_check_mode=True,
    )

    name = module.params['name']
    state = module.params['state']
    value = module.params['value']

    # Implementation
    changed = False

    if module.check_mode:
        module.exit_json(changed=False)

    module.exit_json(
        changed=changed,
        name=name,
        message=f"Resource {name} is {state}"
    )

if __name__ == '__main__':
    main()
```

## 7.2 Writing a Callback Plugin

```python
# callbacks/notification.py

from ansible.plugins.callback import CallbackBase

class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'notification'

    def v2_runner_on_ok(self, result):
        if result._task.action == 'debug':
            return
        self._display.display(
            f"Task completed: {result._task.name}",
            color='green'
        )
```

## 7.3 Writing a Filter Plugin

```python
# filter_plugins/custom_filters.py

def to_uppercase(value):
    return value.upper()

def filter_by_key(lst, key, value):
    return [item for item in lst if item.get(key) == value]

class FilterModule(object):
    def filters(self):
        return {
            'to_uppercase': to_uppercase,
            'filter_by_key': filter_by_key,
        }
```

## 7.4 Writing a Connection Plugin

```python
# connection/my_ssh.py

from ansible.plugins.connection.ssh import Connection as SSHConnection

class Connection(SSHConnection):
    """Custom SSH connection plugin."""

    transport = 'my_ssh'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
```

---

# 8. Integration

## 8.1 Ansible + Terraform

```yaml
# Terraform outputs to Ansible inventory
# terraform output -json > inventory/terraform.json

# Dynamic inventory from Terraform
# Use terraform-inventory or custom script
```

```bash
# Workflow:
terraform apply -auto-approve
terraform-inventory --inventory > inventory.json
ansible-playbook -i inventory.json playbook.yml
```

## 8.2 Ansible + Docker

```yaml
# roles/docker/tasks/main.yml
---
- name: Install Docker
  apt:
    name: docker.io
    state: present

- name: Add user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes

- name: Pull application image
  docker_image:
    name: "registry.example.com/{{ app_name }}:{{ app_version }}"
    source: pull

- name: Run container
  docker_container:
    name: "{{ app_name }}"
    image: "registry.example.com/{{ app_name }}:{{ app_version }}"
    state: started
    restart_policy: unless-stopped
    ports:
      - "{{ app_port }}:8080"
    env:
      DB_HOST: "{{ db_host }}"
      DB_PASSWORD: "{{ vault_db_password }}"
```

## 8.3 Ansible + Kubernetes

```yaml
# k8s-deploy.yml
---
- hosts: localhost
  collections:
    - kubernetes.core
  tasks:
    - name: Create namespace
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Namespace
          metadata:
            name: "{{ namespace }}"

    - name: Deploy application
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: "{{ app_name }}"
            namespace: "{{ namespace }}"
          spec:
            replicas: "{{ replicas }}"
            selector:
              matchLabels:
                app: "{{ app_name }}"
            template:
              metadata:
                labels:
                  app: "{{ app_name }}"
              spec:
                containers:
                  - name: "{{ app_name }}"
                    image: "{{ app_image }}:{{ app_version }}"
                    ports:
                      - containerPort: 8080
```

## 8.4 Ansible + AWX/Tower

```bash
# Install AWX
git clone https://github.com/ansible/awx.git
cd awx
docker-compose up -d

# Configure in web UI
# 1. Create credentials
# 2. Create inventory
# 3. Create project (link to Git repo)
# 4. Create job template
# 5. Run job
```

## 8.5 CI/CD with GitHub Actions

```yaml
# .github/workflows/ansible.yml
name: Ansible Deployment

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Ansible
        run: pip install ansible

      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa

      - name: Run playbook
        env:
          ANSIBLE_HOST_KEY_CHECKING: "False"
        run: |
          ansible-playbook -i inventory/production/hosts.yml \
            playbooks/site.yml \
            --ask-vault-pass \
            --vault-password-file=<(...) echo "${{ secrets.ANSIBLE_VAULT_PASS }}"
```

---

# 9. Security

## 9.1 SSH Security

```yaml
# roles/ssh_hardening/tasks/main.yml
---
- name: Disable password authentication
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "^#?PasswordAuthentication"
    line: "PasswordAuthentication no"
  notify: Restart sshd

- name: Disable root login
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "^#?PermitRootLogin"
    line: "PermitRootLogin no"
  notify: Restart sshd

- name: Set SSH port
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "^#?Port"
    line: "Port {{ ssh_port }}"
  notify: Restart sshd
```

## 9.2 Secrets Management

```bash
# Create encrypted variable file
ansible-vault create group_vars/production/secrets.yml

# Content:
# vault_db_password: "encrypted_value"
# vault_api_key: "encrypted_value"
```

```yaml
# Use in playbook
- name: Configure application
  template:
    src: app.conf.j2
    dest: /etc/app/config.conf
  vars:
    db_password: "{{ vault_db_password }}"
```

```bash
# Run with vault
ansible-playbook site.yml --ask-vault-pass

# Use vault password file
ansible-playbook site.yml --vault-password-file=~/.vault_pass
```

## 9.3 Role-Based Access Control

```yaml
# AWX/Tower RBAC
# Create organizations, teams, and roles
# Assign permissions to job templates
```

## 9.4 Audit Logging

```ini
# ansible.cfg
[defaults]
log_path = /var/log/ansible.log

[syslog]
facility = daemon
```

## 9.5 Credential Management

```bash
# Use Ansible Tower/AWX credentials
# Store in encrypted vars files
# Use HashiCorp Vault integration

# With HashiCorp Vault
ansible-vault lookup plugin
```

---

# 10. Troubleshooting

## Issue 1: SSH Connection Timeout

```
Failed to connect to the host via ssh: Connection timed out
```

**Fix**:
```bash
# Test SSH manually
ssh -i ~/.ssh/key user@host -o ConnectTimeout=10

# Check ansible.cfg
# Increase timeout
[defaults]
timeout = 60

# Or per-host
ansible_host: 10.0.1.10
ansible_timeout: 60
```

## Issue 2: Host Key Verification Failed

```
Failed to connect to the host via ssh: Host key verification failed
```

**Fix**:
```bash
# Disable (development only)
[defaults]
host_key_checking = False

# Or add host key
ssh-keyscan host >> ~/.ssh/known_hosts
```

## Issue 3: Permission Denied

```
Failed to connect to the host via ssh: Permission denied (publickey,password)
```

**Fix**:
```bash
# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh

# Verify key-based auth
ssh -i ~/.ssh/id_rsa user@host

# Check user
ansible_user: correct_user
```

## Issue 4: Module Not Found

```
module not found: docker_container
```

**Fix**:
```bash
# Install collection
ansible-galaxy collection install community.docker

# Or use full qualified name
community.docker.docker_container:
```

## Issue 5: Variable Not Defined

```
'variable_name' is undefined
```

**Fix**:
```yaml
# Use default
{{ variable_name | default('fallback_value') }}

# Define in vars
vars:
  variable_name: "value"

# Check precedence
ansible-inventory --list
```

## Issue 6: Handler Not Running

Handler doesn't execute when expected.

**Fix**:
```yaml
# Ensure notify matches handler name exactly
notify: "Restart nginx"  # Must match handler name

# Check handlers list
handlers:
  - name: Restart nginx  # This must match
    service:
      name: nginx
      state: restarted

# Force handler execution
ansible-playbook site.yml --force-handlers
```

## Issue 7: Circular Dependencies

```
ERROR! A pending task cannot depend on this task
```

**Fix**:
- Restructure tasks to break cycles
- Use `include_tasks` with different tag structure
- Check role dependencies in `meta/main.yml`

## Issue 8: Jinja2 Template Error

```
template error while templating string
```

**Fix**:
```jinja2
{# Use raw blocks for Jinja2 syntax #}
{% raw %}
{{ template_var }}
{% endraw %}

{# Check variable type #}
{{ var | string }}
{{ var | int }}
```

## Issue 9: Connection Plugin Error

```
ERROR! unexpected connection type "paramiko"
```

**Fix**:
```bash
# Install paramiko
pip install paramiko

# Or use SSH
[defaults]
connection = ssh
```

## Issue 10: Vault Decryption Failed

```
ERROR! A vault password is required
```

**Fix**:
```bash
# Provide vault password
ansible-playbook site.yml --ask-vault-pass

# Or use password file
ansible-playbook site.yml --vault-password-file=~/.vault_pass

# Check vault password
ansible-vault view secrets.yml --vault-password-file=~/.vault_pass
```

## Issue 11: Race Condition in Parallel Execution

```
fatal: [web2]: FAILED! => {"msg": "Error: resource already exists"}
```

**Fix**:
```yaml
# Serialize tasks
- name: Create resource
  command: create_resource.sh
  throttle: 1

# Or reduce forks
ansible-playbook site.yml --forks 1
```

## Issue 12: Fact Caching Issues

Stale facts used after infrastructure change.

**Fix**:
```yaml
# Force fact refresh
- name: Refresh facts
  setup:

# Or disable fact caching
[defaults]
gathering = implicit
fact_caching = memory
```

## Issue 13: Module Timeout

```
ERROR! Timeout waiting for reply
```

**Fix**:
```yaml
# Increase timeout
- name: Long running task
  command: /opt/slow-operation.sh
  async: 3600
  poll: 0
  register: job

- name: Wait for completion
  async_status:
    jid: "{{ job.ansible_job_id }}"
  register: result
  until: result.finished
  retries: 300
  delay: 10
```

## Issue 14: Import/Roles Not Found

```
ERROR! the role 'nginx' was not found
```

**Fix**:
```bash
# Check role path
ansible-galaxy role list

# Install role
ansible-galaxy role install geerlingguy.nginx

# Check roles_path in ansible.cfg
[defaults]
roles_path = ./roles
```

## Issue 15: Syntax Error in YAML

```
ERROR! Syntax Error while loading YAML
```

**Fix**:
```bash
# Validate YAML
python -c "import yaml; yaml.safe_load(open('playbook.yml'))"

# Use yamllint
yamllint playbook.yml
```

## Issue 16: Running Out of File Descriptors

```
ERROR! [Errno 24] Too many open files
```

**Fix**:
```bash
# Increase ulimit
ulimit -n 10240

# Or reduce forks
ansible-playbook site.yml --forks 10
```

## Issue 17: Module Execution Error

```
FAILED! => {"changed": false, "msg": "Error: unable to connect to database"}
```

**Fix**:
```yaml
# Debug first
- name: Debug connection string
  debug:
    msg: "Connecting to {{ db_host }}:{{ db_port }}"

# Check variables
ansible-inventory --host db-prod-01
```

## Issue 18: When Condition Evaluation Error

```
The conditional check 'ansible_os_family == "Debian"' failed
```

**Fix**:
```yaml
# Debug the fact
- debug:
    var: ansible_os_family

# Use correct comparison
when: ansible_os_family == "Debian"

# Check available facts
ansible web1 -m setup | grep os_family
```

## Issue 19: Tag Filtering Issues

Tasks not running when expected.

**Fix**:
```bash
# Check tags
ansible-playbook site.yml --list-tags

# Run specific tags
ansible-playbook site.yml --tags "config,deploy"

# Skip tags
ansible-playbook site.yml --skip-tags "test"

# Tags in roles
roles:
  - role: nginx
    tags: ['nginx', 'web']
```

## Issue 20: Memory Issues with Large Inventory

Playbook hangs or runs out of memory.

**Fix**:
```bash
# Use dynamic inventory
ansible-playbook -i aws_ec2.yml playbook.yml

# Reduce forks
ansible-playbook site.yml --forks 10

# Use fact caching
[defaults]
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
```

---

# 11. Tips and Best Practices

## Tip 1: Use idempotent Tasks

```yaml
# BAD: Runs every time
- name: Run migration
  command: python manage.py migrate

# GOOD: Check if needed
- name: Run migration
  command: python manage.py migrate
  when: migration_needed
```

## Tip 2: Use Roles for Organization

```
roles/
  common/
  nginx/
  postgresql/
  app/
```

## Tip 3: Use Tags for Selective Execution

```yaml
tasks:
  - name: Install dependencies
    tags: ['install', 'dependencies']

  - name: Deploy code
    tags: ['deploy']

  - name: Configure
    tags: ['config', 'configure']
```

## Tip 4: Use Handlers for Service Restarts

```yaml
- name: Deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Restart nginx  # Only restart if changed
```

## Tip 5: Use Blocks for Error Handling

```yaml
- block:
    - name: Deploy application
      # ...
    - name: Run smoke tests
      # ...
  rescue:
    - name: Rollback on failure
      # ...
  always:
    - name: Cleanup
      # ...
```

## Tip 6: Use Check Mode

```bash
ansible-playbook site.yml --check --diff
```

## Tip 7: Use ansible-lint

```bash
pip install ansible-lint
ansible-lint playbooks/
```

## Tip 8: Use Jinja2 Templates Effectively

```jinja2
{# Use filters #}
{{ variable | default('fallback') }}
{{ list | join(', ') }}
{{ dict | to_json }}

{# Use loops #}
{% for item in list %}
{{ item }}
{% endfor %}
```

## Tip 9: Use Registered Variables for Debugging

```yaml
- name: Run command
  command: some-command
  register: result

- debug:
    var: result
```

## Tip 10: Use Delegation

```yaml
- name: Configure load balancer
  template:
    src: lb.conf.j2
    dest: /etc/haproxy/haproxy.cfg
  delegate_to: lb-server
```

## Tip 11: Use ansible-vault for Secrets

```bash
ansible-vault create secrets.yml
ansible-playbook site.yml --ask-vault-pass
```

## Tip 12: Use Fact Caching

```ini
[defaults]
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
```

## Tip 13: Use Serial for Rolling Updates

```yaml
- hosts: webservers
  serial: 1  # One at a time
  max_fail_percentage: 10
```

## Tip 14: Use pre_tasks and post_tasks

```yaml
- hosts: webservers
  pre_tasks:
    - name: Drain load balancer
      # ...
  roles:
    - nginx
  post_tasks:
    - name: Add to load balancer
      # ...
```

## Tip 15: Use Strategy Plugins

```yaml
- hosts: webservers
  strategy: free  # Run tasks as fast as possible
  # or
  strategy: linear  # Wait for all hosts per task
```

## Tip 16: Use ansible-doc

```bash
ansible-doc apt
ansible-doc -l | grep docker
```

## Tip 17: Use Variables Files

```yaml
# vars/production.yml
http_port: 80
max_clients: 200
```

```yaml
# playbook.yml
- hosts: webservers
  vars_files:
    - vars/production.yml
```

## Tip 18: Use async for Long Tasks

```yaml
- name: Long running task
  command: /opt/backup.sh
  async: 3600
  poll: 0
  register: backup_job
```

## Tip 19: Use Molecule for Role Testing

```bash
pip install molecule
molecule init role my_role
molecule create
molecule converge
molecule verify
molecule destroy
```

## Tip 20: Use ansible-inventory

```bash
ansible-inventory --list  # Full inventory
ansible-inventory --graph  # Visual representation
ansible-inventory --host web1  # Host variables
```

---

# 12. Command Reference

## ansible

Run ad-hoc commands.

```bash
ansible <host-pattern> -m <module> -a "<args>" [options]

# Options:
-m MODULE           # Module to execute
-a ARGUMENTS        # Module arguments
-i INVENTORY        # Inventory file
-u USER            # Remote user
--become           # Use privilege escalation
--become-user USER # User for privilege escalation
-k                 # Ask for SSH password
-K                 # Ask for sudo password
-f FORKS           # Parallel execution forks
--check            # Dry run
--diff             # Show file differences
-t TREE            # Log output to directory
-v                 # Verbose (up to -vvvv)
```

## ansible-playbook

Execute playbooks.

```bash
ansible-playbook <playbook.yml> [options]

# Options:
-i INVENTORY       # Inventory file
-e VARS            # Extra variables
--ask-vault-pass   # Ask for vault password
--vault-password-file FILE  # Vault password file
--tags TAGS        # Only run tagged tasks
--skip-tags TAGS   # Skip tagged tasks
--limit HOSTS      # Limit to specific hosts
--forks N          # Parallel forks
--step             # Step-by-step execution
--check            # Dry run
--diff             # Show file differences
--syntax-check     # Syntax check only
--list-tasks       # List all tasks
--list-tags        # List all tags
--list-hosts       # List target hosts
--start-at-task TASK  # Start at specific task
--force-handlers   # Force handler execution
-t TREE            # Log output directory
--connection TYPE  # Connection type
-c CONNECTION      # Connection plugin
-M MODULE_PATH     # Module library path
```

## ansible-galaxy

Manage roles and collections.

```bash
# Roles
ansible-galaxy role init <role_name>        # Create new role
ansible-galaxy role install <role>          # Install role
ansible-galaxy role remove <role>           # Remove role
ansible-galaxy role list                    # List installed roles
ansible-galaxy role info <role>             # Role information
ansible-galaxy role delete <role>           # Delete from Galaxy

# Collections
ansible-galaxy collection init <namespace.collection_name>
ansible-galaxy collection install <collection>
ansible-galaxy collection list
ansible-galaxy collection info <collection>
ansible-galaxy collection uninstall <collection>

# From requirements file
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
```

## ansible-vault

Manage encrypted secrets.

```bash
ansible-vault create <file>              # Create encrypted file
ansible-vault edit <file>                # Edit encrypted file
ansible-vault encrypt <file>             # Encrypt existing file
ansible-vault decrypt <file>             # Decrypt file
ansible-vault view <file>                # View encrypted file
ansible-vault encrypt_string <string>    # Encrypt a string
ansible-vault rekey <file>              # Change vault password
ansible-vault encrypt_file <file> <newfile>  # Encrypt to new file
```

## ansible-inventory

Display inventory information.

```bash
ansible-inventory --list                # Full inventory (JSON)
ansible-inventory --graph               # Inventory tree
ansible-inventory --host <host>         # Host variables
ansible-inventory --vars                # All variables
ansible-inventory --limit <host>        # Limit to host
ansible-inventory --list --yaml         # YAML format
```

## ansible-doc

Module and plugin documentation.

```bash
ansible-doc <module>                # Module documentation
ansible-doc -l                     # List all modules
ansible-doc -s <module>            # Module synopsis
ansible-doc -t <type>              # Plugin type (callback, filter, etc.)
ansible-doc -F                     # List all plugins
```

## ansible-lint

Playbook linting.

```bash
ansible-lint [playbook.yml]       # Lint playbook
ansible-lint roles/               # Lint roles
ansible-lint -p                  # Parseable output
ansible-lint -r rules/           # Custom rules directory
ansible-lint --exclude roles/vendor  # Exclude directories
```

## ansible-config

Manage configuration.

```bash
ansible-config list               # List all config options
ansible-config dump              # Show current config
ansible-config dump --only-changed  # Show non-defaults
ansible-config view              # Show config file path
ansible-config init              # Generate ansible.cfg
```

---

# 13. Configuration Reference

## 13.1 ansible.cfg Sections

```ini
[defaults]
inventory = ./inventory
remote_user = deploy
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
timeout = 30
forks = 20
log_path = /var/log/ansible.log
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
retry_files_enabled = False
nocows = 1
stdout_callback = yaml
callback_whitelist = timer, profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
ssh_args = -o ControlMaster=auto -o ControlPersist=60s

[inventory]
enable_plugins = script, yaml, ini, auto

[diff]
context = 3
```

## 13.2 Playbook Structure

```yaml
---
# Playbook header
- name: Description
  hosts: host_pattern
  become: yes
  gather_facts: yes
  strategy: linear
  serial: 1
  max_fail_percentage: 10
  any_errors_fatal: false

  vars:
    key: value

  vars_files:
    - vars/main.yml

  pre_tasks:
    - name: Pre-task
      # ...

  roles:
    - role: common
      tags: ['common']

  tasks:
    - name: Task name
      module:
        option: value
      when: condition
      tags: ['tag']
      notify: handler_name
      register: result

  post_tasks:
    - name: Post-task
      # ...

  handlers:
    - name: handler_name
      module:
        option: value
```

## 13.3 Role Structure

```
roles/
  role_name/
    tasks/
      main.yml          # Main task list
    handlers/
      main.yml          # Handler definitions
    templates/
      file.j2           # Jinja2 templates
    files/
      file              # Static files
    vars/
      main.yml          # Role variables (high precedence)
    defaults/
      main.yml          # Default variables (low precedence)
    meta/
      main.yml          # Role metadata
    tests/
      inventory         # Test inventory
      test.yml          # Test playbook
    molecule/
      default/
        molecule.yml    # Molecule config
```

## 13.4 Common Modules Reference

| Module | Purpose |
|--------|---------|
| `apt` | Manage apt packages |
| `yum` | Manage yum packages |
| `dnf` | Manage dnf packages |
| `service` | Manage services |
| `systemd` | Manage systemd services |
| `user` | Manage users |
| `group` | Manage groups |
| `copy` | Copy files |
| `template` | Template files (Jinja2) |
| `file` | Manage files/directories |
| `lineinfile` | Manage line in file |
| `blockinfile` | Manage block in file |
| `git` | Manage git repositories |
| `command` | Run commands |
| `shell` | Run shell commands |
| `raw` | Execute raw SSH commands |
| `script` | Run local scripts on remote |
| `setup` | Gather facts |
| `debug` | Print debug messages |
| `assert` | Assert conditions |
| `uri` | Make HTTP requests |
| `docker_container` | Manage Docker containers |
| `docker_image` | Manage Docker images |
| `kubernetes` | Manage K8s resources |
| `aws_ec2` | Manage AWS EC2 instances |
| `azure_rm` | Manage Azure resources |
| `mysql_user` | Manage MySQL users |
| `postgresql_user` | Manage PostgreSQL users |

---

# 14. Real-World Examples

## Example 1: Complete LAMP Stack

```yaml
---
# playbooks/lamp.yml
- name: Deploy LAMP stack
  hosts: webservers
  become: yes
  vars:
    app_name: myapp
    db_host: db-server
    db_name: myapp
    db_user: myapp

  roles:
    - common
    - nginx
    - php
    - { role: mysql, when: "'dbservers' in group_names" }

  tasks:
    - name: Deploy application code
      git:
        repo: "https://github.com/org/{{ app_name }}.git"
        dest: "/var/www/{{ app_name }}"
        version: "{{ app_version | default('main') }}"
      notify: Restart php-fpm

    - name: Configure database connection
      template:
        src: templates/config.php.j2
        dest: "/var/www/{{ app_name }}/config/database.php"
        owner: www-data
        group: www-data
      notify: Restart php-fpm

    - name: Run database migrations
      command: "php /var/www/{{ app_name }}/artisan migrate --force"
      become_user: www-data

    - name: Set up cron jobs
      cron:
        name: "{{ item.name }}"
        minute: "{{ item.minute }}"
        job: "{{ item.job }}"
        user: www-data
      loop:
        - { name: "queue worker", minute: "*", job: "php /var/www/{{ app_name }}/artisan queue:work" }
        - { name: "schedule", minute: "*", job: "php /var/www/{{ app_name }}/artisan schedule:run" }

  handlers:
    - name: Restart php-fpm
      service:
        name: php{{ php_version }}-fpm
        state: restarted

    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

## Example 2: Kubernetes Deployment with Rolling Updates

```yaml
---
- name: Deploy to Kubernetes
  hosts: localhost
  connection: local
  gather_facts: no

  vars:
    app_name: myapp
    namespace: production
    image: "registry.example.com/myapp"
    replicas: 3

  tasks:
    - name: Update deployment image
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: "{{ app_name }}"
            namespace: "{{ namespace }}"
          spec:
            replicas: "{{ replicas }}"
            selector:
              matchLabels:
                app: "{{ app_name }}"
            strategy:
              type: RollingUpdate
              rollingUpdate:
                maxSurge: 1
                maxUnavailable: 0
            template:
              metadata:
                labels:
                  app: "{{ app_name }}"
              spec:
                containers:
                  - name: "{{ app_name }}"
                    image: "{{ image }}:{{ new_version }}"
                    ports:
                      - containerPort: 8080
                    readinessProbe:
                      httpGet:
                        path: /health
                        port: 8080
                      initialDelaySeconds: 10
                      periodSeconds: 5
                    resources:
                      requests:
                        memory: "128Mi"
                        cpu: "250m"
                      limits:
                        memory: "256Mi"
                        cpu: "500m"

    - name: Wait for rollout
      command: >
        kubectl rollout status deployment/{{ app_name }}
        -n {{ namespace }}
      register: result
      until: result.rc == 0
      retries: 30
      delay: 10
```

## Example 3: Automated Security Hardening

```yaml
---
- name: Security Hardening
  hosts: all
  become: yes

  roles:
    - { role: dev-sec.os-hardening }
    - { role: dev-sec.ssh-hardening }

  tasks:
    - name: Install security updates
      apt:
        upgrade: dist
        update_cache: yes

    - name: Configure automatic security updates
      template:
        src: templates/50unattended-upgrades.j2
        dest: /etc/apt/apt.conf.d/50unattended-upgrades

    - name: Set up fail2ban
      apt:
        name: fail2ban
        state: present

    - name: Configure fail2ban
      template:
        src: templates/jail.local.j2
        dest: /etc/fail2ban/jail.local
      notify: Restart fail2ban

    - name: Enable UFW
      ufw:
        state: enabled
        policy: deny

    - name: Allow SSH
      ufw:
        rule: allow
        port: "{{ ssh_port }}"
        proto: tcp

    - name: Allow HTTP/HTTPS
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "80"
        - "443"

    - name: Check for rootkits
      apt:
        name:
          - rkhunter
          - chkrootkit
        state: present

    - name: Set up logwatch
      apt:
        name: logwatch
        state: present

    - name: Configure logwatch
      template:
        src: templates/logwatch.conf.j2
        dest: /etc/logwatch/conf/logwatch.conf

  handlers:
    - name: Restart fail2ban
      service:
        name: fail2ban
        state: restarted
```

## Example 4: Multi-Environment Deployment Pipeline

```yaml
---
# playbooks/deploy.yml
- name: Deploy to environment
  hosts: "{{ target_env }}"
  become: yes

  vars:
    app_name: myapp
    app_version: "{{ lookup('env', 'APP_VERSION') }}"

  pre_tasks:
    - name: Notify deployment start
      uri:
        url: "https://hooks.slack.com/services/{{ slack_webhook }}"
        method: POST
        body_format: json
        body:
          text: "Deploying {{ app_name }} {{ app_version }} to {{ target_env }}"
      delegate_to: localhost

    - name: Drain load balancer
      uri:
        url: "https://{{ lb_host }}/api/drain/{{ target_env }}"
        method: POST
        headers:
          Authorization: "Bearer {{ lb_api_token }}"
      delegate_to: localhost

    - name: Wait for connections to drain
      wait_for:
        timeout: 30
      delegate_to: localhost

  roles:
    - app

  post_tasks:
    - name: Run smoke tests
      uri:
        url: "https://{{ app_url }}/health"
        status_code: 200
      retries: 10
      delay: 5

    - name: Add to load balancer
      uri:
        url: "https://{{ lb_host }}/api/enable/{{ target_env }}"
        method: POST
        headers:
          Authorization: "Bearer {{ lb_api_token }}"
      delegate_to: localhost

    - name: Notify deployment success
      uri:
        url: "https://hooks.slack.com/services/{{ slack_webhook }}"
        method: POST
        body_format: json
        body:
          text: "✅ {{ app_name }} {{ app_version }} deployed to {{ target_env }}"
      delegate_to: localhost
```

## Example 5: Role with Molecule Testing

```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: docker.io/geerlingguy/docker-ubuntu2204-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    command: /lib/systemd/systemd
    privileged: true
provisioner:
  name: ansible
  inventory:
    host_vars:
      instance:
        ansible_python_interpreter: /usr/bin/python3
verifier:
  name: ansible
```

```yaml
# molecule/default/converge.yml
---
- name: Converge
  hosts: all
  become: yes
  roles:
    - role: my_role
```

```bash
# Run tests
molecule create
molecule converge
molecule verify
molecule destroy
```

---

# 15. Further Reading

## Official Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible GitHub](https://github.com/ansible/ansible)
- [Red Hat Ansible Automation](https://www.ansible.com/)
- [AWX Project](https://github.com/ansible/awx)

## Learning Resources

- [Ansible for DevOps](https://www.ansiblefordevops.com/) by Jeff Geerling
- [Mastering Ansible](https://www.packtpub.com/product/mastering-ansible/9781789954432) by James Freeman
- [Ansible: Up and Running](https://www.oreilly.com/library/view/ansible-up/9781492079859/) by Lorin Hochstein
- [Ansible Lightspeed](https://www.ansible.com/lightspeed) - AI-assisted Ansible

## Community

- [Ansible Discuss](https://AnsibleDiscuss.com/)
- [Ansible subreddit](https://www.reddit.com/r/ansible/)
- [Ansible Newsletter](https://www.ansible.com/newsletter)

## Related Tools

- **Molecule**: Role testing framework
- **Ansible Lint**: Playbook linter
- **AWX/Tower**: Web-based Ansible UI
- **Ansible Semaphore**: Alternative web UI
- **ARA**: Ansible Run Analysis
- **Semaphore**: Ansible UI alternative
- **Jinja2**: Templating engine

---

*This guide covers Ansible Core as of version 2.16.x. For the latest features, refer to the official documentation.*
