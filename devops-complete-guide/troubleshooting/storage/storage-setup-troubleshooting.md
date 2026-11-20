# Storage Troubleshooting (NFS + MinIO + PostgreSQL + disks)

> Shared-storage home: NFS exports/mounts, MinIO S3, PostgreSQL placement, USB HDD.
> Master log: `../ansible/ansible-setup-troubleshooting.md` (ERRORs 49, 51, 65-minio…,
> C-4/C-5, NFS/MinIO/postgres roles). *Last Updated: 2026-09-10 — NFS serving,
> MinIO live (+Gateway, root rotated to kv/minio, Forgejo OIDC proven with per-user policies), postgres per-container, USB on UUID fstab.*

## 1. Current State (2026-09-09)

| Store | Where | Served as | Notes |
|---|---|---|---|
| NFS server | master (`nfs-kernel-server`) | `/srv/efs/{shared,k3s-volumes,backups,logs}` | exports restricted to `10.195.94.0/24` + Tailscale range, `root_squash` (never `*` + `no_root_squash`) |
| NFS clients | K3s workers ONLY | `/mnt/nfs/*` | privileged containers can NFS-mount; unprivileged (vault/monitoring) get the same paths via Incus disk devices instead |
| MinIO (S3) | master systemd, data `/srv/s3-data` (NVMe) | `:9000` API / `:9001` console + Gateway `s3.*` / `minio.*` | creds in group_vars (lab) → Vault in production; health check = `/minio/health/live` on :9000, not console :9001 |
| PostgreSQL | per-consumer container (sonarqube: PC2 fresh; was PC1 `/srv/rds-data` device) | localhost:5432 | DB passwords in files (`/root/*-db-password`), never regenerated |
| USB HDD 75GB | host `/dev/sdb1-4` (renames!) | `/srv/efs/*` mounts | **UUID fstab + `nofail`** — never `/dev/sdX` |

## 2. How to Install (playbook order = dependency order)

```bash
ansible-playbook playbooks/site-nfs-server.yml -i inventory/hosts.ini   # master: exports restricted to LAN + Tailscale, root_squash
ansible-playbook playbooks/site-nfs-client.yml -i inventory/hosts.ini   # K3s WORKERS ONLY (privileged can mount; unprivileged VMs get Incus disk devices — ERROR 32)
ansible-playbook playbooks/site-minio.yml -i inventory/hosts.ini        # master: pinned binary + systemd + health gate on :9000/API (never :9001 console); Gateway ServiceEntry+VS
ansible-playbook playbooks/site-sonarqube.yml -i inventory/hosts.ini     # includes postgres-local per consumer: stop → move data dir → symlink → chown (block/rescue, ERROR 31 pattern)
```
- Verify per store with §3 commands (exports list, client mounts, `/minio/health/live`, `psql -l`).
- Rollback per store (independent): unexport/remount, stop minio service, restore PG data dir from symlink target.

## 3. The Two Storage Rules (violate these and you get paged)

1. **Privileged-only NFS mounts.** Unprivileged LXC = `Operation not permitted`
   (ERROR 51). Pattern: workers → NFS; other VMs → Incus `disk` devices mapping
   the same host paths.
2. **UUIDs, never device names.** Old USB drives drop and reappear as a
   different `sdX` (ERROR 49). fstab uses `UUID=` + `nofail`; Incus devices use
   stable host *paths* (immune to renames once mounted).

## 3. Verification Commands

```bash
# Host: disk present + mounted by UUID?
lsblk -o NAME,UUID,MOUNTPOINT | grep -E "efs|s3|rds"
mount | grep -E "/srv/efs|/srv/s3"            # rw? (stale mount = EIO on write)
sudo touch /srv/efs/shared/.w && sudo rm /srv/efs/shared/.w && echo HOST_DISK_OK

# NFS server (master): exports + clients
incus exec k3s-master -- bash -c "exportfs -v 2>&1 | head -6; showmount -e localhost"

# NFS clients (workers): mounted?
ansible k3s_workers -m shell -a "mount | grep /mnt/nfs | wc -l" -i inventory/hosts.ini

# MinIO: local + via Gateway
curl -s http://10.195.94.80:9000/minio/health/live
curl -sk -o /dev/null -w "%{http_code}\n" --resolve s3.devops-devsecops.kdns.fr:443:10.195.94.100 https://s3.devops-devsecops.kdns.fr/minio/health/live

# PostgreSQL (per container): running + DB present
incus exec <c> -- sudo -u postgres psql -lqt | cut -d'|' -f1 | grep -i <db>
```

## 4. Error Catalog (condensed)

| # | Symptom | Fix |
|---|---|---|
| C-4 | NFS exports world-readable (`*` + `no_root_squash`) | Restrict to cluster subnets + `root_squash` |
| 49 | `Input/output error` on writes; `/dev/sda` gone | USB dropped, reappeared as `sdb`; lazy-unmount stale, remount by current name, UUID fstab; restart containers holding stale mounts |
| 51 | `mount.nfs: Operation not permitted` (vault/monitoring) | Don't NFS-mount there — Incus disk devices instead; `nfs-client` role targets workers only |
| C-5 | MinIO creds hardcoded `minioadmin/...123` | group_vars now (Vault next); health check on API `:9000/minio/health/live` |
| 67 | postgres `chown EPERM` on mounted disk | privileged container + restart (limits/flags need restart to apply; verify `uid_map`) |
| 70/71 | DB version mismatch / stale artifacts on switches | DROP+CREATE virgin DBs; purge `/tmp` artifacts; verify on-disk versions, not task colors |

## 5. First-Actions Runbook (storage broken?)

1. Host first: `lsblk` (device present?) → `mount` (mounted rw?) → touch-test (writes work?).
2. EIO on write + `ls`/`df` fine ⇒ stale mount from device rename (§4-49).
3. NFS client failing ⇒ privileged? (`cat /proc/self/uid_map`) → server exports? (`showmount -e`) → subnet allowed?
4. MinIO down ⇒ systemd unit? disk full? (`/srv/s3-data` on NVMe).
5. Postgres auth fail ⇒ password file vs actual DB role (reset: file is source of truth on fresh installs; existing data → `ALTER ROLE`).
