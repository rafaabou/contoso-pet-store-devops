# Deployment Tasks

> Cluster: k3s-master (10.195.94.80), k3s-worker-1 (10.195.94.81), k3s-worker-2 (10.195.94.82)

- [ ] TASK-101: Deploy order-service hotfix (cherry-pick → build → push → ArgoCD sync)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `hotfix` `order-service` `argocd`
  - **Services:** [order-service, postgres-order]
  - **Steps:** Cherry-pick fix from `hotfix/order-4521` branch, build Docker image tagged `order-service:1.14.1-hotfix`, push to registry, update ArgoCD app manifest with new image tag, trigger sync, verify rollout status and smoke test /orders/health endpoint
  - **Rollback:** ArgoCD rollback to previous revision, redeploy image `order-service:1.14.0`

- [ ] TASK-102: Roll back makeline-service to previous version (ArgoCD rollback)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 30m | **Tags:** `rollback` `makeline-service` `argocd`
  - **Services:** [makeline-service, rabbitmq]
  - **Steps:** Identify broken revision in ArgoCD UI, run `argocd app rollback makeline-service <prev-rev>`, verify pods restart on old image, confirm /makeline/queue depth returns to normal, check RabbitMQ message backlog drains
  - **Rollback:** Re-sync to the newer (broken) revision only after root cause is fixed

- [ ] TASK-103: Set up ArgoCD application for ai-service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `argocd` `ai-service` `setup`
  - **Services:** [ai-service, redis-cache]
  - **Steps:** Create Helm values file at `argocd/apps/ai-service.yaml`, define Application resource with repo URL, target revision, path `charts/ai-service`, destination namespace `store-ai`, configure sync policy automated with self-heal, set resource limits 500m/1Gi, add health checks for /health endpoint
  - **Rollback:** `kubectl delete application ai-service -n argocd`, remove values file

- [ ] TASK-104: Configure Argo Rollouts blue-green for store-front
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `argo-rollouts` `blue-green` `store-front`
  - **Services:** [store-front, nginx-ingress]
  - **Steps:** Replace Deployment with Rollout resource in `k8s/store-front/rollout.yaml`, set `strategy: blueGreen`, configure `activeService: store-front-active`, `previewService: store-front-preview`, `autoPromotionEnabled: false`, add analysisTemplate for smoke tests, set `scaleDownDelaySeconds: 300`
  - **Rollback:** `kubectl argo rollouts undo store-front` to revert to previous ReplicaSet

- [ ] TASK-105: Create Helm chart for virtual-customer service
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `helm` `virtual-customer` `chart`
  - **Services:** [virtual-customer]
  - **Steps:** Scaffold chart with `helm create charts/virtual-customer`, define Deployment, Service, HPA, ServiceAccount in templates, add values.yaml with image repo/tag, replicaCount, resources, ingress toggle, create helpers.tpl for common labels, add NOTES.txt with port-forward instructions
  - **Rollback:** Delete chart directory, remove from `Chart.yaml` dependencies if referenced

- [ ] TASK-106: Update Helm values for resource limits across all services
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `helm` `resources` `limits`
  - **Services:** [order-service, makeline-service, product-service, store-front, virtual-customer]
  - **Steps:** Edit each chart's `values.yaml` to set requests (cpu: 100m, memory: 128Mi) and limits (cpu: 500m, memory: 512Mi), run `helm upgrade --dry-run` to validate, apply to staging first, verify no OOMKill or CPU throttling with `kubectl top pods`
  - **Rollback:** `helm rollback <release> <prev-revision>` per service

- [ ] TASK-107: Set up ArgoCD Image Updater for auto-deployment
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `argocd` `image-updater` `ci-cd`
  - **Services:** [argocd-image-updater, order-service, product-service]
  - **Steps:** Install via `helm install argocd-image-updater argoproj/argocd-image-updater`, configure registry credentials in `argocd-image-updater-config` secret, add annotation `argocd-image-updater.argoproj.ai/image-list` on each Application, set write-back method to `argocd`, test by pushing new tag
  - **Rollback:** Remove annotations, uninstall helm release

- [ ] TASK-108: Deploy MongoDB with persistent storage
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `mongodb` `persistence` `database`
  - **Services:** [mongodb, order-service, product-service]
  - **Steps:** Deploy via Helm (`bitnami/mongodb`), set `persistence.enabled=true`, `persistence.storageClass=nfs-client`, `persistence.size=10Gi`, configure `auth.rootPassword` via Vault secret, set `replicaSet.enabled=true` with 3 replicas, verify PVC bound on worker nodes
  - **Rollback:** `helm uninstall mongodb`, PVC remains; reattach on redeploy

- [ ] TASK-109: Deploy RabbitMQ cluster
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `rabbitmq` `cluster` `messaging`
  - **Services:** [rabbitmq, makeline-service, order-service]
  - **Steps:** Deploy via Helm (`bitnami/rabbitmq`), set `clustering.enabled=true`, `replicaCount=3`, configure `auth.username/password` from Vault, enable management plugin, set `resources.requests.memory=512Mi`, verify cluster status with `rabbitmqctl cluster_status`
  - **Rollback:** Scale to 1 replica, `helm uninstall rabbitmq`, PVC remains

- [ ] TASK-110: Configure Horizontal Pod Autoscaler for order-service
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `hpa` `autoscaling` `order-service`
  - **Services:** [order-service, metrics-server]
  - **Steps:** Create HPA manifest in `k8s/order-service/hpa.yaml`, set `minReplicas: 2`, `maxReplicas: 10`, `metrics: [{type: Resource, resource: {name: cpu, target: {type: Utilization, averageUtilization: 70}}}]`, apply and verify with `kubectl describe hpa`
  - **Rollback:** `kubectl delete hpa order-service-hpa -n store`

- [ ] TASK-111: Set up canary deployment for product-service
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `canary` `argo-rollouts` `product-service`
  - **Services:** [product-service, nginx-ingress]
  - **Steps:** Create Rollout resource with canary strategy, set `canary.steps` with `setWeight: 10`, `pause: {duration: 5m}`, `setWeight: 30`, `pause: {duration: 10m}`, `setWeight: 100`, add analysisTemplate checking error rate < 1%, verify traffic splitting via ingress annotations
  - **Rollback:** `kubectl argo rollouts abort product-service`, manual promote previous

- [ ] TASK-112: Create Kubernetes namespace strategy (dev/staging/prod)
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `namespace` `rbac` `environment`
  - **Services:** [all services]
  - **Steps:** Create namespaces `store-dev`, `store-staging`, `store-prod`, apply ResourceQuotas (cpu: 8/16/32 cores, memory: 16/32/64Gi), set LimitRange for default pod limits, configure NetworkPolicies for namespace isolation, create RBAC roles per namespace, set up labels `env=dev|staging|prod`
  - **Rollback:** `kubectl delete namespace store-{dev,staging,prod}` (deletes all resources)

- [ ] TASK-113: Deploy Prometheus stack via Helm
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `prometheus` `monitoring` `helm`
  - **Services:** [kube-prometheus-stack, grafana]
  - **Steps:** `helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring`, set `prometheus.retention=15d`, `prometheus.storageSpec.volumeClaimTemplate.storageClass=nfs-client`, configure `alertmanager.config.global.resolve_timeout=5m`, verify all CRDs applied
  - **Rollback:** `helm uninstall prometheus -n monitoring`, PVCs remain

- [ ] TASK-114: Deploy Grafana with pre-built dashboards
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `grafana` `dashboards` `monitoring`
  - **Services:** [grafana, prometheus]
  - **Steps:** Add Grafana dashboards via ConfigMap provisioning: K8s cluster overview (ID 7249), node exporter (ID 1860), nginx ingress (ID 9614), configure Grafana admin password from Vault, set ingress with TLS for `grafana.store.internal`, add Prometheus datasource
  - **Rollback:** `kubectl delete configmap grafana-dashboards -n monitoring`, restart Grafana pod

- [ ] TASK-115: Set up Vault via Helm chart
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `vault` `secrets` `security`
  - **Services:** [vault, vault-agent-injector]
  - **Steps:** Deploy via `helm install vault hashicorp/vault -n vault`, initialize with `vault operator init -key-shares=5 -key-threshold=3`, unseal with 3 keys, enable KV v2 secrets engine, configure policies for `store-*` services, set up AppRole auth for CI/CD
  - **Rollback:** `helm uninstall vault -n vault`, seal via `vault operator seal` (keys required to reinit)

- [ ] TASK-116: Deploy nginx-ingress controller
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `ingress` `nginx` `load-balancer`
  - **Services:** [ingress-nginx, MetalLB]
  - **Steps:** `helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx`, set `controller.service.type=LoadBalancer`, `controller.service.loadBalancerIP=10.195.94.90`, configure `controller.config.use-forwarded-headers=true`, `controller.config.proxy-body-size=50m`, verify with `kubectl get svc -n ingress-nginx`
  - **Rollback:** `helm uninstall ingress-nginx -n ingress-nginx`

- [ ] TASK-117: Configure cert-manager with Let's Encrypt
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `cert-manager` `tls` `letsencrypt`
  - **Services:** [cert-manager, ingress-nginx]
  - **Steps:** Install via `helm install cert-manager jetstack/cert-manager -n cert-manager --set installCRDs=true`, create ClusterIssuer `letsencrypt-prod` with ACME email, set up HTTP01 solver class `nginx`, verify with a test Certificate resource, ensure ingress annotations reference the issuer
  - **Rollback:** `kubectl delete clusterissuer letsencrypt-prod`, uninstall helm release

- [ ] TASK-118: Set up MetalLB for on-prem load balancing
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `metallb` `load-balancer` `networking`
  - **Services:** [metallb-system]
  - **Steps:** `kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml`, wait for CRDs, create IPAddressPool `10.195.94.90-10.195.94.95`, create L2Advertisement referencing pool, verify with `kubectl get metallb -A`
  - **Rollback:** `kubectl delete -f metallb-native.yaml`, remove IPAddressPool/L2Advertisement

- [ ] TASK-119: Deploy Falco for runtime security
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `falco` `security` `runtime`
  - **Services:** [falco, falcosidekick]
  - **Steps:** `helm install falco falcosecurity/falco -n falco`, enable `falcosidekick.enabled=true`, configure `falcosidekick.config.slack.webhookurl` from Vault, add custom rules for unexpected shell in containers, set `driver.kind=modern_ebpf`, verify with `kubectl logs -n falco`
  - **Rollback:** `helm uninstall falco -n falco`

- [ ] TASK-120: Configure OPA Gatekeeper
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `opa` `gatekeeper` `policy`
  - **Services:** [gatekeeper-system]
  - **Steps:** Apply Gatekeeper manifests, create ConstraintTemplate `K8sRequiredLabels` (app, team, env), create Constraint requiring labels on all Deployments, create ConstraintTemplate `K8sResourceLimits` to enforce CPU/memory limits, test with `kubectl apply` of a non-compliant pod
  - **Rollback:** `kubectl delete constraint` resources, uninstall Gatekeeper

- [ ] TASK-121: Deploy Loki + Promtail for log aggregation
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `loki` `promtail` `logging`
  - **Services:** [loki, promtail, grafana]
  - **Steps:** Install Loki via Helm with `storageConfig.filesystem.directory=/loki`, `retention_period=720h`, install Promtail Helm chart with `config.clients[0].url=http://loki:3100/loki/api/v1/push`, add Loki as Grafana datasource, create log exploration dashboard
  - **Rollback:** `helm uninstall loki promtail -n logging`

- [ ] TASK-122: Set up Jaeger for distributed tracing
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | `jaeger` `tracing` `observability`
  - **Services:** [jaeger, order-service, makeline-service]
  - **Steps:** Deploy Jaeger operator via Helm, create `Jaeger` CR with `strategy: production`, `storage.type: elasticsearch`, configure order-service and makeline-service with OTLP exporter endpoints, add ` tracing-sampling-ratio=0.1` for production, verify traces in Jaeger UI
  - **Rollback:** `kubectl delete jaeger production -n observability`, remove OTLP config from services

- [ ] TASK-123: Deploy kube-state-metrics
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `kube-state-metrics` `metrics` `monitoring`
  - **Services:** [kube-state-metrics, prometheus]
  - **Steps:** `helm install kube-state-metrics prometheus-community/kube-state-metrics -n monitoring`, configure `metricLabelsAllowlist=pods=[app,version]`, `metricAnnotationsAllowlist=pods=[kubectl.kubernetes.io/restartedAt]`, verify metrics at `:8080/metrics`
  - **Rollback:** `helm uninstall kube-state-metrics -n monitoring`

- [ ] TASK-124: Deploy node-exporter DaemonSet
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `node-exporter` `metrics` `monitoring`
  - **Services:** [prometheus-node-exporter]
  - **Steps:** Included in kube-prometheus-stack Helm chart (verify `nodeExporter.enabled=true`), configure `nodeExporter.config.collectors.filesystem`, confirm `kubectl get ds -n monitoring`, verify scrape targets in Prometheus UI
  - **Rollback:** Set `nodeExporter.enabled=false` in values, `helm upgrade`

- [ ] TASK-125: Configure Alertmanager receivers
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `alertmanager` `alerting` `slack`
  - **Services:** [alertmanager, prometheus]
  - **Steps:** Create `alertmanager-config` Secret with receivers: `slack-critical` (webhook from Vault), `email-oncall` (smtp config), `pagerduty-p1` (integration key), create routing tree: severity=critical → slack+pagerduty, severity=warning → email, test with `amtool alert add`
  - **Rollback:** Revert secret to previous version, `kubectl rollout restart alertmanager -n monitoring`

- [ ] TASK-126: Set up Prometheus rules for SLOs
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `slo` `prometheus` `alerting`
  - **Services:** [prometheus, order-service, product-service]
  - **Steps:** Create PrometheusRule `store-slos.yaml`: order-service availability SLO (99.9% → alert at 99.85%), product-service latency SLO (p95 < 500ms → alert at >600ms), error budget burn rate rules (1h and 6h windows), verify rules loaded with `kubectl get prometheusrule`
  - **Rollback:** `kubectl delete prometheusrule store-slos -n monitoring`

- [ ] TASK-127: Create ConfigMap for application settings
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `configmap` `configuration` `k8s`
  - **Services:** [order-service, product-service, makeline-service]
  - **Steps:** Create `app-config` ConfigMap in `store-dev`/`store-staging`/`store-prod` namespaces with keys: `DB_HOST`, `RABBITMQ_URL`, `LOG_LEVEL`, `FEATURE_FLAGS`, mount in Deployments via `envFrom`, verify with `kubectl describe configmap`
  - **Rollback:** `kubectl delete configmap app-config`, redeploy with previous values

- [ ] TASK-128: Rotate application secrets via Vault
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `vault` `secrets` `rotation`
  - **Services:** [vault, order-service, product-service, mongodb]
  - **Steps:** Read current secrets from `secret/store/*`, generate new MongoDB password, new RabbitMQ credentials, update via `vault kv put secret/store/order-service db_password=...`, trigger rolling restart of affected services, verify new secrets injected via Vault Agent
  - **Rollback:** Restore previous secret version via `vault kv get -version=<prev>`, restart pods

- [ ] TASK-129: Deploy virtual-worker service
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `virtual-worker` `deployment` `worker`
  - **Services:** [virtual-worker, rabbitmq]
  - **Steps:** Create Deployment `k8s/virtual-worker/deployment.yaml` with image `registry/store/virtual-worker:latest`, Service, ServiceAccount, configure RabbitMQ connection via Vault secret, set up HPA based on queue depth metric, apply to staging namespace, verify pod consumes messages from RabbitMQ
  - **Rollback:** `kubectl delete deployment virtual-worker -n store-staging`

- [ ] TASK-130: Update ingress rules for new domain
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `ingress` `dns` `domain`
  - **Services:** [nginx-ingress, cert-manager, store-front]
  - **Steps:** Add new Ingress resource for `app.store.internal`, configure TLS with cert-manager annotation `cert-manager.io/cluster-issuer: letsencrypt-prod`, add path rules for `/api → order-service`, `/products → product-service`, `/ → store-front`, verify DNS resolution and certificate issuance
  - **Rollback:** `kubectl delete ingress store-ingress -n store-prod`, remove DNS record

- [ ] TASK-131: Set up database migration pipeline
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `migration` `database` `ci-cd`
  - **Services:** [order-service, product-service, mongodb]
  - **Steps:** Create `migrate.sh` script using `migrate` CLI tool, add migration files in `migrations/` per service, configure CI stage to run `migrate -path ./migrations -database $DB_URL up` before deployment, add pre-deploy hook in Helm chart, verify on staging with sample migration
  - **Rollback:** `migrate -path ./migrations -database $DB_URL down 1` to rollback last migration

- [ ] TASK-132: Configure CI/CD for ai-service (Python)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `ci-cd` `python` `ai-service`
  - **Services:** [ai-service, GitHub Actions]
  - **Steps:** Create `.github/workflows/ai-service.yml` with steps: checkout, setup-python 3.11, pip install + pytest, build Docker image, push to registry, update ArgoCD image tag, add caching for pip dependencies, configure secrets for registry credentials and ArgoCD token
  - **Rollback:** Revert workflow file, manually rollback ArgoCD app

- [ ] TASK-133: Configure CI/CD for product-service (Rust)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `ci-cd` `rust` `product-service`
  - **Services:** [product-service, GitHub Actions]
  - **Steps:** Create `.github/workflows/product-service.yml`: checkout, setup-rust stable, `cargo fmt --check`, `cargo clippy`, `cargo test`, `cargo build --release`, build Docker image with multi-stage build, push to registry, trigger ArgoCD sync, add cargo caching
  - **Rollback:** Revert workflow file, manually rollback ArgoCD app

- [ ] TASK-134: Set up staging environment identical to production
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `staging` `environment` `parity`
  - **Services:** [all services]
  - **Steps:** Create `envs/staging/values.yaml` overriding prod values: replicaCount=1, resources reduced 50%, ingress host=staging.store.internal, Prometheus retention=3d, create ArgoCD ApplicationSet with git generator for staging namespace, apply all Helm charts with staging values, verify feature parity
  - **Rollback:** `argocd app delete store-*-staging`, remove staging values files

- [ ] TASK-135: Create deployment checklist runbook
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `runbook` `documentation` `process`
  - **Services:** [all services]
  - **Steps:** Create `docs/runbooks/deployment-checklist.md` with pre-deploy (tests pass, images tagged, secrets updated), deploy (ArgoCD sync, rollout status, pod health), post-deploy (smoke tests, monitoring dashboards, rollback plan), include service-specific notes, add escalation contacts, link to ArgoCD and Grafana
  - **Rollback:** N/A (documentation only)
