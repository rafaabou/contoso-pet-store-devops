# CIS Benchmark Complete Guide

## Table of Contents

1. What Is CIS Benchmark
2. Why Use CIS Benchmark
3. Architecture Overview
4. Installation and Setup
5. Core Concepts
6. Usage Guide
7. CIS Benchmarks for Kubernetes
8. CIS Benchmarks for Linux
9. CIS Benchmarks for Docker
10. Integration with Compliance Tools
11. Security
12. Troubleshooting
13. Tips and Best Practices
14. Command Reference
15. Configuration Reference
16. Real-World Examples
17. Further Reading

---

## 1. What Is CIS Benchmark

The Center for Internet Security (CIS) provides consensus-based best practice benchmarks for securing IT systems and data. CIS Benchmarks are internationally recognized as prescriptive configuration guidelines developed through a global community of IT professionals and security experts.

### 1.1 Overview

CIS Benchmarks are:
- **Prescriptive Configuration Guidelines**: Step-by-step instructions for secure configuration
- **Consensus-Based**: Developed collaboratively by security experts worldwide
- **Vendor-Agnostic**: Cover multiple platforms and technologies
- **Regularly Updated**: Reviewed and updated regularly to address new threats
- **Auditable**: Provide clear pass/fail criteria for compliance verification

### 1.2 Available CIS Benchmarks

**Operating Systems:**
- CIS Benchmark for Ubuntu Linux
- CIS Benchmark for CentOS/RHEL Linux
- CIS Benchmark for Debian Linux
- CIS Benchmark for Windows Server
- CIS Benchmark for macOS

**Containers and Orchestration:**
- CIS Benchmark for Kubernetes
- CIS Benchmark for Docker
- CIS Benchmark for Docker EE
- CIS Benchmark for Amazon EKS
- CIS Benchmark for Azure AKS
- CIS Benchmark for Google GKE

**Cloud Platforms:**
- CIS Benchmark for AWS Foundations
- CIS Benchmark for Azure Foundations
- CIS Benchmark for Google Cloud Platform
- CIS Benchmark for Office 365

**Applications:**
- CIS Benchmark for Apache HTTP Server
- CIS Benchmark for NGINX
- CIS Benchmark for PostgreSQL
- CIS Benchmark for MySQL

### 1.3 Key Features

- **Comprehensive Coverage**: 100+ benchmarks for different technologies
- **Clear Remediation Steps**: Detailed instructions for fixing non-compliant settings
- **Automation Support**: Integration with tools like kube-bench, Docker Bench Security
- **Scoring System**: Quantitative compliance measurement
- **Regular Updates**: Quarterly reviews and updates
- **Free Availability**: Basic benchmarks available at no cost

---

## 2. Why Use CIS Benchmark

### 2.1 Benefits

**Security Hardening**
- Reduce attack surface through proper configuration
- Implement defense-in-depth strategies
- Follow industry-accepted security practices

**Compliance**
- Meet regulatory requirements (PCI DSS, HIPAA, SOC 2, GDPR)
- Pass security audits and assessments
- Demonstrate due diligence in security practices

**Risk Reduction**
- Identify and remediate security misconfigurations
- Reduce likelihood of successful attacks
- Minimize impact of security incidents

**Standardization**
- Create consistent security configurations across environments
- Enable reproducible security posture
- Facilitate knowledge sharing across teams

### 2.2 Use Cases

**Enterprise Organizations**
- Meet compliance requirements for regulatory frameworks
- Standardize security configurations across infrastructure
- Pass security audits and assessments

**Cloud-Native Applications**
- Secure Kubernetes clusters and Docker containers
- Implement DevSecOps practices
- Validate infrastructure-as-code configurations

**Small and Medium Businesses**
- Implement security best practices without dedicated security teams
- Meet customer and partner security requirements
- Reduce risk of security incidents

**Managed Service Providers**
- Demonstrate security controls to clients
- Meet service level agreements for security
- Comply with industry regulations

### 2.3 Prerequisites

- Understanding of system administration concepts
- Access to target systems for scanning
- Administrative/root privileges for remediation
- Familiarity with security best practices
- Time allocated for implementation and testing

---

## 3. Architecture Overview

### 3.1 CIS Benchmark Structure

```
+---------------------------------------------------+
|                CIS Benchmark Framework              |
|  +----------+  +----------+  +------------------+ |
|  | Control  |  | Profile  |  | Configuration    | |
|  | Families |  | Levels   |  | Settings         | |
|  +----------+  +----------+  +------------------+ |
|         |              |              |             |
|         +--------------+--------------+             |
|                        |                            |
|              +---------v---------+                  |
|              |   Assessment      |                  |
|              |   Tools           |                  |
|              | (kube-bench,      |                  |
|              |  Docker Bench)    |                  |
|              +-------------------+                  |
+--------------------------+-------------------------+
                           |
              +------------+------------+
              |            |            |
       +------v------+ +--v------+ +--v------+
       | Manual      | | Auto-   | | Cloud   |
       | Review      | | mated   | | Provider|
       |             | | Scans   | | Tools   |
       +-------------+ +---------+ +---------+
```

### 3.2 Benchmark Components

**Control Families**
- Group of related security controls
- Organized by technology and function
- Example: Kubernetes Benchmark has control families for Master, Worker, Policies

**Profile Levels**
- Level 1: Basic security hygiene (recommended for all)
- Level 2: Defense-in-depth (for sensitive systems)
- Level 3: Maximum security (for high-security environments)

**Configuration Settings**
- Specific system settings that need to be verified
- Clear pass/fail criteria
- Remediation instructions for non-compliant settings

**Assessment Tools**
- Automated scanners for different platforms
- Manual verification procedures
- Reporting and scoring capabilities

### 3.3 Benchmark Workflow

```
1. Select Benchmark -> Choose appropriate benchmark for technology
2. Define Scope -> Determine which systems to assess
3. Run Assessment -> Execute automated or manual scans
4. Analyze Results -> Review findings and prioritize remediation
5. Remediate -> Apply recommended configurations
6. Re-Assess -> Verify remediation was successful
7. Document -> Record compliance status and exceptions
8. Monitor -> Continuously monitor for configuration drift
```

---

## 4. Installation and Setup

### 4.1 kube-bench (Kubernetes CIS Benchmark)

**Installation via Binary**

```bash
# Download kube-bench
curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.7.0/kube-bench_0.7.0_linux_amd64.tar.gz -o kube-bench.tar.gz

# Extract
tar -xzf kube-bench.tar.gz

# Move to PATH
sudo mv kube-bench /usr/local/bin/

# Verify installation
kube-bench version
```

**Installation via Docker**

```bash
# Pull the image
docker pull aquasec/kube-bench:latest

# Run kube-bench
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -v /usr/lib:/usr/lib:ro   aquasec/kube-bench:latest
```

**Installation via Helm (for running in cluster)**

```bash
# Add Helm repository
helm repo add kube-bench https://aquasecurity.github.io/helm-charts
helm repo update

# Install kube-bench
helm install kube-bench kube-bench/kube-bench \
  --namespace kube-bench \
  --create-namespace
```

### 4.2 Docker Bench Security

**Installation**

```bash
# Clone the repository
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security

# Make the script executable
chmod +x docker-bench-security.sh

# Run the benchmark
sudo ./docker-bench-security.sh
```

**Installation via Docker**

```bash
# Run Docker Bench Security
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /etc:/etc:ro \
  --label docker_bench_security \
  docker/docker-bench-security
```

### 4.3 CIS-CAT Pro (CIS Official Tool)

**Installation**

```bash
# Download CIS-CAT Pro from CIS website
# Requires CIS WorkBench account

# Extract
unzip CIS-CAT_Pro_v4.zip

# Run installer
./install.sh

# Follow installation wizard
```

### 4.4 Lynis (Linux Security Auditing)

**Installation**

```bash
# Debian/Ubuntu
sudo apt-get install lynis

# CentOS/RHEL
sudo yum install lynis

# From source
git clone https://github.com/CISOfy/lynis.git
cd lynis
sudo ./lynis audit system
```

---

## 5. Core Concepts

### 5.1 Control Families

**Kubernetes Benchmark Control Families**

| ID | Control Family | Description |
|----|---------------|-------------|
| 1.x | Master Components | API server, controller manager, scheduler, etcd |
| 2.x | Worker Components | kubelet, kube-proxy, container runtime |
| 3.x | Policies | RBAC, pod security, network policies |
| 4.x | Managed Services | Cloud provider-specific configurations |

**Linux Benchmark Control Families**

| ID | Control Family | Description |
|----|---------------|-------------|
| 1.x | Initial Setup | Filesystem, software updates, secure boot |
| 2.x | Services | Running services, inetd services |
| 3.x | Network Configuration | Network parameters, firewall |
| 4.x | Logging and Auditing | Auditd, rsyslog, journald |
| 5.x | Access, Authentication | PAM, SSH, user accounts |
| 6.x | System Maintenance | File permissions, user/group settings |

### 5.2 Profile Levels

**Level 1 - Basic Security Hygiene**
- Recommended for all environments
- Minimal impact on system functionality
- Quick to implement
- Addresses most common attack vectors

**Level 2 - Defense-in-Depth**
- Recommended for sensitive systems
- May impact system functionality
- Requires thorough testing before implementation
- Provides additional security layers

**Level 3 - Maximum Security**
- Recommended for high-security environments
- Significant impact on system functionality
- Requires extensive testing and validation
- Maximum protection against advanced threats

### 5.3 Scoring System

```yaml
scoring:
  total_controls: 100
  passed: 85
  failed: 10
  not_applicable: 5
  
  score_percentage: 85%
  
  ratings:
    - score: "0-49%"
      rating: "Low"
      description: "Significant security gaps"
    - score: "50-79%"
      rating: "Medium"
      description: "Moderate security posture"
    - score: "80-94%"
      rating: "High"
      description: "Good security posture"
    - score: "95-100%"
      rating: "Excellent"
      description: "Strong security posture"
```

### 5.4 Exception Handling

```yaml
exceptions:
  - control: "4.1.1.1"
    reason: "Legacy application requires NIS"
    approver: "security-team"
    expiry: "2024-12-31"
    documentation: "Legacy financial system migration planned for Q4"
  
  - control: "5.2.10"
    reason: "Password complexity breaks user workflow"
    approver: "ciso"
    expiry: "2024-06-30"
    documentation: "MFA implemented as compensating control"
```

---

## 6. Usage Guide

### 6.1 Running kube-bench

**Basic Scan**

```bash
# Run all checks
kube-bench run

# Run specific control family
kube-bench run --targets master
kube-bench run --targets worker
kube-bench run --targets policies

# Run specific check
kube-bench run --check 1.1.1
```

**Output Formats**

```bash
# JSON output
kube-bench run --json > results.json

# JUnit XML output
kube-bench run --junit > results.xml

# CSV output
kube-bench run --csv > results.csv
```

**Remediation**

```bash
# Show remediation instructions
kube-bench run --targets master --remediate

# Auto-remediate (use with caution)
kube-bench run --targets master --remediate --apply
```

### 6.2 Running Docker Bench Security

**Basic Scan**

```bash
# Run all checks
sudo ./docker-bench-security.sh

# Run specific group
sudo ./docker-bench-security.sh -g check_1
sudo ./docker-bench-security.sh -g check_2

# Run specific test
sudo ./docker-bench-security.sh -t 1.1.1
```

**Output Options**

```bash
# JSON output
sudo ./docker-bench-security.sh -l /var/log/docker-bench-security.log

# Manual review mode
sudo ./docker-bench-security.sh -m auto
```

### 6.3 Running Lynis

**Basic Scan**

```bash
# Run full audit
sudo lynis audit system

# Run specific tests
sudo lynis audit system --tests-from-group "firewalls"

# Quick scan
sudo lynis audit system --quick
```

**Output and Reporting**

```bash
# View report
cat /var/log/lynis.log

# Show hardening index
sudo lynis show details

# Show warnings
sudo lynis show warnings
```

### 6.4 Interpreting Results

**kube-bench Output Example**

```
[INFO] 4 Worker Node Security Configuration
[WARN] 4.2.1 Ensure that the kubelet configuration file has file permissions set to 644 or more restrictive
[PASS] 4.2.2 Ensure that the kubelet configuration file ownership is set to root:root
[FAIL] 4.2.3 Ensure that the --anonymous-auth argument is set to false
[INFO] 4.2.3 remediation: If the file exists, set --anonymous-auth=false
```

**Severity Levels**

- **PASS**: Control is compliant
- **WARN**: Control requires manual review
- **FAIL**: Control is non-compliant
- **INFO**: Informational message
- **SKIP**: Control was skipped

---

## 7. CIS Benchmarks for Kubernetes

### 7.1 Master Components

**API Server**

```bash
# 1.1.1 Ensure that the --anonymous-auth argument is set to false
# File: /etc/kubernetes/manifests/kube-apiserver.yaml
# --anonymous-auth=false

# 1.1.2 Ensure that the --basic-auth-file argument is not set
# Remove --basic-auth-file argument if present

# 1.1.3 Ensure that the --token-auth-file argument is not set
# Remove --token-auth-file argument if present

# 1.1.4 Ensure that the --kubelet-https argument is set to true
# --kubelet-https=true

# 1.1.5 Ensure that the --kubelet-client-certificate and --kubelet-client-key arguments are set
# --kubelet-client-certificate=/path/to/cert
# --kubelet-client-key=/path/to/key
```

**Controller Manager**

```bash
# 1.2.1 Ensure that the --terminated-pod-gc-threshold argument is set to 100
# --terminated-pod-gc-threshold=100

# 1.2.2 Ensure that the --profiling argument is set to false
# --profiling=false

# 1.2.3 Ensure that the --use-service-account-credentials argument is set to true
# --use-service-account-credentials=true
```

**Scheduler**

```bash
# 1.3.1 Ensure that the --profiling argument is set to false
# --profiling=false
```

**etcd**

```bash
# 1.4.1 Ensure that the --cert-file and --key-file arguments are set as appropriate
# --cert-file=/path/to/cert
# --key-file=/path/to/key

# 1.4.2 Ensure that the --client-cert-auth argument is set to true
# --client-cert-auth=true

# 1.4.3 Ensure that the --auto-tls argument is not set to true
# Do not use --auto-tls=true
```

### 7.2 Worker Components

**kubelet**

```bash
# 4.2.1 Ensure that the kubelet configuration file has file permissions set to 644
chmod 644 /var/lib/kubelet/config.yaml

# 4.2.2 Ensure that the kubelet configuration file ownership is set to root:root
chown root:root /var/lib/kubelet/config.yaml

# 4.2.3 Ensure that the --anonymous-auth argument is set to false
# anonymousAuthentication:
#   anonymous: false

# 4.2.4 Ensure that the --authorization-mode argument is set to Webhook
# authorizationMode: Webhook

# 4.2.5 Ensure that the --client-ca-file argument is set as appropriate
# clientCAFile: /path/to/ca.crt
```

**kube-proxy**

```bash
# 4.3.1 Ensure that a pickle is set for kube-proxy
# metricsBindAddress: "0.0.0.0:10249"
```

### 7.3 Policies

**RBAC and Service Accounts**

```bash
# 5.1.1 Ensure that the cluster-admin role is only used where required
# Review ClusterRoleBindings for cluster-admin

# 5.1.2 Minimize the use of wildcards
# Review ClusterRoles for wildcards in apiGroups, resources, and verbs

# 5.1.3 Minimize access to secrets
# Review ClusterRoles and Roles that grant access to secrets

# 5.1.4 Ensure that the default service account is not used
automountServiceAccountToken: false

# 5.1.5 Ensure that Service Account Tokens are not mounted automatically
automountServiceAccountToken: false
```

**Pod Security**

```yaml
# 5.2.1 Minimize the admission of privileged containers
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
```

**Network Policies**

```yaml
# 5.3.2 Ensure that all namespaces have Network Policies defined
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

---

## 8. CIS Benchmarks for Linux

### 8.1 Initial Setup

```bash
# 1.1.1.1 Ensure mounting of cramfs filesystems is disabled
echo "install cramfs /bin/true" >> /etc/modprobe.d/cramfs.conf

# 1.1.1.2 Ensure mounting of freevxfs filesystems is disabled
echo "install freevxfs /bin/true" >> /etc/modprobe.d/freevxfs.conf

# 1.1.1.3 Ensure mounting of hfs filesystems is disabled
echo "install hfs /bin/true" >> /etc/modprobe.d/hfs.conf

# 1.1.1.4 Ensure mounting of hfsplus filesystems is disabled
echo "install hfsplus /bin/true" >> /etc/modprobe.d/hfsplus.conf

# 1.1.1.5 Ensure mounting of udf filesystems is disabled
echo "install udf /bin/true" >> /etc/modprobe.d/udf.conf

# 1.1.2 Ensure /tmp is a separate partition
# Configure /tmp in fstab

# 1.1.3 Ensure /tmp nodev option is set
# Add nodev option to /tmp in fstab

# 1.1.4 Ensure /tmp nosuid option is set
# Add nosuid option to /tmp in fstab

# 1.1.5 Ensure /tmp noexec option is set
# Add noexec option to /tmp in fstab
```

### 8.2 Services

```bash
# 2.1.1 Ensure NIS is not installed
apt-get remove -y nis

# 2.1.2 Ensure rsh server is not installed
apt-get remove -y rsh-server

# 2.1.3 Ensure rsh client is not installed
apt-get remove -y rsh-client

# 2.1.4 Ensure NIS client is not installed
apt-get remove -y nis

# 2.2.1 Ensure time synchronization is in use
apt-get install -y chrony
systemctl enable chrony
systemctl start chrony

# 2.2.2 Ensure an NTP server is configured
# Edit /etc/chrony/chrony.conf
# server 0.pool.ntp.org iburst
```

### 8.3 Network Configuration

```bash
# 3.1.1 Ensure IP forwarding is disabled
echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 0" >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv6.conf.all.forwarding=0

# 3.1.2 Ensure packet redirect sending is disabled
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0

# 3.2.1 Ensure source routed packet acceptance is disabled
echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0

# 3.2.2 Ensure ICMP redirects are not accepted
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
```

### 8.4 Logging and Auditing

```bash
# 4.1.1.1 Ensure auditd is installed
apt-get install -y auditd

# 4.1.1.2 Ensure auditd service is enabled
systemctl enable auditd

# 4.1.1.3 Ensure audit log storage size is configured
# Edit /etc/audit/auditd.conf
# max_log_file = 50

# 4.1.1.4 Ensure audit logs are not automatically deleted
# Edit /etc/audit/auditd.conf
# max_log_file_action = keep_logs

# 4.1.2 Ensure audit log storage directory is permissions are set
chmod 750 /var/log/audit
chown root:adm /var/log/audit
```

### 8.5 Access, Authentication, and Authorization

```bash
# 5.1.1 Ensure cron daemon is enabled
systemctl enable cron

# 5.1.2 Ensure permissions on /etc/crontab are configured
chmod 600 /etc/crontab
chown root:root /etc/crontab

# 5.1.3 Ensure permissions on /etc/cron.hourly are configured
chmod 700 /etc/cron.hourly
chown root:root /etc/cron.hourly

# 5.1.4 Ensure permissions on /etc/cron.daily are configured
chmod 700 /etc/cron.daily
chown root:root /etc/cron.daily

# 5.1.5 Ensure permissions on /etc/cron.weekly are configured
chmod 700 /etc/cron.weekly
chown root:root /etc/cron.weekly

# 5.1.6 Ensure permissions on /etc/cron.monthly are configured
chmod 700 /etc/cron.monthly
chown root:root /etc/cron.monthly

# 5.1.7 Ensure permissions on /etc/cron.d are configured
chmod 700 /etc/cron.d
chown root:root /etc/cron.d

# 5.2.1 Ensure password creation requirements are configured
# Edit /etc/security/pwquality.conf
# minlen = 14
# dcredit = -1
# ucredit = -1
# ocredit = -1
# lcredit = -1

# 5.2.2 Ensure lockout for failed password attempts is configured
# Edit /etc/pam.d/common-auth
# auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900

# 5.2.3 Ensure password hashing algorithm is SHA512
# Edit /etc/login.defs
# ENCRYPT_METHOD SHA512
```

---

## 9. CIS Benchmarks for Docker

### 9.1 Host Configuration

```bash
# 1.1.1 Ensure a separate partition for containers has been created
# Create /var/lib/docker on a separate partition

# 1.1.2 Ensure only trusted users are allowed to control Docker daemon
usermod -aG docker <trusted_user>

# 1.1.3 Ensure auditing is configured for Docker files and directories
# /var/lib/docker
# /etc/docker
# docker.service
# docker.socket
# /etc/default/docker
# /etc/docker/daemon.json
# /etc/containerd/config.toml
# /etc/docker/certs.d
```

### 9.2 Docker Daemon Configuration

```bash
# 2.1 Ensure the Docker socket is not used by containers
# Do not mount Docker socket inside containers

# 2.2 Ensure network traffic between containers is restricted
# Enable inter-container communication only when necessary

# 2.3 Ensure that logging level is set to info
# Edit /etc/docker/daemon.json
# { "log-level": "info" }

# 2.4 Ensure that Go seccomp profile is not disabled
# Default seccomp profile should be enabled

# 2.5 Ensure that experimental features are not enabled in production
# Do not use --experimental flag
```

### 9.3 Docker Daemon Configuration Files

```bash
# 3.1 Ensure permissions on docker.service are set correctly
chmod 644 /lib/systemd/system/docker.service
chown root:root /lib/systemd/system/docker.service

# 3.2 Ensure permissions on docker.socket are set correctly
chmod 644 /lib/systemd/system/docker.socket
chown root:root /lib/systemd/system/docker.socket

# 3.3 Ensure permissions on /etc/docker are set correctly
chmod 755 /etc/docker
chown root:root /etc/docker

# 3.4 Ensure permissions on containerd.sock are set correctly
chmod 660 /run/containerd/containerd.sock
chown root:root /run/containerd/containerd.sock
```

### 9.4 Container Images and Build File

```bash
# 4.1 Ensure that a user for the container has been created
# Create Dockerfile with USER directive

# 4.2 Ensure that containers use only trusted base images
# Use verified images from official registries

# 4.3 Ensure that unnecessary packages are not installed in containers
# Minimize packages in Dockerfile

# 4.4 Ensure that HEALTHCHECK instructions have been added to the container image
# Add HEALTHCHECK instruction in Dockerfile
```

### 9.5 Container Runtime

```bash
# 5.1 Ensure that, if applicable, SELinux or AppArmor is enabled
# AppArmor or SELinux should be enabled

# 5.2 Ensure that container rootfs is not mounted as read-only
# Do not use --read-only unless necessary

# 5.3 Ensure that Docker socket is not mounted inside any containers
# Do not mount Docker socket inside containers

# 5.4 Ensure that privileged containers are not used
# Do not run containers with --privileged flag

# 5.5 Ensure sensitive host system containers are not created
# Do not mount /proc, /sys, etc. inside containers
```

---

## 10. Integration with Compliance Tools

### 10.1 Integration with Prometheus

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'kube-bench'
    static_configs:
      - targets: ['kube-bench:9090']
    metrics_path: '/metrics'
```

### 10.2 Integration with Grafana

```json
{
  "dashboard": {
    "title": "CIS Benchmark Compliance",
    "panels": [
      {
        "title": "Compliance Score",
        "targets": [
          {
            "expr": "kube_bench_score_total",
            "legendFormat": "{{benchmark}}"
          }
        ]
      },
      {
        "title": "Failed Controls",
        "targets": [
          {
            "expr": "kube_bench_fail_total",
            "legendFormat": "{{control_family}}"
          }
        ]
      }
    ]
  }
}
```

### 10.3 Integration with CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - security

cis-benchmark:
  stage: security
  image: aquasec/kube-bench:latest
  script:
    - kube-bench run --json > results.json
    - |
      SCORE=$(cat results.json | jq '.score')
      if [ $SCORE -lt 80 ]; then
        echo "Compliance score $SCORE is below threshold"
        exit 1
      fi
  artifacts:
    paths:
      - results.json
    when: always
```

### 10.4 Integration with Terraform

```hcl
# terraform CIS benchmark compliance check
resource "null_resource" "cis_compliance_check" {
  provisioner "local-exec" {
    command = "kube-bench run --json > cis-results.json"
  }

  triggers = {
    always_run = timestamp()
  }
}

output "compliance_score" {
  value = "Check cis-results.json for details"
}
```

---

## 11. Security

### 11.1 Security Best Practices

**Regular Scanning**
- Schedule regular CIS benchmark scans
- Monitor for configuration drift
- Track compliance trends over time

**Remediation Process**
- Prioritize critical findings
- Test remediation in staging first
- Document exceptions and approvals
- Verify remediation with follow-up scans

**Access Control**
- Restrict access to scan results
- Protect remediation scripts
- Audit configuration changes

**Documentation**
- Document all exceptions
- Maintain compliance evidence
- Track remediation progress

### 11.2 Compliance Frameworks

**PCI DSS**
- CIS Benchmarks provide foundational security controls
- Regular scans required for compliance
- Documentation of compliance is mandatory

**HIPAA**
- Technical safeguards include access controls
- Audit logging is required
- Regular security assessments needed

**SOC 2**
- Security controls must be implemented
- Regular testing of controls required
- Evidence of compliance must be maintained

**GDPR**
- Security measures must be implemented
- Regular assessment of security posture
- Documentation of security controls

---

## 12. Troubleshooting

### 12.1 Common Issues and Solutions

**Issue 1: kube-bench not finding correct config**

```bash
# Check kubeconfig location
kube-bench run --kubeconfig /etc/kubernetes/admin.conf

# Verify config file exists
ls -la /etc/kubernetes/admin.conf

# Fix: Specify correct kubeconfig path
```

**Issue 2: Permission denied errors**

```bash
# Run with appropriate privileges
sudo kube-bench run

# Check RBAC permissions
kubectl auth can-i get pods --as=system:serviceaccount:kube-system:kube-bench

# Fix: Ensure proper RBAC or run as root
```

**Issue 3: Docker Bench not detecting containers**

```bash
# Verify Docker daemon is running
systemctl status docker

# Check Docker socket permissions
ls -la /var/run/docker.sock

# Fix: Ensure Docker daemon is running and socket is accessible
```

**Issue 4: Scan results not matching expected controls**

```bash
# Verify benchmark version matches Kubernetes version
kube-bench version

# Check benchmark targets
kube-bench run --targets master,worker,policies

# Fix: Use correct benchmark version for your platform
```

**Issue 5: High false positive rate**

```bash
# Review control descriptions carefully
kube-bench run --json | jq '.controls[].checks[] | select(.status == "FAIL")'

# Document exceptions for valid configurations
# Fix: Review each finding and document legitimate exceptions
```

**Issue 6: Scan performance issues**

```bash
# Run specific control families instead of full scan
kube-bench run --targets master

# Reduce scan scope
kube-bench run --check 1.1.1

# Fix: Optimize scan scope based on requirements
```

**Issue 7: Missing benchmark controls**

```bash
# Check benchmark version and coverage
kube-bench run --json | jq '.controls[].id'

# Use manual checks for missing controls
# Fix: Supplement with manual verification for uncovered areas
```

**Issue 8: Remediation breaks application**

```bash
# Test remediation in staging first
# Rollback changes if issues occur
kubectl rollout undo deployment/affected-service

# Fix: Always test remediation before applying to production
```

**Issue 9: Automated scan fails in CI/CD**

```bash
# Check CI/CD runner permissions
# Verify Docker-in-Docker configuration
# Fix: Ensure proper permissions and Docker configuration in CI/CD
```

**Issue 10: Benchmark updates cause scan failures**

```bash
# Pin benchmark version
kube-bench run --version 0.7.0

# Update scan scripts for new benchmark versions
# Fix: Test new benchmark versions before deploying to production
```

**Issue 11: False negatives in cloud environments**

```bash
# Use cloud-specific benchmarks
kube-bench run --targets master --cloud-provider aws

# Verify cloud provider configuration
# Fix: Use appropriate cloud-specific benchmark controls
```

**Issue 12: Scan results not persisting**

```bash
# Configure persistent storage for results
# Use external database for compliance tracking
# Fix: Implement proper data persistence for audit trail
```

**Issue 13: Cannot access scan results remotely**

```bash
# Configure secure API access
# Implement proper authentication
# Fix: Set up secure remote access to scan results
```

**Issue 14: Multiple benchmark versions causing confusion**

```bash
# Standardize on specific benchmark versions
# Document benchmark version requirements
# Fix: Implement version control for benchmarks
```

**Issue 15: Custom configurations not covered**

```bash
# Extend benchmarks with custom controls
# Document custom configurations
# Fix: Create custom controls for organization-specific requirements
```

---

## 13. Tips and Best Practices

### 13.1 Implementation Strategy

1. **Start with Level 1**: Begin with basic security hygiene controls
2. **Prioritize by risk**: Focus on critical controls first
3. **Test in staging**: Validate changes before production
4. **Document exceptions**: Record and approve all exceptions
5. **Regular reviews**: Schedule periodic compliance reviews

### 13.2 Scanning Best Practices

6. **Automate scans**: Schedule regular automated scans
7. **Monitor trends**: Track compliance scores over time
8. **Set thresholds**: Define minimum compliance requirements
9. **Alert on drift**: Notify when compliance drops below threshold
10. **Integrate with CI/CD**: Include compliance checks in deployment pipeline

### 13.3 Remediation Best Practices

11. **Prioritize findings**: Address critical findings first
12. **Test thoroughly**: Validate changes in non-production
13. **Rollback plan**: Have rollback procedures ready
14. **Verify remediation**: Run follow-up scans after remediation
15. **Document changes**: Record all configuration changes

### 13.4 Organizational Best Practices

16. **Assign ownership**: Designate compliance owners for each control
17. **Regular training**: Train teams on CIS benchmarks
18. **Share knowledge**: Document lessons learned
19. **Continuous improvement**: Regularly review and update processes
20. **Executive visibility**: Report compliance status to leadership

### 13.5 Technical Best Practices

21. **Version control**: Store benchmark configurations in version control
22. **Infrastructure-as-Code**: Implement compliance as code
23. **Immutable infrastructure**: Use immutable infrastructure patterns
24. **Defense-in-depth**: Layer security controls
25. **Least privilege**: Implement principle of least privilege

---

## 14. Command Reference

### 14.1 kube-bench Commands

```bash
# Basic Commands
kube-bench version                                      # Show version
kube-bench run                                           # Run all checks
kube-bench run --targets master                          # Run master checks
kube-bench run --targets worker                          # Run worker checks
kube-bench run --targets policies                        # Run policy checks

# Output Formats
kube-bench run --json                                   # JSON output
kube-bench run --junit                                  # JUnit XML output
kube-bench run --csv                                    # CSV output

# Specific Checks
kube-bench run --check 1.1.1                            # Run specific check
kube-bench run --targets master --check 1.1              # Run specific control

# Remediation
kube-bench run --targets master --remediate              # Show remediation
kube-bench run --targets master --remediate --apply      # Auto-remediate

# Configuration
kube-bench run --kubeconfig /path/to/kubeconfig         # Specify kubeconfig
kube-bench run --json-config /path/to/config.json       # Use config file
```

### 14.2 Docker Bench Security Commands

```bash
# Basic Commands
sudo ./docker-bench-security.sh                         # Run all checks
sudo ./docker-bench-security.sh -g check_1              # Run specific group
sudo ./docker-bench-security.sh -t 1.1.1                # Run specific test

# Output Options
sudo ./docker-bench-security.sh -l /var/log/docker-bench.log  # Log to file
sudo ./docker-bench-security.sh -m auto                 # Manual mode

# Specific Options
sudo ./docker-bench-security.sh -c docker_host         # Check specific config
sudo ./docker-bench-security.sh -e excluding           # Exclude tests
```

### 14.3 Lynis Commands

```bash
# Basic Commands
sudo lynis audit system                                  # Full audit
sudo lynis audit system --quick                         # Quick scan
sudo lynis audit system --tests-from-group "firewalls"  # Specific tests

# Reporting
sudo lynis show details                                  # Show details
sudo lynis show warnings                                 # Show warnings
sudo lynis show suggestions                              # Show suggestions

# Configuration
sudo lynis audit system --logfile /var/log/lynis.log   # Specify log file
sudo lynis audit system --report-file /tmp/report.txt  # Specify report file
```

---

## 15. Configuration Reference

### 15.1 kube-bench Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| --kubeconfig | string | Path to kubeconfig file | ~/.kube/config |
| --targets | string | Targets to scan | master,worker,policies |
| --check | string | Specific check to run | - |
| --json | bool | Output JSON | false |
| --junit | bool | Output JUnit XML | false |
| --csv | bool | Output CSV | false |
| --remediate | bool | Show remediation | false |
| --json-config | string | JSON config file | - |

### 15.2 Docker Bench Security Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| -g | string | Group to check | all |
| -t | string | Specific test | all |
| -l | string | Log file path | stdout |
| -m | string | Manual mode | auto |
| -c | string | Config file | - |
| -e | string | Exclude tests | - |

### 15.3 CIS Benchmark Severity Mapping

| CIS Level | kube-bench | Lynis | Description |
|-----------|------------|-------|-------------|
| Level 1 | PASS/WARN | OK/WARNING | Basic security hygiene |
| Level 2 | FAIL | SUGGESTION | Defense-in-depth |
| Level 3 | SKIP | - | Maximum security |

---

## 16. Real-World Examples

### 16.1 Kubernetes Production Cluster

```bash
# Run full CIS benchmark scan
kube-bench run --json > cis-results-$(date +%Y%m%d).json

# Parse results
PASS=$(cat cis-results-$(date +%Y%m%d).json | jq '.summary.pass')
FAIL=$(cat cis-results-$(date +%Y%m%d).json | jq '.summary.fail')
TOTAL=$((PASS + FAIL))
SCORE=$((PASS * 100 / TOTAL))

echo "Compliance Score: $SCORE% ($PASS/$TOTAL)"

# Alert if below threshold
if [ $SCORE -lt 80 ]; then
  echo "ALERT: Compliance score below threshold"
  # Send notification
fi
```

### 16.2 Docker Environment

```bash
# Run Docker Bench Security
sudo ./docker-bench-security.sh -l /var/log/docker-bench.log

# Parse results
PASS=$(grep -c "PASS" /var/log/docker-bench.log)
WARN=$(grep -c "WARN" /var/log/docker-bench.log)
FAIL=$(grep -c "FAIL" /var/log/docker-bench.log)

echo "Results: $PASS PASS, $WARN WARN, $FAIL FAIL"

# Generate report
cat <<EOF > docker-compliance-report.txt
Docker CIS Benchmark Compliance Report
Date: $(date)
Results:
  - PASS: $PASS
  - WARN: $WARN
  - FAIL: $FAIL
EOF
```

### 16.3 Linux Server Hardening

```bash
# Run Lynis audit
sudo lynis audit system --quick --logfile /var/log/lynis.log

# Extract hardening index
HARDENING_INDEX=$(grep "hardening_index" /var/log/lynis.log | awk '{print $3}')

echo "Hardening Index: $HARDENING_INDEX"

# Identify critical findings
sudo lynis show warnings | grep -i "critical" > critical-findings.txt

# Generate remediation script
cat <<EOF > remediate.sh
#!/bin/bash
# CIS Benchmark Remediation Script
$(sudo lynis show suggestions)
EOF
chmod +x remediate.sh
```

### 16.4 CI/CD Pipeline Integration

```yaml
# .github/workflows/cis-benchmark.yml
name: CIS Benchmark Compliance

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  cis-benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run kube-bench
        uses: aquasecurity/kube-bench-action@main
        with:
          json: results.json
      
      - name: Check compliance score
        run: |
          SCORE=$(cat results.json | jq '.summary.pass / (.summary.pass + .summary.fail) * 100')
          if (( $(echo "$SCORE < 80" | bc -l) )); then
            echo "Compliance score $SCORE% is below threshold"
            exit 1
          fi
          echo "Compliance score: $SCORE%"
      
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: cis-benchmark-results
          path: results.json
```

---

## 17. Further Reading

### 17.1 Official Documentation

- CIS Benchmark Website: https://www.cisecurity.org/cis-benchmarks
- CIS WorkBench: https://workbench.cisecurity.org
- kube-bench: https://github.com/aquasecurity/kube-bench
- Docker Bench Security: https://github.com/docker/docker-bench-security
- Lynis: https://cisofy.com/documentation/lynis/

### 17.2 Books and Guides

- "CIS Controls Implementation Guide"
- "Hardening Linux Systems" by Steve SHIELDS
- "Kubernetes Security" by Liz Rice, Michael Hausenblas
- "Container Security" by Liz Rice

### 17.3 Community Resources

- CIS Community: https://community.cisecurity.org
- Kubernetes Security: https://kubernetes.io/docs/concepts/security/
- Docker Security: https://docs.docker.com/engine/security/

### 17.4 Related Tools

- kube-bench: https://github.com/aquasecurity/kube-bench
- kube-hunter: https://github.com/aquasecurity/kube-hunter
- Trivy: https://github.com/aquasecurity/trivy
- Falco: https://falco.org

### 17.5 Blog Posts and Tutorials

- Getting Started with CIS Benchmarks
- Implementing CIS Benchmarks in Kubernetes
- Automating CIS Compliance with kube-bench
- Docker Security Best Practices

---

*Last updated: 2026*
