# Security Tasks

Real-world DevSecOps security work items.

## Vulnerability Management

- [ ] TASK-046: Patch CVE-2026-XXXX in base container images
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `cve` `images` `patching`
  - **Services:** [base-images, registry, ci-pipeline]
  - **Symptoms:** Trivy scan reports critical CVE in base image; CI pipeline blocks on merge; no upstream fix available yet
  - **Investigation steps:** trivy image <image>:latest --severity CRITICAL; check distro security trackers; grep -r "FROM" Dockerfile; docker history <image>
  - **Expected fix:** Update base image to patched version, rebuild all dependent images, push to registry, update deployments

- [ ] TASK-047: Run Trivy scan on all images and triage findings
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `trivy` `scan` `triage`
  - **Services:** [trivy, registry, all-deployments]
  - **Symptoms:** Unknown number of CVEs across images; no baseline scan results; compliance audit approaching
  - **Investigation steps:** trivy image --severity HIGH,CRITICAL <registry>/<ns>/<image>:<tag> for each; trivy filesystem --severity HIGH,CRITICAL /; cat trivyignore for existing exceptions
  - **Expected fix:** Generate scan report, triage critical/high findings, create tickets for fix, add trivyignore for accepted risks, set up scheduled scans

- [ ] TASK-048: Update OPA Gatekeeper policies for new constraint templates
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `opa` `gatekeeper` `policy`
  - **Services:** [gatekeeper, constraint-templates]
  - **Symptoms:** New workloads deploying without required labels; Gatekeeper audit shows violations not enforced; policy gap identified
  - **Investigation steps:** kubectl get constrainttemplates; kubectl get constraints -A; kubectl describe constrainttemplate <name>; cat gatekeeper/policies/*.yaml
  - **Expected fix:** Create new constraint template, deploy constraint with audit mode first, verify no false positives, switch to enforce, update documentation

- [ ] TASK-049: OWASP dependency check baseline — fix critical advisories
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `owasp` `dependency` `sbom`
  - **Services:** [ci-pipeline, application-deps]
  - **Symptoms:** OWASP check reports 12 critical advisories; baseline scan never established; merge blocked
  - **Investigation steps:** cat dependency-check-report.xml | grep severity="critical"; npm audit 2>&1 | grep critical; pip-audit 2>&1; check package.json/go.mod for vulnerable versions
  - **Expected fix:** Update vulnerable dependencies, create suppression file for accepted risks, establish baseline scan, add to CI pipeline

- [ ] TASK-050: Audit Terraform provider versions for known CVEs
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `terraform` `providers` `cve`
  - **Services:** [terraform, provider-registry]
  - **Symptoms:** Security scan flags outdated provider with CVE; terraform providers lock needs updating
  - **Investigation steps:** terraform providers lock -platform=linux_amd64; grep -r "required_providers" *.tf; cat .terraform.lock.hcl | grep "version"
  - **Expected fix:** Update provider version constraints, run terraform init -upgrade, re-lock providers, verify compatibility

- [ ] TASK-051: Configure Snyk monitoring for open source dependencies
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `snyk` `monitoring` `dependencies`
  - **Services:** [snyk, github-integration]
  - **Symptoms:** No ongoing monitoring of dependencies; new vulnerabilities discovered in production after release
  - **Investigation steps:** snyk test --all-projects; snyk monitor --all-projects; cat .snyk policy; check snyk dashboard for baseline
  - **Expected fix:** Set up Snyk monitor in CI, configure org policies, set up PR checks, establish baseline, configure alerts

- [ ] TASK-052: Review Ansible playbook for hardcoded secrets
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `ansible` `secrets` `hardcoded`
  - **Services:** [ansible, vault, playbooks]
  - **Symptoms:** git secrets scan flags hardcoded passwords; ansible-vault files found in repo; playbook contains plaintext API keys
  - **Investigation steps:** git secrets --scan; grep -rn "password\|secret\|api_key\|token" *.yml | grep -v vault; cat ansible.cfg | grep vault_password; ansible-vault view secrets.yml
  - **Expected fix:** Move secrets to ansible-vault, use environment variables, set up git hooks for secret detection, rotate exposed credentials

## Certificate & Secret Management

- [ ] TASK-053: Rotate TLS certificates before expiry — cluster-wide
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `tls` `certificates` `rotation`
  - **Services:** [cert-manager, ingress, apiserver]
  - **Symptoms:** Certificate expires in 7 days; cert-manager renewal failing; browser shows security warning
  - **Investigation steps:** kubectl get certificate -A -o wide; kubectl describe certificate <cert> | grep -A5 "Conditions"; openssl s_client -connect <host>:443 </dev/null 2>/dev/null | openssl x509 -noout -dates; certbot certificates 2>/dev/null
  - **Expected fix:** Manually trigger renewal, check cert-manager issuer, verify DNS challenge, update ingress TLS secrets

- [ ] TASK-054: Rotate Vault token — expired root token
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `vault` `token` `rotation`
  - **Services:** [vault]
  - **Symptoms:** vault status shows sealed=false but operations fail with "permission denied"; token expired 24h ago; no recovery key available
  - **Investigation steps:** vault token lookup <token>; vault status; cat /vault/config/vault.json; vault operator raft list-peers 2>/dev/null
  - **Expected fix:** Unseal vault with recovery keys, generate new root token, update all integrations, set up token auto-rotation

- [ ] TASK-055: Rotate database credentials via Vault dynamic secrets
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `vault` `database` `dynamic-secrets`
  - **Services:** [vault, postgresql, application]
  - **Symptoms:** Static database password known to multiple engineers; last rotation 6+ months ago; compliance finding
  - **Investigation steps:** vault read database/creds/my-role; vault write database/rotate-role/my-role; kubectl get secret db-creds -o yaml; psql -h db-host -U app-user -d mydb -c "SELECT current_user"
  - **Expected fix:** Enable Vault database secrets engine, configure dynamic credential rotation, update application to use Vault CSI provider, set TTL

- [ ] TASK-056: Rotate Git repository secrets — leaked token in CI
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `git` `secrets` `rotation`
  - **Services:** [github, ci-runner, vault]
  - **Symptoms:** Secret detected in CI logs; token exposed in workflow output; GitHub warns of secret in commit
  - **Investigation steps:** git log --all -p | grep -i "<secret-pattern>"; check CI logs for leaked values; vault kv get -field=token secret/ci/deploy
  - **Expected fix:** Revoke compromised token immediately, rotate via GitHub/Vault, update CI secrets, add pre-commit hooks for secret detection

- [ ] TASK-057: Enable encryption at rest for Kubernetes secrets
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `encryption` `secrets` `k8s`
  - **Services:** [apiserver, encryption-config]
  - **Symptoms:** Secrets stored in etcd as plaintext; compliance audit requires encryption at rest; no encryption config present
  - **Investigation steps:** cat /var/lib/rancher/k3s/server/cred/encryption-config.json; etcdctl get --prefix kubernetes.secrets; kubectl get secret <secret> -o json | grep -c "kind"
  - **Expected fix:** Generate encryption config with AES-CBC or AES-GCM, configure apiserver flag, restart apiserver, migrate existing secrets

- [ ] TASK-058: Vault auto-unseal configuration — AWS KMS integration
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `vault` `unseal` `kms`
  - **Services:** [vault, aws-kms]
  - **Symptoms:** Vault seals on every restart; manual unseal required each time; HA cluster nodes seal independently
  - **Investigation steps:** vault status; cat /vault/config/vault.hcl | grep seal; aws kms describe-key --key-id <key-id>; vault operator unseal -migrate
  - **Expected fix:** Configure KMS auto-unseal in vault.hcl, provide AWS credentials, migrate unseal keys, test restart behavior

- [ ] TASK-059: Set up Sealed Secrets for production environments
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `sealed-secrets` `secrets` `gitops`
  - **Services:** [sealed-secrets, argocd, kubeseal]
  - **Symptoms:** Secrets cannot be stored in git; ArgoCD syncs fail for encrypted secrets; no SealedSecret controller running
  - **Investigation steps:** kubectl get pods -n kube-system | grep sealed; kubeseal --version; kubectl get crd sealedsecrets.bitnami.com -o yaml; cat sealed-secret.yaml | head -10
  - **Expected fix:** Deploy sealed-secrets controller, create SealedSecret for each namespace, verify ArgoCD can sync, backup sealing key

## Container & Runtime Security

- [ ] TASK-060: Configure Falco custom rules for sensitive operations
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `falco` `rules` `runtime`
  - **Services:** [falco, falco-rules]
  - **Symptoms:** Falco installed with default rules only; no detection of sensitive file access or reverse shells; audit requires custom detections
  - **Investigation steps:** kubectl logs falco-xxx | grep -i "rule\|alert"; cat /etc/falco/falco_rules.yaml | tail -50; falco --list; kubectl get configmap falco-config -n falco
  - **Expected fix:** Write custom Falco rules for sensitive operations, test in audit mode, configure alert routing (Slack/webhook), deploy via Helm values

- [ ] TASK-061: Set up AppArmor profiles for workloads
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `apparmor` `profiles` `runtime`
  - **Services:** [apparmor, runtime]
  - **Symptoms:** No AppArmor enforcement on containers; containers running as unconfined; audit finding for missing MAC
  - **Investigation steps:** kubectl get pods -o json | jq '.items[].metadata.annotations["container.apparmor.security.beta.kubernetes.io/*"]'; aa-status; cat /etc/apparmor.d/* | head -20
  - **Expected fix:** Create custom AppArmor profiles, apply annotations to deployments, test in audit mode, enforce after validation

- [ ] TASK-062: Apply Seccomp profiles to containers
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `seccomp` `profiles` `runtime`
  - **Services:** [seccomp, runtime]
  - **Symptoms:** Containers using runtime default seccomp profile; no custom profiles; syscall audit logs show excessive permissions
  - **Investigation steps:** kubectl get pods -o json | jq '.items[].spec.securityContext.seccompProfile'; strace -p <pid> -c -S syscall; cat /var/log/audit/audit.log | grep seccomp
  - **Expected fix:** Generate seccomp profile from strace, apply to pod security context, test with audit mode, enforce for production

- [ ] TASK-063: Review Containerfile security with hadolint
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `hadolint` `containerfile` `best-practices`
  - **Services:** [docker, ci-pipeline]
  - **Symptoms:** hadolint reports DL3008 (pin versions), DL3009 (delete apt cache), DL3007 (using latest tag); security review pending
  - **Investigation steps:** hadolint Dockerfile 2>&1; cat Dockerfile | grep -E "FROM|RUN|COPY|USER"; check .hadolint.yaml for ignores
  - **Expected fix:** Pin all package versions, add apt-get clean, use specific base image tags, run as non-root user, add HEALTHCHECK

- [ ] TASK-064: Enable Seccomp profile on k3s kubelet
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `k3s` `seccomp` `kubelet`
  - **Services:** [k3s, kubelet]
  - **Symptoms:** k3s uses default seccomp profile; no custom profile configured; audit finding
  - **Investigation steps:** cat /var/lib/rancher/k3s/agent/etc/containerd/config.toml | grep seccomp; kubectl get runtimeclass; ls /var/lib/kubelet/seccomp/
  - **Expected fix:** Configure seccomp profile path in containerd config, create custom profiles directory, restart kubelet

## RBAC & Access Control

- [ ] TASK-065: Audit RBAC ClusterRoleBindings — remove stale accounts
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `rbac` `clusterrolebinding` `audit`
  - **Services:** [rbac, serviceaccounts]
  - **Symptoms:** 15+ stale ClusterRoleBindings found; some bind to deleted service accounts; excessive permissions for debugging
  - **Investigation steps:** kubectl get clusterrolebinding -o yaml | grep -B2 "name:"; kubectl auth can-i --list --as=system:serviceaccount:default:<sa>; kubectl get sa -A | wc -l
  - **Expected fix:** Identify unused bindings, remove stale accounts, apply principle of least privilege, document exceptions

- [ ] TASK-066: Enable audit logging on k3s API server
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `audit` `apiserver` `logging`
  - **Services:** [k3s, apiserver, audit-log]
  - **Symptoms:** No API audit logs found; compliance requires audit trail; cannot trace who modified resources
  - **Investigation steps:** ls /var/lib/rancher/k3s/server/logs/; cat /var/lib/rancher/k3s/server/audit.yaml 2>/dev/null; kubectl logs -n kube-system kube-apiserver-xxx | grep -i audit
  - **Expected fix:** Create audit policy yaml, configure audit log path, set retention, verify log collection, test with kubectl create

- [ ] TASK-067: Review IAM policies for least privilege — cloud provider
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `iam` `cloud` `least-privilege`
  - **Services:** [aws-iam, service-accounts]
  - **Symptoms:** IAM roles with * permissions; multiple service accounts with admin access; last access analysis shows unused permissions
  - **Investigation steps:** aws iam get-account-authorization-details; aws iam generate-credential-report; cat terraform/*.tf | grep -i "iam\|role\|policy"
  - **Expected fix:** Narrow IAM policies, remove unused permissions, set up access analyzer, enable credential reports, apply SCPs

- [ ] TASK-068: Review and tighten Tailscale ACLs
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `tailscale` `acl` `vpn`
  - **Services:** [tailscale, tailscale-acl]
  - **Symptoms:** All Tailscale nodes can reach all ports; no segmentation; ACL policy allows everything
  - **Investigation steps:** tailscale status; cat tailscale-acl.json | jq .; tailscale ping <node>; cat /etc tailscale/tailscaled.state 2>/dev/null
  - **Expected fix:** Define per-node/port ACL rules, test with tailscale acl dry-run, deploy updated policy, verify connectivity

- [ ] TASK-069: Set up Pod Security Admission exemptions for system namespaces
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `psa` `admission` `exemptions`
  - **Services:** [kube-apiserver, pod-security-admission]
  - **Symptoms:** System pods violating restricted profile; kube-system pods fail admission; Pod Security Admission blocking critical workloads
  - **Investigation steps:** kubectl get ns kube-system -o jsonpath='{.metadata.labels}'; kubectl get pods -n kube-system -o json | jq '.items[].spec.securityContext'; kubectl logs -n kube-system kube-apiserver-xxx | grep -i "pod-security"
  - **Expected fix:** Add PSA exemptions for kube-system/kube-public, configure audit/enforce/warn levels per namespace, test with dry-run

## Network Security

- [ ] TASK-070: Review and update Network Policies — restrict pod-to-pod traffic
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `networkpolicy` `segmentation` `zero-trust`
  - **Services:** [networkpolicy, all-namespaces]
  - **Symptoms:** All pods can communicate with all other pods; no network segmentation; compliance requires zero-trust
  - **Investigation steps:** kubectl get networkpolicy -A; kubectl exec -it <pod-a> -- curl <pod-b-ip>:80; cat network-policies/*.yaml | wc -l
  - **Expected fix:** Create default deny ingress/egress policies, add allow rules per application, test connectivity, document exceptions

- [ ] TASK-071: Configure rate limiting on ingress — DDoS protection
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `ingress` `ratelimit` `ddos`
  - **Services:** [ingress-nginx, rate-limit]
  - **Symptoms:** API endpoints receiving 10k+ RPM from single IP; no rate limiting configured; backend overwhelmed
  - **Investigation steps:** kubectl logs -n ingress-nginx <pod> | grep -c "requests"; kubectl get ingress <ingress> -o json | jq '.metadata.annotations'; curl -I -H "X-Forwarded-For: 1.2.3.4" http://ingress/
  - **Expected fix:** Add nginx rate-limit annotations, configure per-IP limits, set connection limits, test with hey/wrk

- [ ] TASK-072: Enable mTLS with service mesh — mutual TLS between services
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `mtls` `istio` `service-mesh`
  - **Services:** [istio, envoy, citadel]
  - **Symptoms:** No encryption between services; mTLS not enforced; compliance requires service-to-service encryption
  - **Investigation steps:** istioctl analyze; kubectl get peerauthentication -A; istioctl proxy-status; curl -v <service> | grep -i "ssl\|tls"
  - **Expected fix:** Install Istio, configure PeerAuthentication for strict mLS, verify with istioctl proxy-status, test mTLS between services

- [ ] TASK-073: Set up WAF rules on ingress — OWASP Top 10 protection
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `waf` `owasp` `ingress`
  - **Services:** [ingress-nginx, modsecurity]
  - **Symptoms:** No WAF protection on web applications; SQL injection/XSS possible; OWASP audit failed
  - **Investigation steps:** kubectl get ingress -o yaml | grep -i "modsecurity\|waf"; curl -s "http://app/?id=1' OR '1'='1"; kubectl logs -n ingress-nginx <pod> | grep -i "modsecurity"
  - **Expected fix:** Enable ModSecurity in ingress-nginx, configure OWASP CRS rules, test with SQLi/XSS payloads, tune false positives

## Image Security

- [ ] TASK-074: Set up Cosign image signing in CI
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `cosign` `signing` `ci`
  - **Services:** [cosign, ci-pipeline, registry]
  - **Symptoms:** No image signatures; cannot verify image provenance; supply chain attack risk
  - **Investigation steps:** cosign version; cosign sign <image> 2>&1; kubectl get pods -o json | grep -i "cosign"; cat .cosign/cosign.pub
  - **Expected fix:** Generate cosign key pair, add signing step to CI, configure verification in admission controller, sign all images

- [ ] TASK-075: Generate SBOM with Syft for compliance
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `sbom` `syft` `compliance`
  - **Services:** [syft, ci-pipeline]
  - **Symptoms:** No SBOM generated; compliance requires software bill of materials; supply chain audit pending
  - **Investigation steps:** syft version; syft <image> -o spdx-json > sbom.json; cat sbom.json | jq '.artifacts | length'; grype sbom:sbom.json
  - **Expected fix:** Integrate Syft into CI, generate SBOM for each image, store in OCI registry, set up SBOM verification

- [ ] TASK-076: Set up Trivy operator for continuous scanning
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `trivy-operator` `continuous` `scanning`
  - **Services:** [trivy-operator, trivy]
  - **Symptoms:** No continuous vulnerability scanning; only one-time scans; new CVEs not detected after deployment
  - **Investigation steps:** kubectl get pods -n trivy-system; kubectl get vulnerabilityreports -A; helm list -n trivy-system; kubectl logs -n trivy-system trivy-operator-xxx
  - **Expected fix:** Deploy trivy-operator via Helm, configure scheduled scans, set up CRD-based reporting, integrate with alerting

- [ ] TASK-077: Configure OPA Gatekeeper for image policy enforcement
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `opa` `gatekeeper` `image-policy`
  - **Services:** [gatekeeper, constraint-templates]
  - **Symptoms:** Workloads deploying with :latest tag; no image provenance verification; unauthorized registries allowed
  - **Investigation steps:** kubectl get constrainttemplates | grep image; kubectl get k8sallowedrepos -o yaml; cat gatekeeper/policies/image-constraint.yaml
  - **Expected fix:** Deploy K8sAllowedRepos/K8sImageDigests constraint templates, set audit mode, enforce after validation, document exceptions

## Compliance & Audit

- [ ] TASK-078: Run kube-bench CIS benchmark — remediate findings
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `kube-bench` `cis` `benchmark`
  - **Services:** [k3s, all-nodes]
  - **Symptoms:** CIS benchmark audit required; kube-bench shows 15 failures; compliance certification pending
  - **Investigation steps:** kube-bench run --targets master,node; cat /etc/kubernetes/audit-policy.yaml; ssh k3s-master; cat /var/lib/rancher/k3s/server/audit.yaml
  - **Expected fix:** Fix critical CIS failures (API server authorization mode, audit logging, etcd encryption), document non-applicable controls, re-run benchmark

- [ ] TASK-079: Remediate CIS benchmark findings — master node
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `cis` `remediation` `master`
  - **Services:** [k3s-master, apiserver, etcd]
  - **Symptoms:** kube-bench master section shows FAIL for 4.1.1 (anonymous auth), 1.2.20 (audit log), 1.2.21 (audit policy)
  - **Investigation steps:** cat /var/lib/rancher/k3s/server/audit.yaml; grep -i "anonymous" /var/lib/rancher/k3s/server/cred/admin.kubeconfig; etcdctl endpoint health
  - **Expected fix:** Enable audit logging, configure audit policy, disable anonymous auth for kube-apiserver, enable etcd encryption at rest

- [ ] TASK-080: Set up security scanning in GitHub Actions
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `github-actions` `scanning` `ci`
  - **Services:** [github-actions, trivy, snyk, hadolint]
  - **Symptoms:** No security scanning in CI pipeline; vulnerabilities merged to main; no PR checks for security
  - **Investigation steps:** cat .github/workflows/*.yml | grep -i "trivy\|snyk\|hadolint\|security"; git log --oneline | head -20; cat .github/dependabot.yml
  - **Expected fix:** Add Trivy/Snyk/hadolint steps to workflow, configure as required checks, set up Dependabot, add secret scanning

- [ ] TASK-081: Review public exposure of services — find unintended public endpoints
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `exposure` `public` `ingress`
  - **Services:** [ingress, services, metallb]
  - **Symptoms:** Internal services exposed via NodePort/LoadBalancer; no network-level access control; debug endpoints publicly accessible
  - **Investigation steps:** kubectl get svc -A --field-selector spec.type=LoadBalancer; kubectl get ingress -A -o yaml | grep "host:"; curl -s http://<node-ip>:<nodeport>/actuator/health
  - **Expected fix:** Remove unnecessary LoadBalancer/NodePort services, add NetworkPolicies, restrict ingress hosts, disable debug endpoints in production

- [ ] TASK-082: Review and update incident response runbooks
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `runbook` `incident` `response`
  - **Services:** [documentation, oncall]
  - **Symptoms:** Runbooks outdated; last update 6+ months ago; new team members don't know escalation procedures
  - **Investigation steps:** cat docs/runbooks/*.md | head -20; git log --oneline docs/runbooks/ | head -5; grep -r "TODO\|FIXME" docs/runbooks/
  - **Expected fix:** Review all runbooks, update contact info, add new procedures, test with tabletop exercise, share with team

- [ ] TASK-083: Test disaster recovery procedures — restore from backup
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `disaster-recovery` `backup` `restore`
  - **Services:** [etcd, s3, restore-tool]
  - **Symptoms:** DR procedures untested; last backup 30 days old; RTO/RPO targets not validated
  - **Investigation steps:** ls -la /var/lib/rancher/k3s/server/db/snapshots/; aws s3 ls s3://backup-bucket/k3s/; cat docs/runbooks/dr-restore.md; k3s etcd-snapshot list
  - **Expected fix:** Perform test restore to staging, validate data integrity, document actual RTO/RPO, update runbook, schedule quarterly DR tests

- [ ] TASK-084: Validate backup encryption — ensure etcd snapshots encrypted
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `backup` `encryption` `etcd`
  - **Services:** [etcd, backup-storage]
  - **Symptoms:** etcd snapshots stored unencrypted; S3 bucket has no server-side encryption; compliance requires encrypted backups
  - **Investigation steps:** file /var/lib/rancher/k3s/server/db/snapshots/*.db; aws s3api get-bucket-encryption --bucket backup-bucket; etcdctl snapshot status <snapshot>.db 2>&1 | head
  - **Expected fix:** Enable S3 server-side encryption, set up client-side encryption for etcd snapshots, verify key management, test restore

## Secret Management & Rotation

- [ ] TASK-085: Review Docker Hub access tokens — rotate old tokens
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `docker-hub` `tokens` `access`
  - **Services:** [docker-hub, ci-runner]
  - **Symptoms:** Docker Hub tokens older than 90 days; multiple unused tokens; no rotation policy
  - **Investigation steps:** curl -s -H "Authorization: Bearer $DOCKER_HUB_TOKEN" https://hub.docker.com/v2/users/me/; cat ~/.docker/config.json | jq .auths; check CI secrets for docker token age
  - **Expected fix:** Revoke old tokens, generate new ones, update CI secrets, set rotation reminder, use automated token management

- [ ] TASK-086: Update Dependabot security alerts — fix all critical/high
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `dependabot` `github` `security`
  - **Services:** [github, dependabot]
  - **Symptoms:** 8 critical/12 high Dependabot alerts open; some 30+ days old; merge blocked
  - **Investigation steps:** gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[] | select(.security_advisory.severity=="critical")'; cat dependabot.yml; git log --oneline | grep -i "dependabot\|bump"
  - **Expected fix:** Review and merge critical PRs, update vulnerable packages, configure auto-merge for patch versions, set up security alerts

- [ ] TASK-087: Configure Vault audit logging — all operations logged
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `vault` `audit` `logging`
  - **Services:** [vault]
  - **Symptoms:** No Vault audit logs; cannot trace who accessed secrets; compliance requires full audit trail
  - **Investigation steps:** vault audit list; vault audit enable file file_path=/var/log/vault/audit.log 2>&1; cat /var/log/vault/audit.log | tail -5 | jq .
  - **Expected fix:** Enable file audit device, configure log rotation, test with vault read, set up log forwarding to SIEM

- [ ] TASK-088: Enable Sealed Secrets backup — export and backup keys
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `sealed-secrets` `backup` `keys`
  - **Services:** [sealed-secrets]
  - **Symptoms:** No SealedSecret key backup; if controller lost, all secrets unrecoverable; DR procedure missing
  - **Investigation steps:** kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml; cat sealed-secrets-backup.yaml 2>/dev/null; ls /backup/sealed-secrets/
  - **Expected fix:** Export signing keys, store encrypted backup in secure location, document restore procedure, test recovery

- [ ] TASK-089: Rotate Helm chart repository secrets
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `helm` `repository` `secrets`
  - **Services:** [helm, repository-secrets]
  - **Symptoms:** Helm repository credentials in plaintext in values.yaml; no secret rotation; shared across environments
  - **Investigation steps:** helm repo list; cat values.yaml | grep -i "password\|secret\|token"; kubectl get secret -n helm-system | grep repo
  - **Expected fix:** Move credentials to Kubernetes secret, reference via existingSecret, rotate credentials, update documentation

## Supply Chain Security

- [ ] TASK-090: Set up image pull secrets rotation — automated via CronJob
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `image-pull` `secrets` `rotation`
  - **Services:** [cronjob, imagepullsecret]
  - **Symptoms:** Image pull secrets expire every 90 days; manual rotation; pods fail to pull images after expiry
  - **Investigation steps:** kubectl get secret -A | grep docker-registry; kubectl get cronjob -A | grep secret-rotator; cat rotator-script.sh | head -20
  - **Expected fix:** Create rotation CronJob, generate new tokens, update secrets in all namespaces, verify pod scheduling

- [ ] TASK-091: Review and harden GitHub Actions workflows
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `github-actions` `workflow` `security`
  - **Services:** [github-actions]
  - **Symptoms:** Workflows using unpinned action versions; secrets accessible to all jobs; no permissions block
  - **Investigation steps:** cat .github/workflows/*.yml | grep -E "uses:|secrets\.|permissions"; cat .github/workflows/ci.yml | grep -A5 "permissions"; git log --oneline .github/ | head -10
  - **Expected fix:** Pin action versions to SHA, add permissions blocks, restrict secret access per job, add workflow_dispatch limits

- [ ] TASK-092: Set up SBOM verification in admission controller
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `sbom` `admission` `verification`
  - **Services:** [admission-controller, syft, grype]
  - **Symptoms:** No SBOM verification at deploy time; images deployed without provenance check; supply chain risk
  - **Investigation steps:** kubectl get validatingwebhookconfiguration | grep sbom; cat admission-config/sbom-webhook.yaml; syft <image> -o spdx-json | jq '.artifacts | length'
  - **Expected fix:** Deploy SBOM verification webhook, configure OCI registry for SBOM storage, integrate with CI, test with unsigned images

- [ ] TASK-093: Configure Sigstore policy controller for cluster
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `sigstore` `policy-controller` `admission`
  - **Services:** [sigstore, policy-controller]
  - **Symptoms:** No image signature verification; any image can be deployed; no supply chain integrity check
  - **Investigation steps:** kubectl get pods -n sigstore; kubectl get clusterimagepolicy -o yaml; cosign verify <image> --key cosign.pub 2>&1
  - **Expected fix:** Deploy Sigstore policy controller, create ClusterImagePolicy, configure keyless signing with Fulcio/Rekor, test enforcement

## Runtime Security

- [ ] TASK-094: Set up Falco sidekick integrations — Slack/PagerDuty alerts
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `falco` `sidekick` `alerting`
  - **Services:** [falco, falcosidekick, slack, pagerduty]
  - **Symptoms:** Falco alerts only to stdout; no notification to oncall; security events missed
  - **Investigation steps:** kubectl logs falcosidekick-xxx | grep -i "error\|send"; cat falcosidekick-config.yaml | grep -A5 "slack\|pagerduty"; curl -s http://falcosidekick:2801/healthz
  - **Expected fix:** Configure Falco sidekick outputs, set up Slack/PagerDuty integration, test with sample alert, configure alert routing

- [ ] TASK-095: Configure alert routing for security events — separate channel
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `alerting` `routing` `security`
  - **Services:** [alertmanager, security-channel]
  - **Symptoms:** Security alerts mixed with operational alerts; no separate security channel; high-severity alerts missed
  - **Investigation steps:** cat alertmanager/alertmanager.yml | grep -A10 "route\|match"; kubectl get alertmanagerconfig -A; kubectl logs alertmanager-xxx | grep -i "route\|send"
  - **Expected fix:** Create security-specific alert routing, set up dedicated Slack channel, configure escalation, test with security alerts

- [ ] TASK-096: Enable runtime threat detection with Tetragon
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `tetragon` `ebpf` `threat-detection`
  - **Services:** [tetragon, cilium]
  - **Symptoms:** No runtime process monitoring; suspicious syscalls not detected; eBPF-based detection not configured
  - **Investigation steps:** kubectl get pods -n cilium | grep tetragon; cat tetragon/tracing-policies/*.yaml | head -30; kubectl logs -n cilium tetragon-xxx | grep -i "policy\|enforce"
  - **Expected fix:** Deploy Tetragon, create TracingPolicies for sensitive operations, configure alert routing, test with malicious syscalls

## Compliance & Governance

- [ ] TASK-097: Generate compliance report — SOC2/ISO27001 evidence
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `compliance` `soc2` `report`
  - **Services:** [audit, compliance]
  - **Symptoms:** SOC2 audit approaching; no automated compliance evidence; manual reporting taking days
  - **Investigation steps:** cat compliance/controls.md; kube-bench run -j --json | jq .; trivy image --format json <image> | jq '.Results[].Vulnerabilities | length'
  - **Expected fix:** Automate evidence collection, generate compliance dashboards, document control mappings, prepare auditor package

- [ ] TASK-098: Set up security policy documentation — enforce in CI
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `policy` `documentation` `ci`
  - **Services:** [policy-engine, ci-pipeline]
  - **Symptoms:** No security policy documentation; policies enforced inconsistently; new team members unaware of requirements
  - **Investigation steps:** cat SECURITY.md 2>/dev/null; cat .github/CODEOWNERS 2>/dev/null; grep -r "security" .github/workflows/ | head -10
  - **Expected fix:** Create security policy document, add CODEOWNERS, enforce in CI, set up security champion role, regular reviews

- [ ] TASK-099: Conduct tabletop exercise — test incident response
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `tabletop` `incident` `exercise`
  - **Services:** [incident-response, team]
  - **Symptoms:** Incident response never tested; team unclear on roles; last exercise was 12+ months ago
  - **Investigation steps:** cat docs/runbooks/incident-response.md; cat escalation-matrix.md; grep -r "oncall" .github/; ls docs/postmortems/
  - **Expected fix:** Plan tabletop scenario, execute with team, document findings, update runbooks based on gaps, schedule quarterly exercises

- [ ] TASK-100: Review and update security governance policies — annual review
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `governance` `policy` `annual`
  - **Services:** [governance, compliance]
  - **Symptoms:** Security policies 18 months old; no annual review; new threats not addressed; technology stack changed
  - **Investigation steps:** cat docs/policies/*.md | head -20; git log --oneline docs/policies/ | head -5; grep -r "TODO\|FIXME\|UPDATE" docs/policies/
  - **Expected fix:** Review all security policies, update for current technology stack, address new threat landscape, get management sign-off, distribute to team
