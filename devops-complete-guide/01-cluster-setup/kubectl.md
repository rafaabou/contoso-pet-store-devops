# kubectl — Complete Guide

> The definitive reference for Kubernetes' command-line interface.

---

## Table of Contents

1. [What Is kubectl?](#1-what-is-kubectl)
2. [Installation](#2-installation)
3. [Configuration](#3-configuration)
4. [Core Commands](#4-core-commands)
5. [Resource Types](#5-resource-types)
6. [Output Formats](#6-output-formats)
7. [Filtering & Selection](#7-filtering--selection)
8. [Debugging](#8-debugging)
9. [Deployment](#9-deployment)
10. [Config Management](#10-config-management)
11. [Advanced Commands](#11-advanced-commands)
12. [Aliases & Shortcuts](#12-aliases--shortcuts)
13. [JSONPath Expressions](#13-jsonpath-expressions)
14. [Command Reference](#14-command-reference)
15. [Troubleshooting](#15-troubleshooting)
16. [Tips & Best Practices](#16-tips--best-practices)
17. [Real-World Examples](#17-real-world-examples)
18. [Further Reading](#18-further-reading)

---

## 1. What Is kubectl?

kubectl (pronounced "kube-C-T-L" or "kube-control") is the official command-line tool for interacting with a Kubernetes cluster. It sends HTTP requests to the Kubernetes API server and displays the responses.

### How It Works

```
┌──────────┐     HTTPS/JSON      ┌──────────────┐     etcd     ┌────────┐
│  kubectl │ ──────────────────►  │  API Server  │ ◄──────────► │  etcd  │
│  (CLI)   │ ◄──────────────────  │  (port 6443) │              │  store │
└──────────┘    JSON response     └──────┬───────┘              └────────┘
                                         │
                                    ┌────┴────┐
                                    │ kubelet │ ──► container runtime
                                    │ controller│
                                    │ scheduler│
                                    └─────────┘
```

When you run `kubectl get pods`, the tool:

1. Reads your `~/.kube/config` to find the API server URL and credentials.
2. Opens an HTTPS connection to the API server (e.g. `https://192.168.1.100:6443`).
3. Sends a request like `GET /api/v1/namespaces/default/pods`.
4. The API server validates your token/certificate, then queries etcd.
5. Returns JSON which kubectl formats and prints to your terminal.

### Key Concepts

- **Declarative vs Imperative**: `kubectl apply -f file.yaml` is declarative (tell K8s what you want). `kubectl create deployment nginx --image=nginx` is imperative (tell K8s to do something now).
- **API Groups**: Resources are organized into groups (`core`, `apps`, `batch`, `networking.k8s.io`, etc.). kubectl abstracts this — `kubectl get ingress` just works.
- **Server-Side vs Client-Side**: `kubectl apply` can apply changes server-side (the API server does the merge), avoiding conflicts with other tools.

---

## 2. Installation

### 2.1 Direct Binary Download

```bash
# Linux amd64
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

### 2.2 Package Manager (Ubuntu/Debian)

```bash
# Add Kubernetes apt repository
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
```

### 2.3 Snap (Ubuntu)

```bash
sudo snap install kubectl --classic
```

### 2.4 macOS

```bash
# Homebrew
brew install kubectl

# or MacPorts
sudo port install kubectl
```

### 2.5 Windows

```powershell
# Chocolatey
choco install kubernetes-cli

# winget
winget install Kubernetes.kubectl
```

### 2.6 Shell Completion

**Bash:**

```bash
# Install completion (requires bash-completion package)
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

# Or for user-only
kubectl completion bash > ~/.kube/completion.bash.inc
echo 'source ~/.kube/completion.bash.inc' >> ~/.bashrc
```

**Zsh:**

```bash
kubectl completion zsh > "${fpath[1]}/_kubectl"
# or
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
```

**Fish:**

```fish
kubectl completion fish | source
# or save to config
kubectl completion fish > ~/.config/fish/completions/kubectl.fish
```

**PowerShell:**

```powershell
kubectl completion powershell | Out-String | Invoke-Expression
# or save to profile
kubectl completion powershell > kubectl.ps1
# then add: . .\kubectl.ps1 to $PROFILE
```

### 2.7 Kubernetes-aware Shell Prompt

```bash
# Install kube-ps1
git clone https://github.com/jonmosco/kube-ps1.git
source "kube-ps1/kube-ps1.sh"

# Add to .bashrc
echo 'source "kube-ps1/kube-ps1.sh"' >> ~/.bashrc

# Customize prompt colors
KUBE_PS1_SEPARATOR='|'
KUBE_PS1_NS_COLOR="red"
KUBE_PS1_CTX_COLOR="cyan"
```

Prompt output: `(⎈ |my-cluster:production) $` — shows current context and namespace.

### 2.8 Version Checking

```bash
# Client only
kubectl version --client

# Client + server (requires cluster access)
kubectl version --short

# Output as YAML
kubectl version -o yaml

# Check if cluster is reachable
kubectl cluster-info
kubectl cluster-info dump  # verbose cluster state
```

---

## 3. Configuration

### 3.1 Kubeconfig File Structure

The kubeconfig file (`~/.kube/config` by default, or `$KUBECONFIG`) contains three main sections:

```yaml
apiVersion: v1
kind: Config
current-context: my-production-context   # which context is active

clusters:          # list of cluster endpoints
- name: my-production-cluster
  cluster:
    server: https://10.0.1.100:6443
    certificate-authority: /path/to/ca.crt
    # or inline:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUS...
    # skip TLS verify (DANGEROUS, lab only)
    # insecure-skip-tls-verify: true

users:             # authentication credentials
- name: admin
  user:
    client-certificate: /path/to/admin.crt
    client-key: /path/to/admin.key
    # or token-based:
    # token: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
    # or exec-based (e.g. cloud provider auth):
    # exec:
    #   apiVersion: client.authentication.k8s.io/v1beta1
    #   command: aws
    #   args: ["eks", "get-token", "--cluster-name", "my-cluster"]

contexts:          # maps user+cluster+namespace
- name: my-production-context
  context:
    cluster: my-production-cluster
    user: admin
    namespace: production
```

### 3.2 Multiple Kubeconfigs

```bash
# Merge multiple files (colon-separated)
export KUBECONFIG=~/.kube/config:~/.kube/config-staging:~/.kube/config-dev

# kubectl sees all clusters/contexts from all files
kubectl config get-contexts
```

### 3.3 Context Management

```bash
# List all contexts
kubectl config get-contexts
kubectl config current-context

# Switch context
kubectl config use-context my-production-context

# Switch namespace within current context
kubectl config set-context --current --namespace=production

# Create a new context
kubectl config set-context dev-context \
  --cluster=dev-cluster \
  --user=dev-user \
  --namespace=development

# Delete a context
kubectl config delete-context old-context

# Rename a context
kubectl config rename-context old-name new-name
```

### 3.4 Cluster Information

```bash
# Show current cluster info
kubectl cluster-info
kubectl cluster-info dump                    # full dump to stdout
kubectl cluster-info dump --output-directory=/tmp/cluster-dump

# View API server endpoints
kubectl get endpoints kubernetes -n default
```

### 3.5 Authentication Methods

```bash
# Certificate-based
kubectl config set-credentials myuser \
  --client-certificate=myuser.crt \
  --client-key=myuser.key

# Token-based
kubectl config set-credentials myuser --token=mytoken123

# Exec-based (OIDC / cloud providers)
kubectl config set-credentials myuser \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://accounts.google.com \
  --exec-arg=--oidc-client-id=my-client-id
```

### 3.6 Environment Variables

```bash
# Override kubeconfig location
export KUBECONFIG=/custom/path/to/config

# Override API server
export KUBERNETES_MASTER=https://10.0.1.100:6443

# kubectl debug flags
export KUBECTL_EXTERNAL_DIFF="diff --color=auto"
```

---

## 4. Core Commands

### 4.1 `kubectl get` — List Resources

```bash
# Basic listing
kubectl get pods
kubectl get pods -n kube-system
kubectl get pods --all-namespaces

# Different resource types
kubectl get deployments
kubectl get services
kubectl get nodes
kubectl get namespaces
kubectl get events

# Wide output (extra columns)
kubectl get pods -o wide

# Show labels
kubectl get pods --show-labels

# Sort by field
kubectl get pods --sort-by='.status.startTime'
kubectl get pods --sort-by='.metadata.creationTimestamp'

# Watch for changes
kubectl get pods -w

# Output as YAML or JSON
kubectl get pod my-pod -o yaml
kubectl get pod my-pod -o json

# Custom columns
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
STATUS:.status.phase,\
NODE:.spec.nodeName,\
IP:.status.podIP

# Using go-template
kubectl get pods -o go-template --template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'

# Export (strip server-managed fields)
kubectl get deployment my-deploy -o yaml --export

# Raw API output
kubectl get --raw /api/v1/namespaces
kubectl get --raw /metrics
```

### 4.2 `kubectl describe` — Detailed Information

```bash
# Pod details (events, conditions, container states)
kubectl describe pod my-pod
kubectl describe pod my-pod -n production

# Node details (capacity, allocatable, conditions)
kubectl describe node k3s-worker-1

# Deployment details
kubectl describe deployment my-deploy

# Service details (endpoints, ports)
kubectl describe svc my-service

# Describe all resources of a type
kubectl describe pods -n kube-system

# Describe a specific resource
kubectl describe deployment nginx -n default
```

### 4.3 `kubectl create` — Imperative Creation

```bash
# Create from command line
kubectl create deployment nginx --image=nginx:1.25 --replicas=3
kubectl create namespace staging
kubectl create secret generic db-pass --from-literal=password=supersecret
kubectl create configmap app-config --from-file=config.yaml
kubectl create service clusterip my-svc --tcp=80:8080
kubectl create job my-job --image=busybox --date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
kubectl create cronjob my-cron --image=busybox --schedule="0 */6 * * *" -- echo "hello"

# From YAML
kubectl create -f deployment.yaml
kubectl create -f https://example.com/resource.yaml

# Dry run (preview without applying)
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
kubectl create namespace test --dry-run=client -o yaml
```

### 4.4 `kubectl apply` — Declarative Management

```bash
# Apply a file
kubectl apply -f deployment.yaml
kubectl apply -f dir/                  # all YAML files in directory
kubectl apply -f https://example.com/configs/

# Recurse into directories
kubectl apply -f dir/ -R

# Server-side apply
kubectl apply -f config.yaml --server-side
kubectl apply -f config.yaml --server-side --force-conflicts

# Dry run
kubectl apply -f config.yaml --dry-run=server
kubectl apply -f config.yaml --dry-run=client

# Diff before applying
kubectl diff -f config.yaml
```

### 4.5 `kubectl delete` — Remove Resources

```bash
# Delete by name
kubectl delete pod my-pod
kubectl delete deployment my-deploy
kubectl delete svc my-service

# Delete from file
kubectl delete -f deployment.yaml

# Delete by label
kubectl delete pods -l app=nginx
kubectl delete pods -l 'env in (dev, staging)'

# Delete by field selector
kubectl delete pods --field-selector=status.phase=Failed

# Delete all resources of a type
kubectl delete pods --all
kubectl delete deployments --all -n production

# Delete all resources matching a label
kubectl delete all -l app=my-app

# Delete namespace (everything inside!)
kubectl delete namespace staging

# Force delete (skip grace period)
kubectl delete pod my-pod --grace-period=0 --force
kubectl delete pod my-pod -n kube-system --force --grace-period=0

# Delete resources not in a file (conflict detection)
kubectl delete -f config.yaml --cascade=foreground
```

### 4.6 `kubectl explain` — Documentation Lookup

```bash
# Explain any resource
kubectl explain pods
kubectl explain pods.spec
kubectl explain pods.spec.containers
kubectl explain pods.spec.containers.resources

# Recursive (all nested fields)
kubectl explain pods --recursive

# Specific version
kubectl explain pods --api-version=apps/v1
```

### 4.7 `kubectl edit` — Edit Resources in Place

```bash
# Opens resource in $EDITOR (vim/nano)
kubectl edit deployment my-deploy
kubectl edit svc my-service -n production

# Edit specific field
kubectl edit deployment my-deploy -o yaml

# Non-interactive edits (specify editor)
KUBE_EDITOR="code --wait" kubectl edit deployment my-deploy
```

### 4.8 `kubectl patch` — Update Fields

```bash
# Strategic merge patch
kubectl patch deployment my-deploy --type=strategic \
  -p '{"spec":{"replicas":5}}'

# JSON patch
kubectl patch deployment my-deploy --type=json \
  -p '[{"op":"replace","path":"/spec/replicas","value":3}]'

# Patch with a file
kubectl patch deployment my-deploy --type=strategic -p patch.yaml

# Patch specific containers
kubectl patch deployment my-deploy --type=strategic \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.26"}]}}}}'

# Patch node taints
kubectl patch node k3s-worker-1 --type=json \
  -p '[{"op":"add","path":"/spec/taints/-","value":{"key":"dedicated","value":"gpu","effect":"NoSchedule"}}]'
```

### 4.9 `kubectl replace` — Full Resource Replacement

```bash
# Replace resource from file (fails if doesn't exist)
kubectl replace -f deployment.yaml

# Force replace (delete and recreate)
kubectl replace -f deployment.yaml --force

# Replace from stdin
cat deployment.yaml | kubectl replace -f -
```

---

## 5. Resource Types

### 5.1 Core Resources

| Resource | Short | Description |
|----------|-------|-------------|
| `pods` | `po` | Smallest deployable unit; one or more containers |
| `services` | `svc` | Stable network endpoint (ClusterIP, NodePort, LoadBalancer) |
| `configmaps` | `cm` | Non-sensitive key-value config |
| `secrets` | `sec` | Sensitive data (passwords, tokens, certs) |
| `namespaces` | `ns` | Virtual cluster isolation |
| `nodes` | `no` | Physical/virtual machines in the cluster |
| `persistentvolumes` | `pv` | Cluster-wide storage |
| `persistentvolumeclaims` | `pvc` | Request for storage by a pod |
| `serviceaccounts` | `sa` | Identity for pods |
| `endpoints` | `ep` | Network addresses backing a service |
| `events` | `ev` | Cluster activity log |
| `resourcequotas` | `quota` | Namespace resource limits |
| `limitranges` | `limits` | Default/min/max resource limits per container |
| `replicationcontrollers` | `rc` | Legacy pod replication (use Deployments instead) |

### 5.2 Apps Resources

| Resource | Short | Description |
|----------|-------|-------------|
| `deployments` | `deploy` | Declarative pod management, rolling updates |
| `statefulsets` | `sts` | Ordered, stable pods (databases, etc.) |
| `daemonsets` | `ds` | One pod per node |
| `replicasets` | `rs` | Desired pod count (managed by Deployments) |

### 5.3 Batch Resources

| Resource | Short | Description |
|----------|-------|-------------|
| `jobs` | `jobs` | Run-to-completion tasks |
| `cronjobs` | `cj` | Scheduled jobs |

### 5.4 Networking Resources

| Resource | Short | Description |
|----------|-------|-------------|
| `ingresses` | `ing` | HTTP routing (requires ingress controller) |
| `networkpolicies` | `netpol` | Pod-to-pod traffic rules |
| `ingressclasses` | `ingc` | Ingress class selection |
| `services` | `svc` | Network endpoint abstraction |

### 5.5 Storage Resources

| Resource | Short | Description |
|----------|-------|-------------|
| `storageclasses` | `sc` | Storage provisioning definitions |
| `volumeattachments` | `va` | Attach/detach volumes to nodes |

### 5.6 Cluster Resources

| Resource | Short | Description |
|----------|-------|-------------|
| `clusterrolebindings` | `crb` | Bind cluster roles to subjects |
| `roles` | `role` | Namespace-scoped permissions |
| `rolebindings` | `rb` | Bind roles to subjects |
| `clusterroles` | `cr` | Cluster-wide permissions |
| `certificatesigningrequests` | `csr` | TLS certificate requests |
| `node` | `no` | Cluster node |

### 5.7 List All Resource Types

```bash
# See everything available
kubectl api-resources

# With short names
kubectl api-resources --verbs=list

# API versions
kubectl api-versions

# Specific group
kubectl api-resources --api-group=apps
kubectl api-resources --api-group=batch
```

---

## 6. Output Formats

### 6.1 Standard Formats

```bash
# Default (name only)
kubectl get pods
# NAME                    READY   STATUS    RESTARTS   AGE
# nginx-7c5ddbdf54-x2j9k  1/1     Running   0          2d

# Wide (extra columns: IP, node, etc.)
kubectl get pods -o wide
# NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE
# nginx-7c5ddbdf54-x2j9k  1/1     Running   0          2d    10.42.1.5    k3s-worker-1

# YAML output
kubectl get pod nginx-7c5ddbdf54-x2j9k -o yaml

# JSON output
kubectl get pod nginx-7c5ddbdf54-x2j9k -o json
```

### 6.2 Custom Columns

```bash
kubectl get pods -o custom-columns=\
'NAME':.metadata.name,\
'STATUS':.status.phase,\
'RESTARTS':.status.containerStatuses[0].restartCount,\
'NODE':.spec.nodeName,\
'IP':.status.podIP

# Output:
# NAME                    STATUS    RESTARTS  NODE           IP
# nginx-7c5ddbdf54-x2j9k  Running   0         k3s-worker-1   10.42.1.5
```

### 6.3 JSONPath

```bash
# Get all pod names
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Specific field
kubectl get pod nginx-7c5ddbdf54-x2j9k -o jsonpath='{.status.podIP}'

# Nested arrays
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# With range and condition
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.conditions[*]}{.type}={.status}{" "}{end}{"\n"}{end}'
```

### 6.4 Go Templates

```bash
kubectl get pods -o go-template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'

# With conditional
kubectl get pods -o go-template='{{range .items}}{{if eq .status.phase "Running"}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'
```

### 6.5 JSONPath vs Custom Columns

| Feature | JSONPath | Custom Columns |
|---------|----------|----------------|
| Complex expressions | Yes | Limited |
| Array iteration | `range` | `[index]` |
| Conditional | `range` + `if` | No |
| Readability | Medium | High |
| Performance | Fast | Fast |

---

## 7. Filtering & Selection

### 7.1 Label Selectors (`-l`)

```bash
# Equality-based
kubectl get pods -l app=nginx
kubectl get pods -l env!=production
kubectl get pods -l environment=production,tier=frontend

# Set-based
kubectl get pods -l 'app in (nginx,apache)'
kubectl get pods -l 'environment notin (dev,staging)'
kubectl get pods -l 'tier'
kubectl get pods -l '!unused'

# Combine
kubectl get pods -l 'app=nginx,environment in (dev,staging)'
```

### 7.2 Field Selectors (`--field-selector`)

```bash
# By status
kubectl get pods --field-selector=status.phase=Running
kubectl get pods --field-selector=status.phase=Failed
kubectl get pods --field-selector=status.phase!=Running

# By node
kubectl get pods --field-selector=spec.nodeName=k3s-worker-1

# By namespace
kubectl get pods --field-selector=metadata.namespace=production

# By conditions
kubectl get nodes --field-selector=status.condition[0].type=Ready

# Combine
kubectl get pods --field-selector=status.phase=Running,spec.nodeName=k3s-worker-1
```

### 7.3 All Namespaces

```bash
# View pods across all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A    # shorthand

# Common pattern: find all pods with a label across namespaces
kubectl get pods -A -l app=nginx

# Events from all namespaces
kubectl get events -A --sort-by='.lastTimestamp'
```

### 7.4 Resource-Specific Filtering

```bash
# Pods by container image
kubectl get pods --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{" "}{range .spec.containers[*]}{.image}{" "}{end}{"\n"}{end}'

# Deployments by minimum ready
kubectl get deployments -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.availableReplicas}{"\n"}{end}'

# Services by type
kubectl get svc -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.name}{"\n"}{end}'
```

---

## 8. Debugging

### 8.1 `kubectl logs` — Container Logs

```bash
# Pod logs
kubectl logs my-pod
kubectl logs my-pod -n production

# Specific container in multi-container pod
kubectl logs my-pod -c sidecar

# Previous instance (after crash)
kubectl logs my-pod --previous

# Follow logs in real time
kubectl logs -f my-pod

# Follow with timestamps
kubectl logs -f my-pod --timestamps

# Show last N lines
kubectl logs my-pod --tail=100

# Since a time ago
kubectl logs my-pod --since=2h
kubectl logs my-pod --since=10m

# All containers in a pod
kubectl logs my-pod --all-containers

# All pods matching a label
kubectl logs -l app=nginx --all-containers

# Logs from a daemonset
kubectl logs -l name=my-ds --all-containers

# Stream logs from a deployment
kubectl logs -f deployment/my-deploy --all-containers

# Raw log query (if supported)
kubectl logs my-pod --output=json | jq '.items[0].log'
```

### 8.2 `kubectl exec` — Execute Commands

```bash
# Interactive shell
kubectl exec -it my-pod -- /bin/bash
kubectl exec -it my-pod -c container-name -- /bin/sh

# Run single command
kubectl exec my-pod -- ls /app
kubectl exec my-pod -- cat /etc/nginx/nginx.conf

# Run in background
kubectl exec -d my-pod -- /app/start-worker.sh

# Environment variables
kubectl exec my-pod -- env

# Working directory
kubectl exec -w /app my-pod -- pwd
```

### 8.3 `kubectl port-forward` — Port Forwarding

```bash
# Forward local port to pod
kubectl port-forward my-pod 8080:80
kubectl port-forward my-pod 8080:80 -n production

# Forward to a service
kubectl port-forward svc/my-service 8080:80

# Forward to a deployment
kubectl port-forward deployment/my-deploy 8080:80

# Multiple port forwards
kubectl port-forward my-pod 8080:80 9090:9090

# Listen on all interfaces
kubectl port-forward my-pod 8080:80 --address 0.0.0.0

# Background process
kubectl port-forward my-pod 8080:80 &
```

### 8.4 `kubectl proxy` — API Proxy

```bash
# Start API proxy on localhost:8001
kubectl proxy
kubectl proxy --port=8080

# Access API directly
curl http://localhost:8001/api/v1/namespaces/default/pods
curl http://localhost:8001/apis/apps/v1/namespaces/default/deployments

# Access dashboard via proxy
kubectl proxy
# Then open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/service/http:kubernetes-dashboard:/proxy/
```

### 8.5 `kubectl top` — Resource Usage

```bash
# Pod resource usage
kubectl top pods
kubectl top pods -n kube-system

# Node resource usage
kubectl top nodes

# Pod with containers
kubectl top pods --containers

# Memory in specific unit
kubectl top pods --sort-by=memory

# CPU in specific unit
kubectl top pods --sort-by=cpu

# Sort by total resource usage
kubectl top pods --sort-by=cpu -o jsonpath='{range .items[*]}{.metadata.name}{"\tCPU: "}{.usage.cpu}{"\tMEM: "}{.usage.memory}{"\n"}{end}'
```

### 8.6 `kubectl debug` — Ephemeral Containers

```bash
# Debug a running pod with ephemeral container
kubectl debug my-pod -it --image=busybox

# Debug a node
kubectl debug node/k3s-worker-1 -it --image=busybox

# Debug with custom command
kubectl debug my-pod -it --image=nicolaka/netshoot --target=nginx

# Copy pod spec for debugging
kubectl debug my-pod --copy-to=debug-pod --container=debug --image=busybox -- sh
```

### 8.7 Events for Debugging

```bash
# Recent events
kubectl get events
kubectl get events --sort-by='.lastTimestamp'

# Events for a specific pod
kubectl describe pod my-pod | grep -A 10 "Events"

# Events in a namespace
kubectl get events -n production

# Filter by reason
kubectl get events --field-selector=reason=FailedScheduling
kubectl get events --field-selector=reason=BackOff

# Warning events only
kubectl get events --field-selector type=Warning
```

---

## 9. Deployment

### 9.1 `kubectl rollout` — Rollout Management

```bash
# Check rollout status
kubectl rollout status deployment/my-deploy
kubectl rollout status deployment/my-deploy -n production

# View rollout history
kubectl rollout history deployment/my-deploy
kubectl rollout history deployment/my-deploy --revision=3

# Undo rollout
kubectl rollout undo deployment/my-deploy
kubectl rollout undo deployment/my-deploy --to-revision=2

# Pause/Resume rollout
kubectl rollout pause deployment/my-deploy
kubectl rollout resume deployment/my-deploy

# Restart (triggers rollout)
kubectl rollout restart deployment/my-deploy
kubectl rollout restart deployment/my-deploy -n production
```

### 9.2 `kubectl scale` — Scaling

```bash
# Scale deployment
kubectl scale deployment my-deploy --replicas=5
kubectl scale deployment my-deploy --replicas=0   # scale down
kubectl scale deployment my-deploy --replicas=10 --current-replicas=5  # conditional

# Scale statefulset
kubectl scale statefulset my-db --replicas=3
```

### 9.3 `kubectl autoscale` — Horizontal Pod Autoscaler

```bash
# Create HPA
kubectl autoscale deployment my-deploy --min=2 --max=10 --cpu-percent=80

# HPA with custom metrics
kubectl autoscale deployment my-deploy --min=2 --max=10 --metric=type=External,externalMetricName=nginx_requests_per_second,targetValue=100

# View HPA
kubectl get hpa
kubectl describe hpa my-deploy

# Delete HPA
kubectl delete hpa my-deploy
```

### 9.4 `kubectl set image` — Update Container Image

```bash
# Update image
kubectl set image deployment/my-deploy nginx=nginx:1.26

# Update specific container
kubectl set image deployment/my-deploy sidecar=sidecar:v2

# Record the change (for history)
kubectl set image deployment/my-deploy nginx=nginx:1.26 --record
```

### 9.5 `kubectl set env` — Set Environment Variables

```bash
# Set a single env var
kubectl set env deployment/my-deploy DATABASE_URL=postgres://db:5432/mydb

# Set from a Secret
kubectl set env deployment/my-deploy DB_PASSWORD=my-secret-value

# Set from a ConfigMap
kubectl set env deployment/my-deploy --from=configmap/my-config

# Remove an env var
kubectl set env deployment/my-deploy DATABASE_URL-
```

### 9.6 `kubectl set resources` — Resource Limits

```bash
# Set resource requests and limits
kubectl set resources deployment/my-deploy \
  --limits=cpu=500m,memory=256Mi \
  --requests=cpu=100m,memory=128Mi

# For a specific container
kubectl set resources deployment/my-deploy -c nginx \
  --limits=cpu=200m,memory=128Mi
```

---

## 10. Config Management

### 10.1 ConfigMaps

```bash
# Create from literal values
kubectl create configmap app-config --from-literal=LOG_LEVEL=debug

# Create from file
kubectl create configmap nginx-config --from-file=nginx.conf

# Create from directory
kubectl create configmap app-config --from-file=config/

# Create from env file
kubectl create configmap app-config --from-env-file=config.env

# Create from YAML
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: production
  LOG_LEVEL: info
EOF

# View ConfigMap
kubectl get configmap app-config -o yaml
kubectl describe configmap app-config

# Edit ConfigMap
kubectl edit configmap app-config
```

### 10.2 Secrets

```bash
# Create from literal values
kubectl create secret generic db-secret --from-literal=password=mydbpass

# Create from file
kubectl create secret tls my-tls --cert=tls.crt --key=tls.key

# Create docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=my@email.com

# Create from YAML (base64 encoded)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  password: bXlkYnBhc3M=    # echo -n 'mydbpass' | base64
  username: YWRtaW4=
EOF

# View Secret (base64)
kubectl get secret db-secret -o yaml

# Decode secret value
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 -d

# Edit Secret
kubectl edit secret db-secret

# Patch Secret
kubectl patch secret db-secret --type=json \
  -p '[{"op":"replace","path":"/data/password","value":"bmV3cGFzcw=="}]'
```

### 10.3 Labels and Annotations

```bash
# Add labels
kubectl label pods my-pod env=production
kubectl label nodes k3s-worker-1 gpu=true

# Remove labels
kubectl label pods my-pod env-

# Add annotations
kubectl annotate pods my-pod description="Main web server"
kubectl annotate deployment my-deploy note="Deployed on 2024-01-15"

# Remove annotations
kubectl annotate pods my-pod description-

# Overwrite existing label
kubectl label pods my-pod env=dev --overwrite
```

### 10.4 Taints and Tolerations

```bash
# Add taint to node
kubectl taint nodes k3s-worker-1 dedicated=gpu:NoSchedule
kubectl taint nodes k3s-worker-1 key=value:PreferNoSchedule
kubectl taint nodes k3s-worker-1 key=value:NoExecute

# Remove taint
kubectl taint nodes k3s-worker-1 dedicated=gpu:NoSchedule-
kubectl taint nodes k3s-worker-1 dedicated:NoSchedule-

# View taints
kubectl describe node k3s-worker-1 | grep -A 5 Taints
```

### 10.5 Cordoning and Draining

```bash
# Cordon (mark unschedulable)
kubectl cordon k3s-worker-1

# Uncordon (mark schedulable again)
kubectl uncordon k3s-worker-1

# Drain (evict pods, then cordon)
kubectl drain k3s-worker-1 --ignore-daemonsets --delete-emptydir-data
kubectl drain k3s-worker-1 --ignore-daemonsets --force --grace-period=60

# Check node status
kubectl get nodes
kubectl get node k3s-worker-1 -o wide
```

---

## 11. Advanced Commands

### 11.1 `kubectl wait` — Wait for Conditions

```bash
# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/my-pod --timeout=60s

# Wait for deployment rollout
kubectl wait --for=condition=Available deployment/my-deploy --timeout=300s

# Wait for pod to be deleted
kubectl wait --for=delete pod/my-pod --timeout=120s

# Wait for all pods in namespace
kubectl wait --for=condition=Ready pods -l app=nginx -n production --timeout=120s

# Wait for multiple conditions
kubectl wait --for=jsonpath='{.status.conditions[?(@.type=="Ready")].status}'=True pod/my-pod --timeout=60s
```

### 11.2 `kubectl diff` — Diff Changes

```bash
# Preview changes before applying
kubectl diff -f deployment.yaml
kubectl diff -f deployment.yaml -f service.yaml

# Diff with server
kubectl diff --server-side -f config.yaml
```

### 11.3 `kubectl kustomize` — Kustomize Integration

```bash
# Build kustomization
kubectl kustomize ./overlays/production

# Apply kustomization
kubectl apply -k ./overlays/production

# Diff kustomization
kubectl diff -k ./overlays/production
```

### 11.4 `kubectl api-resources` — Discover APIs

```bash
# List all resources
kubectl api-resources

# With short names
kubectl api-resources -o wide

# By API group
kubectl api-resources --api-group=apps
kubectl api-resources --api-group=batch
kubectl api-resources --api-group=networking.k8s.io
kubectl api-resources --api-group=rbac.authorization.k8s.io

# List all API versions
kubectl api-versions

# Specific group versions
kubectl api-versions apps/v1
```

### 11.5 `kubectl auth` — Authorization

```bash
# Check if you can do something
kubectl auth can-i create deployments
kubectl auth can-i delete pods -n production
kubectl auth can-i get svc --as=system:serviceaccount:default:my-sa

# List what you can do
kubectl auth can-i --list
kubectl auth can-i --list -n production

# Check specific resource
kubectl auth can-i list pods
kubectl auth can-i create,delete deployments
```

### 11.6 `kubectl plugin` — Plugin Management

```bash
# List installed plugins
kubectl plugin list

# Install a plugin (krew)
kubectl krew install ctx
kubectl krew install ns
kubectl krew install neat

# Use plugins
kubectl ctx    # quick context switching
kubectl ns     # quick namespace switching
```

### 11.7 `kubectl copy` — Copy Files

```bash
# Copy from pod to local
kubectl cp my-pod:/var/log/app.log ./app.log

# Copy from local to pod
kubectl cp ./config.yaml my-pod:/etc/config/config.yaml

# Copy directory
kubectl cp my-pod:/app/logs/ ./logs/

# Copy from specific container
kubectl cp my-pod:/app/logs/ ./logs/ -c sidecar
```

### 11.8 `kubectl label` and `kubectl annotate`

```bash
# Batch label
kubectl label pods -l app=nginx env=production

# Batch annotate
kubectl annotate pods -l app=nginx description="nginx web server"

# Select and label
kubectl label nodes --all topology.kubernetes.io/zone=us-east-1a
```

### 11.9 `kubectl drain` and `kubectl uncordon`

```bash
# Drain for maintenance
kubectl drain k3s-worker-1 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=60 \
  --timeout=300s

# Skip specific pods
kubectl drain k3s-worker-1 \
  --ignore-daemonsets \
  --pod-selector='app!=critical-app'
```

### 11.10 `kubectl certificate` — CSR Management

```bash
# Approve CSR
kubectl certificate approve node-csr-abc123

# Deny CSR
kubectl certificate deny node-csr-abc123

# View pending CSRs
kubectl get csr
kubectl describe csr node-csr-abc123
```

### 11.11 `kubectl config` — Advanced Config Operations

```bash
# View current config
kubectl config view
kubectl config view --minify    # current context only
kubectl config view --raw       # raw kubeconfig

# Set cluster
kubectl config set-cluster my-cluster \
  --server=https://10.0.1.100:6443 \
  --certificate-authority=/path/to/ca.crt

# Set credentials
kubectl config set-credentials my-user \
  --client-certificate=/path/to/client.crt \
  --client-key=/path/to/client.key

# Set context
kubectl config set-context my-context \
  --cluster=my-cluster \
  --user=my-user \
  --namespace=production

# Unset (remove) fields
kubectl config unset users.my-user

# Merge configs
KUBECONFIG=config1.yaml:config2.yaml kubectl config view --merge --flatten > merged.yaml
```

---

## 12. Aliases & Shortcuts

### 12.1 Essential Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Base alias
alias k='kubectl'

# Resource shortcuts
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kgc='kubectl get configmaps'
alias kgsa='kubectl get serviceaccounts'
alias kgi='kubectl get ingress'
alias kge='kubectl get events'
alias kgj='kubectl get jobs'
alias kgcj='kubectl get cronjobs'
alias kgnp='kubectl get networkpolicies'
alias kgpv='kubectl get persistentvolumes'
alias kgpvc='kubectl get persistentvolumeclaims'
alias kgrb='kubectl get rolebindings'
alias kgcrb='kubectl get clusterrolebindings'
alias kgsa='kubectl get serviceaccounts'
alias kgsc='kubectl get storageclasses'
alias kghpa='kubectl get hpa'

# All namespaces
alias kgpa='kubectl get pods --all-namespaces'
alias kgsa='kubectl get services --all-namespaces'

# Wide output
alias kgpw='kubectl get pods -o wide'
alias kgnw='kubectl get nodes -o wide'

# Delete shortcuts
alias kdp='kubectl delete pod'
alias kds='kubectl delete svc'
alias kdd='kubectl delete deployment'
alias kdn='kubectl delete namespace'

# Describe shortcuts
alias kdep='kubectl describe pod'
alias kdes='kubectl describe svc'
alias kded='kubectl describe deployment'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kl1='kubectl logs --tail=1'
alias klp='kubectl logs --previous'

# Execute
alias kex='kubectl exec -it'

# Apply/Delete
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# Context
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# Output formats
alias kgpy='kubectl get pods -o yaml'
alias kgpjson='kubectl get pods -o json'
alias kgpwide='kubectl get pods -o wide'

# Debugging
alias ktop='kubectl top pods'
alias ktopn='kubectl top nodes'
alias kwatch='kubectl get pods -w'
alias kauth='kubectl auth can-i'
```

### 12.2 Advanced Aliases

```bash
# Quick pod operations
alias kshell='kubectl exec -it -- /bin/sh'
alias klog='kubectl logs -f --tail=100'
alias kdescribe='kubectl describe'

# Namespace switching
alias kprod='kubectl config set-context --current --namespace=production'
alias kdev='kubectl config set-context --current --namespace=development'
alias kstg='kubectl config set-context --current --namespace=staging'
alias kdefault='kubectl config set-context --current --namespace=default'

# Common workflows
alias krestart='kubectl rollout restart deployment'
alias kscale='kubectl scale deployment'
alias kstatus='kubectl rollout status deployment'
alias khistory='kubectl rollout history deployment'
alias kundo='kubectl rollout undo deployment'

# Resource management
alias klabel='kubectl label'
alias kannotate='kubectl annotate'
alias ktaint='kubectl taint nodes'
alias kcordon='kubectl cordon'
alias kuncordon='kubectl uncordon'
alias kdrain='kubectl drain --ignore-daemonsets --delete-emptydir-data'
```

### 12.3 Shell Functions

```bash
# Quick namespace selector
kns() {
  if [ -z "$1" ]; then
    kubectl config set-context --current --namespace="${1:-default}"
  else
    kubectl config set-context --current --namespace="$1"
  fi
}

# Pod selector (interactive)
kpods() {
  local ns="${1:-default}"
  kubectl get pods -n "$ns" -o custom-columns=\
NAME:.metadata.name,\
STATUS:.status.phase,\
IP:.status.podIP,\
NODE:.spec.nodeName
}

# Quick logs for pod
klogf() {
  local pod=$1
  shift
  kubectl logs -f "$pod" "$@"
}

# Quick exec into first pod
kexec() {
  local deploy=$1
  shift
  local pod=$(kubectl get pods -l "app=$deploy" -o jsonpath='{.items[0].metadata.name}')
  kubectl exec -it "$pod" "$@"
}

# Check pod status
kcheck() {
  kubectl get pods -A -o custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
STATUS:.status.phase,\
RESTARTS:.status.containerStatuses[0].restartCount,\
NODE:.spec.nodeName | grep -E "(Error|CrashLoop|Failed|Pending)" || echo "All pods healthy"
}
```

### 12.4 kubectx and kubens

```bash
# Install
kubectl krew install ctx
kubectl krew install ns

# Or standalone
curl -Lo kubectx https://github.com/ahmetb/kubectx/releases/latest/download/kubectx
chmod +x kubectx
sudo mv kubectx /usr/local/bin/

# Usage
kubectx                    # list contexts
kubectx my-production      # switch context
kubectx -                  # switch to previous context
kubectx -d my-old-context  # delete context

kubens                    # list namespaces
kubens production         # switch namespace
kubens -                   # switch to previous namespace
```

---

## 13. JSONPath Expressions

### 13.1 Syntax Basics

```
$.key                    # root key
$['key']                 # bracket notation
$.items[0]               # first array element
$.items[*]               # all array elements
$.items[-1]              # last array element
$.items[0:3]             # slice (first 3)
$.items[?(@.key=="val")] # filter
```

### 13.2 Common Patterns

```bash
# Get all pod names
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# Get specific pod status
kubectl get pod nginx-xxx -o jsonpath='{.status.phase}'

# Get all pod IPs
kubectl get pods -o jsonpath='{.items[*].status.podIP}'

# Get pod containers
kubectl get pod nginx-xxx -o jsonpath='{.spec.containers[*].name}'

# Get pod with labels
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.app}{"\n"}{end}'

# Get node capacity
kubectl get node k3s-worker-1 -o jsonpath='{.status.capacity}'

# Get resource requests
kubectl get pod nginx-xxx -o jsonpath='{.spec.containers[0].resources.requests}'

# Get events sorted by time
kubectl get events -o jsonpath='{range .items[*]}{.lastTimestamp}{" "}{.reason}{" "}{.message}{"\n"}{end}' | sort -t' ' -k1,1

# Find pods not running
kubectl get pods -o jsonpath='{range .items[?(@.status.phase!="Running")]}{.metadata.name}{" "}{.status.phase}{"\n"}{end}'

# Get services of type LoadBalancer
kubectl get svc -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.name}{"\n"}{end}'

# Get deployment replicas
kubectl get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" desired:"}{.spec.replicas}{" ready:"}{.status.readyReplicas}{"\n"}{end}'

# Get PVC status
kubectl get pvc -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{" "}{.status.capacity.storage}{"\n"}{end}'

# Get Ingress hosts
kubectl get ingress -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.rules[*]}{.host}{" "}{end}{"\n"}{end}'

# Get secrets
kubectl get secret my-secret -o jsonpath='{.data}' | base64 -d
```

### 13.3 Advanced Filters

```bash
# Filter by label value
kubectl get pods -o jsonpath='{.items[?(@.metadata.labels.env=="production")].metadata.name}'

# Filter by status
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Failed")].metadata.name}'

# Filter by node
kubectl get pods -o jsonpath='{.items[?(@.spec.nodeName=="k3s-worker-1")].metadata.name}'

# Multiple conditions
kubectl get pods -o jsonpath='{.items[?(@.metadata.labels.app=="nginx" && @.status.phase=="Running")].metadata.name}'

# Filter with wildcards
kubectl get pods -o jsonpath='{.items[?(@.metadata.name=~/web-.*-prod/)].metadata.name}'

# Conditional output
kubectl get pods -o jsonpath='{range .items[*]}{if eq .status.phase "Running"}{.metadata.name}{"\n"}{end}{end}'

# Nested conditions
kubectl get pods -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.name}{" has image: "}{.image}{"\n"}{end}{end}'
```

### 13.4 Formatting Tips

```bash
# Use range for multi-line output
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# Tab-separated output
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\t"}{.spec.nodeName}{"\n"}{end}'

# CSV format
kubectl get pods -o jsonpath='Name,Phase,Node\n{range .items[*]}{.metadata.name},{.status.phase},{.spec.nodeName}{"\n"}{end}'

# Header + data
echo "NAME STATUS NODE"
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{" "}{.spec.nodeName}{"\n"}{end}'
```

---

## 14. Command Reference

### Complete Command List

| Command | Description | Example |
|---------|-------------|---------|
| `kubectl annotate` | Add/remove annotations | `kubectl annotate pod my-pod desc="text"` |
| `kubectl api-resources` | List API resources | `kubectl api-resources --api-group=apps` |
| `kubectl api-versions` | List API versions | `kubectl api-versions` |
| `kubectl apply` | Apply config | `kubectl apply -f config.yaml` |
| `kubectl attach` | Attach to container | `kubectl attach my-pod -c nginx` |
| `kubectl auth` | Authorization check | `kubectl auth can-i get pods` |
| `kubectl autoscale` | Create HPA | `kubectl autoscale deploy my-app --min=2 --max=10` |
| `kubectl certificate` | Manage CSRs | `kubectl certificate approve node-csr-abc` |
| `kubectl cluster-info` | Cluster information | `kubectl cluster-info` |
| `kubectl completion` | Shell completion | `kubectl completion bash > ~/.bash_completion.d/kubectl` |
| `kubectl config` | Config operations | `kubectl config use-context my-cluster` |
| `kubectl convert` | Convert YAML versions | `kubectl convert -f old.yaml --output-version apps/v1` |
| `kubectl cp` | Copy files | `kubectl cp my-pod:/app/log.txt ./log.txt` |
| `kubectl create` | Create resources | `kubectl create deploy nginx --image=nginx` |
| `kubectl debug` | Debug pods/nodes | `kubectl debug my-pod -it --image=busybox` |
| `kubectl delete` | Delete resources | `kubectl delete pod my-pod` |
| `kubectl describe` | Describe resources | `kubectl describe pod my-pod` |
| `kubectl diff` | Diff changes | `kubectl diff -f config.yaml` |
| `kubectl drain` | Drain node | `kubectl drain node-1 --ignore-daemonsets` |
| `kubectl edit` | Edit resources | `kubectl edit deployment my-app` |
| `kubectl exec` | Execute in container | `kubectl exec -it my-pod -- /bin/sh` |
| `kubectl explain` | API documentation | `kubectl explain pods.spec.containers` |
| `kubectl expose` | Create service | `kubectl expose deploy my-app --port=80` |
| `kubectl get` | List resources | `kubectl get pods -A -o wide` |
| `kubectl kustomize` | Build kustomize | `kubectl kustomize ./overlays/production` |
| `kubectl label` | Add/remove labels | `kubectl label pod my-pod env=prod` |
| `kubectl logs` | View container logs | `kubectl logs my-pod --previous` |
| `kubectl patch` | Patch resources | `kubectl patch deploy my-app -p '{"spec":{"replicas":5}}'` |
| `kubectl plugin` | Plugin management | `kubectl plugin list` |
| `kubectl port-forward` | Forward ports | `kubectl port-forward my-pod 8080:80` |
| `kubectl proxy` | API proxy | `kubectl proxy --port=8001` |
| `kubectl replace` | Replace resources | `kubectl replace -f config.yaml` |
| `kubectl rollout` | Rollout operations | `kubectl rollout undo deploy my-app` |
| `kubectl run` | Run single pod | `kubectl run nginx --image=nginx` |
| `kubectl scale` | Scale resources | `kubectl scale deploy my-app --replicas=5` |
| `kubectl set` | Set fields | `kubectl set image deploy my-app nginx=1.26` |
| `kubectl taint` | Taint nodes | `kubectl taint nodes node1 key=val:NoSchedule` |
| `kubectl top` | Resource usage | `kubectl top pods` |
| `kubectl uncordon` | Mark schedulable | `kubectl uncordon node-1` |
| `kubectl wait` | Wait for condition | `kubectl wait --for=condition=Ready pod/my-pod` |

### Common Flags

| Flag | Description |
|------|-------------|
| `-n, --namespace` | Namespace scope |
| `-A, --all-namespaces` | All namespaces |
| `-l, --selector` | Label selector |
| `-o, --output` | Output format (yaml, json, wide, jsonpath, custom-columns) |
| `--field-selector` | Field selector |
| `-f, --filename` | Resource file/directory |
| `-R, --recursive` | Recurse into directories |
| `--dry-run` | Dry run (client/server) |
| `--server-side` | Server-side apply |
| `--force` | Force operations |
| `--grace-period` | Grace period (seconds) |
| `--timeout` | Timeout (seconds) |
| `--wait` | Wait for condition |
| `--recursive` | Recursive directory search |
| `--all` | All resources of type |
| `-w, --watch` | Watch for changes |
| `--show-labels` | Show labels |
| `--sort-by` | Sort by field |
| `--context` | Kubeconfig context |
| `--kubeconfig` | Kubeconfig file |
| `--certificate-authority` | CA certificate |
| `--token` | Auth token |
| `--user` | Kubeconfig user |
| `--cluster` | Kubeconfig cluster |
| `--server` | API server URL |
| `--insecure-skip-tls-verify` | Skip TLS verify (DANGEROUS) |
| `--as` | Impersonate user |
| `--as-group` | Impersonate group |
| `--as-service-account` | Impersonate SA |
| `--record` | Record change in annotations |
| `--overwrite` | Overwrite existing labels/annotations |

---

## 15. Troubleshooting

### Error: "The connection to the server was refused"

```bash
# Check if API server is running
kubectl cluster-info
curl -k https://192.168.1.100:6443

# Check kubeconfig
kubectl config view --minify

# Check if port is open
nc -zv 192.168.1.100 6443

# If using k3s
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

### Error: "Unable to connect to the server: x509: certificate has expired"

```bash
# Regenerate certificates (k3s)
sudo cp /var/lib/rancher/k3s/server/tls/server-ca.crt /etc/kubernetes/pki/

# Or skip TLS verify (DANGEROUS, lab only)
kubectl config set-cluster my-cluster --insecure-skip-tls-verify=true

# Or update CA
kubectl config set-cluster my-cluster --certificate-authority=/new/path/ca.crt
```

### Error: "No resource found" or "Error from server (NotFound)"

```bash
# Check namespace
kubectl get pods -n default
kubectl get pods -A

# Check if resource exists
kubectl get deploy my-deploy -n production

# Check spelling
kubectl api-resources | grep -i deploy
```

### Error: "Error from server (Forbidden): Unauthorized"

```bash
# Check RBAC
kubectl auth can-i get pods
kubectl auth can-i get pods --as=system:serviceaccount:default:my-sa

# Check service account
kubectl get sa my-sa -o yaml
kubectl get clusterrolebinding,rolebinding -A | grep my-sa

# Check token
kubectl describe secret $(kubectl get sa my-sa -o jsonpath='{.secrets[0].name}')
```

### Error: "Error from server (Conflict): Operation cannot be fulfilled"

```bash
# Add --force flag
kubectl replace -f config.yaml --force

# Or delete and recreate
kubectl delete -f config.yaml
kubectl apply -f config.yaml
```

### Pod stuck in "Pending"

```bash
# Check events
kubectl describe pod my-pod

# Common causes:
# - No nodes available (tainted)
kubectl describe nodes | grep -A 5 Taints

# - Insufficient resources
kubectl top nodes
kubectl top pods

# - PVC not bound
kubectl get pvc
kubectl describe pvc my-pvc
```

### Pod stuck in "CrashLoopBackOff"

```bash
# Check logs
kubectl logs my-pod
kubectl logs my-pod --previous    # last crashed container

# Check events
kubectl describe pod my-pod

# Common causes:
# - Application error
# - Missing config/secret
# - Liveness probe failing
# - Resource limits too low
```

### Pod stuck in "ImagePullBackOff"

```bash
# Check image name
kubectl describe pod my-pod | grep -A 5 "Image:"

# Test image pull
docker pull nginx:1.25    # or crictl pull

# Check registry credentials
kubectl get secret regcred -o yaml
```

### Service not reachable

```bash
# Check endpoints
kubectl get endpoints my-service
kubectl describe svc my-service

# Check selector matches pods
kubectl get pods -l app=my-app

# Check pod readiness
kubectl get pods -o wide
kubectl describe pod my-pod | grep -A 3 Readiness

# Test with port-forward
kubectl port-forward svc/my-service 8080:80
curl localhost:8080
```

### Node in "NotReady" state

```bash
# Check node conditions
kubectl describe node my-node

# Check kubelet
ssh my-node
sudo systemctl status kubelet
sudo journalctl -u kubelet -f

# Check node resources
kubectl top nodes
kubectl describe node my-node | grep -A 10 Conditions
```

### Deployment rollout stuck

```bash
# Check status
kubectl rollout status deployment/my-deploy
kubectl rollout history deployment/my-deploy

# Check replica set
kubectl get rs
kubectl describe rs my-deploy-xxxxx

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Force rollout
kubectl rollout restart deployment/my-deploy
```

### PVC stuck in "Pending"

```bash
# Check storage class
kubectl get sc
kubectl describe pvc my-pvc

# Check PV
kubectl get pv
kubectl describe pv my-pv

# Check dynamic provisioning
kubectl get events -n default
```

### Network connectivity issues

```bash
# Test DNS resolution
kubectl run dns-test --image=busybox:1.36 --rm -it -- nslookup kubernetes.default

# Test pod-to-pod connectivity
kubectl run test-pod --image=nicolaka/netshoot --rm -it -- ping <pod-ip>

# Test service connectivity
kubectl run test-svc --image=nicolaka/netshoot --rm -it -- curl http://my-service:80

# Check network policies
kubectl get netpol
kubectl describe netpol my-netpol
```

### "The connection to the server localhost:8080 was refused"

```bash
# Wrong kubeconfig or no config
echo $KUBECONFIG
kubectl config view --minify

# Fix: set kubeconfig
export KUBECONFIG=~/.kube/config
# or
kubectl config use-context my-cluster
```

### Container stuck in "Terminating"

```bash
# Force delete pod
kubectl delete pod my-pod --grace-period=0 --force

# Delete with finalizers
kubectl patch pod my-pod -p '{"metadata":{"finalizers":null}}'
kubectl delete pod my-pod
```

### PVC stuck in "Bound" but pod can't mount

```bash
# Check PV access modes
kubectl get pv -o custom-columns=NAME:.metadata.name,ACCESS:.spec.accessModes,STATUS:.status.phase

# Check volume attachment
kubectl get volumeattachments

# Check node capacity
kubectl describe node my-node | grep -A 10 "Allocated resources"
```

---

## 16. Tips & Best Practices

### 16.1 Use Declarative, Not Imperative

```bash
# BAD: imperative (harder to track changes)
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=3
kubectl set image deployment nginx nginx=1.26

# GOOD: declarative (version-controlled)
kubectl apply -f deployment.yaml
kubectl diff -f deployment.yaml    # review changes first
```

### 16.2 Always Use Namespaces

```bash
# BAD: everything in default
kubectl create deployment nginx --image=nginx -n default

# GOOD: isolated namespaces
kubectl create namespace production
kubectl create deployment nginx --image=nginx -n production
```

### 16.3 Set Resource Limits

```yaml
# Always define resource requests and limits
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

### 16.4 Use Labels Consistently

```yaml
# Standard label scheme
metadata:
  labels:
    app: my-app          # application name
    app.kubernetes.io/name: my-app
    app.kubernetes.io/version: "1.0"
    app.kubernetes.io/component: web
    app.kubernetes.io/part-of: my-platform
    environment: production
    team: platform
```

### 16.5 Dry Run Everything

```bash
# Preview what would happen
kubectl apply -f config.yaml --dry-run=client
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
kubectl delete pod my-pod --dry-run=server
```

### 16.6 Use Wait for Automation

```bash
# In CI/CD pipelines
kubectl apply -f deployment.yaml
kubectl rollout status deployment/my-deploy --timeout=300s
kubectl wait --for=condition=Available deployment/my-deploy --timeout=300s
```

### 16.7 Set Defaults with Contexts

```bash
# Each environment gets its own context
kubectl config set-context dev --cluster=dev-cluster --user=dev-user --namespace=development
kubectl config set-context staging --cluster=staging-cluster --user=staging-user --namespace=staging
kubectl config set-context prod --cluster=prod-cluster --user=prod-user --namespace=production

# Switch quickly
kubectx dev
kubens my-app
```

### 16.8 Use ConfigMaps and Secrets

```yaml
# Don't hardcode config in deployments
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: url
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: log-level
```

### 16.9 Use Liveness and Readiness Probes

```yaml
# Prevent downtime and detect unhealthy pods
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 16.10 Use initContainers for Dependencies

```yaml
# Wait for services to be ready
initContainers:
- name: wait-for-db
  image: busybox
  command: ['sh', '-c', 'until nc -z my-db 5432; do sleep 2; done']
```

### 16.11 Use -R for Directories

```bash
# Apply all YAML in a directory tree
kubectl apply -f ./manifests/ -R
kubectl apply -k ./overlays/production
```

### 16.12 Keep Secrets Encrypted

```bash
# Use sealed-secrets, external-secrets, or SOPS
# Never commit raw secrets to git
kubectl get secret my-secret -o json | base64 -d
```

### 16.13 Monitor with Events

```bash
# Check cluster health
kubectl get events -A --sort-by='.lastTimestamp' --field-selector=type=Warning
kubectl get events -n production --field-selector=reason=FailedScheduling
```

### 16.14 Clean Up Regularly

```bash
# Remove completed jobs
kubectl delete jobs --field-selector=status.successful=1

# Remove failed pods
kubectl delete pods --field-selector=status.phase=Failed

# Remove evicted pods
kubectl get pods -A | grep Evicted | awk '{print $1, $2}' | xargs -n2 kubectl delete pod -n
```

### 16.15 Use --force Wisely

```bash
# --force skips grace period and deletes immediately
# Only use when you're sure (e.g. stuck pods)
kubectl delete pod stuck-pod --grace-period=0 --force

# Don't use --force for routine operations
```

### 16.16 Pipe Operations

```bash
# Find and delete all failed pods
kubectl get pods --field-selector=status.phase=Failed -o name | xargs kubectl delete

# Get all pod IPs
kubectl get pods -o jsonpath='{.items[*].status.podIP}' | tr ' ' '\n' | sort -u

# Count pods per node
kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c

# Find pods using too much memory
kubectl top pods -A --sort-by=memory | head -10
```

### 16.17 Use Output Templates in Scripts

```bash
# Script-friendly output
while IFS= read -r pod; do
  echo "Checking $pod..."
  kubectl exec "$pod" -- cat /app/health
done < <(kubectl get pods -l app=my-app -o jsonpath='{.items[*].metadata.name}')
```

---

## 17. Real-World Examples

### 17.1 Deploy a Full Application

```bash
# Create namespace
kubectl create namespace myapp

# Create config
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info \
  -n myapp

# Create secret
kubectl create secret generic db-secret \
  --from-literal=URL=postgres://db:5432/mydb \
  --from-literal=PASSWORD=supersecret \
  -n myapp

# Deploy application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: myapp
  labels:
    app: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: myregistry/web-app:1.0
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: db-secret
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
EOF

# Create service
kubectl expose deployment web-app --port=80 --target-port=8080 -n myapp

# Create ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app
  namespace: myapp
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app
            port:
              number: 80
EOF
```

### 17.2 Rolling Update

```bash
# Deploy v1
kubectl create deployment web-app --image=myapp:v1 -n production

# Update to v2 (creates rollout)
kubectl set image deployment/web-app web-app=myapp:v2 -n production

# Watch rollout
kubectl rollout status deployment/web-app -n production

# If something goes wrong
kubectl rollout history deployment/web-app -n production
kubectl rollout undo deployment/web-app -n production
kubectl rollout undo deployment/web-app --to-revision=1 -n production
```

### 17.3 Debug a CrashLooping Pod

```bash
# Find the pod
kubectl get pods -n production
# NAME                        READY   STATUS             RESTARTS   AGE
# web-app-7c5ddbdf54-x2j9k   0/1     CrashLoopBackOff   5          10m

# Check logs
kubectl logs web-app-7c5ddbdf54-x2j9k -n production
kubectl logs web-app-7c5ddbdf54-x2j9k -n production --previous

# Describe for events
kubectl describe pod web-app-7c5ddbdf54-x2j9k -n production

# Exec into pod (if it stays alive long enough)
kubectl exec -it web-app-7c5ddbdf54-x2j9k -n production -- /bin/sh

# Check resource limits
kubectl top pod web-app-7c5ddbdf54-x2j9k -n production

# Try with debug container
kubectl debug web-app-7c5ddbdf54-x2j9k -it --image=busybox -n production
```

### 17.4 Manage Storage

```bash
# Create PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: production
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: nfs-client
  resources:
    requests:
      storage: 10Gi
EOF

# Verify PVC bound
kubectl get pvc data-pvc -n production

# Check PV
kubectl get pv

# Attach to pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
  namespace: production
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "while true; do sleep 3600; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
EOF
```

### 17.5 Node Maintenance

```bash
# Check node status
kubectl get nodes
kubectl describe node k3s-worker-1

# Cordon (stop scheduling)
kubectl cordon k3s-worker-1

# Drain (evict pods)
kubectl drain k3s-worker-1 --ignore-daemonsets --delete-emptydir-data

# Perform maintenance (upgrade, reboot, etc.)
ssh k3s-worker-1
sudo reboot

# Wait for node to come back
kubectl get nodes -w

# Uncordon (resume scheduling)
kubectl uncordon k3s-worker-1
```

### 17.6 Backup and Restore

```bash
# Export all resources in namespace
kubectl get all -n production -o yaml > backup.yaml

# Export specific resources
kubectl get deployment web-app -n production -o yaml > web-app-deploy.yaml
kubectl get svc web-app -n production -o yaml > web-app-svc.yaml
kubectl get configmap -n production -o yaml > configmaps.yaml
kubectl get secret -n production -o yaml > secrets.yaml

# Export cluster-wide resources
kubectl get clusterrolebinding -o yaml > clusterroles.yaml
kubectl get storageclass -o yaml > storageclasses.yaml

# Restore from backup
kubectl apply -f backup.yaml
```

### 17.7 Monitoring and Health Checks

```bash
# Check cluster health
kubectl get nodes
kubectl get componentstatuses    # deprecated but still works
kubectl get pods -n kube-system

# Resource usage
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Events summary
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Check deployment health
kubectl get deployments -A
kubectl rollout status deployment/web-app -n production
```

### 17.8 Scaling Operations

```bash
# Manual scale
kubectl scale deployment web-app --replicas=5 -n production

# Autoscale
kubectl autoscale deployment web-app --min=2 --max=10 --cpu-percent=80 -n production

# Check HPA
kubectl get hpa -n production
kubectl describe hpa web-app -n production

# Scale statefulset
kubectl scale statefulset my-db --replicas=3 -n production
```

### 17.9 Security Operations

```bash
# Check RBAC
kubectl auth can-i get pods
kubectl auth can-i --list

# Audit access
kubectl auth can-i create deployments --as=system:serviceaccount:default:my-sa

# Manage secrets
kubectl create secret tls my-tls --cert=tls.crt --key=tls.key -n production
kubectl get secret my-tls -n production -o jsonpath='{.data.tls\.crt}' | base64 -d

# Rotate secrets
kubectl create secret tls my-tls-new --cert=tls-new.crt --key=tls-new.key -n production
kubectl patch deployment web-app -n production -p '{"spec":{"template":{"spec":{"volumes":[{"name":"tls","secret":{"secretName":"my-tls-new"}}]}}}}'
```

### 17.10 Cluster Operations

```bash
# Get cluster info
kubectl cluster-info
kubectl cluster-info dump > cluster-dump.txt

# Check all namespaces
kubectl get all -A

# Find resources by label
kubectl get all -l app=nginx -A

# Delete all resources in namespace (DANGEROUS)
kubectl delete all --all -n staging

# Scale down everything in namespace
kubectl scale deployment --all --replicas=0 -n staging
```

---

## 18. Further Reading

### Official Documentation

- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Command Line Tools](https://kubernetes.io/docs/tasks/tools/)
- [JSONPath Support](https://kubernetes.io/docs/reference/kubectl/jsonpath/)
- [kubectl Debugging](https://kubernetes.io/docs/tasks/debug/debug-cluster/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

### Tools and Extensions

- [kubectx/kubens](https://github.com/ahmetb/kubectx) - Fast context/namespace switching
- [k9s](https://github.com/derailed/k9s) - Terminal UI for Kubernetes
- [stern](https://github.com/stern/stern) - Multi-pod log tailing
- [popeye](https://github.com/derailed/popeye) - Cluster resource sanitizer
- [kube-linter](https://github.com/stackrox/kube-linter) - YAML linting
- [kubent](https://github.com/doitintl/kube-no-trouble) - Deprecated API finder

### Books

- *Kubernetes in Action* by Marko Lukša
- *Kubernetes: Up and Running* by Kelsey Hightower
- *The Kubernetes Book* by Nigel Poulton
- *Kubernetes Patterns* by Bilgin Ibryam

### Practice

- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [KillerCoda Scenarios](https://killercoda.com/playgrounds/scenario/kubernetes)
- [Katacoda/Killercoda](https://killercoda.com) - Interactive Kubernetes scenarios

---

## Quick Reference Card

```bash
# ─── GETTING STARTED ───────────────────────────────────
kubectl get nodes                          # list nodes
kubectl get pods -A                        # all pods
kubectl get pods -o wide                   # pods with extra info
kubectl get pods -w                        # watch pods
kubectl get all -n production              # everything in namespace

# ─── DEPLOYING ─────────────────────────────────────────
kubectl apply -f config.yaml               # declarative create/update
kubectl create deployment nginx --image=nginx   # imperative
kubectl rollout status deploy/nginx        # check deployment status
kubectl rollout undo deploy/nginx          # rollback
kubectl scale deploy/nginx --replicas=5    # scale

# ─── INSPECTING ────────────────────────────────────────
kubectl describe pod/nginx                 # detailed info
kubectl logs nginx                         # container logs
kubectl logs -f nginx                      # follow logs
kubectl logs nginx --previous              # previous container logs
kubectl exec -it nginx -- /bin/sh          # shell into pod

# ─── NETWORKING ────────────────────────────────────────
kubectl port-forward svc/nginx 8080:80     # port forward
kubectl proxy                              # API proxy
kubectl get svc                            # list services
kubectl get ingress                        # list ingresses
kubectl get endpoints                      # service backends

# ─── STORAGE ───────────────────────────────────────────
kubectl get pv                             # persistent volumes
kubectl get pvc                            # persistent volume claims
kubectl get sc                             # storage classes

# ─── SECURITY ──────────────────────────────────────────
kubectl auth can-i <action> <resource>     # check permissions
kubectl get sa                             # service accounts
kubectl get clusterrolebinding             # cluster bindings
kubectl get rolebinding -A                 # namespace bindings

# ─── DEBUGGING ─────────────────────────────────────────
kubectl get events -A --sort-by='.lastTimestamp'   # recent events
kubectl top pods                           # pod resource usage
kubectl top nodes                          # node resource usage
kubectl debug nginx -it --image=busybox    # debug container

# ─── CLEANUP ───────────────────────────────────────────
kubectl delete pod nginx                   # delete pod
kubectl delete -f config.yaml              # delete from file
kubectl delete pods -l app=nginx           # delete by label
kubectl delete pods --field-selector=status.phase=Failed   # by status

# ─── ALIASES ───────────────────────────────────────────
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
```

---

*This guide covers kubectl version 1.30+. Some flags and features may vary across versions. Always check `kubectl <command> --help` for the most current options.*
