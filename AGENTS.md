# AGENTS.md

## What This Is

Contoso Pet Store — 8 polyglot microservices with Helm charts, GitHub Actions CI, Terraform+Ansible infrastructure for a local K3s cluster (Incus LXC containers on 2 PCs via Tailscale VPN) plus optional AWS EKS.

## Learning Guide

**New to DevOps?** Check out the comprehensive guide:
- 📚 **[Zero to Hero Guide](devops-complete-guide/ZERO-TO-HERO-GUIDE.md)** — From beginner to advanced, everything explained with analogies, diagrams, and 100+ reference links.

## Repository Layout

```
src/                          # 8 microservices (the actual app code)
helm-charts/                  # Custom Helm charts per service + mongodb/rabbitmq
application_services/         # Raw K8s YAML manifests (alternative to Helm)
infrastructure/               # ArgoCD app-of-apps, Datadog, testing manifests
Deployment_Automation/        # ArgoCD, Argo Rollouts, Image Updater Helm charts
github/workflows/             # 11 GitHub Actions workflows (8 service + 3 infra)
ansible-opentofu/             # OpenTofu (Incus) + Ansible (K3s cluster setup)
aws_eks_infrastructure/       # Terraform modules for AWS EKS (Dev/Stg/Prod)
vault_github_setup/           # Vault + GitHub Actions integration
vault_pgsql_sonarqube/        # Vault, PostgreSQL, SonarQube Helm charts
monitoring/                   # Prometheus, Grafana, Alertmanager, Datadog
logging/                      # EFK + ELK stacks
observability/                # Jaeger, Kiali, Loki
Istio_Service_mesh/           # Istio base + istiod Helm charts
devops-complete-guide/        # 18-chapter reference + setup scripts
```

## Microservices (src/)

| Service | Language | Framework | Port | Test Command |
|---------|----------|-----------|------|--------------|
| `ai-service` | Python 3.12 | FastAPI | 5001 | `pytest tests -q` (19 offline tests: chain, parsing, contracts, upload guards) |
| `order-service` | Node.js 18 | Fastify | 3000 | `npm test` (tap) |
| `product-service` | Rust | actix-web | 3002 | `cargo test` |
| `makeline-service` | Go 1.22 | gin | 3001 | none |
| `store-front` | Vue.js 3 | nginx | 8080 | `npm run lint` |
| `store-admin` | Vue.js 3 | nginx | 8081 | `npm run lint` |
| `virtual-customer` | Rust | reqwest | — | none |
| `virtual-worker` | Rust | reqwest | — | none |

## Build Commands

```bash
# Python (ai-service)
cd src/ai-service && pip install -r requirements.txt
source environment.sh && uvicorn main:app --host 0.0.0.0 --port 5001

# Node.js (order-service)
cd src/order-service && npm install && npm start
# Dev: npm run dev | Test: npm test

# Rust (product-service, virtual-customer, virtual-worker)
cd src/<service> && cargo build --release && cargo test

# Go (makeline-service)
cd src/makeline-service && go build -o main .

# Vue.js (store-front, store-admin)
cd src/<service> && npm install && npm run build
# Lint: npm run lint | Dev: npm run serve
```

All services have Dockerfiles. Docker build: `docker build -t <service>:latest .` from each `src/<service>/`.

## Full Stack (Docker Compose)

```bash
cd src/store-admin && docker-compose up    # or src/virtual-worker
```

Starts: mongodb (27017), rabbitmq (5672/15672), order-service, makeline-service, product-service, virtual-customer. RabbitMQ default creds: `username`/`password`.

## Service Dependency Map

```
virtual-customer → order-service → RabbitMQ → makeline-service → MongoDB
store-front ──→ order-service (proxy /order/*)
store-front ──→ product-service (proxy /products/*)
store-admin ──→ order-service (proxy /order/*)
store-admin ──→ product-service (proxy /product/*)
store-admin ──→ makeline-service (proxy /makeline/*)
product-service ──→ ai-service (optional, /ai/*)
```

Nginx proxy routes are in `src/store-front/nginx.conf` and `src/store-admin/nginx.conf`. In-cluster service DNS: `<service>.application.svc.cluster.local`.

## CI/CD Pipeline (GitHub Actions)

All 8 service workflows are identical 3-job patterns, triggered by `workflow_dispatch`:
1. SonarQube analysis (SonarCloud)
2. OWASP dependency check
3. Build → Trivy scan → push to ECR (`591234613960.dkr.ecr.us-east-1.amazonaws.com`)

Image tags: `{major}.{minor}.{patch}-{short_sha}`. Runners: self-hosted in `store-app` environment.

## Helm Charts

Each service has a chart in `helm-charts/<service>/`. Key patterns:
- **Argo Rollouts** canary strategy (ai/order/product/makeline) or blue-green (store-front/admin)
- **Istio** VirtualService + DestinationRule in every chart
- **Vault** integration for secrets (kv/data/<service>)
- **HPA**: min 2, max 6, CPU 70% / memory 75%
- **Analysis**: error-rate < 0.05, p95-latency < 1000ms (Datadog-backed)

## Infrastructure Setup

```bash
# OPERATING RULE (standing, never override silently)
- The assistant NEVER executes anything by itself. For every step it must
  TELL the user what to run and EXPLAIN why, then WAIT for the user to run
  it and report back. This applies to shell commands, playbooks, tofu,
  incus, file syncs — everything. "Do it" from the user authorizes at most
  read-only diagnosis, never state-changing execution, unless the user names
  the exact command to run. When in doubt, ask.
- Guidance is ALWAYS step-by-step, one action per step: the exact command (or
  click path) + HOW it works + WHY this step exists and what it proves, then
  WAIT for the reported result before the next step. Never batch independent
  unknowns; never say "try X or Y" without naming how each outcome decides the
  next move. Remember context across turns: open loops, pending verifications,
  and the operator's last reported state are re-read before every answer.
- Troubleshooting is a living system: after EVERY config/role/playbook/IP
  change, update the affected guide(s). Every new error gets an ERROR entry.
  Every deployed component gets its own folder under
  `devops-complete-guide/troubleshooting/<component>/` — if one doesn't
  exist yet, CREATE it (state table, install flow, verify commands, error
  catalog). Never leave a component undocumented.
- Follow the repo task system and log files so work is never lost:
  * Before starting, read `devops-complete-guide/TASKS.md` board columns
    (TODO / IN PROGRESS / DONE / BLOCKED) and today's
    `devops-complete-guide/tasks/daily/YYYY-MM-DD.md` for current state.
  * Every playbook/tofu run is logged: `tee /tmp/ansible-<play>.log`
    (e.g. `/tmp/ansible-networking.log`, `/tmp/ansible-sonar.log`).
    Diagnose from the log file first, never from memory.
  * After work: move TASKS.md rows between columns, append session tasks to
    `tasks/categories/<area>.md` (next free TASK-XXX id), update STATISTICS,
    and write/extend today's daily log (focus, results, blockers, incidents).

# Local K3s cluster (8 containers, Incus LXC on 2 PCs)
cd ansible-opentofu/opentofu/pc1 && tofu apply -auto-approve    # Creates PC1 containers (master + worker1 + vault + monitoring)
cd ansible-opentofu/opentofu/pc2 && tofu apply -auto-approve    # Creates PC2 containers (worker2 + sonarqube + forgejo-ci + runner-1). ALWAYS run on PC2: provider talks to the LOCAL daemon, PC1 plans phantom duplicates (ERROR 85)
cd ansible-opentofu/ansible && ansible-playbook site.yml  # Installs K3s + tools + vault + monitoring

# Or use the all-in-one scripts:
devops-complete-guide/scripts/install-all.sh   # Full setup
devops-complete-guide/scripts/verify-all.sh    # Health check
devops-complete-guide/scripts/quick-start.sh   # Prerequisites → cluster
```

Ansible inventory (SSH keys, no passwords — run `setup-ssh-keys.sh` once): `k3s-master@10.195.94.80`, `k3s-worker-1@10.195.94.81`, `k3s-worker-2@100.100.13.113` (Tailscale), `vault@10.195.94.200` (750MB since 2026-09-09), `monitoring@10.195.94.210`, `sonarqube@100.73.135.124` (Tailscale, container on PC2), `forgejo@100.88.159.38` + `ci-runner-1@100.113.54.77` (Tailscale, containers on PC2, TASK-262). Fresh ubuntu-noble images ship NO openssh-server and lock root password: install via `incus exec` + push key directly to /root/.ssh/authorized_keys (ssh-copy-id can never succeed).

**Production Architecture:**
- **K3s Cluster** (3 nodes): k3s-master, k3s-worker-1, k3s-worker-2
- **Vault Server** (dedicated VM): HashiCorp Vault with TLS + auto-init/unseal
- **Monitoring Server** (dedicated VM): Prometheus + Grafana + OTel + Jaeger + Loki
- **SonarQube Server** (PC2 container, migrated from PC1 2026-09-09): SonarQube Community 26.5.0 + Branch Plugin 26.5.0 + Forgejo OIDC plugin + PostgreSQL, privileged, 3GB (raised from 2.5GB 2026-09-10: ~214MB free starved the login page while API stayed fast)
- **Forgejo CI** (PC2, TASK-262 in progress 2026-09-09): `k3s-forgejo-ci` (2 CPU/4GB/30GB, privileged, Forgejo 16.0.3 binary + SQLite + ci-light host runner) + `k3s-runner-1` (2 CPU/3GB/20GB, unprivileged, ci-heavy host runner + Buildah). No Docker anywhere. Gateway route `forgejo.*` (wildcard covers, zero DNS work). No runner on PC1, no runner in Vault VM (root token material lives there — secrets plane never shares a host with compute)
- **Storage**: NFS server on master (external USB HDD via /srv/efs), MinIO S3 on master (NVMe /srv/s3-data, exposed as `minio.*` console + `s3.*` API via Istio ServiceEntry), node-exporter on all K3s nodes

MetalLB pool: `10.195.94.100-150` (`.100` pinned to istio-ingressgateway = wildcard DNS target). Ingress: Istio 1.30.4 sidecar mesh, PERMISSIVE mTLS, classic Gateway + VirtualService. TLS: cert-manager DNS-01 via Cloudflare (token in Vault `kv/cloudflare`), wildcard cert. Local registry: `10.195.94.101:5000`.

## Secrets / Env Vars

**Required for local dev** (order-service needs RabbitMQ; ai-service needs Gemini/Google AI Studio):
- `ORDER_QUEUE_HOSTNAME`, `ORDER_QUEUE_PORT`, `ORDER_QUEUE_USERNAME`, `ORDER_QUEUE_PASSWORD`
- `GEMINI_API_KEY` (required), `GEMINI_TEXT_MODEL` (default `gemini-3.6-flash`), `GEMINI_IMAGE_MODEL` (default `gemini-2.5-flash-image`); optional fallback `NVIDIA_API_KEY` (free `nvapi-...`), `NVIDIA_TEXT_MODEL` (default `openai/gpt-oss-20b`), `NVIDIA_IMAGE_MODEL` (default `black-forest-labs/flux.1-schnell`); last-resort image fallback `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` (free plan at dash.cloudflare.com, Workers AI token, 10k Neurons/day ≈ 170 images/day), `CLOUDFLARE_IMAGE_MODEL` (default `@cf/black-forest-labs/flux-1-schnell`); 4th image fallback `XKIRO_API_KEY` (free plan at xkiro.com, dashboard → API Keys, no card), `XKIRO_IMAGE_MODEL` (default `sensenova/sensenova-u1.5-lite`); failover order `AI_TEXT_PROVIDERS` (default `gemini,nvidia`) / `AI_IMAGE_PROVIDERS` (default `gemini,cloudflare,xkiro` — nvidia dropped from images, persistent 504); opt-in parallel race mode `AI_IMAGE_PARALLEL=true` (default `false` = sequential, protects free quotas)

**Vault paths** (for cluster deployment):
- `kv/data/ai-service` — Gemini API key (+ optional `NVIDIA_API_KEY`)
- `kv/data/order-service` — RabbitMQ creds
- `kv/data/rabbitmq` — RabbitMQ creds
- `kv/data/cloudflare` — Cloudflare API token (cert-manager DNS-01)
- `kv/data/sonarqube` — SonarQube admin password (rotated 2026-09-09)
- `kv/data/argocd` — ArgoCD admin password (v6, old versions destroyed)
- `kv/data/forgejo` — Forgejo admin password (v1 live, 2026-09-09); runner tokens server-minted per label (never in Vault — machine-to-machine only)
- `secret/data/aws/credentials` — AWS keys

**GitHub Actions secrets**: `ECR_REGISTRY`, `SONAR_TOKEN`, `SONAR_ORGANIZATION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TF_STATE_BUCKET`

## Gotchas

- `ai-service` is Gemini-first with failover to NVIDIA NIM (2026-09-15, `routers/providers.py`): request tries each armed provider in `AI_TEXT_PROVIDERS`/`AI_IMAGE_PROVIDERS` order (key set = armed), all-fail returns 503 with a per-provider `attempted` map; response includes `"provider"`. `environment.sh`/`.env` hold ONLY API keys + model names + provider order, deliberately empty; never commit a real key (`environment.sh` was scrubbed 2026-09-14 — old Azure/OpenAI keys were hardcoded). Model names go stale: if a provider replies "model no longer available", set the matching `*_MODEL` to the name it suggests. `gemini-3.6-flash` is TEXT-ONLY (cannot generate images) — never set it as `GEMINI_IMAGE_MODEL`. Gemini image models all return `429 RESOURCE_EXHAUSTED limit:0` on this free-tier key (tested 2026-09-15: `gemini-2.5-flash-image`, `gemini-3-pro-image`, `gemini-3.1-flash-lite-image`, `gemini-3.1-flash-image` — zero free image quota). NVIDIA NIM hosted `Infer` endpoint `https://ai.api.nvidia.com/v1/genai/{publisher}/{model}` (default model `black-forest-labs/flux.1-schnell`, JSON body prompt, response `artifacts[].base64` JPEG; NOT the OpenAI-compatible `/v1/images/generations` which only exists for self-hosted NIM, NOT `integrate.api.nvidia.com` for images) returns a persistent `504 Gateway Timeout` instead — gateway accepts but the free-tier FLUX backend never answers (repeatable, not transient). Hugging Face was tried and rejected (free tier is only $0.10/month credits, depleted after 1 image → `402`). Images therefore come from Cloudflare Workers AI (`POST .../ai/run/@cf/black-forest-labs/flux-1-schnell`, Bearer token + Account ID, free plan 10k Neurons/day ≈ 170 images/day, response `result.image` base64; 600s request timeout). Behind that, xKiro (`POST /v1/images/generations` async job + poll, free `sensenova/sensenova-u1.5-lite`, CDN url fetched and wrapped as data URI; free image quota "limited" = a few per rolling 24h). Text generation on Gemini remains fully free. `application_services/ai-service-vault.yaml` + `infrastructure/testing_services/ai-service_with_vault.yaml` still inject the Vault secret as `openai.env` (legacy Azure-era filename — harmless, keep notes in sync if renamed).
- RabbitMQ `username`/`password` defaults are hardcoded in docker-compose files
- product-service uses a git dependency for wasmtime (`release-15.0` branch)
- store-front/store-admin eslintConfig references deprecated `@babel/eslint-parser`
- All CI workflows trigger on `workflow_dispatch` only (push triggers commented out)
- Incus containers need `linux.kernel_modules=ip_tables,ip6_tables,iptable_nat,...` for K3s (set in Terraform)
- Services in `src/` that share the same language (Rust: product, virtual-customer, virtual-worker) have independent Cargo.toml — no workspace
- PC1 is full (14Gi iron, 14GB promised, ~3.6Gi avail, 1.1GB swap in use 2026-09-09): all new VMs go on PC2 (11Gi, ~8.6Gi avail). Only Vault trim allowed on PC1; worker headroom is reserved for the 8 incoming app services
- ANY Incus config apply on the Vault host re-seals Vault (seal is in-memory): `vault-unseal.service` now auto-heals on boot (init-file key, root-only script); still verify seal after restarts, `site-vault.yml` remains the manual path (ERROR 86)
- Prompt discipline for cross-PC work: `antix@antix` = PC1, `antix@home` = PC2. If the prompt is wrong, ssh first — never apply. `incus exec <pc2-container>` only ever works on PC2 ("Instance not found" = proof you're on PC1, not a bug)
- PC2 controller user has NO keypair: `scp ~/.ssh/id_ed25519.pub antix@100.110.171.119:/tmp/` first, then push into containers via `incus exec` on PC2 (ERROR 88)
- PC2 rides on WiFi: any disconnect takes ALL its containers' tailnets dark simultaneously (2026-09-10 incident — first suspect for multi-peer offline, before kill-switch). Prefer ethernet for server PCs; treat WiFi as the SPOF it is
- Vault play dies on apt cache update with EMPTY error though network + `apt-get update` task pass (ERROR 103): HashiCorp rotated its repo signing key (old 798A → FC9CA9) and the `creates:`-guarded key download froze the stale keyring — bare apt only warns on unsigned repos, the Ansible module fails the run. Fix = check-then-remove (grep keyring for current key id, delete on mismatch) before the guarded download; diagnose with `apt-get update` output + `gpg --show-keys` (direct evidence, never assume network)
- Credentials live NOWHERE in docs (scrubbed repo-wide 2026-09-09: SSH keys only, contradicting advice rows fixed). Never paste passwords into guides, chat, or shell history — rotate + destroy versions if exposed
- Troubleshooting debt is zero (2026-09-13): 113 ERRORs, 14 component folders (12 + sso + forgejo), all state tables show 8 containers; TASK-260 DONE (flannel→tailscale0, 5b 0% loss both ways). Keep it that way: every change updates its guide the same turn
- Makeline order flow was dead with `500` + `failed to connect to order queue: unexpected protocol version 0.9.1` (2026-09-15): BOTH queue clients speak AMQP 1.0 (order-service publishes via Node `rhea`, makeline-service reads via Go `go-amqp`) but stock RabbitMQ 3.11 only serves 0.9.1 on 5672. Fix = `rabbitmq_amqp1_0` in the repo-root `rabbitmq_enabled_plugins` file (bind-mounted into every compose stack, content `[rabbitmq_management,rabbitmq_prometheus,rabbitmq_amqp1_0].` — the file must EXIST or the daemon auto-creates a directory that breaks the mount). Subtlety: runtime `rabbitmq-plugins enable` starts the app (`[E*]`) but 5672 still answers 0.9.1 — a `docker restart rabbitmq` (plugin boots with the broker, no message loss on restart) is what actually attaches 1.0. Ground truth is a raw socket probe (`send AMQP\x00\x01\x00\x00`, expect anything but the `AMQP\x00\x00\x09\x01` header back), NOT the `rabbitmq-diagnostics listeners` purpose string (static text). Verified: `/order/fetch` drained 55 queued orders into MongoDB, HTTP 200
- Robustness pass 2026-09-15 (P0+P1+P2, all verified): nginx `proxy_*_timeout 600s` on store-admin `/ai/generate/*` (60s default 504s 40s-5min image calls in cluster); `.dockerignore` added (store-admin/store-front ship 186MB node_modules otherwise); makeline poison messages are logged+dropped instead of `log.Fatalf` crash-looping, order IDs are `UnixNano` not `rand.Intn(100000)`; product-service reqwest has a 660s timeout (was: hang forever) and forwards upstream status+body verbatim, inventing 500 only for its own failures (via tested `map_upstream_response` + `#[cfg(test)]` cases — run with `cargo test`, needs toolchain); ai-service deps pinned (`google-genai==1.2.0`, `openai==3.14.0`, `python-multipart==0.0.32`); order-service reuses one rhea connection (was: new TCP+SASL handshake per message); store-admin compose has named volumes (`mongo-data`, `rabbitmq-data` survive `down -v`)
- TASK-262 (Forgejo CI) IN PROGRESS: runners registered + idle ×2 confirmed, `sysadmin` rotated, `kv/forgejo` live; architecture-first per operator (no app deploy yet — code not in git, pilot PARKED by operator, pick any day); remaining = generic correlation → hardening (SSO 5/5 done incl. SonarQube + Vault; plugin v1.0.3 released)
- TASK-263 (monitoring) IN PROGRESS: steps 1–3 proven live (edge metrics+logs, probes + 7/7 peer pings, Telegram buzzed); remaining = step 4 correlation (needs pilot app) + step 5 hardening
- TASK-260 DONE 2026-09-13: flannel→tailscale0 on 3/3 nodes, VTEPs all-Tailnet (master .206.35, worker-1 .126.108, worker-2 .113), 5b proven 3/3 0% loss both ways (10.42.0.105 ↔ 10.42.2.30); guard taint `dedicated=remote:NoSchedule` + master pins stay until welcome-back decision
- SSO (Forgejo-as-IdP) DONE 5/5: Grafana + ArgoCD + MinIO + SonarQube + Vault all operator-confirmed (SonarQube: provider + local admin; Vault: OIDC Role `default`). `kv/sso/` holds 5 clients; break-glass local logins stay everywhere

## Sync Rule

After ANY update to files in `~/Videos/Store-App_Soruce_Code-GitHub/`, run:

```bash
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

This keeps PC1 and PC2 in sync. Always sync before running `tofu` or `ansible` on PC2.
