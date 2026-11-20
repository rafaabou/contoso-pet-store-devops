# Vault Agent Complete Guide

## Table of Contents

1. [What Is Vault Agent](#what-is-vault-agent)
2. [Why Use Vault Agent — Real Breaches](#why-use-vault-agent--real-breaches)
3. [Architecture Overview](#architecture-overview)
4. [Installation](#installation)
5. [Core Concepts](#core-concepts)
6. [Configuration Reference](#configuration-reference)
7. [Auto-Auth](#auto-auth)
8. [Vault Agent Templates](#vault-agent-templates)
9. [Secret Caching](#secret-caching)
10. [Usage Guide — Step by Step](#usage-guide--step-by-step)
11. [Sidecar Injection on Kubernetes](#sidecar-injection-on-kubernetes)
12. [Template Functions](#template-functions)
13. [Performance Tuning](#performance-tuning)
14. [Integration with Applications](#integration-with-applications)
15. [Security Considerations](#security-considerations)
16. [Troubleshooting (20+ Issues)](#troubleshooting-20-issues)
17. [Tips & Best Practices (20+ Tips)](#tips--best-practices-20-tips)
18. [Command Reference](#command-reference)
19. [Configuration Reference (Full)](#configuration-reference-full)
20. [Real-World Examples — Our Cluster](#real-world-examples--our-cluster)
21. [Further Reading](#further-reading)

---

## What Is Vault Agent

Vault Agent is a client daemon that provides the following functionality:

1. **Auto-Auth** — Automatically authenticates to Vault and manages token lifecycle
2. **Caching** — Caches Vault responses locally to reduce network round-trips
3. **Templating** — Renders secrets into files using Go templates
4. **Proxy** — Proxies requests to Vault (useful for limited connectivity)

Vault Agent runs as a sidecar container (or standalone process) alongside your application, handling all Vault interactions so your application code doesn't need to.

### Core Value Proposition

Vault Agent solves the "last mile" problem of Vault integration: how do applications actually consume secrets without coupling to Vault's API?

Instead of each application implementing:
- Vault client libraries
- Authentication logic
- Token renewal
- Secret fetching
- Error handling

Vault Agent handles all of this transparently:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│              │     │              │     │              │
│  Application │────▶│  Vault Agent │────▶│    Vault     │
│              │     │              │     │              │
│  reads file  │     │  auth+cache  │     │  stores      │
│  or proxy    │     │  +template   │     │  secrets     │
│              │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

### What Vault Agent Is NOT

- **Not a Vault server** — Agent is a client only
- **Not a secrets store** — Agent caches but doesn't persist secrets
- **Not a replacement for Vault** — Still needs a Vault server
- **Not for all use cases** — Some apps may prefer direct Vault API calls

### Key Features

| Feature | Description |
|---------|-------------|
| **Auto-Auth** | Automatic authentication and token renewal |
| **Caching** | Local cache for Vault responses |
| **Templates** | Go templates for file rendering |
| **Sink Files** | Persist tokens to disk for recovery |
| **Proxy Mode** | HTTP proxy for Vault API |
| **Mlock** | Lock memory to prevent swapping |
| **SIGUSR1** | Force token/sink renewal |
| **Graceful Shutdown** | Proper cleanup on SIGTERM/SIGINT |

---

## Why Use Vault Agent — Real Breaches

### The Problem Vault Agent Solves

Without Vault Agent, applications must:
1. Import Vault client libraries
2. Implement authentication logic
3. Handle token lifecycle (acquire, renew, re-authenticate)
4. Fetch secrets on startup and handle rotation
5. Deal with Vault unavailability
6. Implement retry logic
7. Handle secret caching for performance

This creates:
- **Code duplication** across applications
- **Inconsistent implementations** (different teams, different libraries)
- **Security risks** (hardcoded credentials in application code)
- **Operational complexity** (monitoring token expiry, secret rotation)
- **Performance issues** (frequent Vault API calls)

### Real-World Breaches Vault Agent Prevents

#### 1. Hardcoded Vault Tokens
**Problem**: Developers hardcode Vault tokens in application config files
**Impact**: Token compromise → full secret access
**Vault Agent Fix**: Auto-auth generates tokens dynamically, never stored in config

#### 2. Token Expiry Blindness
**Problem**: Applications don't handle token renewal, leading to outages
**Impact**: Secret access failures → application downtime
**Vault Agent Fix**: Automatic token renewal before expiry

#### 3. Secret Sprawl
**Problem**: Applications fetch secrets once and cache forever
**Impact**: Stale secrets used after rotation → security risk
**Vault Agent Fix**: Configurable refresh intervals, template re-rendering

#### 4. Inconsistent Authentication
**Problem**: Each team implements their own Vault auth logic
**Impact**: Vulnerable implementations → attack surface
**Vault Agent Fix**: Standardized auto-auth across all workloads

#### 5. Application Code Coupling
**Problem**: Application code tightly coupled to Vault API
**Impact**: Difficult to migrate, upgrade, or replace Vault
**Vault Agent Fix**: Agent abstracts Vault from application code

---

## Architecture Overview

### Vault Agent Components

```
┌─────────────────────────────────────────────────────────┐
│                    Vault Agent                           │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Auto-Auth Module                    │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  AppRole │  │ Kubernetes│  │   JWT    │     │   │
│  │  │  Module  │  │  Module   │  │  Module  │     │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘     │   │
│  │       │              │              │           │   │
│  │       └──────────────┼──────────────┘           │   │
│  │                      │                          │   │
│  │              ┌───────▼───────┐                  │   │
│  │              │  Token Sink   │                  │   │
│  │              │  (File/API)   │                  │   │
│  │              └───────────────┘                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Cache Layer                         │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  In-     │  │  K8s     │  │  File    │     │   │
│  │  │  Memory  │  │  Secret  │  │  Cache   │     │   │
│  │  │  Cache   │  │  Store   │  │          │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Template Engine                     │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Template │  │  Render  │  │  Watch   │     │   │
│  │  │  Parser   │  │  Engine   │  │  Files   │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              API Proxy                           │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  HTTP    │  │  Unix    │  │  TCP     │     │   │
│  │  │  Proxy   │  │  Socket  │  │  Proxy   │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Request Flow

```
1. Application starts
2. Vault Agent authenticates (Auto-Auth)
3. Agent receives token + renewal info
4. Agent fetches secrets (or waits for template requests)
5. Templates rendered to disk
6. Application reads secrets from files
7. Agent renews token and refreshes secrets
8. On secret rotation, templates re-render
9. Application can use inotify/SIGHUP to reload
```

### Agent Modes

**Sidecar Mode** (Kubernetes):
- Agent runs as sidecar container
- Shares network namespace with application
- Injected automatically via mutating webhook
- Managed by Vault Secrets Operator

**Standalone Mode** (VM/Bare Metal):
- Agent runs as systemd service
- Manages its own lifecycle
- Suitable for non-Kubernetes environments

**Proxy Mode**:
- Agent acts as HTTP proxy
- Application sends requests to Agent, Agent forwards to Vault
- Useful when application can't directly reach Vault

---

## Installation

### Binary Installation

```bash
# Download (same as Vault server)
VAULT_VERSION="1.15.4"
wget -qO /tmp/vault.zip \
  "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
unzip -o /tmp/vault.zip -d /usr/local/bin/

# Verify
vault --version
# vault v1.15.4
```

### Docker Installation

```bash
# Pull image
docker pull hashicorp/vault:1.15.4

# Run agent
docker run -d --name vault-agent \
  -v /opt/vault-agent/config:/vault/config \
  -v /opt/vault-agent/logs:/vault/logs \
  hashicorp/vault:1.15.4 \
  agent -config=/vault/config/agent.hcl
```

### Kubernetes Installation (Helm)

```bash
# Add HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault with agent injector enabled
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true \
  --set injector.enabled=true \
  --set injector.replicas=2
```

### Systemd Service (Standalone)

```bash
# Create vault-agent user
sudo useradd --system --home /etc/vault-agent --shell /bin/false vault-agent

# Create directories
sudo mkdir -p /etc/vault-agent /var/log/vault-agent
sudo chown -R vault-agent:vault-agent /etc/vault-agent /var/log/vault-agent

# Create systemd service
sudo tee /etc/systemd/system/vault-agent.service << 'EOF'
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault-agent/config.hcl

[Service]
User=vault-agent
Group=vault-agent
Type=simple
ExecStart=/usr/local/bin/vault agent -config=/etc/vault-agent/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable vault-agent
sudo systemctl start vault-agent
```

---

## Core Concepts

### Auto-Auth

Auto-Auth handles authentication to Vault and token lifecycle:

```
┌─────────────────────────────────────────────────────────┐
│                    Auto-Auth                             │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Method                             │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  AppRole │  │ Kubernetes│  │   JWT    │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  Performs initial authentication                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Sink                               │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  File    │  │  API     │  │  K8s     │     │   │
│  │  │  Sink    │  │  Sink    │  │  Secret  │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  Persists token for recovery                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Renewal                            │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Token   │  │  Grace   │  │  Backoff │     │   │
│  │  │  Renew   │  │  Period  │  │  Retry   │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  Handles token lifecycle                          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**How Auto-Auth Works:**

1. **Initial Authentication**: Agent authenticates using configured method (AppRole, K8s, JWT)
2. **Token Received**: Vault returns a client token with TTL
3. **Token Stored**: Token written to sink file(s)
4. **Token Renewed**: Agent automatically renews token before expiry
5. **Re-Authentication**: If renewal fails, Agent re-authenticates from scratch
6. **Sink Recovery**: On restart, Agent reads token from sink file

### Token Sinks

Sinks persist tokens to disk for agent recovery:

```hcl
auto_auth {
  method "approle" {
    config = {
      role_id_file_path                   = "/vault/role-id"
      secret_id_file_path                 = "/vault/secret-id"
      remove_secret_id_file_after_reading = true
    }
  }

  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }

  sink "file" {
    config = {
      path = "/vault/token/.vault-token-backup"
    }
  }
}
```

**Sink Types:**
- **File Sink**: Writes token to a file (default, recommended)
- **Kubernetes Secret Sink**: Writes token to a K8s Secret
- **API Sink**: Sends token to a local API endpoint

### Caching

Vault Agent caches Vault responses to reduce network load:

```
┌─────────────────────────────────────────────────────────┐
│                    Cache Layer                           │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              In-Memory Cache                    │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Token   │  │  Secret  │  │  Lease   │     │   │
│  │  │  Cache   │  │  Cache   │  │  Cache   │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  Fast access, lost on restart                    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Persistent Cache                   │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  K8s     │  │  File    │  │  Raft    │     │   │
│  │  │  Secret  │  │  Cache   │  │  Cache   │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  Survives restarts (Enterprise)                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Cache Types:**
- **In-Memory**: Fast, lost on restart (default)
- **Kubernetes Secret**: Stored in K8s Secret, survives pod restarts
- **File**: Stored on disk, survives agent restarts
- **Raft**: Stored in Vault's integrated storage (Enterprise)

### Templates

Templates use Go templating to render secrets into files:

```hcl
template {
  source      = "/vault/templates/config.ctmpl"
  destination = "/vault/secrets/config.json"
  perms       = 0600
  command     = "pkill -HUP myapp"
}

template {
  source      = "/vault/templates/env.ctmpl"
  destination = "/vault/secrets/.env"
  perms       = 0644
}
```

---

## Configuration Reference

### Complete Agent Configuration

```hcl
# /etc/vault-agent/config.hcl

# Vault server address
vault {
  address = "https://vault.example.com:8200"

  # Retry configuration
  retry {
    num_retries = 5
  }

  # Client cache
  client_cache {
    # Persist cache to Kubernetes Secret
    persist "kubernetes" {
      name      = "vault-agent-cache"
      namespace = "default"
    }

    # Or persist to file
    # persist "file" {
    #   path = "/vault/cache"
    # }
  }
}

# Auto-Authentication
auto_auth {
  # Method (only one allowed)
  method "approle" {
    # Namespace (Enterprise only)
    # namespace = "admin"

    config = {
      # Role ID
      role_id_file_path                   = "/vault/role-id"
      secret_id_file_path                 = "/vault/secret-id"
      remove_secret_id_file_after_reading = true

      # Or use environment variables
      # role_id_env_var  = "VAULT_ROLE_ID"
      # secret_id_env_var = "VAULT_SECRET_ID"

      # Token TTL (default: 60s)
      token_ttl = "1h"

      # Token max TTL (default: 0 = no max)
      token_max_ttl = "10h"

      # Disable renewal (default: false)
      disable_token_renewal = false

      # Remove secret_id file after reading (default: true)
      # remove_secret_id_file_after_reading = true

      # Wrap secrets response (default: false)
      wrap_secrets_response = false
    }
  }

  # Sinks for token persistence
  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }

  # Backup sink
  sink "file" {
    config = {
      path = "/vault/token/.vault-token-backup"
    }
  }
}

# Cache configuration
cache {
  # Use persistent cache (Enterprise)
  # persist "kubernetes" {
  #   name      = "vault-agent-cache"
  #   namespace = "default"
  # }

  # Persistent file cache
  # persist "file" {
  #   path = "/vault/cache"
  # }

  # Listen address for cache API
  listen {
    address = "127.0.0.1:8200"
    tls_disable = false
    tls_cert_file = "/vault/tls/tls.crt"
    tls_key_file  = "/vault/tls/tls.key"
  }
}

# Listener for API proxy (optional)
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = false
  tls_cert_file = "/vault/tls/tls.crt"
  tls_key_file  = "/vault/tls/tls.key"
}

# Template configuration
template {
  # Source template file
  source      = "/vault/templates/config.ctmpl"

  # Destination file
  destination = "/vault/secrets/config.json"

  # File permissions
  perms       = 0600

  # Command to execute after rendering
  command     = "pkill -HUP myapp"

  # Error behavior
  error_on_missing_key = false

  # Perms for destination directory
  perms = 0600

  # Left delimiter (default: {{)
  left_delimiter  = "{{"

  # Right delimiter (default: }})
  right_delimiter = "}}"

  # Create destination directory (default: false)
  create_dest_dirs = true

  # Embedded template (alternative to source)
  # contents = "{{ with secret \"secret/data/myapp\" }}{{ .Data.data.password }}{{ end }}"
}

# Second template
template {
  source      = "/vault/templates/env.ctmpl"
  destination = "/vault/secrets/.env"
  perms       = 0644
}

# Third template for Kubernetes secret
template {
  source      = "/vault/templates/k8s-secret.ctmpl"
  destination = "/vault/secrets/k8s-secret.json"
  perms       = 0600

  # Write to Kubernetes Secret
  command = "kubectl create secret generic myapp-secrets --from-file=/vault/secrets/k8s-secret.json --dry-run=client -o yaml | kubectl apply -f -"
}

# Log level
log_level  = "info"
log_format = "json"

# PID file
pid_file = "/vault-agent/pidfile"

# Disable mlock (set to true for containers without IPC_LOCK capability)
disable_mlock = true

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname          = true
}
```

### Configuration Sections

#### `vault` Section
```hcl
vault {
  address = "https://vault.example.com:8200"
  retry {
    num_retries = 5
  }
  client_cache {
    persist "kubernetes" {
      name      = "vault-agent-cache"
      namespace = "default"
    }
  }
}
```

#### `auto_auth` Section
```hcl
auto_auth {
  method "approle" {
    config = {
      role_id_file_path = "/vault/role-id"
      secret_id_file_path = "/vault/secret-id"
    }
  }
  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }
}
```

#### `cache` Section
```hcl
cache {
  listen {
    address = "127.0.0.1:8200"
  }
}
```

#### `template` Section
```hcl
template {
  source      = "/vault/templates/config.ctmpl"
  destination = "/vault/secrets/config.json"
  perms       = 0600
  command     = "pkill -HUP myapp"
}
```

#### `listener` Section
```hcl
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = false
}
```

---

## Auto-Auth

### Authentication Methods

#### AppRole

```hcl
auto_auth {
  method "approle" {
    config = {
      # File-based credentials
      role_id_file_path                   = "/vault/role-id"
      secret_id_file_path                 = "/vault/secret-id"
      remove_secret_id_file_after_reading = true

      # Environment variable credentials
      # role_id_env_var  = "VAULT_ROLE_ID"
      # secret_id_env_var = "VAULT_SECRET_ID"

      # Token configuration
      token_ttl = "1h"
      token_max_ttl = "10h"

      # Renewal configuration
      disable_token_renewal = false

      # Wrap secrets response
      wrap_secrets_response = false

      # Disable human readable names
      disable_human_readable_names = false

      # Role ID
      # role_id = "abc123"

      # Secret ID
      # secret_id = "xyz789"
    }
  }
}
```

**AppRole Setup:**
```bash
# Enable AppRole
vault auth enable approle

# Create role for agent
vault write auth/approle/role/vault-agent \
  token_policies="agent-policy" \
  token_ttl=1h \
  token_max_ttl=10h \
  secret_id_ttl=0 \
  secret_id_num_uses=0

# Get role_id
vault read auth/approle/role/vault-agent/role_id
# Save to /vault/role-id

# Generate secret_id
vault write -f auth/approle/role/vault-agent/secret-id
# Save to /vault/secret-id
```

#### Kubernetes

```hcl
auto_auth {
  method "kubernetes" {
    config = {
      # Role name
      role = "vault-agent"

      # Kubernetes API configuration
      kubernetes_api_host = "https://kubernetes.default.svc"
      kubernetes_ca_cert = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

      # Token path (default: /var/run/secrets/kubernetes.io/serviceaccount/token)
      token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"

      # Service account token expiration (default: 0 = use K8s default)
      service_account_token_exp_time = 3600

      # Disable local CA JWT (default: false)
      disable_local_ca_jwt = true

      # Use annotation for role name
      # role_annotation_key = "vault.hashicorp.com/agent-auth-role"

      # Use annotation for service account
      # service_account_annotation_key = "vault.hashicorp.com/agent-auth-service-account"

      # Use annotation for namespace
      # namespace_annotation_key = "vault.hashicorp.com/agent-auth-namespace"
    }
  }
}
```

**Kubernetes Setup:**
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  disable_local_ca_jwt=true

# Create role
vault write auth/kubernetes/role/vault-agent \
  bound_service_account_names=vault-agent \
  bound_service_account_namespaces=vault \
  policies=agent-policy \
  ttl=1h \
  max_ttl=10h
```

#### JWT/OIDC

```hcl
auto_auth {
  method "jwt" {
    config = {
      # Role name
      role = "vault-agent"

      # JWT path (default: /var/run/secrets/kubernetes.io/serviceaccount/token)
      jwt = "/var/run/secrets/kubernetes.io/serviceaccount/token"

      # Or inline JWT
      # jwt = "eyJhbGciOiJSUzI1NiIs..."

      # OIDC discovery URL
      oidc_discovery_url = "https://accounts.google.com"

      # OIDC client ID
      oidc_client_id = "my-client-id"

      # OIDC client secret
      oidc_client_secret = "my-client-secret"

      # OIDC scopes
      oidc_scopes = ["openid", "email", "profile"]

      # Token TTL
      token_ttl = "1h"

      # Token max TTL
      token_max_ttl = "10h"
    }
  }
}
```

#### TLS Certificate

```hcl
auto_auth {
  method "cert" {
    config = {
      # Certificate path
      cert_file = "/vault/tls/client.crt"

      # Key file
      key_file = "/vault/tls/client.key"

      # CA certificate
      ca_cert = "/vault/tls/ca.crt"

      # Token TTL
      token_ttl = "1h"

      # Token max TTL
      token_max_ttl = "10h"
    }
  }
}
```

#### Userpass

```hcl
auto_auth {
  method "userpass" {
    config = {
      # Username
      username = "vault-agent"

      # Password (use environment variable in production)
      password = "changeme"

      # Or use file
      # password_file = "/vault/password"

      # Token TTL
      token_ttl = "1h"

      # Token max TTL
      token_max_ttl = "10h"
    }
  }
}
```

### Token Renewal

Auto-Auth automatically renews tokens:

```hcl
auto_auth {
  method "approle" {
    config = {
      # Token TTL (how long before renewal needed)
      token_ttl = "1h"

      # Token max TTL (maximum lifetime, even with renewal)
      token_max_ttl = "10h"

      # Disable renewal (not recommended)
      disable_token_renewal = false
    }
  }
}
```

**Renewal Behavior:**
1. Agent renews token at 2/3 of TTL (e.g., 40 min for 1h TTL)
2. If renewal fails, Agent retries with exponential backoff
3. If max TTL reached, Agent re-authenticates from scratch
4. Agent uses sink files to recover tokens on restart

### Sink Files

Sink files persist tokens for recovery:

```hcl
auto_auth {
  # Primary sink
  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }

  # Backup sink (redundancy)
  sink "file" {
    config = {
      path = "/vault/token/.vault-token-backup"
    }
  }

  # Kubernetes Secret sink
  sink "kubernetes" {
    config = {
      name      = "vault-agent-token"
      namespace = "vault"
    }
  }
}
```

**Sink File Format:**
```json
{
  "token": "s.xxxx...",
  "accessor": "hmac-sha256:abc123",
  "policies": ["agent-policy"],
  "ttl": 3600,
  "creation_time": "2024-01-15T10:30:00Z"
}
```

---

## Vault Agent Templates

### Template Basics

Templates use Go template syntax with Vault-specific functions:

```go
{{ with secret "secret/data/myapp/config" }}
DB_HOST={{ .Data.data.host }}
DB_PORT={{ .Data.data.port }}
DB_USER={{ .Data.data.username }}
DB_PASS={{ .Data.data.password }}
{{ end }}
```

### Template Functions

```go
// secret - Read a secret
{{ with secret "secret/data/myapp/config" }}
  {{ .Data.data.db_password }}
{{ end }}

// with secret - Conditional rendering
{{ with secret "secret/data/myapp/config" }}
  {{ if .Data.data.db_password }}
    DB_PASS={{ .Data.data.db_password }}
  {{ else }}
    # No password configured
  {{ end }}
{{ end }}

// secret with version - Read specific version
{{ with secret "secret/data/myapp/config?version=2" }}
  {{ .Data.data.db_password }}
{{ end }}

// database - Get database credentials
{{ with database "database/creds/readonly" }}
  DB_USER={{ .Data.username }}
  DB_PASS={{ .Data.password }}
{{ end }}

// pki - Issue certificate
{{ with pkiIssue "pki/issue/internal-server" "common_name" "web.internal" }}
  CERT={{ .Data.certificate }}
  KEY={{ .Data.private_key }}
  CA={{ .Data.issuing_ca }}
{{ end }}

// pkiCert - Parse certificate
{{ with pkiCert "pki/cert/ca" }}
  CA_FINGERPRINT={{ .Fingerprint }}
  CA_SERIAL={{ .SerialNumber }}
{{ end }}

// safeLs - List secrets safely
{{ range safeLs "secret/data/myapp/" }}
  {{ .Data.key }}={{ .Data.value }}
{{ end }}

// safeLs with iteration
{{ range safeLs "secret/data/myapp/" }}
  {{ .Data.key }}={{ .Data.data.value }}
{{ end }}
```

### Template Examples

#### Example 1: JSON Configuration File

```
{{ with secret "secret/data/myapp/config" }}
{
  "database": {
    "host": "{{ .Data.data.db_host }}",
    "port": {{ .Data.data.db_port }},
    "username": "{{ .Data.data.db_username }}",
    "password": "{{ .Data.data.db_password }}"
  },
  "redis": {
    "host": "{{ .Data.data.redis_host }}",
    "port": {{ .Data.data.redis_port }}
  },
  "api_key": "{{ .Data.data.api_key }}"
}
{{ end }}
```

#### Example 2: Environment File

```
{{ with secret "secret/data/myapp/config" }}
DB_HOST={{ .Data.data.db_host }}
DB_PORT={{ .Data.data.db_port }}
DB_USER={{ .Data.data.db_username }}
DB_PASS={{ .Data.data.db_password }}
REDIS_HOST={{ .Data.data.redis_host }}
REDIS_PORT={{ .Data.data.redis_port }}
API_KEY={{ .Data.data.api_key }}
SECRET_KEY={{ .Data.data.secret_key }}
{{ end }}
```

#### Example 3: Database Connection String

```
{{ with secret "secret/data/myapp/config" }}
DATABASE_URL=postgresql://{{ .Data.data.db_username }}:{{ .Data.data.db_password }}@{{ .Data.data.db_host }}:{{ .Data.data.db_port }}/{{ .Data.data.db_name }}
{{ end }}
```

#### Example 4: Multiple Secrets

```
{{ with secret "secret/data/myapp/database" }}
DB_USER={{ .Data.data.username }}
DB_PASS={{ .Data.data.password }}
{{ end }}

{{ with secret "secret/data/myapp/redis" }}
REDIS_HOST={{ .Data.data.host }}
REDIS_PORT={{ .Data.data.port }}
{{ end }}

{{ with secret "secret/data/myapp/api" }}
API_KEY={{ .Data.data.key }}
API_SECRET={{ .Data.data.secret }}
{{ end }}
```

#### Example 5: Conditional Rendering

```
{{ with secret "secret/data/myapp/config" }}
{{ if .Data.data.db_password }}
DATABASE_URL=postgresql://{{ .Data.data.db_user }}:{{ .Data.data.db_password }}@{{ .Data.data.db_host }}:{{ .Data.data.db_port }}/{{ .Data.data.db_name }}
{{ else }}
# No database password configured
{{ end }}

{{ if .Data.data.redis_password }}
REDIS_URL=redis://:{{ .Data.data.redis_password }}@{{ .Data.data.redis_host }}:{{ .Data.data.redis_port }}
{{ else }}
REDIS_URL=redis://{{ .Data.data.redis_host }}:{{ .Data.data.redis_port }}
{{ end }}
{{ end }}
```

#### Example 6: Kubernetes Secret

```
{{ with secret "secret/data/myapp/config" }}
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: production
type: Opaque
data:
  db-password: {{ .Data.data.db_password | base64 }}
  api-key: {{ .Data.data.api_key | base64 }}
{{ end }}
```

#### Example 7: Certificate and Key

```
{{ with pkiIssue "pki/issue/internal-server" "common_name" "web.internal" "ttl" "72h" }}
-----BEGIN CERTIFICATE-----
{{ .Data.certificate }}
-----END CERTIFICATE-----

-----BEGIN RSA PRIVATE KEY-----
{{ .Data.private_key }}
-----END RSA PRIVATE KEY-----

-----BEGIN CERTIFICATE-----
{{ .Data.issuing_ca }}
-----END CERTIFICATE-----
{{ end }}
```

#### Example 8: Dynamic Database Credentials

```
{{ with database "database/creds/readonly" }}
DB_USER={{ .Data.username }}
DB_PASS={{ .Data.password }}
{{ end }}
```

---

## Secret Caching

### Cache Configuration

```hcl
vault {
  client_cache {
    # Persist cache to Kubernetes Secret
    persist "kubernetes" {
      name      = "vault-agent-cache"
      namespace = "default"
    }

    # Or persist to file
    # persist "file" {
    #   path = "/vault/cache"
    # }
  }
}

cache {
  # Listen address for cache API
  listen {
    address = "127.0.0.1:8200"
    tls_disable = false
    tls_cert_file = "/vault/tls/tls.crt"
    tls_key_file  = "/vault/tls/tls.key"
  }
}
```

### Cache Types

#### In-Memory Cache
- Fastest access
- Lost on restart
- Default behavior

#### Kubernetes Secret Cache
- Survives pod restarts
- Stored in K8s Secret
- Enterprise feature

#### File Cache
- Survives agent restarts
- Stored on local disk
- Enterprise feature

#### Raft Cache
- Stored in Vault's integrated storage
- Survives agent restarts
- Enterprise feature

### Cache Behavior

**When secrets are cached:**
- First request to a path
- After cache invalidation
- On agent restart (if persistent cache)

**When cache is invalidated:**
- Secret lease expires
- Secret is rotated
- Agent restart (in-memory cache)
- Explicit cache invalidation

**Cache TTL:**
- Default: 0 (no caching)
- Configurable per secret path
- Respects secret lease TTL

---

## Usage Guide — Step by Step

### Step 1: Set Up Vault

```bash
# Initialize Vault (if not already done)
vault operator init

# Unseal
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### Step 2: Enable Auth Method

```bash
# Enable AppRole
vault auth enable approle

# Create policy
vault policy write agent-policy - << 'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
path "database/creds/readonly" {
  capabilities = ["read"]
}
path "pki/issue/internal-server" {
  capabilities = ["create", "update"]
}
EOF

# Create role
vault write auth/approle/role/vault-agent \
  token_policies="agent-policy" \
  token_ttl=1h \
  token_max_ttl=10h \
  secret_id_ttl=0 \
  secret_id_num_uses=0
```

### Step 3: Get Credentials

```bash
# Get role_id
vault read -format=json auth/approle/role/vault-agent/role_id | \
  jq -r '.data.role_id' > /vault/role-id

# Generate secret_id
vault write -format=json -f auth/approle/role/vault-agent/secret-id | \
  jq -r '.data.secret_id' > /vault/secret-id
```

### Step 4: Create Templates

```bash
# Create template directory
mkdir -p /vault/templates

# Create config template
cat > /vault/templates/config.ctmpl << 'EOF'
{{ with secret "secret/data/myapp/config" }}
{
  "database": {
    "host": "{{ .Data.data.db_host }}",
    "port": {{ .Data.data.db_port }},
    "username": "{{ .Data.data.db_username }}",
    "password": "{{ .Data.data.db_password }}"
  }
}
{{ end }}
EOF

# Create environment template
cat > /vault/templates/env.ctmpl << 'EOF'
{{ with secret "secret/data/myapp/config" }}
DB_HOST={{ .Data.data.db_host }}
DB_PORT={{ .Data.data.db_port }}
DB_USER={{ .Data.data.db_username }}
DB_PASS={{ .Data.data.db_password }}
{{ end }}
EOF
```

### Step 5: Create Agent Configuration

```bash
cat > /vault/config/agent.hcl << 'EOF'
vault {
  address = "https://vault.example.com:8200"
}

auto_auth {
  method "approle" {
    config = {
      role_id_file_path                   = "/vault/role-id"
      secret_id_file_path                 = "/vault/secret-id"
      remove_secret_id_file_after_reading = true
      token_ttl                           = "1h"
      token_max_ttl                       = "10h"
    }
  }

  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }
}

template {
  source      = "/vault/templates/config.ctmpl"
  destination = "/vault/secrets/config.json"
  perms       = 0600
  command     = "pkill -HUP myapp"
}

template {
  source      = "/vault/templates/env.ctmpl"
  destination = "/vault/secrets/.env"
  perms       = 0644
}
EOF
```

### Step 6: Start Vault Agent

```bash
# Start agent
vault agent -config=/vault/config/agent.hcl

# Or as systemd service
sudo systemctl start vault-agent
```

### Step 7: Verify

```bash
# Check token
cat /vault/token/.vault-token

# Check rendered secrets
cat /vault/secrets/config.json
cat /vault/secrets/.env

# Check agent logs
journalctl -u vault-agent -f
```

---

## Sidecar Injection on Kubernetes

### How It Works

1. **Mutating Webhook** intercepts pod creation
2. **Webhook injects** Vault Agent sidecar container
3. **Agent authenticates** via Kubernetes auth method
4. **Agent fetches secrets** based on pod annotations
5. **Agent renders templates** to shared volume
6. **Application reads secrets** from files

### Pod Annotations

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        # Enable injection
        vault.hashicorp.com/agent-inject: "true"

        # Vault role
        vault.hashicorp.com/role: "myapp"

        # Secret path 1
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"

        # Template for secret 1
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "secret/data/myapp/config" -}}
          {
            "db_password": "{{ .Data.data.db_password }}",
            "api_key": "{{ .Data.data.api_key }}"
          }
          {{- end -}}

        # Secret path 2
        vault.hashicorp.com/agent-inject-secret-db: "secret/data/myapp/database"

        # Template for secret 2
        vault.hashicorp.com/agent-inject-template-db: |
          {{- with secret "secret/data/myapp/database" -}}
          DB_HOST={{ .Data.data.host }}
          DB_PORT={{ .Data.data.port }}
          DB_USER={{ .Data.data.username }}
          DB_PASS={{ .Data.data.password }}
          {{- end -}}

        # Command to run after rendering
        vault.hashicorp.com/agent-command: "pkill -HUP myapp"

        # Agent memory limit
        vault.hashicorp.com/agent-requests-mem: "64Mi"

        # Agent CPU limit
        vault.hashicorp.com/agent-limits-cpu: "100m"

        # Agent CPU request
        vault.hashicorp.com/agent-requests-cpu: "50m"

        # Disable injection for this pod
        # vault.hashicorp.com/agent-inject: "false"

        # Use specific container
        # vault.hashicorp.com/agent-inject-status: "enabled"

        # Agent image
        # vault.hashicorp.com/agent-image: "hashicorp/vault:1.15.4"

        # Agent log level
        # vault.hashicorp.com/agent-log-level: "info"

        # Agent memory limit
        # vault.hashicorp.com/agent-requests-mem: "64Mi"

        # Agent CPU limit
        # vault.hashicorp.com/agent-limits-cpu: "100m"

        # Agent CPU request
        # vault.hashicorp.com/agent-requests-cpu: "50m"
    spec:
      serviceAccountName: myapp
      containers:
        - name: myapp
          image: myapp:latest
          volumeMounts:
            - name: vault-secrets
              mountPath: /vault/secrets
              readOnly: true
      volumes:
        - name: vault-secrets
          emptyDir:
            medium: Memory
```

### Advanced Annotations

```yaml
# Memory and CPU limits
vault.hashicorp.com/agent-requests-mem: "64Mi"
vault.hashicorp.com/agent-limits-mem: "128Mi"
vault.hashicorp.com/agent-requests-cpu: "50m"
vault.hashicorp.com/agent-limits-cpu: "100m"

# Image override
vault.hashicorp.com/agent-image: "hashicorp/vault:1.15.4"

# Log level
vault.hashicorp.com/agent-log-level: "debug"

# Proxy mode
vault.hashicorp.com/agent-inject-status: "enabled"

# Cache configuration
vault.hashicorp.com/agent-cache-enable: "true"

# Secret version
vault.hashicorp.com/agent-inject-secret-config-version: "2"

# Template format
vault.hashicorp.com/agent-inject-template-config-format: "json"

# Command
vault.hashicorp.com/agent-command: "pkill -HUP myapp"

# Left/Right delimiters
vault.hashicorp.com/agent-template-left-delimiter: "{{"
vault.hashicorp.com/agent-template-right-delimiter: "}}"

# Error behavior
vault.hashicorp.com/agent-template-error-on-missing-key: "false"

# Create destination directory
vault.hashicorp.com/agent-template-create-dest-dirs: "true"
```

### Namespace Configuration

```yaml
# Vault namespace (Enterprise)
vault.hashicorp.com/namespace: "production"

# Agent namespace
vault.hashicorp.com/agent-namespace: "vault"

# Secret namespace
vault.hashicorp.com/secret-namespace: "production"
```

### TLS Configuration

```yaml
# CA certificate
vault.hashicorp.com/tls-skip-verify: "false"
vault.hashicorp.com/tls-ca-cert: "/vault/tls/ca.crt"

# Client certificate
vault.hashicorp.com/tls-client-cert: "/vault/tls/client.crt"
vault.hashicorp.com/tls-client-key: "/vault/tls/client.key"
```

---

## Template Functions

### secret

Read a secret from Vault:

```
{{ with secret "secret/data/myapp/config" }}
  {{ .Data.data.db_password }}
{{ end }}
```

**Parameters:**
- Path to secret
- Optional query parameters: `?version=2`

**Returns:**
- `.Data` - Secret data
- `.Data.data` - Key-value pairs
- `.Data.metadata` - Metadata (version, created_time)

### database

Get dynamic database credentials:

```
{{ with database "database/creds/readonly" }}
  {{ .Data.username }}
  {{ .Data.password }}
{{ end }}
```

**Returns:**
- `.Data.username` - Dynamic username
- `.Data.password` - Dynamic password
- `.LeaseID` - Lease ID
- `.LeaseDuration` - TTL

### pkiIssue

Issue a certificate:

```
{{ with pkiIssue "pki/issue/internal-server" "common_name" "web.internal" "ttl" "72h" }}
  {{ .Data.certificate }}
  {{ .Data.private_key }}
  {{ .Data.issuing_ca }}
  {{ .Data.serial_number }}
{{ end }}
```

**Returns:**
- `.Data.certificate` - Certificate PEM
- `.Data.private_key` - Private key PEM
- `.Data.issuing_ca` - CA certificate PEM
- `.Data.serial_number` - Serial number

### pkiCert

Parse a certificate:

```
{{ with pkiCert "pki/cert/ca" }}
  {{ .Fingerprint }}
  {{ .SerialNumber }}
{{ end }}
```

### safeLs

List secrets safely:

```
{{ range safeLs "secret/data/myapp/" }}
  {{ .Data.key }}
{{ end }}
```

### base64

Encode data as base64:

```
{{ .Data.data.password | base64 }}
```

### json

Encode data as JSON:

```
{{ .Data.data | toJson }}
```

### env

Read environment variable:

```
{{ env "HOME" }}
```

### now

Current time:

```
{{ now | date "2006-01-02T15:04:05Z07:00" }}
```

### timestamp

Unix timestamp:

```
{{ timestamp }}
```

---

## Performance Tuning

### Cache Optimization

```hcl
vault {
  client_cache {
    # Enable persistent cache
    persist "kubernetes" {
      name      = "vault-agent-cache"
      namespace = "default"
    }
  }
}
```

### Template Optimization

```hcl
# Single template for multiple secrets
template {
  source      = "/vault/templates/all-secrets.ctmpl"
  destination = "/vault/secrets/all.json"
  perms       = 0600
}

# Instead of multiple templates
# template {
#   source      = "/vault/templates/db.ctmpl"
#   destination = "/vault/secrets/db.json"
# }
# template {
#   source      = "/vault/templates/redis.ctmpl"
#   destination = "/vault/secrets/redis.json"
# }
```

### Auto-Auth Optimization

```hcl
auto_auth {
  method "approle" {
    config = {
      # Longer TTL for stable environments
      token_ttl = "4h"

      # No secret_id expiry for long-running processes
      secret_id_ttl = 0
      secret_id_num_uses = 0
    }
  }
}
```

### Resource Limits

```yaml
# Kubernetes pod resource limits
vault.hashicorp.com/agent-requests-mem: "64Mi"
vault.hashicorp.com/agent-limits-mem: "128Mi"
vault.hashicorp.com/agent-requests-cpu: "50m"
vault.hashicorp.com/agent-limits-cpu: "100m"
```

### Retry Configuration

```hcl
vault {
  retry {
    num_retries = 5
  }
}
```

---

## Integration with Applications

### Python Application

```python
import os
import json

def get_config():
    """Read configuration from Vault Agent rendered file"""
    config_path = "/vault/secrets/config.json"
    
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    else:
        raise FileNotFoundError(f"Config file not found: {config_path}")

def get_env():
    """Read environment variables from Vault Agent rendered file"""
    env_path = "/vault/secrets/.env"
    
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    os.environ[key] = value

# Usage
get_env()  # Load .env file
config = get_config()  # Load JSON config

# Access secrets
db_password = config['database']['password']
api_key = config['api_key']
```

### Go Application

```go
package main

import (
    "encoding/json"
    "fmt"
    "os"
)

type Config struct {
    Database struct {
        Host     string `json:"host"`
        Port     int    `json:"port"`
        Username string `json:"username"`
        Password string `json:"password"`
    } `json:"database"`
    APIKey string `json:"api_key"`
}

func main() {
    // Read config file rendered by Vault Agent
    data, err := os.ReadFile("/vault/secrets/config.json")
    if err != nil {
        panic(err)
    }

    var config Config
    if err := json.Unmarshal(data, &config); err != nil {
        panic(err)
    }

    // Use secrets
    fmt.Printf("DB Host: %s\n", config.Database.Host)
    fmt.Printf("DB Pass: %s\n", config.Database.Password)
}
```

### Node.js Application

```javascript
const fs = require('fs');
const path = require('path');

function getConfig() {
  const configPath = '/vault/secrets/config.json';
  
  if (fs.existsSync(configPath)) {
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  }
  
  throw new Error(`Config file not found: ${configPath}`);
}

function loadEnv() {
  const envPath = '/vault/secrets/.env';
  
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    content.split('\n').forEach(line => {
      line = line.trim();
      if (line && !line.startsWith('#')) {
        const [key, value] = line.split('=', 1);
        process.env[key] = value;
      }
    });
  }
}

// Usage
loadEnv();
const config = getConfig();

console.log(`DB Host: ${config.database.host}`);
console.log(`DB Pass: ${config.database.password}`);
```

### Java Application

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import com.fasterxml.jackson.databind.ObjectMapper;

public class VaultConfig {
    private DatabaseConfig database;
    private String apiKey;

    public static VaultConfig load() throws IOException {
        String configPath = "/vault/secrets/config.json";
        String content = new String(Files.readAllBytes(Paths.get(configPath)));
        ObjectMapper mapper = new ObjectMapper();
        return mapper.readValue(content, VaultConfig.class);
    }

    // Getters
    public DatabaseConfig getDatabase() { return database; }
    public String getApiKey() { return apiKey; }

    public static class DatabaseConfig {
        private String host;
        private int port;
        private String username;
        private String password;

        // Getters
        public String getHost() { return host; }
        public int getPort() { return port; }
        public String getUsername() { return username; }
        public String getPassword() { return password; }
    }
}
```

---

## Security Considerations

### Token Security

```hcl
auto_auth {
  method "approle" {
    config = {
      # Use file-based credentials
      role_id_file_path = "/vault/role-id"
      secret_id_file_path = "/vault/secret-id"

      # Remove secret_id after reading
      remove_secret_id_file_after_reading = true

      # Short-lived tokens
      token_ttl = "1h"
      token_max_ttl = "10h"
    }
  }

  # Multiple sinks for redundancy
  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }

  sink "file" {
    config = {
      path = "/vault/token/.vault-token-backup"
    }
  }
}
```

### File Permissions

```bash
# Vault Agent config
chmod 600 /vault/config/agent.hcl

# Credentials
chmod 600 /vault/role-id
chmod 600 /vault/secret-id

# Token files
chmod 600 /vault/token/.vault-token

# Rendered secrets
chmod 600 /vault/secrets/*
```

### Memory Protection

```bash
# Disable mlock in containers without IPC_LOCK capability
disable_mlock = true

# Or grant IPC_LOCK capability in Docker
docker run --cap-add IPC_LOCK ...
```

### Network Security

```hcl
# TLS for all connections
vault {
  address = "https://vault.example.com:8200"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = false
  tls_cert_file = "/vault/tls/tls.crt"
  tls_key_file  = "/vault/tls/tls.key"
}
```

### Audit Logging

```bash
# Enable audit logging on Vault server
vault audit enable file file_path=/var/log/vault/audit.log
```

### Secret Rotation

```hcl
# Rotate secrets periodically
template {
  source      = "/vault/templates/config.ctmpl"
  destination = "/vault/secrets/config.json"
  perms       = 0600
  # Re-render every hour
  command = "pkill -HUP myapp"
}
```

---

## Troubleshooting (20+ Issues)

### Issue 1: Agent Won't Start

**Symptom**: `vault agent` exits immediately

```bash
# Check logs
journalctl -u vault-agent

# Validate config
vault agent -config=/vault/config/agent.hcl -validate

# Check file permissions
ls -la /vault/config/agent.hcl
ls -la /vault/role-id /vault/secret-id
```

### Issue 2: Authentication Failed

**Symptom**: `permission denied` when authenticating

```bash
# Check role_id
cat /vault/role-id

# Check secret_id
cat /vault/secret-id

# Verify role exists
vault read auth/approle/role/vault-agent

# Test login manually
vault write auth/approle/login \
  role_id=$(cat /vault/role-id) \
  secret_id=$(cat /vault/secret-id)
```

### Issue 3: Token Expired

**Symptom**: `permission denied` errors

```bash
# Check token status
vault token lookup

# Check token TTL
vault token lookup -format=json | jq '.data.ttl'

# Renew token
vault token renew
```

### Issue 4: Template Rendering Failed

**Symptom**: Destination file not created or empty

```bash
# Check template syntax
vault agent -config=/vault/config/agent.hcl -validate

# Check Vault connectivity
vault status

# Check agent logs
journalctl -u vault-agent | grep -i template

# Test template manually
vault read secret/data/myapp/config
```

### Issue 5: Command Not Executed

**Symptom**: Application not restarted after secret rotation

```bash
# Check command syntax
cat /vault/config/agent.hcl | grep command

# Test command manually
pkill -HUP myapp

# Check agent logs
journalctl -u vault-agent | grep -i command
```

### Issue 6: Cache Not Working

**Symptom**: Frequent Vault API calls

```bash
# Check cache configuration
vault agent -config=/vault/config/agent.hcl -validate | grep cache

# Check cache hit rate
vault metrics | grep vault_agent_cache

# Enable debug logging
log_level = "debug"
```

### Issue 7: Token Sink Not Created

**Symptom**: Token not persisted to file

```bash
# Check sink configuration
cat /vault/config/agent.hcl | grep -A5 sink

# Check file permissions
ls -la /vault/token/

# Check agent logs
journalctl -u vault-agent | grep -i sink
```

### Issue 8: Agent Can't Reach Vault

**Symptom**: `dial tcp` errors

```bash
# Check Vault address
curl -k https://vault.example.com:8200/v1/sys/health

# Check TLS certificates
openssl s_client -connect vault.example.com:8200

# Check network connectivity
ping vault.example.com
```

### Issue 9: Agent Out of Memory

**Symptom**: OOM killed

```bash
# Check memory usage
docker stats vault-agent

# Increase memory limit
# Kubernetes: vault.hashicorp.com/agent-limits-mem: "256Mi"

# Reduce cache size
# Disable persistent cache if not needed
```

### Issue 10: Agent CPU High

**Symptom**: High CPU usage

```bash
# Check CPU usage
docker stats vault-agent

# Check for infinite loops in templates
vault agent -config=/vault/config/agent.hcl -validate

# Reduce polling frequency
# Use longer token_ttl
```

### Issue 11: Secret Not Rotated

**Symptom**: Old secret still in use

```bash
# Check secret version
vault kv get -version-metadata secret/data/myapp/config

# Force rotation
vault kv put secret/data/myapp/config db_password=new_password

# Check agent logs
journalctl -u vault-agent | grep -i secret
```

### Issue 12: Multiple Agents Conflict

**Symptom**: Token conflicts

```bash
# Check running agents
ps aux | grep vault-agent

# Kill duplicate agents
pkill -f vault-agent

# Use different sink paths
# Agent 1: sink "file" { config = { path = "/vault/token/.vault-token-1" } }
# Agent 2: sink "file" { config = { path = "/vault/token/.vault-token-2" } }
```

### Issue 13: Agent Can't Write to Disk

**Symptom**: `permission denied` when writing secrets

```bash
# Check directory permissions
ls -la /vault/secrets/

# Fix permissions
chmod 755 /vault/secrets/
chmod 600 /vault/secrets/*

# Check disk space
df -h /vault
```

### Issue 14: Agent Loop Restart

**Symptom**: Agent keeps restarting

```bash
# Check logs
journalctl -u vault-agent | tail -50

# Check config syntax
vault agent -config=/vault/config/agent.hcl -validate

# Check Vault availability
vault status
```

### Issue 15: Template Syntax Error

**Symptom**: `template error` in logs

```bash
# Validate template syntax
vault agent -config=/vault/config/agent.hcl -validate

# Check template file
cat /vault/templates/config.ctmpl

# Test template rendering
vault read secret/data/myapp/config | jq .
```

### Issue 16: Agent Can't Read Role-ID

**Symptom**: `role_id_file_path` not found

```bash
# Check file exists
cat /vault/role-id

# Check file permissions
chmod 600 /vault/role-id

# Check agent can read file
su -s /bin/sh vault-agent -c "cat /vault/role-id"
```

### Issue 17: Agent Can't Read Secret-ID

**Symptom**: `secret_id_file_path` not found

```bash
# Check file exists
cat /vault/secret-id

# Check file permissions
chmod 600 /vault/secret-id

# Regenerate secret_id
vault write -f auth/approle/role/vault-agent/secret-id
```

### Issue 18: Agent Can't Renew Token

**Symptom**: Token renewal failed

```bash
# Check token status
vault token lookup

# Check token policies
vault token lookup -format=json | jq '.data.policies'

# Check Vault connectivity
vault status
```

### Issue 19: Agent Cache Corrupted

**Symptom**: Cache errors

```bash
# Clear cache
# For file cache
rm -rf /vault/cache/*

# For Kubernetes Secret cache
kubectl delete secret vault-agent-cache

# Restart agent
systemctl restart vault-agent
```

### Issue 20: Agent TLS Certificate Expired

**Symptom**: TLS handshake failed

```bash
# Check certificate expiry
openssl x509 -in /vault/tls/tls.crt -noout -dates

# Regenerate certificate
vault write pki/issue/internal-server common_name=vault-agent.internal

# Update agent config
```

### Issue 21: Agent Can't Connect to Kubernetes API

**Symptom**: Kubernetes auth failed

```bash
# Check service account
kubectl get sa vault-agent -o yaml

# Check token
kubectl exec -it myapp-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Check Kubernetes auth config
vault read auth/kubernetes/config
```

### Issue 22: Agent Memory Leak

**Symptom**: Memory usage grows over time

```bash
# Check memory usage
docker stats vault-agent

# Restart agent
systemctl restart vault-agent

# Update Vault version
# Check for known memory leak issues
```

---

## Tips & Best Practices (20+ Tips)

### Tip 1: Use File-Based Credentials

Always use file-based credentials for AppRole instead of environment variables:

```hcl
auto_auth {
  method "approle" {
    config = {
      role_id_file_path = "/vault/role-id"
      secret_id_file_path = "/vault/secret-id"
      remove_secret_id_file_after_reading = true
    }
  }
}
```

### Tip 2: Use Multiple Sinks

Create multiple sink files for redundancy:

```hcl
auto_auth {
  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }
  sink "file" {
    config = {
      path = "/vault/token/.vault-token-backup"
    }
  }
}
```

### Tip 3: Set Appropriate TTLs

Balance between security and performance:

```hcl
auto_auth {
  method "approle" {
    config = {
      # Shorter TTL for better security
      token_ttl = "1h"

      # Longer max TTL for stability
      token_max_ttl = "10h"
    }
  }
}
```

### Tip 4: Use Persistent Cache

For Kubernetes, use persistent cache to survive pod restarts:

```hcl
vault {
  client_cache {
    persist "kubernetes" {
      name      = "vault-agent-cache"
      namespace = "default"
    }
  }
}
```

### Tip 5: Optimize Templates

Use a single template for multiple secrets:

```
{{ with secret "secret/data/myapp/config" }}
{{ .Data.data | toJson }}
{{ end }}
```

### Tip 6: Set Resource Limits

Always set resource limits for agent containers:

```yaml
vault.hashicorp.com/agent-requests-mem: "64Mi"
vault.hashicorp.com/agent-limits-mem: "128Mi"
vault.hashicorp.com/agent-requests-cpu: "50m"
vault.hashicorp.com/agent-limits-cpu: "100m"
```

### Tip 7: Use Command for Secret Rotation

Notify application when secrets change:

```hcl
template {
  source      = "/vault/templates/config.ctmpl"
  destination = "/vault/secrets/config.json"
  command     = "pkill -HUP myapp"
}
```

### Tip 8: Monitor Agent Health

Use health checks:

```bash
# Check agent process
pgrep vault-agent

# Check token
cat /vault/token/.vault-token

# Check rendered secrets
ls -la /vault/secrets/
```

### Tip 9: Use Debug Logging for Troubleshooting

Enable debug logging when investigating issues:

```hcl
log_level = "debug"
log_format = "json"
```

### Tip 10: Test Configuration

Always validate configuration before deployment:

```bash
vault agent -config=/vault/config/agent.hcl -validate
```

### Tip 11: Use Kubernetes Auth

For Kubernetes workloads, use Kubernetes auth method instead of AppRole:

```hcl
auto_auth {
  method "kubernetes" {
    config = {
      role = "vault-agent"
      kubernetes_api_host = "https://kubernetes.default.svc"
      kubernetes_ca_cert = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    }
  }
}
```

### Tip 12: Secure Token Files

Protect token files with strict permissions:

```bash
chmod 600 /vault/token/.vault-token
chown vault-agent:vault-agent /vault/token/.vault-token
```

### Tip 13: Use Graceful Shutdown

Handle SIGTERM properly:

```bash
# In systemd service
ExecStop=/bin/kill -TERM $MAINPID
```

### Tip 14: Monitor Cache Hit Rate

Use Prometheus metrics to monitor cache performance:

```bash
vault metrics | grep vault_agent_cache
```

### Tip 15: Use Response Wrapping

For additional security, use response wrapping:

```hcl
auto_auth {
  method "approle" {
    config = {
      wrap_secrets_response = true
    }
  }
}
```

### Tip 16: Rotate Secret-ID

Rotate secret_id periodically:

```bash
# Generate new secret_id
vault write -f auth/approle/role/vault-agent/secret-id

# Update agent config
# Restart agent
```

### Tip 17: Use Namespace Isolation

For multi-tenant environments, use Vault namespaces:

```hcl
vault {
  namespace = "production"
}
```

### Tip 18: Monitor Token Expiry

Alert on token expiry:

```bash
# Check token TTL
vault token lookup -format=json | jq '.data.ttl'

# Set up monitoring
```

### Tip 19: Use Audit Logging

Enable audit logging on Vault server:

```bash
vault audit enable file file_path=/var/log/vault/audit.log
```

### Tip 20: Document Agent Configuration

Maintain documentation for agent configuration:

```bash
# Document configuration
echo "Vault Agent Configuration" > /vault/docs/README.md
echo "Role ID: /vault/role-id" >> /vault/docs/README.md
echo "Secret ID: /vault/secret-id" >> /vault/docs/README.md
echo "Token: /vault/token/.vault-token" >> /vault/docs/README.md
```

---

## Command Reference

### Agent Commands

```bash
vault agent -config=/path/to/config.hcl          # Start agent
vault agent -config=/path/to/config.hcl -validate # Validate config
vault agent -version                              # Version
vault agent -help                                 # Help
```

### Agent Options

```bash
-config=<path>     # Configuration file path
-validate          # Validate configuration
-log-level=<level> # Log level (trace, debug, info, warn, error)
-log-format=<fmt>  # Log format (json, standard)
-pid-file=<path>   # PID file path
```

### Signal Handling

```bash
# Reload configuration
kill -HUP $(pidof vault-agent)

# Force token/sink renewal
kill -USR1 $(pidof vault-agent)

# Graceful shutdown
kill -TERM $(pidof vault-agent)
```

### Debugging

```bash
# Check agent process
pgrep -f vault-agent

# Check token
cat /vault/token/.vault-token

# Check rendered secrets
ls -la /vault/secrets/

# Check logs
journalctl -u vault-agent -f

# Check metrics
vault metrics | grep vault_agent
```

---

## Configuration Reference (Full)

### Complete Configuration File

```hcl
# /etc/vault-agent/config.hcl

# Vault server configuration
vault {
  address = "https://vault.example.com:8200"
  
  # Retry configuration
  retry {
    num_retries = 5
  }
  
  # Client cache
  client_cache {
    # Persist cache to Kubernetes Secret
    persist "kubernetes" {
      name      = "vault-agent-cache"
      namespace = "default"
    }
  }
  
  # Namespace (Enterprise)
  namespace = "production"
}

# Auto-Authentication
auto_auth {
  # Method (only one allowed)
  method "approle" {
    config = {
      role_id_file_path                   = "/vault/role-id"
      secret_id_file_path                 = "/vault/secret-id"
      remove_secret_id_file_after_reading = true
      token_ttl                           = "1h"
      token_max_ttl                       = "10h"
      disable_token_renewal               = false
      wrap_secrets_response               = false
    }
  }
  
  # Sinks for token persistence
  sink "file" {
    config = {
      path = "/vault/token/.vault-token"
    }
  }
  
  sink "file" {
    config = {
      path = "/vault/token/.vault-token-backup"
    }
  }
}

# Cache configuration
cache {
  listen {
    address     = "127.0.0.1:8200"
    tls_disable = false
    tls_cert_file = "/vault/tls/tls.crt"
    tls_key_file  = "/vault/tls/tls.key"
  }
}

# Listener for API proxy
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = false
  tls_cert_file = "/vault/tls/tls.crt"
  tls_key_file  = "/vault/tls/tls.key"
}

# Template configuration
template {
  source      = "/vault/templates/config.ctmpl"
  destination = "/vault/secrets/config.json"
  perms       = 0600
  command     = "pkill -HUP myapp"
  error_on_missing_key = false
  left_delimiter  = "{{"
  right_delimiter = "}}"
  create_dest_dirs = true
}

template {
  source      = "/vault/templates/env.ctmpl"
  destination = "/vault/secrets/.env"
  perms       = 0644
}

# Log configuration
log_level  = "info"
log_format = "json"

# PID file
pid_file = "/vault-agent/pidfile"

# Disable mlock
disable_mlock = true

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname          = true
}
```

---

## Real-World Examples — Our Cluster

### Example 1: K3s Cluster with Vault Agent

```bash
# Deploy Vault with agent injector
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true \
  --set injector.enabled=true

# Create policy for applications
vault policy write app-policy - << 'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# Create Kubernetes auth role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=production \
  policies=app-policy \
  ttl=1h
```

### Example 2: Application Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "secret/data/myapp/config" -}}
          {
            "db_password": "{{ .Data.data.db_password }}",
            "api_key": "{{ .Data.data.api_key }}"
          }
          {{- end -}}
    spec:
      serviceAccountName: myapp
      containers:
        - name: myapp
          image: myapp:latest
          volumeMounts:
            - name: vault-secrets
              mountPath: /vault/secrets
              readOnly: true
      volumes:
        - name: vault-secrets
          emptyDir:
            medium: Memory
```

### Example 3: Standalone VM Deployment

```bash
# Install Vault Agent
VAULT_VERSION="1.15.4"
wget -qO /tmp/vault.zip \
  "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
unzip -o /tmp/vault.zip -d /usr/local/bin/

# Create configuration
mkdir -p /etc/vault-agent
cat > /etc/vault-agent/config.hcl << 'EOF'
vault {
  address = "https://vault.example.com:8200"
}

auto_auth {
  method "approle" {
    config = {
      role_id_file_path                   = "/etc/vault-agent/role-id"
      secret_id_file_path                 = "/etc/vault-agent/secret-id"
      remove_secret_id_file_after_reading = true
      token_ttl                           = "1h"
      token_max_ttl                       = "10h"
    }
  }

  sink "file" {
    config = {
      path = "/etc/vault-agent/.vault-token"
    }
  }
}

template {
  source      = "/etc/vault-agent/templates/config.ctmpl"
  destination = "/etc/myapp/config.json"
  perms       = 0600
  command     = "systemctl reload myapp"
}

template {
  source      = "/etc/vault-agent/templates/env.ctmpl"
  destination = "/etc/myapp/.env"
  perms       = 0644
  command     = "systemctl reload myapp"
}
EOF

# Create systemd service
cat > /etc/systemd/system/vault-agent.service << 'EOF'
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault-agent/config.hcl

[Service]
User=vault-agent
Group=vault-agent
Type=simple
ExecStart=/usr/local/bin/vault agent -config=/etc/vault-agent/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl daemon-reload
systemctl enable vault-agent
systemctl start vault-agent
```

---

## Further Reading

### Official Documentation
- [Vault Agent Documentation](https://developer.hashicorp.com/vault/docs/agent)
- [Vault Agent Templates](https://developer.hashicorp.com/vault/docs/agent/template)
- [Vault Agent Auto-Auth](https://developer.hashicorp.com/vault/docs/agent/autoauth)
- [Vault Agent Cache](https://developer.hashicorp.com/vault/docs/agent/caching)

### Tutorials
- [Vault Agent Sidecar Injector](https://developer.hashicorp.com/vault/tutorials/kubernetes/agent-sidecar)
- [Vault Agent Templates](https://developer.hashicorp.com/vault/tutorials/agent-template)
- [Vault Agent Auto-Auth](https://developer.hashicorp.com/vault/tutorials/agent-template)

### Community
- [Vault Discuss Forum](https://discuss.hashicorp.com/c/vault/29)
- [Vault GitHub Issues](https://github.com/hashicorp/vault/issues)

### Related Guides
- [HashiCorp Vault Complete Guide](vault.md)
- [Vault Dynamic Secrets](vault-dynamic-secrets.md)
- [Sealed Secrets](sealed-secrets.md)
- [SOPS (Mozilla)](sops.md)

---

*Last Updated: 2026*
*Version: 1.15.4*
*Author: OpenWolf DevOps Guide*
