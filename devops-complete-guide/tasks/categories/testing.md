# Testing Tasks

## Task List

- [ ] TASK-191: Write unit tests for order-service order validation
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 8h | **Tags:** `unit-test` `order-service` `validation`
  - **Services:** order-service
  - **Steps:** Write tests for: order item quantity validation (min/max), price calculation accuracy, inventory availability check, order status transitions, invalid input rejection (null fields, negative quantities, invalid product IDs), edge cases (zero items, maximum order size, concurrent stock checks). Aim for 90% coverage on validation module

- [ ] TASK-192: Write integration tests for product-service API
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `integration-test` `product-service` `api`
  - **Services:** product-service, database
  - **Steps:** Test CRUD operations against real database (testcontainers), verify pagination/sorting/filtering, test concurrent writes, validate error responses for duplicate SKUs, test search functionality with various filters, verify product image upload/download flow, add performance assertions (<200ms for list endpoint)

- [ ] TASK-193: Set up end-to-end tests for store-front checkout flow
  - **Priority:** P0 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 10h | **Tags:** `e2e` `store-front` `checkout` `playwright`
  - **Services:** store-front, order-service, payment-service
  - **Steps:** Install Playwright, write tests covering: browse→add to cart→checkout→payment→confirmation, guest vs authenticated checkout, coupon code application, address validation, payment failure handling, order cancellation, cart persistence across sessions. Run against staging environment, integrate into CI pipeline, add visual regression for key pages

- [ ] TASK-194: Perform load testing on order-service (1000 req/s)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `load-test` `k6` `performance`
  - **Services:** order-service, infrastructure
  - **Steps:** Write k6 script simulating realistic traffic mix (60% GET, 30% POST, 10% PUT), ramp up to 1000 req/s over 5 minutes, sustain for 15 minutes, measure p95/p99 latency and error rate. Define pass criteria (p99<500ms, error rate<0.1%). Run against staging with production-like data volume, identify bottlenecks, document results and tuning recommendations

- [ ] TASK-195: Run chaos experiment (kill random pods)
  - **Priority:** P1 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `chaos` `litmus` `resilience`
  - **Services:** all microservices, Kubernetes
  - **Steps:** Install Litmus Chaos, create ChaosHub experiment for pod-delete, target order-service and product-service, kill random pods during peak traffic, verify: zero data loss, automatic recovery within 30s, no cascading failures, alert fires correctly. Run during maintenance window, document findings, add resilience fixes to backlog

- [ ] TASK-196: Test Vault failover scenario
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `vault` `failover` `disaster-recovery`
  - **Services:** Vault, all services consuming secrets
  - **Steps:** Simulate primary Vault pod failure, verify standby promotes within 30s, test that all services can still read secrets, verify no secret leakage during failover, test recovery after primary comes back (reseal/unseal), document RTO and RPO, create runbook for manual Vault recovery

- [ ] TASK-197: Validate OPA Gatekeeper policies block non-compliant pods
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `opa` `gatekeeper` `policy`
  - **Services:** OPA Gatekeeper, Kubernetes
  - **Steps:** Test policies: block pods without resource limits, block images from untrusted registries, block pods running as root, enforce label requirements, block hostNetwork/hostPID. Write kubectl apply scripts with violating manifests, verify admission webhook rejects with clear error messages, document exemptions process

- [ ] TASK-198: Test network policies deny cross-namespace traffic
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `network-policy` `calico` `security`
  - **Services:** Calico, Kubernetes
  - **Steps:** Deploy test pods in namespaces A and B, verify: default deny all ingress/egress, allow traffic within same namespace, block traffic between namespaces without explicit policy, allow specific cross-namespace flows (order-service→payment-service), test DNS resolution still works, validate egress to external endpoints, document policy template

- [ ] TASK-199: Verify RBAC restrictions work correctly
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `rbac` `security` `kubernetes`
  - **Services:** Kubernetes RBAC
  - **Steps:** Create test ServiceAccounts with: readonly (only get/list/watch), developer (CRUD on specific namespaces), admin (full cluster access). Test each: readonly can't create pods, developer can deploy to staging but not production, admin can manage all resources. Verify audit logs capture denied requests, document RBAC matrix in security docs

- [ ] TASK-200: Test TLS certificate auto-renewal
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `tls` `cert-manager` `security`
  - **Services:** cert-manager, ingress-nginx
  - **Steps:** Create Certificate resource with 90-day validity, verify cert-manager issues certificate, manually trigger renewal before expiry, verify zero-downtime cert rotation, check that ingresses pick up new certs automatically, test renewal failure scenario (CA unreachable), monitor cert expiry via Prometheus alert

- [ ] TASK-201: Validate ArgoCD sync with broken manifest
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `argocd` `sync` `resilience`
  - **Services:** ArgoCD, Kubernetes
  - **Steps:** Intentionally deploy manifest with invalid YAML or missing CRD, verify ArgoCD marks app as Degraded, confirm healthy apps remain synced, test auto-heal reverts the broken change, verify rollback via ArgoCD UI, test with broken Kustomize overlay and Helm chart, document recovery procedure

- [ ] TASK-202: Test rollback procedure (Helm + ArgoCD)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `rollback` `helm` `argocd`
  - **Services:** Helm, ArgoCD, all microservices
  - **Steps:** Deploy new version of order-service, introduce intentional bug, verify alert fires, execute rollback: Helm rollback to previous revision AND ArgoCD rollback via UI, confirm zero data loss, measure rollback duration (<5min target), test database migration rollback compatibility, document step-by-step runbook with exact commands

- [ ] TASK-203: Perform security scan on all images (Trivy)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `security` `trivy` `container-scan`
  - **Services:** all container images, CI/CD
  - **Steps:** Run Trivy against all 8 service images, classify vulnerabilities (Critical/High/Medium/Low), create CI pipeline step to block Critical vulnerabilities, generate SBOM per image, set up scheduled weekly scans, create issue template for vulnerability remediation, track remediation SLA (Critical=48h, High=7d)

- [ ] TASK-204: Test disaster recovery (restore from backup)
  - **Priority:** P1 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `disaster-recovery` `backup` `velero`
  - **Services:** Velero, PostgreSQL, all services
  - **Steps:** Execute full cluster backup with Velero, simulate disaster (delete namespace), restore from backup, verify: all PVCs restored, database consistent (check row counts), application functional post-restore, DNS records intact. Measure RTO (target <1h) and RPO (<1h data loss), document restore procedure with exact commands, schedule monthly DR drills

- [ ] TASK-205: Validate Pod Security Standards enforce restricted
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `pod-security` `kubernetes` `security`
  - **Services:** Kubernetes, namespaces
  - **Steps:** Apply restricted PSS label to production namespace, verify: containers can't run as root, no privileged containers, no hostNetwork/hostPID, no hostPath volumes, seccomp profile enforced. Test that compliant pods deploy normally, non-compliant pods are rejected. Document migration path for existing workloads, create exemption list if needed

- [ ] TASK-206: Test DNS resolution under load
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `dns` `coredns` `performance`
  - **Services:** CoreDNS, Kubernetes
  - **Steps:** Deploy dnsperf load generator, simulate 5000 QPS DNS queries, measure latency and failure rate, verify CoreDNS autoscaling triggers, test with node-local DNS cache enabled vs disabled, verify external DNS resolution still works under load, document CoreDNS tuning recommendations

- [ ] TASK-207: Verify monitoring alerts fire correctly
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `monitoring` `alerting` `validation`
  - **Services:** Prometheus, Alertmanager, Grafana
  - **Steps:** For each critical alert, create test condition: kill a pod (CrashLooping), fill disk (DiskUsageHigh), stop a service (ServiceDown). Verify alert fires within expected `for` duration, notification reaches correct channel (Slack/PagerDuty), severity label correct, runbook annotation accessible. Document any alerts that don't fire and fix them

- [ ] TASK-208: Test LogQL queries in Loki
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `loki` `logql` `query`
  - **Services:** Loki, Grafana
  - **Steps:** Write and validate LogQL queries for: error rate by service, slow request detection (>2s), OOM kill patterns, authentication failures, rate of specific error messages. Test query performance on large datasets, optimize with line_format and drop filters, validate alerts based on LogQL metrics queries, document common query patterns in team wiki

- [ ] TASK-209: Validate OpenTelemetry trace collection
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `opentelemetry` `tracing` `jaeger`
  - **Services:** OpenTelemetry Collector, Jaeger, all microservices
  - **Steps:** Instrument all services with OTel SDK, verify traces propagate across service boundaries (store-front→order-service→payment-service), validate span attributes (HTTP method, status, peer.service), check trace sampling rate (1% in prod), verify baggage propagation, build Jaeger dashboard for service latency analysis, test trace context injection into logs

- [ ] TASK-210: Perform accessibility testing on store-front
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `accessibility` `a11y` `store-front`
  - **Services:** store-front
  - **Steps:** Run axe-core automated scan on all pages, fix critical violations (missing alt text, color contrast, keyboard navigation), test screen reader compatibility (NVDA/VoiceOver), verify all interactive elements are focusable, validate ARIA labels, test with 200% zoom, document WCAG 2.1 AA compliance status, add a11y checks to CI pipeline
