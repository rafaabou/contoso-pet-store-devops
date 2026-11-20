# DEVOPS COMPLETE GUIDE — MASTER KANBAN BOARD

> **Last Updated:** 2026-09-04
> **Total Tasks:** 230
> **Status:** Planning

---

## LEGEND

### Priority Levels
| Level | Description |
|-------|-------------|
| **P0** | Critical — must complete before any deployment |
| **P1** | High — core functionality, blocks other work |
| **P2** | Medium — important but not blocking |
| **P3** | Low — nice-to-have, do when time permits |

### Status Flow
```
Backlog → Todo → In Progress → Review → Done
                      ↓
                   Blocked → (unblock) → In Progress
```

### Categories
| Category | ID Range | Count |
|----------|----------|-------|
| Debugging | TASK-001 → TASK-045 | 45 |
| Security | TASK-046 → TASK-100 | 55 |
| Deployment | TASK-101 → TASK-135 | 35 |
| Infrastructure | TASK-136 → TASK-165 | 30 |
| Monitoring | TASK-166 → TASK-190 | 25 |
| Testing | TASK-191 → TASK-210 | 20 |
| Code Quality | TASK-211 → TASK-220 | 10 |
| Documentation | TASK-221 → TASK-230 | 10 |

### Sprint Schedule
| Sprint | Tasks | Focus |
|--------|-------|-------|
| Sprint 1 | 70 tasks | Critical fixes, security hardening, CI basics |
| Sprint 2 | 80 tasks | Infrastructure, monitoring, deployment pipelines |
| Sprint 3 | 80 tasks | Testing, code quality, documentation, polish |

---

## KANBAN COLUMNS

---

## BACKLOG

All 230 tasks are listed below, grouped by category.

---

### DEBUGGING (TASK-001 — TASK-045)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-001 | Fix null pointer exceptions in checkout flow | P0 | Debugging | Sprint 1 | 2h |
| TASK-002 | Debug race condition in inventory sync | P0 | Debugging | Sprint 1 | 4h |
| TASK-003 | Fix memory leak in WebSocket connections | P0 | Debugging | Sprint 1 | 3h |
| TASK-004 | Resolve timeout errors on payment gateway | P0 | Debugging | Sprint 1 | 3h |
| TASK-005 | Fix session persistence across server restart | P1 | Debugging | Sprint 1 | 2h |
| TASK-006 | Debug CSS layout issues in Safari | P1 | Debugging | Sprint 1 | 2h |
| TASK-007 | Fix broken image upload on mobile | P0 | Debugging | Sprint 1 | 3h |
| TASK-008 | Resolve database connection pool exhaustion | P0 | Debugging | Sprint 1 | 4h |
| TASK-009 | Debug email notification delivery failures | P1 | Debugging | Sprint 1 | 2h |
| TASK-010 | Fix incorrect tax calculation on bulk orders | P1 | Debugging | Sprint 1 | 3h |
| TASK-011 | Debug search index inconsistency after updates | P1 | Debugging | Sprint 2 | 4h |
| TASK-012 | Fix OAuth callback URL mismatch in staging | P1 | Debugging | Sprint 2 | 2h |
| TASK-013 | Resolve CDN cache invalidation delays | P2 | Debugging | Sprint 2 | 3h |
| TASK-014 | Debug pagination cursor drift in product listing | P1 | Debugging | Sprint 2 | 3h |
| TASK-015 | Fix locale-dependent date parsing errors | P2 | Debugging | Sprint 2 | 2h |
| TASK-016 | Debug Redis pub/sub message loss under load | P1 | Debugging | Sprint 2 | 4h |
| TASK-017 | Fix webhook retry logic sending duplicates | P1 | Debugging | Sprint 2 | 3h |
| TASK-018 | Debug slow N+1 query in order history endpoint | P1 | Debugging | Sprint 2 | 2h |
| TASK-019 | Fix image EXIF rotation on Android upload | P2 | Debugging | Sprint 2 | 2h |
| TASK-020 | Debug WebSocket reconnect loop on network switch | P1 | Debugging | Sprint 2 | 3h |
| TASK-021 | Fix cookie SameSite policy blocking OAuth flow | P1 | Debugging | Sprint 1 | 1h |
| TASK-022 | Debug inconsistent state after partial payment | P0 | Debugging | Sprint 1 | 4h |
| TASK-023 | Fix streaming response truncation at 64KB | P2 | Debugging | Sprint 2 | 2h |
| TASK-024 | Debug font rendering differences across OS | P3 | Debugging | Sprint 3 | 2h |
| TASK-025 | Fix redirect loop on expired auth tokens | P0 | Debugging | Sprint 1 | 2h |
| TASK-026 | Debug slow startup in development mode | P2 | Debugging | Sprint 2 | 3h |
| TASK-027 | Fix race in concurrent cart item additions | P1 | Debugging | Sprint 1 | 3h |
| TASK-028 | Debug intermittent 502 errors behind load balancer | P1 | Debugging | Sprint 2 | 4h |
| TASK-029 | Fix timezone offset in scheduled reports | P2 | Debugging | Sprint 2 | 2h |
| TASK-030 | Debug browser back button showing stale pages | P2 | Debugging | Sprint 2 | 2h |
| TASK-031 | Fix file upload progress bar not updating | P2 | Debugging | Sprint 2 | 1h |
| TASK-032 | Debug email HTML rendering in Outlook | P2 | Debugging | Sprint 3 | 3h |
| TASK-033 | Fix incorrect grand total with discount codes | P1 | Debugging | Sprint 1 | 2h |
| TASK-034 | Debug slow Chrome DevTools heap snapshots | P3 | Debugging | Sprint 3 | 2h |
| TASK-035 | Fix link prefetch interfering with analytics | P3 | Debugging | Sprint 3 | 1h |
| TASK-036 | Debug database migration lock timeout | P1 | Debugging | Sprint 2 | 3h |
| TASK-037 | Fix accessibility violations in form labels | P2 | Debugging | Sprint 3 | 2h |
| TASK-038 | Debug intermittent CORS preflight failures | P1 | Debugging | Sprint 2 | 2h |
| TASK-039 | Fix memory spike on large CSV import | P2 | Debugging | Sprint 2 | 3h |
| TASK-040 | Debug promise rejection not propagating to handler | P2 | Debugging | Sprint 2 | 2h |
| TASK-041 | Fix currency display showing extra decimals | P2 | Debugging | Sprint 2 | 1h |
| TASK-042 | Debug clipboard API failing in iframe | P3 | Debugging | Sprint 3 | 1h |
| TASK-043 | Fix Stripe webhook signature verification failing | P0 | Debugging | Sprint 1 | 2h |
| TASK-044 | Debug intermittent job queue stall | P1 | Debugging | Sprint 2 | 4h |
| TASK-045 | Fix service worker caching stale assets | P2 | Debugging | Sprint 3 | 2h |

---

### SECURITY (TASK-046 — TASK-100)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-046 | Audit and fix XSS vulnerabilities in user input | P0 | Security | Sprint 1 | 4h |
| TASK-047 | Enable CSP headers on all responses | P0 | Security | Sprint 1 | 2h |
| TASK-048 | Fix SQL injection in legacy search endpoint | P0 | Security | Sprint 1 | 3h |
| TASK-049 | Rotate all secrets and API keys | P0 | Security | Sprint 1 | 2h |
| TASK-050 | Implement rate limiting on auth endpoints | P0 | Security | Sprint 1 | 3h |
| TASK-051 | Enable HTTPS-only cookies | P0 | Security | Sprint 1 | 1h |
| TASK-052 | Fix CSRF token not rotating per session | P1 | Security | Sprint 1 | 2h |
| TASK-053 | Add input validation on all API endpoints | P1 | Security | Sprint 1 | 4h |
| TASK-054 | Implement Content-Security-Policy report-only mode | P1 | Security | Sprint 1 | 2h |
| TASK-055 | Audit third-party dependencies for CVEs | P0 | Security | Sprint 1 | 3h |
| TASK-056 | Fix open redirect vulnerability in login | P0 | Security | Sprint 1 | 1h |
| TASK-057 | Enable HSTS with long max-age | P1 | Security | Sprint 1 | 1h |
| TASK-058 | Implement account lockout after failed attempts | P1 | Security | Sprint 1 | 3h |
| TASK-059 | Fix overly permissive CORS policy | P0 | Security | Sprint 1 | 2h |
| TASK-060 | Add security headers via middleware | P1 | Security | Sprint 1 | 2h |
| TASK-061 | Audit and fix IDOR vulnerabilities | P0 | Security | Sprint 1 | 4h |
| TASK-062 | Implement SRI for external scripts | P1 | Security | Sprint 1 | 1h |
| TASK-063 | Fix password reset token not expiring | P0 | Security | Sprint 1 | 1h |
| TASK-064 | Enable SQL query parameterization in ORM | P1 | Security | Sprint 1 | 2h |
| TASK-065 | Implement session fingerprinting | P2 | Security | Sprint 2 | 3h |
| TASK-066 | Fix SSRF in URL preview endpoint | P0 | Security | Sprint 1 | 2h |
| TASK-067 | Add JWT token revocation mechanism | P1 | Security | Sprint 2 | 4h |
| TASK-068 | Implement API key rotation without downtime | P1 | Security | Sprint 2 | 3h |
| TASK-069 | Fix path traversal in file download endpoint | P0 | Security | Sprint 1 | 2h |
| TASK-070 | Add audit logging for privileged operations | P1 | Security | Sprint 2 | 3h |
| TASK-071 | Implement secrets management with Vault | P2 | Security | Sprint 2 | 4h |
| TASK-072 | Fix information disclosure in error responses | P1 | Security | Sprint 1 | 2h |
| TASK-073 | Add brute-force protection on login | P0 | Security | Sprint 1 | 2h |
| TASK-074 | Implement email verification on signup | P1 | Security | Sprint 2 | 3h |
| TASK-075 | Fix email header injection vulnerability | P0 | Security | Sprint 1 | 1h |
| TASK-076 | Add two-factor authentication | P2 | Security | Sprint 2 | 8h |
| TASK-077 | Fix CSV injection in data export | P1 | Security | Sprint 2 | 2h |
| TASK-078 | Implement RBAC on all admin endpoints | P1 | Security | Sprint 2 | 4h |
| TASK-079 | Fix verbose error messages leaking internals | P1 | Security | Sprint 1 | 2h |
| TASK-080 | Add request signing for webhooks | P2 | Security | Sprint 2 | 3h |
| TASK-081 | Implement secure password hashing (argon2id) | P1 | Security | Sprint 2 | 2h |
| TASK-082 | Fix JWT secret using weak algorithm | P0 | Security | Sprint 1 | 1h |
| TASK-083 | Add TLS 1.3 enforcement | P1 | Security | Sprint 1 | 1h |
| TASK-084 | Implement sensitive data masking in logs | P1 | Security | Sprint 2 | 2h |
| TASK-085 | Fix session fixation after login | P1 | Security | Sprint 1 | 2h |
| TASK-086 | Add dependency scanning to CI pipeline | P1 | Security | Sprint 1 | 2h |
| TASK-087 | Implement encrypted at-rest storage for PII | P1 | Security | Sprint 2 | 3h |
| TASK-088 | Fix download endpoint leaking other users' files | P0 | Security | Sprint 1 | 2h |
| TASK-089 | Add API versioning to prevent breaking changes | P2 | Security | Sprint 2 | 3h |
| TASK-090 | Implement zero-trust network policies | P2 | Security | Sprint 3 | 4h |
| TASK-091 | Fix missing SameSite attribute on cookies | P1 | Security | Sprint 1 | 1h |
| TASK-092 | Add DAST scanning in staging environment | P2 | Security | Sprint 3 | 4h |
| TASK-093 | Fix overly broad database permissions | P1 | Security | Sprint 2 | 2h |
| TASK-094 | Implement connection encryption for Redis | P2 | Security | Sprint 2 | 2h |
| TASK-095 | Add tamper detection for signed URLs | P2 | Security | Sprint 2 | 2h |
| TASK-096 | Fix missing authorization check on admin API | P0 | Security | Sprint 1 | 1h |
| TASK-097 | Implement certificate pinning for mobile app | P3 | Security | Sprint 3 | 4h |
| TASK-098 | Add OS command injection prevention | P1 | Security | Sprint 2 | 2h |
| TASK-099 | Fix admin panel accessible without auth in dev | P1 | Security | Sprint 1 | 1h |
| TASK-100 | Implement security.txt and bug bounty policy | P3 | Security | Sprint 3 | 2h |

---

### DEPLOYMENT (TASK-101 — TASK-135)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-101 | Set up CI pipeline with linting and tests | P0 | Deployment | Sprint 1 | 4h |
| TASK-102 | Configure Docker multi-stage builds | P0 | Deployment | Sprint 1 | 3h |
| TASK-103 | Implement blue-green deployment strategy | P0 | Deployment | Sprint 2 | 6h |
| TASK-104 | Set up staging environment mirror | P0 | Deployment | Sprint 1 | 4h |
| TASK-105 | Configure Kubernetes horizontal pod autoscaler | P1 | Deployment | Sprint 2 | 4h |
| TASK-106 | Implement database migration automation | P1 | Deployment | Sprint 2 | 3h |
| TASK-107 | Set up container image scanning in CI | P1 | Deployment | Sprint 1 | 2h |
| TASK-108 | Configure environment-specific configs | P1 | Deployment | Sprint 1 | 3h |
| TASK-109 | Implement zero-downtime deployment pipeline | P0 | Deployment | Sprint 2 | 6h |
| TASK-110 | Set up artifact registry (container images) | P1 | Deployment | Sprint 1 | 2h |
| TASK-111 | Configure resource limits on all services | P1 | Deployment | Sprint 2 | 3h |
| TASK-112 | Implement health check endpoints | P1 | Deployment | Sprint 1 | 2h |
| TASK-113 | Set up automated rollback on failed deploy | P1 | Deployment | Sprint 2 | 4h |
| TASK-114 | Configure log aggregation pipeline | P1 | Deployment | Sprint 2 | 3h |
| TASK-115 | Implement secrets injection at deploy time | P1 | Deployment | Sprint 2 | 3h |
| TASK-116 | Set up canary deployment for critical services | P2 | Deployment | Sprint 3 | 5h |
| TASK-117 | Configure service mesh (Istio/Linkerd) | P2 | Deployment | Sprint 3 | 6h |
| TASK-118 | Implement immutable infrastructure pattern | P2 | Deployment | Sprint 3 | 4h |
| TASK-119 | Set up multi-region failover | P2 | Deployment | Sprint 3 | 8h |
| TASK-120 | Configure automated SSL certificate renewal | P1 | Deployment | Sprint 2 | 2h |
| TASK-121 | Implement feature flag system | P2 | Deployment | Sprint 2 | 4h |
| TASK-122 | Set up load testing in CI pipeline | P2 | Deployment | Sprint 3 | 3h |
| TASK-123 | Configure DNS failover and health checks | P1 | Deployment | Sprint 2 | 3h |
| TASK-124 | Implement database connection retry logic | P1 | Deployment | Sprint 1 | 2h |
| TASK-125 | Set up Kubernetes namespace isolation | P1 | Deployment | Sprint 2 | 2h |
| TASK-126 | Configure backup and restore automation | P1 | Deployment | Sprint 2 | 3h |
| TASK-127 | Implement cache warming on deploy | P2 | Deployment | Sprint 3 | 2h |
| TASK-128 | Set up scheduled maintenance windows | P2 | Deployment | Sprint 3 | 2h |
| TASK-129 | Configure resource quota alerts | P2 | Deployment | Sprint 3 | 2h |
| TASK-130 | Implement deploy approval workflow | P2 | Deployment | Sprint 3 | 3h |
| TASK-131 | Set up disaster recovery runbook | P1 | Deployment | Sprint 2 | 4h |
| TASK-132 | Configure container startup/readiness probes | P1 | Deployment | Sprint 2 | 2h |
| TASK-133 | Implement infrastructure as code (Terraform) | P1 | Deployment | Sprint 2 | 6h |
| TASK-134 | Set up ArgoCD for GitOps deployments | P2 | Deployment | Sprint 3 | 4h |
| TASK-135 | Configure automated schema migrations | P2 | Deployment | Sprint 3 | 3h |

---

### INFRASTRUCTURE (TASK-136 — TASK-165)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-136 | Set up Kubernetes cluster (production) | P0 | Infrastructure | Sprint 1 | 8h |
| TASK-137 | Configure ingress controller (Nginx/Traefik) | P0 | Infrastructure | Sprint 1 | 3h | SUPERSEDED 2026-09-09: Istio chosen and deployed (see TASK-252) |
| TASK-138 | Set up PostgreSQL with replication | P0 | Infrastructure | Sprint 1 | 6h |
| TASK-139 | Configure Redis cluster for caching | P1 | Infrastructure | Sprint 1 | 4h |
| TASK-140 | Set up object storage (S3/MinIO) | P1 | Infrastructure | Sprint 1 | 3h |
| TASK-141 | Configure VPC and network segmentation | P0 | Infrastructure | Sprint 1 | 4h |
| TASK-142 | Set up load balancer (L7) | P0 | Infrastructure | Sprint 1 | 3h |
| TASK-143 | Configure DNS zones and records | P1 | Infrastructure | Sprint 1 | 2h |
| TASK-144 | Set up bastion host / jump box | P1 | Infrastructure | Sprint 1 | 2h |
| TASK-145 | Configure auto-scaling node groups | P1 | Infrastructure | Sprint 2 | 4h |
| TASK-146 | Set up CDN for static assets | P1 | Infrastructure | Sprint 2 | 2h |
| TASK-147 | Configure log rotation and retention | P1 | Infrastructure | Sprint 2 | 2h |
| TASK-148 | Set up NTP synchronization | P2 | Infrastructure | Sprint 2 | 1h |
| TASK-149 | Configure firewall rules (UFW/iptables) | P1 | Infrastructure | Sprint 1 | 2h |
| TASK-150 | Set up VPN for admin access | P1 | Infrastructure | Sprint 2 | 3h | DONE 2026-09-09 via Tailscale mesh (all nodes + admin); ProtonVPN coexistence documented (kill-switch off) |
| TASK-151 | Configure shared file system (NFS/EFS) | P2 | Infrastructure | Sprint 2 | 3h |
| TASK-152 | Set up message queue (RabbitMQ/Kafka) | P1 | Infrastructure | Sprint 2 | 5h |
| TASK-153 | Configure database connection pooling (PgBouncer) | P1 | Infrastructure | Sprint 2 | 2h |
| TASK-154 | Set up Prometheus + Grafana stack | P1 | Infrastructure | Sprint 2 | 4h |
| TASK-155 | Configure ELK/Loki for log management | P2 | Infrastructure | Sprint 2 | 4h |
| TASK-156 | Set up Helm charts for all services | P2 | Infrastructure | Sprint 3 | 6h |
| TASK-157 | Configure cluster autoscaler | P2 | Infrastructure | Sprint 3 | 3h |
| TASK-158 | Set up Harbor registry for images | P2 | Infrastructure | Sprint 3 | 3h |
| TASK-159 | Configure storage classes (SSD/HDD) | P2 | Infrastructure | Sprint 3 | 2h |
| TASK-160 | Set up network policies (Cilium/Calico) | P2 | Infrastructure | Sprint 3 | 3h |
| TASK-161 | Configure Pod Disruption Budgets | P2 | Infrastructure | Sprint 3 | 2h |
| TASK-162 | Set up cert-manager for TLS | P1 | Infrastructure | Sprint 2 | 2h |
| TASK-163 | Configure external DNS automation | P2 | Infrastructure | Sprint 3 | 2h |
| TASK-164 | Set up Loki for application log aggregation | P2 | Infrastructure | Sprint 3 | 3h |
| TASK-165 | Configure PVC backup strategy | P1 | Infrastructure | Sprint 2 | 2h |

---

### MONITORING (TASK-166 — TASK-190)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-166 | Set up application uptime monitoring | P0 | Monitoring | Sprint 1 | 2h |
| TASK-167 | Configure error tracking (Sentry) | P0 | Monitoring | Sprint 1 | 2h |
| TASK-168 | Set up custom metrics for business KPIs | P1 | Monitoring | Sprint 2 | 3h |
| TASK-169 | Configure latency monitoring (p50/p95/p99) | P1 | Monitoring | Sprint 2 | 2h |
| TASK-170 | Set up database query performance monitoring | P1 | Monitoring | Sprint 2 | 3h |
| TASK-171 | Configure alerting rules for critical thresholds | P0 | Monitoring | Sprint 1 | 3h |
| TASK-172 | Set up synthetic monitoring (API probes) | P1 | Monitoring | Sprint 2 | 3h |
| TASK-173 | Configure log-based alerts | P1 | Monitoring | Sprint 2 | 2h |
| TASK-174 | Set up real user monitoring (RUM) | P2 | Monitoring | Sprint 3 | 3h |
| TASK-175 | Configure infrastructure metrics (CPU/mem/disk) | P1 | Monitoring | Sprint 2 | 2h |
| TASK-176 | Set up distributed tracing (Jaeger/Tempo) | P2 | Monitoring | Sprint 3 | 4h |
| TASK-177 | Configure Slack/PagerDuty alert routing | P1 | Monitoring | Sprint 2 | 2h |
| TASK-178 | Set up Grafana dashboards for services | P1 | Monitoring | Sprint 2 | 4h |
| TASK-179 | Configure anomaly detection on key metrics | P2 | Monitoring | Sprint 3 | 4h |
| TASK-180 | Set up cost monitoring and budgets | P2 | Monitoring | Sprint 3 | 2h |
| TASK-181 | Configure SSL certificate expiry alerts | P1 | Monitoring | Sprint 2 | 1h |
| TASK-182 | Set up database replication lag monitoring | P1 | Monitoring | Sprint 2 | 2h |
| TASK-183 | Configure Kubernetes event monitoring | P2 | Monitoring | Sprint 3 | 2h |
| TASK-184 | Set up cache hit/miss ratio monitoring | P2 | Monitoring | Sprint 3 | 2h |
| TASK-185 | Configure backup success/failure alerts | P1 | Monitoring | Sprint 2 | 1h |
| TASK-186 | Set up dependency health monitoring | P2 | Monitoring | Sprint 3 | 2h |
| TASK-187 | Configure service level objectives (SLOs) | P2 | Monitoring | Sprint 3 | 3h |
| TASK-188 | Set up on-call rotation and escalation | P1 | Monitoring | Sprint 2 | 2h |
| TASK-189 | Configure capacity planning alerts | P2 | Monitoring | Sprint 3 | 2h |
| TASK-190 | Set up post-mortem template and process | P2 | Monitoring | Sprint 3 | 1h |

---

### TESTING (TASK-191 — TASK-210)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-191 | Set up unit test framework and baseline | P0 | Testing | Sprint 1 | 3h |
| TASK-192 | Write unit tests for payment processing | P0 | Testing | Sprint 1 | 4h |
| TASK-193 | Write unit tests for auth/session management | P0 | Testing | Sprint 1 | 3h |
| TASK-194 | Set up integration test suite | P1 | Testing | Sprint 2 | 4h |
| TASK-195 | Write API contract tests | P1 | Testing | Sprint 2 | 3h |
| TASK-196 | Set up E2E test framework (Playwright) | P1 | Testing | Sprint 2 | 4h |
| TASK-197 | Write E2E tests for checkout flow | P0 | Testing | Sprint 2 | 5h |
| TASK-198 | Write E2E tests for user registration | P1 | Testing | Sprint 2 | 3h |
| TASK-199 | Set up visual regression testing | P2 | Testing | Sprint 3 | 3h |
| TASK-200 | Write integration tests for email notifications | P1 | Testing | Sprint 2 | 2h |
| TASK-201 | Set up load testing framework (k6) | P1 | Testing | Sprint 2 | 3h |
| TASK-202 | Write unit tests for cart/pricing logic | P1 | Testing | Sprint 2 | 3h |
| TASK-203 | Set up mutation testing | P3 | Testing | Sprint 3 | 3h |
| TASK-204 | Write accessibility tests (axe-core) | P2 | Testing | Sprint 3 | 2h |
| TASK-205 | Set up test data seeding scripts | P1 | Testing | Sprint 2 | 2h |
| TASK-206 | Write E2E tests for admin dashboard | P2 | Testing | Sprint 3 | 4h |
| TASK-207 | Set up CI test parallelization | P1 | Testing | Sprint 2 | 2h |
| TASK-208 | Write integration tests for search functionality | P2 | Testing | Sprint 3 | 3h |
| TASK-209 | Set up security test suite (OWASP ZAP) | P2 | Testing | Sprint 3 | 3h |
| TASK-210 | Write unit tests for webhook handlers | P2 | Testing | Sprint 3 | 2h |

---

### CODE QUALITY (TASK-211 — TASK-220)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-211 | Configure ESLint with strict rules | P1 | Code Quality | Sprint 1 | 2h |
| TASK-212 | Set up Prettier for consistent formatting | P1 | Code Quality | Sprint 1 | 1h |
| TASK-213 | Configure TypeScript strict mode | P1 | Code Quality | Sprint 1 | 2h |
| TASK-214 | Set up pre-commit hooks (Husky) | P1 | Code Quality | Sprint 1 | 1h |
| TASK-215 | Run SonarQube code quality analysis | P2 | Code Quality | Sprint 2 | 3h |
| TASK-216 | Fix all critical code smells | P1 | Code Quality | Sprint 2 | 4h |
| TASK-217 | Implement code review checklist | P1 | Code Quality | Sprint 2 | 1h |
| TASK-218 | Set up code coverage thresholds (80%) | P2 | Code Quality | Sprint 2 | 2h |
| TASK-219 | Refactor legacy authentication module | P2 | Code Quality | Sprint 3 | 6h |
| TASK-220 | Add API documentation (OpenAPI/Swagger) | P2 | Code Quality | Sprint 3 | 4h |

---

### DOCUMENTATION (TASK-221 — TASK-230)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-221 | Write deployment runbook | P1 | Documentation | Sprint 2 | 4h |
| TASK-222 | Document environment variables and config | P1 | Documentation | Sprint 2 | 2h |
| TASK-223 | Write incident response playbook | P1 | Documentation | Sprint 2 | 3h |
| TASK-224 | Document database schema and ERD | P1 | Documentation | Sprint 2 | 3h |
| TASK-225 | Create architecture decision records (ADRs) | P2 | Documentation | Sprint 3 | 3h |
| TASK-226 | Document API rate limits and versioning | P2 | Documentation | Sprint 3 | 2h |
| TASK-227 | Write onboarding guide for new developers | P2 | Documentation | Sprint 3 | 3h |
| TASK-228 | Document disaster recovery procedures | P1 | Documentation | Sprint 3 | 3h |
| TASK-229 | Create monitoring dashboard documentation | P2 | Documentation | Sprint 3 | 2h |
| TASK-230 | Write security hardening guide | P1 | Documentation | Sprint 3 | 3h |

---

## AUTOSCALING (TASK-231 — TASK-250)

| ID | Title | Priority | Category | Sprint | Estimate |
|-----|-------|----------|----------|--------|----------|
| TASK-231 | Deploy KEDA operator via Helm chart | P1 | Autoscaling | Sprint 2 | 1h |
| TASK-232 | Create KEDA ScaledObject for order-service (RabbitMQ trigger) | P1 | Autoscaling | Sprint 2 | 2h |
| TASK-233 | Create KEDA ScaledObject for virtual-customer (cron, scale-to-zero) | P1 | Autoscaling | Sprint 2 | 1.5h |
| TASK-234 | Create KEDA ScaledObject for ai-service (CPU/memory) | P2 | Autoscaling | Sprint 2 | 1h |
| TASK-235 | Create KEDA ScaledObject for product-service (CPU/memory) | P2 | Autoscaling | Sprint 2 | 1h |
| TASK-236 | Create KEDA ScaledObject for makeline-service (CPU/memory) | P2 | Autoscaling | Sprint 2 | 1h |
| TASK-237 | Create KEDA ScaledObject for store-front (CPU/memory) | P2 | Autoscaling | Sprint 2 | 1h |
| TASK-238 | Create KEDA ScaledObject for store-admin (CPU/memory) | P2 | Autoscaling | Sprint 2 | 1h |
| TASK-239 | Configure KEDA scale-to-zero for virtual-customer | P1 | Autoscaling | Sprint 2 | 1h |
| TASK-240 | Configure KEDA scale-to-zero for virtual-worker | P1 | Autoscaling | Sprint 2 | 1h |
| TASK-241 | Test KEDA autoscaling (RabbitMQ queue → pods) | P1 | Autoscaling | Sprint 2 | 2h |
| TASK-242 | Test KEDA scale-to-zero (idle → zero) | P2 | Autoscaling | Sprint 2 | 1.5h |
| TASK-243 | Deploy Karpenter operator via Helm chart | P1 | Autoscaling | Sprint 2 | 1.5h |
| TASK-244 | Create Karpenter NodePool with requirements | P1 | Autoscaling | Sprint 2 | 2h |
| TASK-245 | Configure Karpenter disruption budgets | P2 | Autoscaling | Sprint 3 | 1.5h |
| TASK-246 | Test Karpenter node provisioning | P1 | Autoscaling | Sprint 2 | 2h |
| TASK-247 | Test Karpenter node consolidation | P2 | Autoscaling | Sprint 3 | 1.5h |
| TASK-248 | Integrate KEDA + Vault (TriggerAuthentication) | P2 | Autoscaling | Sprint 3 | 2h |
| TASK-249 | Create Grafana dashboard for KEDA + Karpenter metrics | P2 | Autoscaling | Sprint 3 | 2h |
| TASK-250 | Document autoscaling strategy (decision tree) | P3 | Autoscaling | Sprint 3 | 2h |

---

## TODO

*(empty — TASK-262 + TASK-263 remain in progress)*

---

## IN PROGRESS

| ID | Title | Priority | Category | Assignee | Started |
|-----|-------|----------|----------|----------|---------|
| TASK-262 | Forgejo CI/CD: PC2 VMs + binary install + Podman-free runners + pilot | P1 | Infrastructure | operator | 2026-09-09 |
| TASK-263 | Production monitoring: Alloy edge + probes + alerts (Telegram) + correlation + hardening | P1 | Infrastructure | operator | 2026-09-10 |

---

## REVIEW

| ID | Title | Priority | Category | Assignee | Reviewer |
|-----|-------|----------|----------|----------|----------|

*(empty)*

---

## DONE

| ID | Title | Priority | Category | Completed |
|-----|-------|----------|----------|-----------|
| TASK-251 | K3s 3-node cluster operational (PC1x2 + PC2 via Tailscale) | P0 | Infrastructure | 2026-09-09 |
| TASK-252 | Istio ingress migration + DNS-01 wildcard TLS | P0 | Infrastructure | 2026-09-09 |
| TASK-253 | Vault TLS + auto-init/unseal + KV engine + secrets seeded | P0 | Infrastructure | 2026-09-09 |
| TASK-254 | Monitoring + observability stack deployed (PC1 VM) | P1 | Infrastructure | 2026-09-09 |
| TASK-255 | SonarQube migrated PC1 to PC2 + Gateway exposure | P1 | Infrastructure | 2026-09-09 |
| TASK-256 | Worker kubeconfig distribution + API TLS SANs | P1 | Infrastructure | 2026-09-09 |
| TASK-257 | sonar.* DNS cutover + Firefox verify + admin password rotation | P1 | Infrastructure | 2026-09-09 |
| TASK-257-note | SonarQube UI confirmed open in Firefox via Gateway (valid LE cert); admin password rotated + confirmed + stored kv/sonarqube | — | — | 2026-09-09 |
| TASK-258 | ArgoCD login verified + admin password stored in Vault kv/argocd | P0 | Infrastructure | 2026-09-09 |
| TASK-259 | Full site.yml convergence proof: failed=0 on all 6 hosts | P0 | Infrastructure | 2026-09-09 |
| TASK-260 | Cross-PC pod networking (flannel-iface=tailscale0, 5b 3/3 0% loss both ways) | P2 | Infrastructure | 2026-09-13 |

---

## BLOCKED

| ID | Title | Priority | Category | Blocker | Since |
|-----|-------|----------|----------|---------|-------|
*(empty — TASK-260 moved to IN PROGRESS 2026-09-12)*

---

## STATISTICS

### Total Tasks: 262 (250 curriculum + 12 session OPS TASK-251→260 + TASK-262/263, 2026-09-10)

### Completion (session OPS scope, 2026-09-10)
| Scope | Done | Open | % done |
|-------|------|------|--------|
| Session OPS (TASK-251→260 + TASK-262/263, 12 tasks) | 10 closed (251–260) + 263 steps 1–3 proven live + SSO 5/5 + plugin v1.0.3 released | 262 pilot (parked), 263 steps 4–5 | 83% by count, ~92% by work |
| Session OPS actionable (excl. blocked 260) | 9 of 11 + 263 three-fifths | 262 tail, 263 tail | 82% by count |
| Whole board (262 incl. untouched 250 curriculum) | 9 | 253 | 3% |

### By Priority
| Priority | Count | Percentage |
|----------|-------|------------|
| P0 — Critical | 46 | 17.7% |
| P1 — High | 109 | 41.9% |
| P2 — Medium | 75 | 28.8% |
| P3 — Low | 10 | 3.8% |

### By Category
| Category | ID Range | Count |
|----------|----------|-------|
| Debugging | TASK-001 → TASK-045 | 45 |
| Security | TASK-046 → TASK-100 | 55 |
| Deployment | TASK-101 → TASK-135 | 35 |
| Infrastructure | TASK-136 → TASK-165 | 30 |
| Monitoring | TASK-166 → TASK-190 | 25 |
| Testing | TASK-191 → TASK-210 | 20 |
| Code Quality | TASK-211 → TASK-220 | 10 |
| Documentation | TASK-221 → TASK-230 | 10 |
| Autoscaling | TASK-231 → TASK-250 | 20 |

### By Sprint
| Sprint | Task Count | Focus Areas |
|--------|------------|-------------|
| Sprint 1 | 70 | Critical fixes, security hardening, CI basics |
| Sprint 2 | 80 | Infrastructure, monitoring, deployment pipelines |
| Sprint 3 | 80 | Testing, code quality, documentation, polish |

### Velocity Estimate
| Metric | Value |
|--------|-------|
| Total estimated hours | ~640h |
| Sprint 1 hours | ~180h |
| Sprint 2 hours | ~240h |
| Sprint 3 hours | ~220h |
| Avg tasks per sprint | 77 |
