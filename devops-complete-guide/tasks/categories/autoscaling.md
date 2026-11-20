# Autoscaling Tasks (Pod & Node Autoscaling)

- [ ] TASK-231: Deploy KEDA operator via Helm chart
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `keda` `helm` `operator`
  - **Services:** cluster-wide (k3s-master 10.195.94.80, k3s-worker-1 10.195.94.81, k3s-worker-2 10.195.94.82)
  - **Steps:** 1) Add KEDA Helm repo: `helm repo add kedacore https://kedacore.github.io/charts && helm repo update` 2) Create namespace `keda-system` 3) Install KEDA: `helm install keda kedacore/keda --namespace keda-system --version 2.14 --wait` 4) Verify all pods running in keda-system 5) Verify CRDs installed: `kubectl get crd | grep keda` 6) Confirm ScaledObject and TriggerAuthentication CRDs exist
  - **Rollback:** `helm uninstall keda -n keda-system && kubectl delete namespace keda-system`

- [ ] TASK-232: Create KEDA ScaledObject for order-service (RabbitMQ queue depth trigger, min 2, max 10)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `keda` `rabbitmq` `scaling` `order-service`
  - **Services:** order-service, RabbitMQ, KEDA
  - **Steps:** 1) Create TriggerAuthentication referencing RabbitMQ credentials (use Vault-stored secret or k8s secret `rabbitmq-credentials`) 2) Create ScaledObject with RabbitMQ scaler: `queueName=orders`, `queueLength=5` 3) Set `minReplicaCount: 2`, `maxReplicaCount: 10` 4) Set `triggers[0].authenticationRef.name` to the TriggerAuthentication 5) Apply manifest to namespace containing order-service 6) Verify ScaledObject status: `kubectl get scaledobject order-service -o yaml` 7) Confirm HPA is created automatically by KEDA
  - **Rollback:** `kubectl delete scaledobject order-service` — pods revert to Deployment replicas

- [ ] TASK-233: Create KEDA ScaledObject for virtual-customer (cron trigger, scale to zero)
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `keda` `cron` `scale-to-zero` `virtual-customer`
  - **Services:** virtual-customer, KEDA
  - **Steps:** 1) Create ScaledObject with cron scaler: `timezone=Europe/Lisbon`, schedule `*/30 8-18 * * 1-5` (business hours) 2) Set `minReplicaCount: 0` (scale to zero) 3) Set `maxReplicaCount: 5` 4) Add CPU trigger as secondary: 70% threshold 5) Apply manifest 6) Verify outside business hours: pods scale to zero 7) During business hours: pods scale up based on CPU load
  - **Rollback:** `kubectl delete scaledobject virtual-customer` — set Deployment replicas manually to desired count

- [ ] TASK-234: Create KEDA ScaledObject for ai-service (CPU/memory triggers, min 2)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `keda` `cpu` `memory` `ai-service`
  - **Services:** ai-service, KEDA
  - **Steps:** 1) Create ScaledObject with CPU trigger: `value=70` (70% threshold), `type=Utilization` 2) Add memory trigger: `value=80` (80% threshold) 3) Set `minReplicaCount: 2`, `maxReplicaCount: 8` 4) Set `pollingInterval: 15` for responsive scaling 5) Apply manifest 6) Verify HPA created with both metrics 7) Load test ai-service with CPU-intensive requests, confirm scale-up
  - **Rollback:** `kubectl delete scaledobject ai-service` — revert to fixed replica count

- [ ] TASK-235: Create KEDA ScaledObject for product-service (CPU/memory triggers, min 2)
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `keda` `cpu` `memory` `product-service`
  - **Services:** product-service, KEDA
  - **Steps:** 1) Create ScaledObject with CPU trigger: `value=70`, `type=Utilization` 2) Add memory trigger: `value=80` 3) Set `minReplicaCount: 2`, `maxReplicaCount: 6` 4) Apply manifest to store namespace 5) Verify HPA binding: `kubectl get hpa product-service` 6) Confirm scaling behavior under load via Grafana
  - **Rollback:** `kubectl delete scaledobject product-service`

- [ ] TASK-236: Create KEDA ScaledObject for makeline-service (CPU/memory triggers, min 2)
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `keda` `cpu` `memory` `makeline-service`
  - **Services:** makeline-service, KEDA
  - **Steps:** 1) Create ScaledObject with CPU trigger: `value=70` 2) Add memory trigger: `value=80` 3) Set `minReplicaCount: 2`, `maxReplicaCount: 6` 4) Apply manifest 5) Verify HPA created 6) Test scaling under simulated order processing load
  - **Rollback:** `kubectl delete scaledobject makeline-service`

- [ ] TASK-237: Create KEDA ScaledObject for store-front (CPU/memory triggers, min 2)
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `keda` `cpu` `memory` `store-front`
  - **Services:** store-front, KEDA
  - **Steps:** 1) Create ScaledObject with CPU trigger: `value=75` 2) Add memory trigger: `value=80` 3) Set `minReplicaCount: 2`, `maxReplicaCount: 8` 4) Apply manifest 5) Verify HPA created 6) Simulate web traffic spike with hey/ab, confirm scaling
  - **Rollback:** `kubectl delete scaledobject store-front`

- [ ] TASK-238: Create KEDA ScaledObject for store-admin (CPU/memory triggers, min 2)
  - **Priority:** P3 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `keda` `cpu` `memory` `store-admin`
  - **Services:** store-admin, KEDA
  - **Steps:** 1) Create ScaledObject with CPU trigger: `value=70` 2) Add memory trigger: `value=80` 3) Set `minReplicaCount: 2`, `maxReplicaCount: 4` (lower max — admin UI has lower traffic) 4) Apply manifest 5) Verify HPA created
  - **Rollback:** `kubectl delete scaledobject store-admin`

- [ ] TASK-239: Configure KEDA scale-to-zero for virtual-customer (cooldownPeriod 300s)
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `keda` `scale-to-zero` `cooldown` `virtual-customer`
  - **Services:** virtual-customer, KEDA
  - **Steps:** 1) Update virtual-customer ScaledObject: set `cooldownPeriod: 300` (5 minutes) 2) Set `minReplicaCount: 0` 3) Set idle polling interval to 30s 4) Apply updated manifest 5) Verify with `kubectl get scaledobject virtual-customer -o yaml` 6) Confirm: idle for 5 min → pods reach zero; load applied → pods scale from zero to target
  - **Rollback:** Revert ScaledObject to `minReplicaCount: 2` or delete it

- [ ] TASK-240: Configure KEDA scale-to-zero for virtual-worker (RabbitMQ trigger, min 0)
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `keda` `scale-to-zero` `rabbitmq` `virtual-worker`
  - **Services:** virtual-worker, RabbitMQ, KEDA
  - **Steps:** 1) Create TriggerAuthentication for RabbitMQ 2) Create ScaledObject with RabbitMQ scaler: `queueName=work-queue`, `queueLength=1` 3) Set `minReplicaCount: 0`, `maxReplicaCount: 10` 4) Set `cooldownPeriod: 120` (2 min) 5) Apply manifest 6) Verify: no messages → zero pods; enqueue messages → pods scale up proportionally 7) Drain queue → pods return to zero after cooldown
  - **Rollback:** `kubectl delete scaledobject virtual-worker`

- [ ] TASK-241: Test KEDA autoscaling — enqueue 50 messages → order-service scales to 5 pods
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `keda` `testing` `rabbitmq` `order-service`
  - **Services:** order-service, RabbitMQ, KEDA
  - **Steps:** 1) Ensure order-service ScaledObject exists and is active 2) Publish 50 test messages to RabbitMQ `orders` queue via Management UI or `rabbitmqadmin` 3) Monitor: `kubectl get hpa order-service -w` 4) Confirm HPA target concurrency decreases as pods increase 5) Verify scale-up to ~5 pods (queueLength=5, 50 messages / 5 per pod) 6) Process messages → observe scale-down 7) Capture scaling timeline for documentation
  - **Rollback:** N/A — test only, no persistent changes

- [ ] TASK-242: Test KEDA scale-to-zero — idle virtual-customer → pods → zero after 5 min
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `keda` `testing` `scale-to-zero` `virtual-customer`
  - **Services:** virtual-customer, KEDA
  - **Steps:** 1) Ensure virtual-customer ScaledObject has `minReplicaCount: 0` and `cooldownPeriod: 300` 2) Verify current state: `kubectl get pods -l app=virtual-customer` — pods running or zero 3) If running, trigger cron outside window or wait for cooldown 4) Monitor: `kubectl get deployment virtual-customer -w` 5) Confirm after 5 min idle: `kubectl get pods -l app=virtual-customer` returns empty 6) Trigger load or cron window → confirm scale from zero 7) Document timeline
  - **Rollback:** N/A — test only

- [ ] TASK-243: Deploy Karpenter operator via Helm chart
  - **Priority:** P1 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `karpenter` `helm` `operator` `node-provisioning`
  - **Services:** cluster-wide (k3s-master 10.195.94.80, k3s-worker-1 10.195.94.81, k3s-worker-2 10.195.94.82)
  - **Steps:** 1) Add Karpenter Helm repo: `helm repo add karpenter https://karpenter.sh/oci --oci ` 2) Create namespace `karpenter-system` 3) Install: `helm install karpenter oci://public.ecr.aws/karpenter/karpenter --version 0.36 --set settings.clusterName=k3s-cluster --set controller.resources.requests.cpu=200m --wait` 4) Verify pods in karpenter-system 5) Confirm CRDs: `kubectl get crd | grep karpenter` (NodePool, EC2NodeClass) 6) Verify webhook and controller are healthy
  - **Rollback:** `helm uninstall karpenter -n karpenter-system && kubectl delete namespace karpenter-system`

- [ ] TASK-244: Create Karpenter NodePool with instance type requirements
  - **Priority:** P1 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `karpenter` `nodepool` `instance-types` `provisioning`
  - **Services:** Karpenter, cluster infrastructure
  - **Steps:** 1) Create NodePool manifest with `spec.template.spec.requirements` 2) Limit `karpenter.sh/capacity-type` to `on-demand` 3) Limit `node.kubernetes.io/instance-type` to `t3.medium`, `t3.large`, `m5.large` 4) Set `spec.template.spec.nodeClassRef.name` to default NodeClass 5) Set `spec.disruption.consolidationPolicy: WhenUnderutilized` 6) Set `spec.limits.maxNodes: 10` 7) Apply manifest 8) Verify: `kubectl get nodepool`
  - **Rollback:** `kubectl delete nodepool <name>`

- [ ] TASK-245: Configure Karpenter disruption budgets (maxUnavailable: 1)
  - **Priority:** P1 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `karpenter` `disruption` `budget` `availability`
  - **Services:** Karpenter, cluster infrastructure
  - **Steps:** 1) Update NodePool `spec.disruption.budgets` 2) Set `maxUnavailable: 1` (only one node disrupted at a time) 3) Add `nodes: 1` 4) Apply updated manifest 5) Verify disruption budget: `kubectl describe nodepool <name>` 6) Test: create a drain event — confirm only one node is cordoned/drained simultaneously
  - **Rollback:** Revert NodePool to previous disruption config or delete NodePool

- [ ] TASK-246: Test Karpenter node provisioning — create 20 pods → new node appears
  - **Priority:** P1 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `karpenter` `testing` `node-provisioning`
  - **Services:** Karpenter, cluster infrastructure
  - **Steps:** 1) Verify current node count: `kubectl get nodes` (expect 3: master + 2 workers) 2) Create test deployment with 20 pods requesting 512Mi memory / 250m CPU each 3) Monitor: `kubectl get nodes -w` and `kubectl logs -n karpenter-system -l app=karpenter -f` 4) Confirm Karpenter provisions new node within 2 minutes 5) Verify 20 pods are scheduled 6) Check node pool limits not exceeded 7) Delete test deployment after verification
  - **Rollback:** Delete test deployment, confirm node consolidation

- [ ] TASK-247: Test Karpenter node consolidation — delete pods → underutilized node removed
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1.5h | **Tags:** `karpenter` `testing` `consolidation` `node-removal`
  - **Services:** Karpenter, cluster infrastructure
  - **Steps:** 1) From TASK-246: node pool has 4+ nodes with test pods running 2) Delete the test deployment: `kubectl delete deploy test-scale` 3) Monitor Karpenter logs for consolidation events 4) Confirm: `kubectl get nodes -w` shows node count decreasing 5) Verify consolidated node is cordoned → drained → removed within 5 minutes 6) Confirm all remaining pods rescheduled to surviving nodes 7) Capture consolidation timeline
  - **Rollback:** N/A — test only, nodes are ephemeral

- [ ] TASK-248: Integrate KEDA + Vault (store RabbitMQ credentials in Vault, use TriggerAuthentication)
  - **Priority:** P1 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `keda` `vault` `triggerauthentication` `secrets`
  - **Services:** KEDA, Vault, RabbitMQ
  - **Steps:** 1) Store RabbitMQ credentials in Vault at `secret/store-app/rabbitmq` (username, password, host) 2) Ensure Vault CSI provider or Vault Agent Injector is running in cluster 3) Create KEDA TriggerAuthentication with `kind: Vault` 4) Set `vault.address`, `vault.role`, `vault.path` pointing to Vault server 5) Set `vault.secrets[].parameter` mapping Vault keys to KEDA trigger params (`username`, `password`, `host`) 6) Update order-service ScaledObject to reference the new TriggerAuthentication 7) Verify: delete original k8s secret → scaling still works via Vault 8) Rotate credentials in Vault → confirm KEDA picks up new creds
  - **Rollback:** Revert ScaledObject to use k8s Secret-based TriggerAuthentication; delete Vault TriggerAuthentication

- [ ] TASK-249: Create Grafana dashboard for KEDA scaling events + Karpenter node metrics
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `grafana` `dashboard` `keda` `karpenter` `monitoring`
  - **Services:** Grafana, Prometheus, KEDA, Karpenter
  - **Steps:** 1) Create Grafana dashboard JSON with datasource variable for Prometheus 2) Panel 1: KEDA ScaledObject active status (`keda_scaled_object_status_active`) 3) Panel 2: Current vs desired replicas per ScaledObject (`keda_scaled_object_spec_replica`, `keda_scaled_object_status_replica`) 4) Panel 3: KEDA trigger metrics (queue depth, CPU, memory) 5) Panel 4: Karpenter node count over time (`karpenter_provisioner_scheduling_duration_seconds_count`) 6) Panel 5: Karpenter disruption events 7) Panel 6: Cluster node count timeline 8) Import dashboard into Grafana via API or UI 9) Verify panels populate with live data
  - **Rollback:** Delete dashboard via Grafana UI or API: `DELETE /api/dashboards/db/<uid>`

- [ ] TASK-250: Document autoscaling strategy (when KEDA vs HPA vs Karpenter, decision tree)
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `documentation` `autoscaling` `decision-tree` `architecture`
  - **Services:** documentation
  - **Steps:** 1) Create `docs/autoscaling-strategy.md` 2) Define decision tree: HPA for simple CPU/memory; KEDA for event-driven (RabbitMQ, cron, external metrics); Karpenter for node-level scaling 3) Document when to use each: HPA = standard apps, KEDA = queue-based + scale-to-zero, Karpenter = dynamic node pool sizing 4) Include comparison table: features, pros, cons, use cases 5) Add example manifests for each tool 6) Document integration pattern: KEDA scales pods → Karpenter provisions nodes when pods can't schedule 7) Review with team
  - **Rollback:** N/A — documentation only
