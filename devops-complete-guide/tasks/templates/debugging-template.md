# Debugging Session Template

Use this for structured incident investigation and debugging.

---

# DEBUG-XXX: [Incident Title]

**Date:** YYYY-MM-DD  
**Severity:** SEV1 / SEV2 / SEV3 / SEV4  
**Status:** investigating / identified / monitoring / resolved  
**Duration:** Xh Xm (open → resolved)  
**Services affected:** [list]

---

## 1. Alert / Report

| Field | Value |
|-------|-------|
| **Alert name** | [Prometheus alert name] |
| **Fired at** | YYYY-MM-DD HH:MM UTC |
| **Reported by** | [monitoring / customer / team member] |
| **Symptom** | [what was observed] |

## 2. Impact

| Metric | Normal | During Incident |
|--------|--------|-----------------|
| Error rate | X% | Y% |
| Latency P99 | Xms | Yms |
| Throughput | X req/s | Y req/s |
| Users affected | 0 | X |

## 3. Timeline

| Time (UTC) | Action |
|------------|--------|
| HH:MM | Alert fired |
| HH:MM | Investigator notified |
| HH:MM | Started investigation |
| HH:MM | Root cause identified |
| HH:MM | Fix deployed |
| HH:MM | Verified resolved |
| HH:MM | Incident closed |

## 4. Investigation

### What I checked first
```bash
# Commands run during investigation
kubectl get pods -n production
kubectl logs -n production -l app=order-service --tail=100
```

### Key findings
- [Finding 1]
- [Finding 2]

### Root cause
[Detailed explanation of what caused the incident]

## 5. Resolution

### Immediate fix
```bash
# What was done to restore service
kubectl rollout restart deployment/order-service -n production
```

### Permanent fix
```yaml
# Changes made to prevent recurrence
```

## 5. Prevention

- [ ] Add monitoring for [specific metric]
- [ ] Update runbook with [new steps]
- [ ] Create alert for [condition]
- [ ] Document in [related guide]

## 6. Post-Mortem

### What went well
- 

### What went wrong
- 

### Action items
| # | Action | Owner | Due | Status |
|---|--------|-------|-----|--------|
| 1 | | | | |

## 7. Related Tasks

- TASK-XXX: [related task]
- TASK-XXX: [related task]
