# SonarQube Complete Guide

## Table of Contents

1. [What Is SonarQube?](#1-what-is-sonarqube)
2. [Why Use SonarQube?](#2-why-use-sonarqube)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide](#6-usage-guide)
7. [Writing Custom Rules](#7-writing-custom-rules)
8. [Integration](#8-integration)
9. [Security Hardening](#9-security-hardening)
10. [Troubleshooting](#10-troubleshooting)
11. [Tips & Best Practices](#11-tips--best-practices)
12. [Command Reference](#12-command-reference)
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

## 1. What Is SonarQube?

### Plain English Explanation

SonarQube is an open-source platform that automatically inspects your source code for bugs, vulnerabilities, and code quality issues. Think of it as a spell-checker and grammar-corrector for your code — but far more sophisticated. It reads every line of your project, understands the programming language, and flags problems ranging from typos (code smells) to security holes (vulnerabilities) to actual logic errors (bugs).

### Why It Exists

Software teams write thousands of lines of code. No human reviewer can catch every problem in every pull request. SonarQube exists to automate the tedious, error-prone work of code review at scale. It provides a single source of truth for code quality across your entire organization.

### Architecture

SonarQube uses a two-tier architecture:

```
┌─────────────────────┐       ┌─────────────────────┐
│   SonarQube Server  │       │    SonarScanner      │
│   (Web + Compute)   │◄──────│    (Client/Agent)    │
│                     │       │                      │
│  - Web UI           │       │  - Runs on build     │
│  - REST API         │       │  - Analyzes code     │
│  - Compute Engine   │       │  - Sends results     │
│  - Database (PostgreSQL)    │                      │
│  - Elasticsearch    │       │                      │
└─────────────────────┘       └─────────────────────┘
```

- **SonarQube Server**: Central hub that stores results, serves the web UI, and computes quality gates. Requires Java 17+ and PostgreSQL.
- **SonarScanner**: Lightweight client that runs on your CI/CD agent, analyzes source code locally, and uploads results to the server. No database needed.
- **SonarLint**: IDE plugin (VS Code, IntelliJ, Eclipse) that provides real-time feedback as you code. Connects to SonarQube for shared rules.

### Community vs. Commercial Editions

| Feature | Community | Developer | Enterprise | Data Center |
|---------|-----------|-----------|------------|-------------|
| Languages | 20+ | 20+ | 30+ | 30+ |
| Rules | ~2,000 | ~4,000 | ~5,000 | ~5,000 |
| Pull Request decoration | No | Yes | Yes | Yes |
| Security hotspots | No | Yes | Yes | Yes |
| Multi-project reporting | No | No | Yes | Yes |
| High availability | No | No | No | Yes |
| License | LGPL | Commercial | Commercial | Commercial |

---

## 2. Why Use SonarQube?

### Real-World Breaches

- **Heartbleed (CVE-2014-0160)**: A missing bounds check in OpenSSL. Static analysis would have flagged the unchecked buffer read.
- **Equifax Breach (2017)**: Apache Struts vulnerability (CVE-2017-5638) exploited via unvalidated input. SonarQube rules catch unvalidated deserialization patterns.
- **Log4Shell (2021)**: CVE-2021-44228 in Log4j. While primarily a dependency issue, SonarQube detects unsafe JNDI lookups in user-controlled input.

### Compliance Requirements

- **PCI DSS**: Requires secure code review for applications handling cardholder data (Requirement 6.5).
- **HIPAA**: Technical safeguards include information system activity review — SonarQube provides audit trails of code quality.
- **SOC 2**: Security controls must include vulnerability management — SonarQube demonstrates proactive scanning.
- **ISO 27001**: A.14.2.1 requires secure development policies — SonarQube enforces them automatically.

### What Happens Without It

- **Technical debt accumulates silently**: Dead code, duplicated blocks, and complex methods grow unchecked.
- **Security vulnerabilities ship to production**: SQL injection, XSS, and buffer overflows go undetected.
- **Refactoring becomes impossible**: Codebases become too tangled to modify safely.
- **Onboarding new developers takes months**: They can't understand poorly documented, overly complex code.

---

## 3. Installation

### Method 1: Docker (Recommended for Development)

```bash
# Pull the latest Community Edition
docker pull sonarqube:community

# Run with PostgreSQL
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -e SONAR_JDBC_URL=jdbc:postgresql://db:5432/sonarqube \
  -e SONAR_JDBC_USERNAME=sonar \
  -e SONAR_JDBC_PASSWORD=sonar \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:community
```

### Method 2: Docker Compose (Full Stack)

```yaml
# docker-compose.yml
version: '3.8'
services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
      SONAR_WEB_JAVAADDITIONALOPTS: "-Xmx1g -Xms512m"
      SONAR_CE_JAVAADDITIONALOPTS: "-Xmx1g -Xms512m"
      SONAR_SEARCH_JAVAADDITIONALOPTS: "-Xmx512m -Xms256m"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ulimits:
      nofile:
        soft: 131072
        hard: 131072
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/api/system/status"]
      interval: 30s
      timeout: 10s
      retries: 10
      start_period: 120s

  db:
    image: postgres:15
    container_name: sonarqube-db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
    volumes:
      - sonarqube_pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sonar"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  sonarqube_pg_data:
```

```bash
# Launch
docker compose up -d

# Check logs
docker compose logs -f sonarqube

# Wait for "SonarQube is operational"
curl http://localhost:9000/api/system/status
```

### Method 3: Kubernetes with Helm

```bash
# Add the Helm repository
helm repo add sonarqube https://SonarSource.github.io/sonarqube-helm-chart/
helm repo update

# Install with custom values
helm install sonarqube sonarqube/sonarqube \
  --namespace sonarqube \
  --create-namespace \
  --set \
    sonarqubeFolder=sonarqube,\
    persistence.enabled=true,\
    persistence.size=10Gi,\
    postgresql.enabled=true,\
    postgresql.persistence.size=10Gi,\
    postgresql.postgresqlUsername=sonar,\
    postgresql.postgresqlPassword=sonarpass,\
    postgresql.postgresqlDatabase=sonarqube,\
    initPlugins.image=bitnami/kubectl:latest

# Verify
kubectl -n sonarqube get pods
kubectl -n sonarqube logs -f deployment/sonarqube-sonarqube
```

### Method 4: Linux Package (APT/RPM)

```bash
# Ubuntu/Debian
# Install prerequisites
sudo apt-get update
sudo apt-get install -y openjdk-17-jre-headless unzip wget

# Download SonarQube
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.6.0.92111.zip
sudo unzip sonarqube-10.6.0.92111.zip -d /opt/
sudo ln -s /opt/sonarqube-10.6.0.92111 /opt/sonarqube

# Create dedicated user
sudo useradd -r -m -d /opt/sonarqube sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube

# Create systemd service
sudo cat > /etc/systemd/system/sonarqube.service << 'EOF'
[Unit]
Description=SonarQube
After=network.target

[Service]
Type=forking
User=sonarqube
Group=sonarqube
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Restart=on-failure
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube
```

### Method 5: macOS

```bash
# Using Homebrew
brew install openjdk@17
brew install sonarqube

# Start
sonarqube start

# Or using Docker (same as Linux)
docker run -d -p 9000:9000 sonarqube:community
```

### First-Time Setup

1. Open `http://localhost:9000` in your browser
2. Default credentials: `admin` / `admin` (you'll be prompted to change the password)
3. Go to **My Account > Security** and generate a user token
4. Store this token securely — you'll need it for scanner authentication

---

## 4. Configuration

### Server Configuration (sonar.properties)

Located at `$SONARQUBE_HOME/conf/sonar.properties`:

```properties
# ──── Web Server ────
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-Xmx2g -Xms1g

# ──── Compute Engine (background tasks) ────
sonar.ce.javaAdditionalOpts=-Xmx4g -Xms2g

# ──── Elasticsearch ────
sonar.search.javaAdditionalOpts=-Xmx2g -Xms1g

# ──── Database ────
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
sonar.jdbc.username=sonar
sonar.jdbc.password=secure_password_here

# ──── Authentication ────
sonar.security.realm=LDAP
sonar.security.savePasswordInDB=false

# ──── Notifications ────
sonar.notifi.email.smtp.url=smtp://smtp.example.com:587
sonar.notifi.email.from=sonarqube@example.com
sonar.notifi.email.subjectPrefix=[SonarQube]
```

### System Configuration via UI

Navigate to **Administration > Configuration > General**:

| Setting | Description | Default |
|---------|-------------|---------|
| General > Server base URL | Public URL for links in emails/notifications | `http://localhost:9000` |
| Security > Force user authentication | Require login for all access | `true` |
| Security > Allow users to sign up | Enable self-registration | `false` |
| Security > New users default group | Auto-assign group for new users | `sonar-users` |
| Quality Gates > Default quality gate | Which gate to use | `Sonar way` |
| Webhook > Global webhook secret | HMAC secret for webhook payloads | (empty) |

### Project Configuration

Each project has a `sonar-project.properties` file:

```properties
# ──── Project Identity ────
sonar.projectKey=my-project
sonar.projectName=My Project
sonar.projectVersion=1.0

# ──── Source Directories ────
sonar.sources=src
sonar.tests=test,tests
sonar.java.binaries=target/classes

# ──── Encoding ────
sonar.sourceEncoding=UTF-8

# ──── Exclusions ────
sonar.exclusions=**/node_modules/**,**/vendor/**
sonar.test.exclusions=**/*Test.java,**/*Spec.ts

# ──── Coverage ────
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.java.jacoco.reportPaths=target/jacoco.exec

# ──── SCM ────
sonar.scm.provider=git

# ──── Analysis Mode ────
sonar.analysis.mode=preview
# Or: sonar.analysis.mode=publish
```

### Quality Gates

Quality gates are pass/fail conditions applied to every analysis. The default **Sonar way** gate requires:

- **Coverage on New Code** >= 80%
- **Duplicated Lines on New Code** <= 3%
- **Reliability Rating** = A (0 bugs)
- **Security Rating** = A (0 vulnerabilities)
- **Maintainability Rating** = A (no new code smells)
- **Security Hotspots Reviewed** = 100%

Create a custom gate at **Quality Gates > Create**:

```
Condition: Coverage on New Code >= 70%
Condition: Duplicated Lines on New Code <= 5%
Condition: Reliability Rating = A
Condition: Security Hotspots Reviewed = 100%
```

### Quality Profiles

Profiles define which rules are enabled per language. Edit at **Quality Profiles**:

```
Language: Java
Default Profile: Sonar way
Active Rules: 450+
Inherited: No

# To create a custom profile:
1. Click "Create" > Name: "My Custom Profile"
2. Copy from "Sonar way"
3. Activate additional rules
4. Set as default for your project
```

### Branch Analysis (Developer/Enterprise Edition)

```properties
# In sonar-project.properties
sonar.branch.name=feature/user-auth
sonar.branch.target=main

# Or for pull requests
sonar.pullrequest.key=123
sonar.pullrequest.branch=feature/user-auth
sonar.pullrequest.base=main
```

---

## 5. Core Concepts

### The Four Smell Categories

SonarQube classifies all findings into four categories:

**Bugs**
Code that is demonstrably wrong and will cause incorrect behavior at runtime.
```java
// BUG: Integer overflow
int max = Integer.MAX_VALUE;
int result = max + 1; // Wraps to -2147483648
```

**Vulnerabilities**
Code that can be exploited by an attacker.
```java
// VULNERABILITY: SQL Injection
String query = "SELECT * FROM users WHERE id = " + userInput;
Statement stmt = connection.createStatement();
ResultSet rs = stmt.executeQuery(query); // Attacker can inject SQL
```

**Code Smells**
Code that works but is poorly written — hard to maintain, understand, or extend.
```java
// CODE SMELL: Too complex method
public void process(Order order) {
    if (order != null) {
        if (order.getStatus() == "PAID") {
            if (order.getItems().size() > 0) {
                for (Item item : order.getItems()) {
                    if (item.getPrice() > 0) {
                        // Deeply nested, hard to test
                    }
                }
            }
        }
    }
}
```

**Security Hotspots**
Code that looks suspicious but needs human review to confirm it's a real vulnerability.
```java
// HOTSPOT: Hardcoded credential
private static final String API_KEY = "sk-abc123def456"; // Review: Is this safe?
```

### Ratings

SonarQube assigns letter grades (A through E) based on:

- **Reliability Rating**: Based on number and severity of bugs (A = 0 bugs, B = minor, etc.)
- **Security Rating**: Based on number and severity of vulnerabilities
- **Maintainability Rating**: Based on technical debt ratio (time to maintain / time to develop)
- **Coverage**: Lines covered by tests / total lines
- **Duplications**: Percentage of lines that appear more than once

### Quality Gate

A quality gate is a set of conditions that must pass for a commit to be considered "clean." If any condition fails, the quality gate is **FAILED**, and the pipeline should break.

```
┌─────────────────────────────────┐
│         Quality Gate            │
│                                 │
│  ✓ Coverage >= 80%    PASS     │
│  ✓ Duplications <= 3% PASS     │
│  ✓ 0 Bugs            PASS     │
│  ✓ 0 Vulnerabilities PASS     │
│  ✗ 2 Hotspots        FAIL     │
│                                 │
│  Result: FAILED                │
└─────────────────────────────────┘
```

### New Code Period

Defines what "new code" means for analysis. Options:

- **Number of days**: All code changed in the last N days
- **Since a specific date**: All code changed since YYYY-MM-DD
- **Reference branch**: All code different from the reference branch
- **Overall code**: Analyze entire codebase (not just new code)

### Technical Debt

SonarQube estimates the time required to fix all code smells, expressed in minutes/hours/days. The **Technical Debt Ratio** is:

```
TDR = (Time to fix all code smells) / (Time to develop the code) × 100%
```

- **A**: TDR <= 5%
- **B**: 5% < TDR <= 10%
- **C**: 10% < TDR <= 20%
- **D**: 20% < TDR <= 50%
- **E**: TDR > 50%

### Issue Lifecycle

```
         ┌──────────┐
         │  Open     │
         └────┬─────┘
              │
    ┌─────────┼──────────┐
    │         │          │
    ▼         ▼          ▼
┌────────┐ ┌────────┐ ┌────────────┐
│Confirmed│ │False   │ │Confirmed   │
│        │ │Positive│ │Security    │
└───┬────┘ └────────┘ │Hotspot    │
    │                  └───┬────────┘
    ▼                      │
┌────────┐                 ▼
│Fixed   │          ┌────────────┐
│        │          │Fixed       │
└────────┘          └────────────┘
```

---

## 6. Usage Guide

### Step-by-Step: First Project Analysis

**1. Create a project in SonarQube UI:**

Navigate to **Projects > Create Project > New Project**:
- Project key: `contoso-petstore`
- Display name: `Contoso Pet Store`
- Main branch: `main`

**2. Generate an authentication token:**

Go to **My Account > Security > Generate Tokens**:
- Token name: `ci-scanner`
- Type: `Project Analysis Token`
- Click **Generate**

**3. Add sonar-project.properties:**

```properties
sonar.projectKey=contoso-petstore
sonar.projectName=Contoso Pet Store
sonar.projectVersion=1.0
sonar.sources=src/main/java
sonar.tests=src/test/java
sonar.java.binaries=target/classes
sonar.java.libraries=target/dependency/*.jar
sonar.sourceEncoding=UTF-8
sonar.exclusions=**/generated/**
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

**4. Run the scanner:**

```bash
# Download the scanner
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-5.0.1.3006-linux.zip
export PATH=$PWD/sonar-scanner-5.0.1.3006-linux/bin:$PATH

# Run analysis
sonar-scanner \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here
```

**5. Check results:**

Open `http://localhost:9000/dashboard?id=contoso-petstore` to see:
- Overall quality gate status
- Bug count and details
- Vulnerability count and details
- Code coverage percentage
- Code smell count
- Duplications

### Running Scanner for Different Languages

**Java (Maven):**
```bash
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=contoso-petstore \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here
```

**Java (Gradle):**
```bash
./gradlew build sonarqube \
  -Dsonar.projectKey=contoso-petstore \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here
```

**JavaScript/TypeScript:**
```bash
npm install
npm run test -- --coverage
sonar-scanner \
  -Dsonar.sources=src \
  -Dsonar.tests=test \
  -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
  -Dsonar.projectKey=contoso-petstore \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here
```

**Python:**
```bash
pip install coverage
coverage run -m pytest
coverage xml -o coverage.xml

sonar-scanner \
  -Dsonar.sources=src \
  -Dsonar.tests=tests \
  -Dsonar.python.coverage.reportPaths=coverage.xml \
  -Dsonar.projectKey=contoso-petstore \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here
```

**Go:**
```bash
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html

sonar-scanner \
  -Dsonar.sources=. \
  -Dsonar.tests=. \
  -Dsonar.go.coverage.reportPaths=coverage.out \
  -Dsonar.projectKey=contoso-petstore \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here
```

### Using the REST API

```bash
# List all projects
curl -u admin:password http://localhost:9000/api/projects/search

# Get project status
curl -u admin:password \
  "http://localhost:9000/api/qualitygates/project_status?projectKey=contoso-petstore"

# Get all issues for a project
curl -u admin:password \
  "http://localhost:9000/api/issues/search?componentKeys=contoso-petstore&types=BUG"

# Get metrics
curl -u admin:password \
  "http://localhost:9000/api/measures/component?component=contoso-petstore&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density"

# Export results as CSV
curl -u admin:password \
  "http://localhost:9000/api/issues/search?componentKeys=contoso-petstore&format=csv" \
  -o issues.csv
```

### SonarLint (IDE Integration)

**VS Code:**
1. Install "SonarLint" extension
2. Ctrl+Shift+P > "SonarLint: Connect to SonarQube"
3. Enter server URL and token
4. Select project binding
5. Get real-time feedback as you type

**IntelliJ IDEA:**
1. Settings > Plugins > Marketplace > "SonarLint"
2. Tools > SonarLint > Bind to SonarQube
3. Configure connection and project
4. Analysis runs automatically on file save

---

## 7. Writing Custom Rules

### Understanding Rule Architecture

SonarQube rules are implemented as plugins using the SonarQube Plugin API. Each rule consists of:

1. **Rule definition**: Metadata (name, description, severity, tags)
2. **Rule implementation**: The actual check (usually an AST visitor or semantic model check)
3. **Rule specification**: Examples of correct/incorrect code

### Creating a Custom Java Rule

**1. Set up the project:**

```xml
<!-- pom.xml -->
<project>
    <groupId>com.mycompany</groupId>
    <artifactId>sonar-custom-rules-java</artifactId>
    <version>1.0.0</version>
    <packaging>sonar-plugin</packaging>

    <dependencies>
        <dependency>
            <groupId>org.sonarsource.java</groupId>
            <artifactId>java-frontend</artifactId>
            <version>7.14.0.35763</version>
        </dependency>
        <dependency>
            <groupId>org.sonarsource.java</groupId>
            <artifactId>java-checks</artifactId>
            <version>7.14.0.35763</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.sonarsource.maven</groupId>
                <artifactId>sonar-packaging-maven-plugin</artifactId>
                <version>1.21.0.505</version>
                <extensions>true</extensions>
                <configuration>
                    <pluginKey>my-custom-java</pluginKey>
                    <pluginName>My Custom Java Rules</pluginName>
                    <pluginClass>com.mycompany.sonar.MyCustomJavaPlugin</pluginClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

**2. Create the rule check:**

```java
package com.mycompany.sonar.java.checks;

import org.sonar.check.Rule;
import org.sonar.plugins.java.api.tree.*;
import org.sonar.plugins.java.api.JavaFileScanner;
import org.sonar.plugins.java.api.JavaFileScannerContext;
import java.util.List;

@Rule(key = "AvoidSystemExit", name = "Avoid System.exit() in Production Code",
      description = "Calling System.exit() prevents proper cleanup and testing.",
      tags = {"bug", "pitfall"})
public class AvoidSystemExitCheck extends BaseTreeVisitor implements JavaFileScanner {

    private JavaFileScannerContext context;

    @Override
    public void scanFile(JavaFileScannerContext context) {
        this.context = context;
        scan(context.getTree());
    }

    @Override
    public void visitMethodInvocation(MethodInvocationTree tree) {
        if (isSystemExit(tree)) {
            context.reportIssue(this, tree,
                "Remove this call to System.exit(). Use exceptions or return codes instead.");
        }
        super.visitMethodInvocation(tree);
    }

    private boolean isSystemExit(MethodInvocationTree tree) {
        ExpressionTree methodSelect = tree.methodSelect();
        if (methodSelect.is(Kind.MEMBER_SELECT)) {
            MemberSelectExpressionTree memberSelect = (MemberSelectExpressionTree) methodSelect;
            return "exit".equals(memberSelect.identifier().name())
                && memberSelect.expression().is(Kind.IDENTIFIER)
                && "System".equals(((IdentifierTree) memberSelect.expression()).name());
        }
        return false;
    }
}
```

**3. Create the plugin entry point:**

```java
package com.mycompany.sonar;

import org.sonar.api.Plugin;
import com.mycompany.sonar.java.checks.AvoidSystemExitCheck;

public class MyCustomJavaPlugin implements Plugin {
    @Override
    public void define(Context context) {
        context.addExtension(AvoidSystemExitCheck.class);
    }
}
```

**4. Add rule metadata:**

```json
// src/main/resources/org/sonar/l10n/java/rules/java/AvoidSystemExit.json
{
  "title": "Avoid System.exit() in Production Code",
  "type": "BUG",
  "status": "READY",
  "tags": ["bug", "pitfall"],
  "description": "Calling System.exit() prevents proper cleanup and testing. It can cause issues in application servers, test frameworks, and CI/CD pipelines.",
  "message": "Remove this call to System.exit(). Use exceptions or return codes instead."
}
```

**5. Add rule examples:**

```java
// Noncompliant
public class MyClass {
    public void doSomething() {
        if (error) {
            System.exit(1); // Noncompliant
        }
    }
}

// Compliant
public class MyClass {
    public void doSomething() {
        if (error) {
            throw new IllegalStateException("Error occurred");
        }
    }
}
```

### Writing Custom JavaScript Rules

```javascript
// rule.js
const { Rule, AST } = require('@sonar-eslint/eslint-plugin');

module.exports = Rule({
  meta: {
    type: 'suggestion',
    docs: {
      description: 'Disallow console.log in production code',
      category: 'Best Practices',
    },
    schema: [],
  },
  create(context) {
    return {
      CallExpression(node) {
        if (node.callee.object?.name === 'console'
            && node.callee.property?.name === 'log') {
          context.report({
            node,
            message: 'Remove console.log() calls before committing.',
          });
        }
      },
    };
  },
});
```

### Writing Custom Regex Rules (Quick Customization)

For simple patterns, use the regex rule template in the UI:

```
# Rule: No Raw HTTP
# Regex: http://[^\s"]*
# Message: Use HTTPS instead of HTTP for security.
# Languages: Java, JavaScript, Python, Go, C#, PHP
```

---

## 8. Integration

### GitHub Actions

```yaml
# .github/workflows/sonarqube.yml
name: SonarQube Analysis
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  sonarqube:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for blame data

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Cache SonarQube packages
        uses: actions/cache@v4
        with:
          path: ~/.sonar/cache
          key: ${{ runner.os }}-sonar
          restore-keys: ${{ runner.os }}-sonar

      - name: Cache Maven packages
        uses: actions/cache@v4
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
          restore-keys: ${{ runner.os }}-m2

      - name: Build and test
        run: mvn -B verify

      - name: SonarQube Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          mvn -B sonar:sonar \
            -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }} \
            -Dsonar.token=$SONAR_TOKEN

      - name: SonarQube Quality Gate check
        uses: SonarSource/sonarqube-quality-gate-action@v1
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - analyze

sonarqube:
  stage: analyze
  image: sonarsource/sonar-scanner-cli:5
  variables:
    SONAR_HOST_URL: "$SONAR_HOST_URL"
    GIT_DEPTH: 0
  script:
    - >
      sonar-scanner
      -Dsonar.projectKey=$CI_PROJECT_NAME
      -Dsonar.sources=src
      -Dsonar.tests=test
      -Dsonar.host.url=$SONAR_HOST_URL
      -Dsonar.token=$SONAR_TOKEN
      -Dsonar.qualitygate.wait=true
  only:
    - main
    - merge_requests
```

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/SonarSource/sonarqube-scan-action
    rev: v3.1.0.8294
    hooks:
      - id: sonarqube-scan
        args:
          - --sonar-host-url=http://localhost:9000
          - --sonar-token=your_token
        stages: [push]
```

### ArgoCD Integration

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sonarqube
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://SonarSource.github.io/sonarqube-helm-chart
    chart: sonarqube
    targetRevision: 10.6.0
    helm:
      values: |
        persistence:
          enabled: true
          size: 20Gi
        postgresql:
          enabled: true
          persistence:
            size: 10Gi
  destination:
    server: https://kubernetes.default.svc
    namespace: sonarqube
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
```

---

## 9. Security Hardening

### Server Hardening

```properties
# sonar.properties — Security settings

# Force HTTPS
sonar.web.https.port=9443
sonar.web.https.keyAlias=sonarqube
sonar.web.https.keyPassphrase=changeit
sonar.web.https.keystoreFile=/path/to/keystore.p12
sonar.web.https.keystorePassword=changeit

# Disable public access to rules API
sonar.security.httpHeaders.enableHSTS=true

# Rate limiting
sonar.web.accessLogs=true

# Disable self-registration
sonar.authenticator.downcase=true
```

### API Token Management

```bash
# Generate token with limited scope
# Via UI: My Account > Security > Generate Tokens

# Token types:
# - Global Analysis Token: Can analyze any project
# - Project Analysis Token: Can analyze only the specified project
# - User Token: Full user access (avoid using)

# Rotate tokens regularly (every 90 days)
# Store in CI/CD secrets, never in code
```

### Network Security

```
                    ┌─────────────┐
                    │  Internet    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   Reverse   │
                    │   Proxy     │
                    │ (nginx/HAProxy) │
                    └──────┬──────┘
                           │ :9000
                    ┌──────▼──────┐
                    │  SonarQube  │
                    │   Server    │
                    └──────┬──────┘
                           │ :5432
                    ┌──────▼──────┐
                    │  PostgreSQL │
                    └─────────────┘
```

### Backup Strategy

```bash
#!/bin/bash
# backup-sonarqube.sh

BACKUP_DIR="/backup/sonarqube/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Stop SonarQube
docker compose stop sonarqube

# Backup database
docker compose exec -T db pg_dump -U sonar sonarqube > "$BACKUP_DIR/sonarqube-db.sql"

# Backup data volume
docker run --rm \
  -v sonarqube_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/sonarqube-data.tar.gz /data

# Backup extensions
docker run --rm \
  -v sonarqube_extensions:/extensions \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/sonarqube-extensions.tar.gz /extensions

# Restart SonarQube
docker compose start sonarqube

echo "Backup completed: $BACKUP_DIR"
```

---

## 10. Troubleshooting

### Issue 1: SonarQube won't start — Elasticsearch exception

**Error:** `org.elasticsearch.bootstrap.BootstrapException: java.lang.RuntimeException: max virtual memory areas vm.max_map_count [65530] is too low`

**Fix:**
```bash
# Temporary
sudo sysctl -w vm.max_map_count=262144

# Permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Issue 2: Scanner fails with "Not authorized"

**Error:** `You're not authorized to analyze this project`

**Fix:**
```bash
# Verify token is valid and not expired
# Check project key matches exactly
# Ensure token has access to the project
# Generate new token in My Account > Security
```

### Issue 3: Analysis hangs or takes too long

**Symptoms:** Scanner runs for hours, no progress

**Fix:**
```properties
# Increase scanner memory
export SONAR_SCANNER_JAVA_OPTS="-Xmx4g"

# Exclude large directories
sonar.exclusions=**/node_modules/**,**/vendor/**,**/dist/**,**/build/**

# Limit analysis scope
sonar.sources=src/main/java
sonar.tests=src/test/java
```

### Issue 4: Coverage report not found

**Error:** `No coverage report found for language 'Java'`

**Fix:**
```bash
# Generate coverage before scanning
mvn test jacoco:report

# Verify report exists
ls target/site/jacoco/jacoco.xml

# Set correct path
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

### Issue 5: "Too many open files" error

**Fix:**
```bash
# Increase file descriptor limit
ulimit -n 131072

# Or in docker-compose.yml
sonarqube:
  ulimits:
    nofile:
      soft: 131072
      hard: 131072
```

### Issue 6: PostgreSQL connection refused

**Fix:**
```bash
# Check PostgreSQL is running
docker compose ps db

# Check logs
docker compose logs db

# Verify credentials match
# In sonar.properties:
# sonar.jdbc.url=jdbc:postgresql://db:5432/sonarqube
# sonar.jdbc.username=sonar
# sonar.jdbc.password=sonar
```

### Issue 7: Scanner can't reach server

**Error:** `Failed to connect to http://localhost:9000`

**Fix:**
```bash
# Check server is running
curl http://localhost:9000/api/system/status

# Check firewall
sudo ufw allow 9000

# Check Docker port mapping
docker port sonarqube

# Test from scanner host
curl -u admin:password http://your-sonarqube-host:9000/api/system/status
```

### Issue 8: Duplicate code detection is slow

**Fix:**
```properties
# Exclude auto-generated files
sonar.exclusions=**/generated/**,**/protobuf/**,**/swagger/**

# Reduce analysis scope
sonar.sources=src/main/java
```

### Issue 9: Quality gate always fails on new projects

**Cause:** Default "Sonar way" gate requires 80% coverage on new code.

**Fix:**
- Option 1: Increase test coverage
- Option 2: Create a custom quality gate with relaxed conditions
- Option 3: Set a new code period that excludes legacy code

### Issue 10: SonarQube UI is very slow

**Fix:**
```properties
# Increase memory
SONAR_WEB_JAVAADDITIONALOPTS="-Xmx2g"
SONAR_CE_JAVAADDITIONALOPTS="-Xmx2g"
SONAR_SEARCH_JAVAADDITIONALOPTS="-Xmx1g"

# Increase Elasticsearch heap
sonar.search.javaAdditionalOpts=-Xmx1g -Xms1g
```

### Issue 11: "SCM provider not found"

**Fix:**
```properties
# In sonar-project.properties
sonar.scm.provider=git

# Ensure git is installed and repo is initialized
git status
```

### Issue 12: Branch analysis shows wrong branch

**Fix:**
```bash
# Ensure correct branch is checked out
git checkout main

# Explicitly set branch name
sonar.branch.name=main
```

### Issue 13: Custom rules not showing up

**Fix:**
```bash
# Restart SonarQube after plugin install
docker compose restart sonarqube

# Check plugin is loaded
curl -u admin:password http://localhost:9000/api/plugins/installed | jq '.plugins[].name' | grep -i custom

# Verify quality profile includes the rule
# Administration > Quality Profiles > [Language]
```

### Issue 14: Memory leak during analysis

**Fix:**
```bash
# Increase scanner memory
export SONAR_SCANNER_JAVA_OPTS="-Xmx4g -XX:+HeapDumpOnOutOfMemoryError"

# Check for circular dependencies in code
# Reduce analysis scope if needed
```

### Issue 15: License/edition limitations

**Symptom:** Features like PR decoration or security hotspots not available

**Fix:**
```bash
# Check current edition
curl -u admin:password http://localhost:9000/api/system/status | jq '.version'

# Upgrade to Developer/Enterprise edition
# Download from https://www.sonarsource.com/downloads/
# Replace sonarqube-*.zip and restart
```

### Issue 16: Scanner fails on large monorepo

**Fix:**
```properties
# Analyze sub-projects separately
# Or use SonarQube's monorepo support (Enterprise)
sonar.sources=services/my-service/src
sonar.projectKey=my-service

# Increase scanner memory
export SONAR_SCANNER_JAVA_OPTS="-Xmx8g"
```

### Issue 17: Cannot analyze .NET projects

**Fix:**
```bash
# Install .NET scanner
dotnet tool install --global dotnet-sonarscanner

# Build with coverage
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover

# Run scanner
dotnet sonarscanner begin \
  /k:"my-project" \
  /d:sonar.host.url="http://localhost:9000" \
  /d:sonar.token="your_token" \
  /d:sonar.cs.opencover.reportsPaths="**/coverage.opencover.xml"

dotnet build

dotnet sonarscanner end /d:sonar.token="your_token"
```

---

## 11. Tips & Best Practices

1. **Start small**: Analyze one project first, fix critical issues, then expand.
2. **Fix new code first**: Set quality gate on new code only — don't block on legacy debt.
3. **Use SonarLint in IDE**: Catch issues before they reach CI/CD.
4. **Branch analysis**: Analyze feature branches to catch issues before merge.
5. **Quality gates in CI**: Fail the build if quality gate fails.
6. **Exclude generated code**: Don't waste time on auto-generated files.
7. **Review security hotspots**: They need human judgment — don't dismiss them.
8. **Set up notifications**: Get alerts for new issues on your projects.
9. **Review duplication**: High duplication = high maintenance cost.
10. **Use custom rules**: Enforce your organization's coding standards.
11. **Regular cleanups**: Schedule quarterly code quality reviews.
12. **Baseline metrics**: Track quality trends over time, not just snapshots.
13. **Avoid false positives**: Mark them as "Won't Fix" or "False Positive" to clean the list.
14. **Review assigned issues**: Check the "My Issues" tab regularly.
15. **Use profiles per language**: Different languages have different best practices.
16. **Keep SonarQube updated**: New versions add rules for new vulnerability patterns.
17. **Secure the server**: Use HTTPS, disable public registration, rotate tokens.
18. **Backup regularly**: Database + data volume + extensions.
19. **Monitor resource usage**: SonarQube needs adequate CPU/RAM/Disk.
20. **Document exclusions**: Explain why certain files are excluded from analysis.

---

## 12. Command Reference

### sonar-scanner CLI

```bash
sonar-scanner [options]

Options:
  -Dsonar.projectKey=KEY           Project key (required)
  -Dsonar.host.url=URL             SonarQube server URL
  -Dsonar.token=TOKEN              Authentication token
  -Dsonar.sources=DIR              Source directories (comma-separated)
  -Dsonar.tests=DIR                Test directories
  -Dsonar.exclusions=PATTERN       Files to exclude (glob patterns)
  -Dsonar.source.encoding=ENC      Source encoding (default: UTF-8)
  -Dsonar.verbose=true             Verbose output
  -Dsonar.log.level=DEBUG          Log level (TRACE/DEBUG/INFO/WARN/ERROR)
  -Dsonar.skip=true                Skip analysis (useful in CI)

# Language-specific
  -Dsonar.java.binaries=DIR        Java compiled classes
  -Dsonar.java.libraries=DIR       Java library JARs
  -Dsonar.javascript.lcov.reportPaths=PATH   JS coverage report
  -Dsonar.python.coverage.reportPaths=PATH   Python coverage report
  -Dsonar.go.coverage.reportPaths=PATH       Go coverage report

# Analysis mode
  -Dsonar.analysis.mode=preview    Preview mode (don't persist)
  -Dsonar.analysis.mode=publish    Publish mode (persist results)
```

### sonar-server CLI (Docker)

```bash
# Start
docker start sonarqube

# Stop
docker stop sonarqube

# Restart
docker restart sonarqube

# View logs
docker logs -f sonarqube

# Execute admin command
docker exec sonarqube curl -u admin:password \
  "http://localhost:9000/api/system/upgrade"
```

### REST API Commands

```bash
# System
curl -u admin:password http://localhost:9000/api/system/status
curl -u admin:password http://localhost:9000/api/system/info

# Projects
curl -u admin:password http://localhost:9000/api/projects/search
curl -u admin:password "http://localhost:9000/api/projects/search?q=my-project"

# Issues
curl -u admin:password "http://localhost:9000/api/issues/search?componentKeys=my-project"
curl -u admin:password "http://localhost:9000/api/issues/search?componentKeys=my-project&types=BUG&severities=BLOCKER"

# Quality Gates
curl -u admin:password http://localhost:9000/api/qualitygates/list
curl -u admin:password "http://localhost:9000/api/qualitygates/project_status?projectKey=my-project"

# Metrics
curl -u admin:password "http://localhost:9000/api/measures/component?component=my-project&metricKeys=bugs,vulnerabilities,code_smells,coverage"

# Users
curl -u admin:password http://localhost:9000/api/users/search

# Quality Profiles
curl -u admin:password "http://localhost:9000/api/qualityprofiles/search?language=java"

# Plugins
curl -u admin:password http://localhost:9000/api/plugins/installed
curl -u admin:password http://localhost:9000/api/plugins/available
```

---

## 13. Configuration Reference

### sonar-project.properties Complete Reference

| Property | Description | Default |
|----------|-------------|---------|
| `sonar.projectKey` | Unique project identifier | (required) |
| `sonar.projectName` | Human-readable name | projectKey |
| `sonar.projectVersion` | Version string | 1.0 |
| `sonar.sources` | Source directories | `.` |
| `sonar.tests` | Test directories | (empty) |
| `sonar.sourceEncoding` | File encoding | UTF-8 |
| `sonar.exclusions` | Glob patterns to exclude | (empty) |
| `sonar.test.exclusions` | Glob patterns for test exclusions | (empty) |
| `sonar.dynamicAnalysis` | Dynamic analysis mode | true |
| `sonar.host.url` | Server URL | `http://localhost:9000` |
| `sonar.token` | Authentication token | (required) |
| `sonar.login` | Deprecated, use sonar.token | (empty) |
| `sonar.password` | Deprecated, use sonar.token | (empty) |
| `sonar.scm.provider` | SCM provider | auto |
| `sonar.branch.name` | Branch name | main |
| `sonar.branch.target` | Target branch for PR analysis | main |
| `sonar.pullrequest.key` | PR number | (empty) |
| `sonar.pullrequest.branch` | PR branch name | (empty) |
| `sonar.pullrequest.base` | PR target branch | main |

### Language-Specific Properties

**Java:**
| Property | Description |
|----------|-------------|
| `sonar.java.binaries` | Compiled class directories |
| `sonar.java.libraries` | Library JARs |
| `sonar.java.source` | Java source version |
| `sonar.java.target` | Java target version |
| `sonar.java.jacoco.reportPaths` | JaCoCo coverage paths |
| `sonar.coverage.jacoco.xmlReportPaths` | JaCoCo XML report paths |

**JavaScript/TypeScript:**
| Property | Description |
|----------|-------------|
| `sonar.javascript.lcov.reportPaths` | LCOV coverage paths |
| `sonar.typescript.lcov.reportPaths` | TypeScript LCOV paths |
| `sonar.javascript-eslint.reportPaths` | ESLint report paths |

**Python:**
| Property | Description |
|----------|-------------|
| `sonar.python.coverage.reportPaths` | Coverage report paths |
| `sonar.python.xunit.reportPath` | Unit test report path |
| `sonar.python.pylint.reportPath` | Pylint report path |

**Go:**
| Property | Description |
|----------|-------------|
| `sonar.go.coverage.reportPaths` | Go coverage report paths |
| `sonar.go.tests.reportPaths` | Go test report paths |

**C#/.NET:**
| Property | Description |
|----------|-------------|
| `sonar.cs.opencover.reportsPaths` | OpenCover report paths |
| `sonar.cs.vstest.reportsPaths` | VSTest report paths |

**PHP:**
| Property | Description |
|----------|-------------|
| `sonar.php.coverage.reportPaths` | Coverage report paths |
| `sonar.php.tests.reportPath` | PHPUnit report path |

---

## 14. Real-World Examples

### Example 1: Scanning Contoso Pet Store (Java/Maven)

```bash
# Project structure
contoso-petstore/
├── pom.xml
├── src/main/java/com/contoso/petstore/
│   ├── PetController.java
│   ├── PetService.java
│   ├── PetRepository.java
│   └── model/Pet.java
├── src/test/java/com/contoso/petstore/
│   └── PetControllerTest.java
└── sonar-project.properties
```

```properties
# sonar-project.properties
sonar.projectKey=contoso-petstore
sonar.projectName=Contoso Pet Store
sonar.projectVersion=1.0
sonar.sources=src/main/java
sonar.tests=src/test/java
sonar.java.binaries=target/classes
sonar.java.libraries=target/dependency/*.jar
sonar.sourceEncoding=UTF-8
sonar.exclusions=**/generated/**
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

```bash
# Build with coverage
mvn clean verify

# Run SonarQube analysis
mvn sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here

# Check quality gate
curl -u admin:password \
  "http://localhost:9000/api/qualitygates/project_status?projectKey=contoso-petstore"
```

### Example 2: Scanning Contoso Pet Store (Node.js)

```bash
# Project structure
contoso-petstore-api/
├── package.json
├── src/
│   ├── index.js
│   ├── routes/
│   │   └── pets.js
│   └── models/
│       └── pet.js
├── test/
│   └── pets.test.js
└── sonar-project.properties
```

```json
// package.json
{
  "scripts": {
    "test": "jest --coverage",
    "sonar": "sonar-scanner"
  },
  "devDependencies": {
    "sonarqube-scanner": "^3.0.0",
    "jest": "^29.0.0"
  }
}
```

```bash
# Generate coverage
npm test -- --coverage

# Run analysis
npx sonar-scanner \
  -Dsonar.projectKey=contoso-petstore-api \
  -Dsonar.sources=src \
  -Dsonar.tests=test \
  -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=your_token_here
```

### Example 3: GitHub Actions for Monorepo

```yaml
# .github/workflows/sonar-monorepo.yml
name: SonarQube Monorepo
on:
  push:
    branches: [main]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      services: ${{ steps.changes.outputs.services }}
    steps:
      - uses: actions/checkout@v4
      - id: changes
        uses: dorny/paths-filter@v3
        with:
          filters: |
            auth-service:
              - 'services/auth/**'
            pet-service:
              - 'services/pet/**'
            order-service:
              - 'services/order/**'

  analyze-auth:
    needs: detect-changes
    if: needs.detect-changes.outputs.services == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: SonarQube Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=auth-service \
            -Dsonar.sources=services/auth/src \
            -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }} \
            -Dsonar.token=$SONAR_TOKEN

  analyze-pet:
    needs: detect-changes
    if: needs.detect-changes.outputs.services == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: SonarQube Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=pet-service \
            -Dsonar.sources=services/pet/src \
            -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }} \
            -Dsonar.token=$SONAR_TOKEN
```

### Example 4: Dockerfile for Scanner in CI

```dockerfile
# Dockerfile.scanner
FROM sonarsource/sonar-scanner-cli:5

WORKDIR /app

# Copy project files
COPY . .

# Run analysis
ENTRYPOINT ["sonar-scanner"]
CMD ["-Dsonar.host.url=http://sonarqube:9000", \
     "-Dsonar.projectKey=my-project", \
     "-Dsonar.token=${SONAR_TOKEN}"]
```

---

## 15. Further Reading

### Official Documentation
- [SonarQube Documentation](https://docs.sonarsource.com/sonarqube/latest/)
- [SonarQube Install Guide](https://docs.sonarsource.com/sonarqube/latest/setup-and-upgrade/install-the-server/introduction/)
- [SonarQube Scanner Docs](https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/)
- [SonarQube API Reference](https://docs.sonarsource.com/sonarqube/latest/extension-guide/web-api/)
- [Quality Gates Documentation](https://docs.sonarsource.com/sonarqube/latest/user-guide/quality-gates/)
- [Custom Rules Guide](https://docs.sonarsource.com/sonarqube/latest/extension-guide/adding-custom-rules/)

### SonarQube Community
- [SonarQube Community Forum](https://community.sonarsource.com/)
- [SonarQube GitHub](https://github.com/SonarSource/sonarqube)
- [SonarSource Blog](https://www.sonarsource.com/blog/)

### Books & Courses
- "Clean Code" by Robert C. Martin — Foundation for code quality
- "Refactoring" by Martin Fowler — Improving existing code
- OWASP Top 10 — Understanding web application security risks

### Related Tools in This Guide
- [Semgrep Guide](./semgrep.md) — Lightweight semantic analysis
- [Gitleaks Guide](./gitleaks.md) — Secret detection in Git

---

*Last updated: 2026*
