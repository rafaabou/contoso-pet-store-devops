# Project Anatomy

## ./

- `ansible.cfg` - Source file (~112 tok)
- `site.yml` - YAML config (~403 tok)

## inventory/

- `hosts.ini` - Source file (~276 tok)

## inventory/group_vars/

- `all.yml` - YAML config (~320 tok)

## playbooks/

- `site-all.yml` - YAML config (~235 tok)
- `site-apps.yml` - YAML config (~181 tok)
- `site-argocd.yml` - YAML config (~67 tok)
- `site-cluster.yml` - YAML config (~114 tok)
- `site-monitoring.yml` - YAML config (~97 tok)
- `site-networking.yml` - YAML config (~87 tok)
- `site-opentelemetry.yml` - YAML config (~98 tok)
- `site-security.yml` - YAML config (~148 tok)
- `site-sonarqube.yml` - YAML config (~534 tok)
- `site-tools.yml` - YAML config (~70 tok)
- `site-vault.yml` - YAML config (~70 tok)

## roles/argocd/tasks/

- `main.yml` - YAML config (~452 tok)

## roles/cert-manager/tasks/

- `main.yml` - YAML config (~347 tok)

## roles/common/tasks/

- `main.yml` - YAML config (~351 tok)

## roles/k3s-master/tasks/

- `main.yml` - YAML config (~764 tok)

## roles/k3s-worker/tasks/

- `main.yml` - YAML config (~681 tok)

## roles/metallb/tasks/

- `main.yml` - YAML config (~330 tok)

## roles/monitoring/defaults/

- `main.yml` - YAML config (~129 tok)

## roles/monitoring/handlers/

- `main.yml` - YAML config (~87 tok)

## roles/monitoring/tasks/

- `main.yml` - YAML config (~1161 tok)

## roles/monitoring/templates/

- `alertmanager.service.j2` - Source file (~113 tok)
- `alertmanager.yml.j2` - Source file (~84 tok)
- `grafana.ini.j2` - Source file (~112 tok)
- `prometheus.service.j2` - Source file (~130 tok)
- `prometheus.yml.j2` - Source file (~343 tok)

## roles/nginx-ingress/tasks/

- `main.yml` - YAML config (~241 tok)

## roles/opentelemetry/defaults/

- `main.yml` - YAML config (~138 tok)

## roles/opentelemetry/handlers/

- `main.yml` - YAML config (~85 tok)

## roles/opentelemetry/tasks/

- `main.yml` - YAML config (~988 tok)

## roles/opentelemetry/templates/

- `jaeger.service.j2` - Source file (~101 tok)
- `loki-config.yml.j2` - Source file (~227 tok)
- `loki.service.j2` - Source file (~88 tok)
- `otel-config.yml.j2` - Source file (~365 tok)
- `otelcol.service.j2` - Source file (~87 tok)

## roles/tools/files/

- `devopstools-guide.sh` - Shell script (~10572 tok)
- `install-k8s-tools.sh` - Shell script (~3557 tok)

## roles/tools/tasks/

- `main.yml` - YAML config (~170 tok)

## roles/vault/defaults/

- `main.yml` - YAML config (~22 tok)

## roles/vault/handlers/

- `main.yml` - YAML config (~25 tok)

## roles/vault/tasks/

- `main.yml` - YAML config (~518 tok)

## roles/vault/templates/

- `vault.hcl.j2` - Source file (~70 tok)

