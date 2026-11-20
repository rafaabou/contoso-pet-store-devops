# Contoso Pet Store — DevSecOps Platform

8 polyglot microservices plus the Kubernetes, GitOps, infrastructure-as-code and
observability stack that runs them (K3s on Incus LXC, Helm + ArgoCD, Istio, Vault,
Prometheus/Grafana/Loki, Terraform/OpenTofu + Ansible, GitHub Actions CI).

Start with [AGENTS.md](AGENTS.md) for the repository map, build commands and
service dependency graph, and [devops-complete-guide/ZERO-TO-HERO-GUIDE.md](devops-complete-guide/ZERO-TO-HERO-GUIDE.md)
for the walkthrough.

## Secrets

**Every credential in this repository has been replaced with `*******`.**
Files that previously held live material (`.env`, `environment.sh`,
`terraform.tfvars`, `cluster-keys.json`, `*.pem`, token notes) now contain
placeholders only — the real values live outside version control.

To run anything locally, copy the template and fill in your own keys:

```bash
cp src/ai-service/.env.example src/ai-service/.env
```

Never commit real credentials. Use Vault (`kv/data/<service>`) for cluster
deployments, as described in AGENTS.md.
