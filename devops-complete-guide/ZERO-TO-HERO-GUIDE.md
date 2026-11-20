# Zero to Hero: Complete DevOps Guide

**From Beginner to Advanced — Everything Explained**

---

# PART 1: FOUNDATIONS (Beginner)

---

## Chapter 1: What is DevOps?

### What is it? (Analogy)

**DevOps** = A way of working where developers (Dev) and operations (Ops) work together instead of separately.

**Analogy:** Imagine a restaurant where:
- **Old way:** The chef (developer) cooks food, throws it over the wall, and the waiter (operations) figures out how to serve it. If something goes wrong, they blame each other.
- **DevOps way:** The chef and waiter work together from the start. The chef knows how the food will be served, and the waiter knows how it's cooked. They use the same tools and communicate constantly.

### Why do we need it?

| Problem (Old Way) | Solution (DevOps) |
|-------------------|-------------------|
| Developers write code, throw it "over the wall" | Developers and ops work together |
| Manual deployments take days | Automated deployments take minutes |
| "It works on my machine" | Same environment everywhere (containers) |
| Fix problems reactively | Monitor and fix proactively |
| Changes are scary and rare | Changes are small and frequent |

### The DevOps Cycle

```
    ┌─────────┐
    │  PLAN   │ ← What to build
    └────┬────┘
         ↓
    ┌─────────┐
    │  CODE   │ ← Write the code
    └────┬────┘
         ↓
    ┌─────────┐
    │  BUILD  │ ← Compile and package
    └────┬────┘
         ↓
    ┌─────────┐
    │  TEST   │ ← Check if it works
    └────┬────┘
         ↓
    ┌─────────┐
    │ RELEASE │ ← Prepare for deployment
    └────┬────┘
         ↓
    ┌─────────┐
    │ DEPLOY  │ ← Put it on servers
    └────┬────┘
         ↓
    ┌─────────┐
    │OPERATE  │ ← Keep it running
    └────┬────┘
         ↓
    ┌─────────┐
    │ MONITOR │ ← Watch for problems
    └────┬────┘
         ↑
         └──── Back to PLAN (continuous loop)
```

### Key DevOps Practices

| Practice | What It Means | Tool |
|----------|---------------|------|
| **Infrastructure as Code** | Define servers in code files | OpenTofu, Terraform |
| **Configuration Management** | Automate server setup | Ansible |
| **CI/CD** | Automatically test and deploy | GitHub Actions, ArgoCD |
| **Containers** | Package apps with dependencies | Docker |
| **Orchestration** | Manage many containers | Kubernetes |
| **Monitoring** | Watch system health | Prometheus, Grafana |
| **Secrets Management** | Protect passwords/keys | Vault |

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| DevOps Roadmap | https://roadmap.sh/devops | Free learning path |
| The Phoenix Project (Book) | https://itrevolution.com/the-phoenix-project | Book |
| DevOps Handbook | https://itrevolution.com/the-devops-handbook | Book |
| Google SRE Book | https://sre.google/sre-book/table-of-contents | Free online |

---

## Chapter 2: Linux Basics

### What is Linux?

**Linux** = An operating system (like Windows or macOS) that runs most servers in the world.

**Analogy:** Linux is like the engine of a car — you don't see it, but it makes everything run.

### Why Linux?

- **Free** — No license cost
- **Secure** — Less viruses than Windows
- **Stable** — Can run for years without restarting
- **Fast** — Uses fewer resources than Windows
- **Everywhere** — 90%+ of servers run Linux

### Essential Commands

#### Navigation

```bash
pwd                 # Where am I? (Print Working Directory)
ls                  # What's here? (List)
ls -la              # List all files with details
cd /home            # Go to /home directory
cd ..               # Go up one directory
cd ~                # Go to home directory
```

#### Files

```bash
touch file.txt      # Create empty file
mkdir mydir         # Create directory
cp file.txt copy.txt # Copy file
mv file.txt new.txt # Rename/move file
rm file.txt         # Delete file
rm -rf mydir        # Delete directory and contents
cat file.txt        # Show file contents
nano file.txt       # Edit file (beginner-friendly)
```

#### System

```bash
top                 # See running processes
htop                # Better process viewer
df -h               # See disk space
free -h             # See memory usage
uname -a            # See system info
whoami              # Who am I logged in as?
```

#### Networking

```bash
ip addr             # See IP addresses
ping google.com     # Test connection
curl google.com     # Fetch webpage
ssh user@server     # Connect to remote server
scp file.txt user@server:/path  # Copy file to server
```

#### Permissions

```bash
chmod +x script.sh  # Make file executable
chmod 755 file.txt  # Set permissions (owner: rwx, group: rx, others: rx)
chown user:group file  # Change owner
```

### Practice Exercise

```bash
# Try these commands on your machine:
1. Open terminal
2. Type: pwd
3. Type: ls -la
4. Type: mkdir test-dir
5. Type: cd test-dir
6. Type: touch hello.txt
7. Type: ls
8. Type: cd ..
9. Type: rm -rf test-dir
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Linux Journey | https://linuxjourney.com | Free interactive course |
| The Linux Command Line | https://linuxcommand.org | Free online book |
| Ubuntu Tutorials | https://ubuntu.com/tutorials | Official |
| Linux Survival | https://linuxsurvival.com | Interactive tutorial |

---

## Chapter 3: Docker & Containers

### What is a Container?

**Container** = A lightweight, isolated environment that runs an application with everything it needs.

**Analogy:** 
- **Without containers:** You install Python, Node.js, and Java on your computer. They might conflict with each other.
- **With containers:** Each app runs in its own "box" with its own dependencies. They can't interfere with each other.

### Container vs Virtual Machine

| Feature | Container | Virtual Machine |
|---------|-----------|-----------------|
| **Size** | Megabytes | Gigabytes |
| **Start time** | Seconds | Minutes |
| **Isolation** | Process level | Hardware level |
| **OS** | Shares host OS | Has own OS |
| **Performance** | Near native | Slower |

### Docker Concepts

```
┌─────────────────────────────────────┐
│           DOCKER IMAGE              │
│  (Blueprint for creating containers)│
│  - Contains: app code + dependencies│
│  - Stored in: Docker Hub/ECR        │
│  - Created from: Dockerfile         │
└─────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────┐
│          DOCKER CONTAINER           │
│  (Running instance of an image)     │
│  - Has: its own filesystem          │
│  - Has: its own network             │
│  - Can: be started/stopped/deleted  │
└─────────────────────────────────────┘
```

### Dockerfile Explained

```dockerfile
# Start from a base image
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package files first (for caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source code
COPY . .

# Expose port (documentation only)
EXPOSE 3000

# Command to run when container starts
CMD ["npm", "start"]
```

### Docker Commands

```bash
# Images
docker build -t myapp:latest .     # Build image from Dockerfile
docker images                      # List all images
docker rmi myapp:latest            # Delete image

# Containers
docker run -d -p 3000:3000 myapp   # Run container (detached, port mapping)
docker ps                          # List running containers
docker ps -a                       # List all containers
docker stop <container_id>         # Stop container
docker rm <container_id>           # Delete container
docker logs <container_id>         # See container logs
docker exec -it <container_id> sh  # Enter container shell

# Cleanup
docker system prune -a             # Delete everything unused
```

### Docker Compose

**Docker Compose** = A tool for running multiple containers together.

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Frontend
  frontend:
    build: ./frontend
    ports:
      - "8080:80"
    depends_on:
      - backend

  # Backend API
  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=mysql://db:3306/myapp
    depends_on:
      - db

  # Database
  db:
    image: mysql:8
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=myapp
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

```bash
# Commands
docker compose up -d              # Start all containers
docker compose down               # Stop all containers
docker compose logs -f            # See all logs
docker compose ps                 # List containers
```

### Your Project — Docker Files

```
src/
├── ai-service/
│   └── Dockerfile              # Python FastAPI
├── order-service/
│   └── Dockerfile              # Node.js Fastify
├── product-service/
│   └── Dockerfile              # Rust actix-web
├── makeline-service/
│   └── Dockerfile              # Go gin
├── store-front/
│   └── Dockerfile              # Vue.js nginx
└── store-admin/
    └── Dockerfile              # Vue.js nginx
```

### Practice Exercise

```bash
# Run your first container
1. docker run -d -p 8080:80 nginx    # Run nginx web server
2. Open browser: http://localhost:8080
3. docker ps                          # See it running
4. docker stop <id>                   # Stop it
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Docker Official Getting Started | https://docs.docker.com/get-started | Official |
| Docker Tutorial for Beginners | https://docs.docker.com/get-started/introduction | Official |
| Docker Labs (Interactive) | https://labs.play-with-docker.com | Hands-on |
| Docker Curriculum | https://docker-curriculum.com | Free course |
| Play with Docker | https://labs.play-with-docker.com | Live playground |

---

## Chapter 4: Kubernetes Concepts

### What is Kubernetes?

**Kubernetes (K8s)** = A system for managing containers across multiple servers.

**Analogy:**
- **Docker** = A shipping container (holds one app)
- **Kubernetes** = A shipping company (manages thousands of containers, decides where they go, monitors them, replaces them if they break)

### Why Kubernetes?

| Problem | Kubernetes Solution |
|---------|---------------------|
| "My app crashed" | Automatically restart it |
| "I need more power" | Add more containers (scale up) |
| "Traffic is spiking" | Add more containers automatically |
| "Server is full" | Move containers to another server |
| "Deploy new version" | Rolling update (zero downtime) |

### Kubernetes Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CONTROL PLANE (Master)                │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   API        │  │  Scheduler  │  │ Controller  │    │
│  │   Server     │  │             │  │ Manager     │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐                      │
│  │  etcd        │  │  Cloud      │                      │
│  │  (database)  │  │  Controller │                      │
│  └─────────────┘  └─────────────┘                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    WORKER NODES                          │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │    │
│  │             │  │             │  │             │    │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │    │
│  │ │  Pod A  │ │  │ │  Pod C  │ │  │ │  Pod E  │ │    │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │    │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │    │
│  │ │  Pod B  │ │  │ │  Pod D  │ │  │ │  Pod F  │ │    │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Key Concepts

#### Pod
**Pod** = The smallest unit in Kubernetes. Contains one or more containers.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app
    image: nginx:latest
    ports:
    - containerPort: 80
```

#### Deployment
**Deployment** = Manages Pods. Ensures the right number of Pods are running.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3          # Run 3 copies
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:latest
        ports:
        - containerPort: 80
```

#### Service
**Service** = Exposes Pods to the network. Provides a stable IP address.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer    # External access
```

#### Ingress
**Ingress** = Routes external traffic to Services based on domain/URL.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

### kubectl Commands

```bash
# Get info
kubectl get nodes                    # List all nodes
kubectl get pods                     # List all pods
kubectl get pods -o wide             # List pods with more info
kubectl get services                 # List all services
kubectl get deployments              # List all deployments
kubectl get ingress                  # List all ingresses

# Describe (detailed info)
kubectl describe pod <pod-name>      # Pod details
kubectl describe node <node-name>    # Node details

# Logs
kubectl logs <pod-name>              # See pod logs
kubectl logs -f <pod-name>           # Follow logs (live)

# Execute
kubectl exec -it <pod-name> -- sh    # Enter pod shell

# Delete
kubectl delete pod <pod-name>        # Delete pod
kubectl delete deployment <name>     # Delete deployment

# Apply/Create
kubectl apply -f file.yaml           # Create/update from file
kubectl create deployment nginx --image=nginx  # Quick create
```

### Your Project — Kubernetes Resources

```
application_services/
├── ai-service.yaml              # Deployment + Service
├── order_service.yaml           # Deployment + Service
├── product_service.yaml         # Deployment + Service
├── makeline_service.yaml        # Deployment + Service
├── store_admin_service.yaml     # Deployment + Service
├── store_front_service.yaml     # Deployment + Service
├── mongodb_statefulset.yaml     # Database (StatefulSet)
├── rabbit_mq.yaml               # Message queue
└── ingress_service.yaml         # Ingress rules
```

### Practice Exercise

```bash
# Deploy nginx to Kubernetes
1. kubectl create deployment nginx --image=nginx
2. kubectl get pods                    # Wait for it to be Ready
3. kubectl expose deployment nginx --port=80 --type=NodePort
4. kubectl get services                # See the service
5. kubectl delete deployment nginx     # Clean up
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Kubernetes Official Tutorials | https://kubernetes.io/docs/tutorials/kubernetes-basics | Official |
| Hello Minikube | https://kubernetes.io/docs/tutorials/hello-minikube | Official |
| Kubernetes Basics (6 modules) | https://v1-36.docs.kubernetes.io/docs/tutorials/kubernetes-basics | Official |
| Killercoda (Interactive) | https://killercoda.com/playgrounds/scenario/kubernetes | Hands-on |
| Kubernetes The Hard Way | https://github.com/kelseyhightower/kubernetes-the-hard-way | GitHub |

---

## Chapter 5: Networking Basics

### What is Networking?

**Networking** = How computers talk to each other.

**Analogy:** Like a phone system — each computer has a phone number (IP address), and they communicate through a network (the internet/LAN).

### Key Concepts

#### IP Address
**IP Address** = A unique number for each computer on a network.

```
10.195.94.80     # Your k3s-master
10.195.94.81     # Your k3s-worker-1
100.100.13.113   # Your k3s-worker-2 (Tailscale)
```

#### Port
**Port** = A "door" on a computer for specific services.

```
Port 22    = SSH (remote login)
Port 80    = HTTP (web traffic)
Port 443   = HTTPS (secure web traffic)
Port 6443  = Kubernetes API server
```

#### DNS
**DNS** = Translates names to IP addresses.

```
google.com  →  142.250.80.46
k3s-master  →  10.195.94.80
```

#### Subnet
**Subnet** = A group of computers on the same network.

```
10.195.94.0/24    # Your local subnet (254 computers)
100.100.13.0/24   # Tailscale subnet
```

### Tailscale VPN

**Tailscale** = A tool that connects computers across different networks securely.

```
┌─────────────────┐          ┌─────────────────┐
│   PC1 (antix)   │          │   PC2 (i3)      │
│   10.195.94.1   │  Tailscale│  10.195.94.1    │
│                 │◄────────►│                 │
│   Tailscale IP: │  VPN     │   Tailscale IP: │
│   100.110.171.119│         │   100.100.13.113 │
└─────────────────┘          └─────────────────┘
```

### Your Project — Network Layout

```
┌─────────────────────────────────────────────────────────┐
│                    LOCAL NETWORK (10.195.94.0/24)        │
│                                                         │
│  PC1 (antix)                                            │
│  ├── k3s-master   = 10.195.94.80                       │
│  └── k3s-worker-1 = 10.195.94.81                       │
│                                                         │
│  PC2 (i3)                                               │
│  └── k3s-worker-2 = 10.195.94.82 (local)               │
│                   = 100.100.13.113 (Tailscale)          │
└─────────────────────────────────────────────────────────┘
                          │
                          │ Tailscale VPN
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    CLOUD (Optional)                      │
│                                                         │
│  AWS EKS Cluster                                        │
│  ├── Control Plane (managed by AWS)                     │
│  └── Worker Nodes (EC2 instances)                       │
└─────────────────────────────────────────────────────────┘
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Tailscale Official Docs | https://tailscale.com/kb | Official |
| Tailscale Getting Started | https://tailscale.com/kb/1017/install | Official |
| Computer Networking (Coursera) | https://www.coursera.org/learn/computer-networking | Course |

---

# PART 2: INFRASTRUCTURE (Intermediate)

---

## Chapter 6: Infrastructure as Code (OpenTofu/Terraform)

### What is Infrastructure as Code?

**Infrastructure as Code (IaC)** = Defining servers and networks in text files instead of clicking buttons.

**Analogy:**
- **Without IaC:** You manually create servers in a web interface (click, click, click).
- **With IaC:** You write a text file saying "I want 3 servers with 4 CPU and 4GB RAM" and a tool creates them automatically.

### Why IaC?

| Problem (Manual) | Solution (IaC) |
|------------------|----------------|
| Takes hours to set up servers | Takes minutes |
| Inconsistent environments | Same environment every time |
| No documentation | Code IS documentation |
| Hard to replicate | One command to create everything |
| Expensive mistakes | Preview changes before applying |

### OpenTofu vs Terraform

| | OpenTofu | Terraform |
|---|----------|-----------|
| **License** | Open source (MPL 2.0) | Business Source License |
| **Maintained by** | Linux Foundation | HashiCorp |
| **Compatibility** | Same language as Terraform | Original |
| **Command** | `tofu` | `terraform` |
| **Best for** | Open source projects | Enterprise (with license) |

### The 3 Main Commands

```bash
tofu init      # "Download ingredients" (plugins, providers)
tofu plan      # "Preview the recipe" (see what will be created)
tofu apply     # "Cook the meal" (actually create the servers)
```

### OpenTofu Files Explained

#### 1. `providers.tf` — "Who creates the servers?"

```hcl
terraform {
  required_providers {
    incus = {
      source = "registry.opentofu.org/lxc/incus"
    }
  }
}

provider "incus" {}
```

**Translation:** "Hey OpenTofu, use Incus to create servers."

#### 2. `variables.tf` — "What settings do I use?"

```hcl
variable "master_cpu" {
  default = 4
}

variable "master_ram" {
  default = "4GB"
}
```

**Translation:** "These are the values I can change later."

#### 3. `main.tf` — "What servers do I want?"

```hcl
resource "incus_instance" "k3s-master" {
  name = "k3s-master"
  image = "ubuntu-noble"

  limits = {
    cpu = var.master_cpu
    memory = var.master_ram
  }
}
```

**Translation:** "Create a container named k3s-master with 4 CPU and 4GB RAM."

#### 4. `outputs.tf` — "What info do I want to see?"

```hcl
output "master_ip" {
  value = incus_instance.k3s-master.ipv4_address
}
```

**Translation:** "After creating, show me the master's IP address."

### The Flow

```
┌─────────────────────────────────────┐
│ 1. You write: main.tf               │
│    "I want 3 containers"            │
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│ 2. Run: tofu init                   │
│    "Download Incus plugin"          │
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│ 3. Run: tofu plan                   │
│    "Preview: will create 3 items"   │
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│ 4. Run: tofu apply                  │
│    "Actually create them"           │
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│ 5. Result: 3 containers running     │
│    k3s-master   = 10.195.94.80     │
│    k3s-worker-1 = 10.195.94.81     │
│    k3s-worker-2 = 100.100.13.113   │
└─────────────────────────────────────┘
```

### Key Concepts

| Concept | What It Is | Example |
|---------|-----------|---------|
| **Provider** | Plugin that talks to cloud/server | `incus` provider talks to Incus |
| **Resource** | What you want to create | `incus_instance` = a container |
| **Variable** | Changeable setting | `master_cpu = 4` |
| **Output** | Info to show after creation | `master_ip = 10.195.94.80` |
| **State** | Memory of what exists | `.tfstate` file tracks created items |
| **Plan** | Preview of changes | Shows what will be created/changed |

### Your Project Structure

```
ansible-opentofu/terraform/
├── providers.tf        # "Use Incus"
├── variables.tf        # "Default settings"
├── pc1/                # PC1 (antix)
│   ├── main.tf         # "Create k3s-master + k3s-worker-1"
│   └── outputs.tf      # "Show me their IPs"
└── pc2/                # PC2 (i3)
    ├── main.tf         # "Create k3s-worker-2"
    └── outputs.tf      # "Show me its IP"
```

### Commands Reference

```bash
tofu init                    # Initialize (download plugins)
tofu plan                    # Preview changes
tofu apply                   # Apply changes
tofu apply -auto-approve     # Apply without confirmation
tofu destroy                 # Delete everything
tofu state list              # List created resources
tofu state show <resource>   # Show resource details
tofu import <resource> <id>  # Import existing resource
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| OpenTofu Official Docs | https://opentofu.org/docs/intro | Official |
| OpenTofu Getting Started | https://opentofu.org/docs/intro/core-workflow | Official |
| OpenTofu Language Docs | https://opentofu.org/docs/language | Official |
| Spacelift OpenTofu Tutorial | https://spacelift.io/blog/opentofu-tutorial | Tutorial |
| Terraform Registry | https://registry.opentofu.org | Providers/Modules |

---

## Chapter 7: Configuration Management (Ansible)

### What is Ansible?

**Ansible** = A tool that configures servers for you using code.

**Analogy:** Instead of SSH-ing into each server and typing commands one by one, you write a text file saying "install Docker on all servers" and Ansible does it on all of them at once.

### Why Ansible?

| Problem (Manual) | Solution (Ansible) |
|------------------|-------------------|
| SSH into 100 servers one by one | Run one command on all 100 |
| Inconsistent configurations | Same config everywhere |
| No documentation | Code IS documentation |
| Human errors | Automated, repeatable |
| Takes hours | Takes seconds |

### Ansible Architecture

```
┌─────────────────────────────────────┐
│         CONTROL MACHINE             │
│         (Your computer)             │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ansible-playbook site.yml  │   │
│  └─────────────────────────────┘   │
│              │                      │
│              │ SSH                  │
│              ▼                      │
├─────────────────────────────────────┤
│         REMOTE SERVERS              │
│                                     │
│  ┌───────────┐  ┌───────────┐     │
│  │ Server 1  │  │ Server 2  │     │
│  │ (Master)  │  │ (Worker)  │     │
│  └───────────┘  └───────────┘     │
└─────────────────────────────────────┘
```

### Ansible Files Explained

#### 1. `ansible.cfg` — "How to connect?"

```ini
[defaults]
inventory = inventory/hosts.ini    # Where server list is
remote_user = root                 # SSH as root
host_key_checking = False          # Skip "yes/no" prompt

[privilege_escalation]
become = True                      # Use sudo

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no
```

**Translation:** "Connect as root, use sudo, skip host key verification."

#### 2. `inventory/hosts.ini` — "Who to talk to?"

```ini
[all:vars]
ansible_user=root
ansible_become=yes
ansible_python_interpreter=/usr/bin/python3

[k3s-master]
k3s-master ansible_host=10.195.94.80

[k3s-workers]
k3s-worker-1 ansible_host=10.195.94.81
k3s-worker-2 ansible_host=100.100.13.113

[k3s_cluster:children]
k3s-master
k3s-workers
```

**Translation:** "Here are my 3 servers with their IPs (SSH keys, never passwords — see `setup-ssh-keys.sh`)."

#### 3. `site.yml` — "What to do?"

```yaml
- name: Configure all nodes
  hosts: k3s_cluster
  become: true
  roles:
    - common

- name: Install k3s master
  hosts: k3s_master
  become: true
  roles:
    - k3s-master
```

**Translation:** "On all servers, run common setup. On master, install K3s server."

### Ansible Concepts

| Concept | What It Is | Example |
|---------|-----------|---------|
| **Inventory** | List of servers | `hosts.ini` |
| **Playbook** | What to do | `site.yml` |
| **Task** | Single action | "Install curl" |
| **Role** | Reusable task group | `common/`, `k3s-master/` |
| **Handler** | Triggered action | "If curl installed, restart service" |
| **Facts** | Server info | "This server has 4GB RAM" |
| **Variables** | Changeable values | `password = rafaa` |

### Commands Reference

```bash
# Test connectivity
ansible all -m ping

# Run a command on all servers
ansible all -m shell -a "uptime"

# Run a playbook
ansible-playbook site.yml

# Run specific role
ansible-playbook site.yml --tags k3s-master

# Dry run (preview)
ansible-playbook site.yml --check

# Verbose output
ansible-playbook site.yml -vvv
```

### Your Project — Ansible Structure

```
ansible/
├── ansible.cfg              # Connection settings
├── inventory/
│   └── hosts.ini           # Server list
├── site.yml                # Master playbook
└── roles/
    ├── common/             # Base setup (all nodes)
    ├── k3s-master/         # Install K3s server
    ├── k3s-worker/         # Install K3s agent
    ├── tools/              # Install kubectl, helm, etc.
    ├── metallb/            # Load balancer
    ├── nginx-ingress/      # Web traffic router
    ├── cert-manager/       # SSL certificates
    ├── monitoring/         # Prometheus + Grafana
    ├── vault/              # Secrets management
    └── argocd/             # GitOps deployment
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Ansible Official Getting Started | https://docs.ansible.com/projects/ansible/latest/getting_started/index.html | Official |
| Ansible Playbook Guide | https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html | Official |
| Ansible Inventory Guide | https://docs.ansible.com/projects/ansible/latest/getting_started/get_started_inventory.html | Official |
| Ansible Quick Start | https://docs.ansible.com/projects/ansible/latest/getting_started/get_started_ansible.html | Official |

---

## Chapter 8: K3s Cluster Setup

### What is K3s?

**K3s** = A lightweight version of Kubernetes, designed for edge devices and small clusters.

**Analogy:**
- **Kubernetes** = A full-size car (powerful, but needs lots of space and fuel)
- **K3s** = A motorcycle (same purpose — transportation — but lighter, faster, uses less resources)

### Why K3s?

| Feature | Kubernetes | K3s |
|---------|------------|-----|
| **Size** | ~1GB | ~50MB |
| **RAM** | ~2GB minimum | ~512MB minimum |
| **Install time** | 15-30 minutes | 1-2 minutes |
| **Dependencies** | Many (etcd, docker, etc.) | Single binary |
| **Best for** | Production clusters | Edge, IoT, development |

### K3s Architecture

```
┌─────────────────────────────────────┐
│         K3S MASTER (Server)         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  K3s Server                 │   │
│  │  - API Server               │   │
│  │  - Scheduler                │   │
│  │  - Controller Manager       │   │
│  │  - etcd (database)          │   │
│  └─────────────────────────────┘   │
│              │                      │
│              │ K3s Token            │
│              ▼                      │
├─────────────────────────────────────┤
│         K3S WORKERS (Agents)        │
│                                     │
│  ┌───────────┐  ┌───────────┐     │
│  │ Worker 1  │  │ Worker 2  │     │
│  │ (Agent)   │  │ (Agent)   │     │
│  │ - kubelet │  │ - kubelet │     │
│  │ - kube-prx│  │ - kube-prx│     │
│  └───────────┘  └───────────┘     │
└─────────────────────────────────────┘
```

### Install K3s

#### On Master (Server Mode)

```bash
# Install K3s server
curl -sfL https://get.k3s.io | sh -s - \
  --disable=traefik \
  --node-ip=10.195.94.80 \
  --advertise-address=10.195.94.80

# Get the node token (for workers to join)
cat /var/lib/rancher/k3s/server/node-token
# Output: K10hash1234567890::server:token1234567890
```

#### On Workers (Agent Mode)

```bash
# Install K3s agent (using master's token)
curl -sfL https://get.k3s.io | sh -s - \
  --server https://10.195.94.80:6443 \
  --token K10hash1234567890::server:token1234567890 \
  --node-ip=10.195.94.81
```

### K3s Commands

```bash
# Check cluster status
k3s kubectl get nodes

# Check pods
k3s kubectl get pods -A

# Check services
k3s kubectl get svc -A

# Get kubeconfig (for external kubectl)
cat /etc/rancher/k3s/k3s.yaml
```

### Your Project — K3s Cluster

| Node | IP | Role | K3s Version |
|------|-----|------|-------------|
| k3s-master | 10.195.94.80 | Server (Control Plane) | v1.36.2+k3s1 |
| k3s-worker-1 | 10.195.94.81 | Agent (runs apps) | v1.36.2+k3s1 |
| k3s-worker-2 | 100.100.13.113 | Agent (runs apps) | v1.36.2+k3s1 |

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| K3s Official Docs | https://docs.k3s.io | Official |
| K3s Getting Started | https://docs.k3s.io/quick-start | Official |
| K3s GitHub | https://github.com/k3s-io/k3s | GitHub |

---

## Chapter 9: Incus Containers

### What is Incus?

**Incus** = A tool for managing system containers (like Docker, but for full operating systems).

**Analogy:**
- **Docker** = Runs apps in containers (like running a single program)
- **Incus** = Runs full OS in containers (like having a virtual machine, but lighter)

### Docker vs Incus

| Feature | Docker | Incus |
|---------|--------|-------|
| **Purpose** | Run apps | Run full OS |
| **Use case** | Microservices | VMs, system containers |
| **Resource usage** | Very light | Light (but more than Docker) |
| **Networking** | Bridge network | Full network stack |
| **Storage** | Volumes | ZFS, LVM, directory |

### Incus Commands

```bash
# List containers
incus list

# Create container
incus launch ubuntu:24.04 my-container

# Start/Stop/Restart
incus start my-container
incus stop my-container
incus restart my-container

# Execute commands
incus exec my-container -- bash

# Delete container
incus delete my-container

# Check network
incus network list
incus network info incusbr0

# Check images
incus image list
```

### Your Project — Incus Containers

```
┌─────────────────────────────────────┐
│         INCUS (on PC1 - antix)      │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  k3s-master                 │   │
│  │  - Ubuntu 24.04             │   │
│  │  - IP: 10.195.94.80         │   │
│  │  - 4 CPU, 4GB RAM           │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  k3s-worker-1               │   │
│  │  - Ubuntu 24.04             │   │
│  │  - IP: 10.195.94.81         │   │
│  │  - 3 CPU, 4GB RAM           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│         INCUS (on PC2 - i3)         │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  k3s-worker-2               │   │
│  │  - Ubuntu 24.04             │   │
│  │  - IP: 100.100.13.113       │   │
│  │  - 2 CPU, 4GB RAM           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Incus Official Docs | https://linuxcontainers.org/incus/docs/main | Official |
| Incus Getting Started | https://linuxcontainers.org/incus/docs/main/getting_started | Official |

---

# PART 3: DEPLOYMENT (Intermediate)

---

## Chapter 10: Helm Charts

### What is Helm?

**Helm** = A package manager for Kubernetes (like apt for Ubuntu, npm for Node.js).

**Analogy:**
- **Without Helm:** You write 100 lines of YAML for each Kubernetes app.
- **With Helm:** You install a pre-made "chart" with one command, like `apt install nginx`.

### Why Helm?

| Problem | Helm Solution |
|---------|---------------|
| Lots of YAML to write | Pre-made charts |
| Hard to share apps | Charts are shareable packages |
| Hard to update | One command to upgrade |
| Hard to rollback | One command to rollback |
| Different configs per env | values.yaml files |

### Helm Concepts

| Concept | What It Is | Analogy |
|---------|-----------|---------|
| **Chart** | A package of K8s resources | Like a .deb or .rpm package |
| **Release** | A running instance of a chart | Like a installed app |
| **Repository** | Collection of charts | Like apt repository |
| **Values** | Configuration options | Like command-line flags |

### Helm Commands

```bash
# Repository management
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx

# Install
helm install my-release bitnami/nginx
helm install my-release bitnami/nginx --set service.type=NodePort

# List
helm list                    # List installed releases
helm list -A                 # List all namespaces

# Upgrade
helm upgrade my-release bitnami/nginx --set replicaCount=3

# Rollback
helm rollback my-release 1

# Uninstall
helm uninstall my-release

# Debug
helm list -A
helm get values my-release
helm history my-release
```

### Your Project — Helm Charts

```
helm-charts/
├── ai-service/           # Custom chart for AI service
├── order-service/        # Custom chart for Order service
├── product-service/      # Custom chart for Product service
├── makeline-service/     # Custom chart for Makeline service
├── store-front/          # Custom chart for Store frontend
├── store-admin/          # Custom chart for Admin panel
├── virtual-customer/     # Custom chart for load generator
├── virtual-worker/       # Custom chart for load worker
├── mongodb/              # MongoDB database
└── rabbitmq/             # RabbitMQ message queue
```

### Chart Structure

```
helm-charts/my-app/
├── Chart.yaml            # Chart metadata (name, version)
├── values.yaml           # Default configuration
├── templates/
│   ├── deployment.yaml   # K8s Deployment template
│   ├── service.yaml      # K8s Service template
│   ├── ingress.yaml      # K8s Ingress template
│   └── _helpers.tpl      # Template helpers
└── README.md             # Documentation
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Helm Official Docs | https://helm.sh/docs | Official |
| Helm Introduction | https://helm.sh/docs/intro | Official |
| Helm Quickstart | https://helm.sh/docs/intro/quickstart | Official |
| Artifact Hub (Charts) | https://artifacthub.io | Charts registry |

---

## Chapter 11: Ingress & Load Balancing

### What is Ingress?

**Ingress** = Routes external web traffic to the right service inside Kubernetes.

**Analogy:** Like a receptionist in a hotel — guests (web traffic) ask for a room, and the receptionist (Ingress) directs them to the right room (service).

### What is Load Balancing?

**Load Balancer** = Distributes traffic across multiple servers.

**Analogy:** Like a traffic cop — cars (requests) come in, and the cop directs them to different lanes (servers) so no lane gets too crowded.

### MetalLB

**MetalLB** = A load balancer for bare-metal Kubernetes (no cloud provider needed).

```
External Traffic
       │
       ▼
┌─────────────────┐
│    MetalLB      │
│ (Load Balancer) │
│ 10.195.94.100-150│
└─────────────────┘
       │
       ▼
┌─────────────────┐
│   K8s Service   │
│  (ClusterIP)    │
└─────────────────┘
       │
       ▼
┌─────────────────┐
│   K8s Pods      │
│ (Replicas)      │
└─────────────────┘
```

### Nginx Ingress Controller

**Nginx Ingress** = Routes web traffic based on domain/URL.

```
https://myapp.example.com          → my-app-service
https://api.example.com/api        → api-service
https://grafana.example.com        → grafana-service
```

### cert-manager

**cert-manager** = Automatically manages SSL/TLS certificates.

```
┌─────────────────┐
│  cert-manager   │
│                 │
│ 1. Detects Ingress with TLS annotation
│ 2. Requests certificate from Let's Encrypt
│ 3. Stores certificate in Secret
│ 4. Auto-renews before expiry
└─────────────────┘
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| MetalLB Official Docs | https://metallb.universe.tf | Official |
| MetalLB Configuration | https://metallb.universe.tf/configuration | Official |
| Nginx Ingress Controller | https://kubernetes.github.io/ingress-nginx | Official |
| cert-manager Official Docs | https://cert-manager.io/docs | Official |
| cert-manager Getting Started | https://cert-manager.io/docs/getting-started | Official |

---

## Chapter 12: GitOps with ArgoCD

### What is GitOps?

**GitOps** = Using Git as the single source of truth for infrastructure and applications.

**Analogy:**
- **Old way:** Deploy apps by SSH-ing into servers and running commands.
- **GitOps way:** Push code to Git, and a tool automatically deploys it.

### What is ArgoCD?

**ArgoCD** = A GitOps tool that automatically deploys apps from Git to Kubernetes.

### How ArgoCD Works

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Git Repo  │     │   ArgoCD    │     │ Kubernetes  │
│             │     │             │     │   Cluster   │
│  Source of  │────►│  Watches    │────►│  Deploys    │
│  Truth      │     │  for changes│     │  apps       │
└─────────────┘     └─────────────┘     └─────────────┘
```

### ArgoCD Commands

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Create application
argocd app create my-app \
  --repo https://github.com/myorg/myrepo.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync (deploy)
argocd app sync my-app

# Check status
argocd app get my-app
```

### Your Project — ArgoCD Apps

```
infrastructure/argocd/applications/
├── app-of-apps.yaml           # Parent app
├── ai-service.yaml            # AI service app
├── order-service.yaml         # Order service app
├── product-service.yaml       # Product service app
├── makeline-service.yaml      # Makeline service app
├── store-front.yaml           # Store frontend app
├── store-admin.yaml           # Admin panel app
├── virtual-customer.yaml      # Load generator app
├── virtual-worker.yaml        # Load worker app
├── rabbitmq.yaml              # RabbitMQ app
└── nginx.yaml                 # Nginx app
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| ArgoCD Official Docs | https://argo-cd.readthedocs.io/en/latest | Official |
| ArgoCD Getting Started | https://argo-cd.readthedocs.io/en/stable/getting_started | Official |
| Argo Project | https://argoproj.github.io/cd | Official |

---

# PART 4: SECURITY (Advanced)

---

## Chapter 13: Secrets Management (Vault)

### What is Vault?

**Vault** = A tool for securely storing and accessing secrets (passwords, API keys, certificates).

**Analogy:** Like a bank vault for your passwords — instead of writing them on sticky notes, you store them securely and control who can access them.

### Why Vault?

| Problem | Vault Solution |
|---------|----------------|
| Passwords in code | Centralized secret storage |
| Hard to rotate secrets | Automatic rotation |
| No audit trail | Complete audit logging |
| Secrets scattered everywhere | Single source of truth |

### Vault Concepts

| Concept | What It Is | Example |
|---------|-----------|---------|
| **Secrets Engine** | Type of secret | KV, Database, PKI |
| **Auth Method** | How to log in | Token, Kubernetes, GitHub |
| **Policy** | Access control | "Can read /secret/*" |
| **Lease** | Temporary access | Token expires in 1 hour |

### Vault Commands

```bash
# Start dev server
vault server -dev

# Authenticate
vault login

# Enable secrets engine
vault secrets enable -path=secret kv

# Store secret
vault kv put secret/my-app password=rafaa

# Get secret
vault kv get secret/my-app

# Enable auth method
vault auth enable kubernetes

# Create policy
vault policy write my-policy - <<EOF
path "secret/data/my-app" {
  capabilities = ["read"]
}
EOF
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Vault Official Docs | https://developer.hashicorp.com/vault/docs | Official |
| Vault Foundations Tutorial | https://developer.hashicorp.com/vault/tutorials/get-started | Official |
| Vault CLI Tutorial | https://docs.hashicorp.com/vault/tutorials/get-started/learn-cli | Official |
| Vault UI Tutorial | https://docs.hashicorp.com/vault/tutorials/get-started/learn-ui | Official |

---

## Chapter 14: CI/CD Security

### What is CI/CD Security?

**CI/CD Security** = Adding security checks to your build and deployment pipeline.

### Security Tools in Your Project

| Tool | Purpose | When It Runs |
|------|---------|--------------|
| **SonarQube** | Static code analysis | Build time |
| **OWASP Dependency Check** | Dependency vulnerabilities | Build time |
| **Trivy** | Container image scanning | Build time |
| **Hadolint** | Dockerfile linting | Build time |
| **Semgrep** | SAST (code patterns) | Build time |
| **Gitleaks** | Secret detection | Build time |
| **tfsec** | Terraform security | Build time |
| **Checkov** | IaC security | Build time |

### Security Pipeline

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Code Push  │────►│  SonarQube  │────►│   OWASP     │
│             │     │  (SAST)     │     │  (Deps)     │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Deploy to  │◄────│    Trivy    │◄────│   Build     │
│  Registry   │     │  (Image)    │     │  (Docker)   │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| SonarQube Docs | https://docs.sonarsource.com/sonarqube/latest | Official |
| Trivy Docs | https://aquasecurity.github.io/trivy | Official |
| OWASP Dependency Check | https://jeremylong.github.io/DependencyCheck | Official |
| Hadolint | https://github.com/hadolint/hadolint | GitHub |

---

## Chapter 15: Service Mesh (Istio)

### What is a Service Mesh?

**Service Mesh** = A dedicated infrastructure layer for managing service-to-service communication.

**Analogy:** Like a postal system for your microservices — it handles delivery, routing, security, and monitoring of all messages between services.

### Why Istio?

| Problem | Istio Solution |
|---------|----------------|
| Hard to secure service communication | Automatic mTLS encryption |
| No visibility into traffic | Traffic monitoring and tracing |
| Hard to implement canary deployments | Traffic splitting |
| No retry/fault tolerance | Automatic retries and circuit breaking |

### Istio Components

```
┌─────────────────────────────────────┐
│           ISTIO CONTROL PLANE       │
│                                     │
│  ┌───────────┐  ┌───────────┐     │
│  │  istiod   │  │  Citadel  │     │
│  │ (Pilot)   │  │ (Cert CA) │     │
│  └───────────┘  └───────────┘     │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│           ISTIO DATA PLANE          │
│                                     │
│  ┌───────────┐  ┌───────────┐     │
│  │  Proxy    │  │  Proxy    │     │
│  │ (Envoy)   │  │ (Envoy)   │     │
│  │ in Pod A  │  │ in Pod B  │     │
│  └───────────┘  └───────────┘     │
└─────────────────────────────────────┘
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Istio Official Docs | https://istio.io/latest/docs | Official |
| Istio Getting Started | https://istio.io/latest/docs/setup/getting-started | Official |

---

# PART 5: OBSERVABILITY (Advanced)

---

## Chapter 16: Monitoring (Prometheus + Grafana)

### What is Monitoring?

**Monitoring** = Watching your systems to know what's happening and detect problems early.

**Analogy:** Like a health tracker on your phone — it watches your heart rate, steps, and sleep, and alerts you if something's wrong.

### Prometheus

**Prometheus** = A tool that collects and stores metrics (numbers) from your systems.

```
┌─────────────────┐     ┌─────────────────┐
│  Your Apps      │     │   Prometheus    │
│  (Metrics)      │────►│   (Collector)   │
│                 │     │                 │
│  - Request rate │     │  - Stores data  │
│  - Error rate   │     │  - Runs queries │
│  - CPU usage    │     │  - Triggers alerts│
└─────────────────┘     └─────────────────┘
```

### Grafana

**Grafana** = A tool that creates dashboards and visualizations from metrics.

```
┌─────────────────┐     ┌─────────────────┐
│   Prometheus    │────►│    Grafana      │
│   (Data)        │     │  (Dashboard)    │
│                 │     │                 │
│  - Time series  │     │  - Graphs       │
│  - Metrics      │     │  - Charts       │
│  - Alerts       │     │  - Alerts       │
└─────────────────┘     └─────────────────┘
```

### Prometheus Commands

```bash
# Query metrics
rate(http_requests_total[5m])          # Requests per second
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))  # 99th percentile latency
sum(container_memory_usage_bytes) by (pod)  # Memory by pod
```

### Your Project — Monitoring Stack

```
monitoring/
├── prometheus/           # Prometheus server
├── grafana/              # Grafana dashboards
├── alertmanager/         # Alert manager
├── kube-state-metrics/   # K8s metrics
├── datadog/              # Datadog agent
├── Custom_Dashboards/    # Pre-built dashboards
│   ├── kubernetes-global.json
│   ├── kubernetes-namespaces.json
│   ├── mongodb.json
│   └── rabbitmq.json
└── correct-alerts-final.yaml  # Alert rules
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Prometheus Official Docs | https://prometheus.io/docs/prometheus/latest/getting_started | Official |
| Prometheus Tutorials | https://prometheus.io/docs/tutorials/getting_started | Official |
| Grafana Official Docs | https://grafana.com/docs/grafana/latest | Official |
| Grafana + Prometheus Guide | https://grafana.com/docs/grafana/latest/getting-started/getting-started-prometheus | Official |

---

## Chapter 17: Logging (EFK, ELK, Loki)

### What is Logging?

**Logging** = Collecting and storing log messages from your applications and systems.

**Analogy:** Like a security camera for your servers — it records everything that happens so you can review it later.

### Logging Stacks

#### EFK Stack (Elasticsearch + Fluentd + Kibana)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Your Apps  │────►│   Fluentd   │────►│Elasticsearch│
│  (Logs)     │     │  (Collector)│     │  (Storage)  │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
                                        ┌─────────────┐
                                        │    Kibana    │
                                        │ (Dashboard)  │
                                        └─────────────┘
```

#### Loki Stack (Grafana Loki)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Your Apps  │────►│    Loki     │────►│   Grafana   │
│  (Logs)     │     │  (Storage)  │     │ (Dashboard) │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Your Project — Logging

```
logging/
├── EFK_Logging/
│   ├── elasticsearch/
│   ├── fluentd/
│   └── kibana/
├── ELK_Logging/
│   ├── elasticsearch.yaml
│   ├── logstash.yaml
│   ├── file_beats.yaml
│   └── kibana.yaml
└── observability/loki/
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Elasticsearch Docs | https://www.elastic.co/guide/en/elasticsearch/reference/current | Official |
| Fluentd Docs | https://docs.fluentd.org | Official |
| Kibana Docs | https://www.elastic.co/guide/en/kibana/current | Official |
| Grafana Loki Docs | https://grafana.com/docs/loki/latest | Official |

---

## Chapter 18: Distributed Tracing (Jaeger)

### What is Distributed Tracing?

**Distributed Tracing** = Tracking a request as it travels through multiple services.

**Analogy:** Like tracking a package from Amazon — you can see each step: warehouse → sorting → delivery truck → your door.

### Why Tracing?

| Problem | Tracing Solution |
|---------|------------------|
| "Where is the bottleneck?" | See which service is slow |
| "Why is this request failing?" | See the full request path |
| "Which service called which?" | See service dependencies |

### Jaeger

**Jaeger** = A distributed tracing system.

```
Request Flow:
User → store-front → order-service → RabbitMQ → makeline-service → MongoDB

Jaeger shows:
├── store-front: 50ms
├── order-service: 120ms
├── RabbitMQ: 10ms
├── makeline-service: 200ms
└── MongoDB: 30ms
Total: 410ms
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Jaeger Official Docs | https://www.jaegertracing.io/docs | Official |
| Jaeger Getting Started | https://www.jaegertracing.io/docs/latest/getting-started | Official |

---

# PART 6: ADVANCED TOPICS

---

## Chapter 19: Argo Rollouts (Canary/Blue-Green)

### What are Deployment Strategies?

| Strategy | How It Works | Use Case |
|----------|--------------|----------|
| **Rolling Update** | Gradually replace old pods with new ones | Default K8s strategy |
| **Canary** | Send 5% traffic to new version, then increase | Safe production deployments |
| **Blue-Green** | Run both versions, switch traffic instantly | Instant rollback |

### Argo Rollouts

**Argo Rollouts** = A Kubernetes controller for advanced deployment strategies.

```
Canary Deployment:
┌─────────────────────────────────────┐
│           Traffic Split             │
│                                     │
│  95% ──────►  Old Version (v1)     │
│  5%  ──────►  New Version (v2)     │
│                                     │
│  After 10 minutes, if no errors:    │
│  100% ─────►  New Version (v2)     │
└─────────────────────────────────────┘
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| Argo Rollouts Docs | https://argo-rollouts.readthedocs.io/en/latest | Official |
| Argo Rollouts Getting Started | https://argo-rollouts.readthedocs.io/en/stable/getting-started | Official |

---

## Chapter 20: Autoscaling (HPA, VPA)

### What is Autoscaling?

**Autoscaling** = Automatically adding or removing resources based on demand.

**Analogy:** Like a taxi company — when there are many passengers, they add more taxis. When it's quiet, they remove some.

### Types of Autoscaling

| Type | What It Scales | How |
|------|----------------|-----|
| **HPA** (Horizontal Pod Autoscaler) | Number of pods | Add more pods when CPU/memory is high |
| **VPA** (Vertical Pod Autoscaler) | Pod resources | Increase CPU/memory per pod |
| **Cluster Autoscaler** | Number of nodes | Add more nodes when pods can't be scheduled |

### HPA Example

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| K8s HPA Docs | https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale | Official |
| K8s VPA Docs | https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler | GitHub |
| K8s Cluster Autoscaler | https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler | GitHub |

---

## Chapter 21: AWS EKS (Cloud)

### What is EKS?

**EKS** = Amazon's managed Kubernetes service.

**Analogy:**
- **Self-managed K8s:** You build and maintain the car yourself.
- **EKS:** You rent a car — AWS maintains the engine (control plane), you just drive.

### EKS Architecture

```
┌─────────────────────────────────────┐
│           AWS CLOUD                 │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      EKS Control Plane      │   │
│  │  (Managed by AWS)           │   │
│  │  - API Server               │   │
│  │  - etcd                     │   │
│  │  - Scheduler                │   │
│  └─────────────────────────────┘   │
│              │                      │
│              │ VPC                  │
│              ▼                      │
│  ┌─────────────────────────────┐   │
│  │      Worker Nodes           │   │
│  │  (EC2 Instances)            │   │
│  │  - Your apps run here       │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Your Project — AWS EKS

```
aws_eks_infrastructure/
├── Env/
│   ├── Dev/         # Development environment
│   ├── Stg/         # Staging environment
│   └── Prod/        # Production environment
└── modules/
    ├── vpc/         # Virtual Private Cloud
    ├── eks/         # EKS cluster
    ├── node-group/  # Worker nodes
    ├── ecr/         # Container registry
    ├── iam/         # Access management
    ├── alb-ingress/ # Load balancer
    └── ebs-csi/     # Storage
```

### Learn More

| Resource | URL | Type |
|----------|-----|------|
| AWS EKS Docs | https://docs.aws.amazon.com/eks | Official |
| EKS Workshop | https://www.eksworkshop.com | Workshop |

---

# APPENDIX: Complete Reference Links

## All Technologies — Official Documentation

| Technology | Official Docs | GitHub |
|------------|---------------|--------|
| Docker | https://docs.docker.com | https://github.com/docker |
| Kubernetes | https://kubernetes.io/docs | https://github.com/kubernetes |
| K3s | https://docs.k3s.io | https://github.com/k3s-io/k3s |
| OpenTofu | https://opentofu.org/docs | https://github.com/opentofu/opentofu |
| Ansible | https://docs.ansible.com | https://github.com/ansible/ansible |
| Helm | https://helm.sh/docs | https://github.com/helm/helm |
| ArgoCD | https://argo-cd.readthedocs.io | https://github.com/argoproj/argo-cd |
| Vault | https://developer.hashicorp.com/vault/docs | https://github.com/hashicorp/vault |
| Prometheus | https://prometheus.io/docs | https://github.com/prometheus/prometheus |
| Grafana | https://grafana.com/docs | https://github.com/grafana/grafana |
| Istio | https://istio.io/docs | https://github.com/istio/istio |
| MetalLB | https://metallb.universe.tf | https://github.com/metallb/metallb |
| cert-manager | https://cert-manager.io/docs | https://github.com/cert-manager/cert-manager |
| Nginx Ingress | https://kubernetes.github.io/ingress-nginx | https://github.com/kubernetes/ingress-nginx |
| Jaeger | https://www.jaegertracing.io/docs | https://github.com/jaegertracing/jaeger |
| Loki | https://grafana.com/docs/loki/latest | https://github.com/grafana/loki |
| Argo Rollouts | https://argo-rollouts.readthedocs.io | https://github.com/argoproj/argo-rollouts |
| Tailscale | https://tailscale.com/kb | https://github.com/tailscale/tailscale |
| Incus | https://linuxcontainers.org/incus/docs | https://github.com/lxc/incus |

## Free Learning Platforms

| Platform | URL | Focus |
|----------|-----|-------|
| Killercoda | https://killercoda.com | Interactive Kubernetes labs |
| KodeKloud | https://kodekloud.com | DevOps courses |
| Play with Docker | https://labs.play-with-docker.com | Docker labs |
| Play with Kubernetes | https://labs.play-with-k8s.com | Kubernetes labs |
| Cloud Resume Challenge | https://cloudresumechallenge.dev | AWS project |

## YouTube Channels

| Channel | Focus |
|---------|-------|
| TechWorld with Nana | DevOps tutorials |
| The Linux Experiment | Linux & containers |
| KodeKloud | DevOps courses |
| Kubernetes | Official channel |
| HashiCorp | Vault, Terraform |

## Books

| Book | Author | Focus |
|------|--------|-------|
| The Phoenix Project | Gene Kim | DevOps culture |
| The DevOps Handbook | Gene Kim | DevOps practices |
| Kubernetes in Action | Marko Lukša | Kubernetes |
| Terraform: Up & Running | Yevgeniy Brikman | IaC |
| Docker Deep Dive | Nigel Poulton | Docker |
| Site Reliability Engineering | Google | SRE |

---

*Last Updated: 2026-09-08*
*Total Technologies Covered: 20+*
*Total Reference Links: 100+*
