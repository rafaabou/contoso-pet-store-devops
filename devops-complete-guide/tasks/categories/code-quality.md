# Code Quality Tasks

## Task List

- [ ] TASK-211: Fix all hadolint warnings in Dockerfiles
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `hadolint` `dockerfile` `linting`
  - **Services:** all Dockerfiles
  - **Steps:** Run hadolint on all Dockerfiles, fix: DL3008 (pin apt versions), DL3009 (delete apt lists), DL3013 (pin pip versions), DL3018 (pin apk versions), DL3025 (use JSON form for CMD), DL4006 (set SHELL pipefail), DL3003 (use WORKDIR instead of cd). Add hadolint to CI pipeline as blocking check, document exceptions with inline ignore comments where justified

- [ ] TASK-212: Configure ESLint for store-front and store-admin
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `eslint` `linting` `javascript`
  - **Services:** store-front, store-admin
  - **Steps:** Create shared .eslintrc.js with: no-unused-vars, no-console in prod, prefer-const, eqeqeq, react-hooks rules, import ordering. Add to CI pipeline (fail on errors, warn on warnings). Run autofix on existing codebase, create .eslintignore for generated files, document custom rules in README

- [ ] TASK-213: Set up SonarQube quality gates
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `sonarqube` `quality-gate` `static-analysis`
  - **Services:** SonarQube, CI/CD pipeline
  - **Steps:** Deploy SonarQube (community edition), configure project per service, define quality gate: coverage>80%, duplications<3%, no new critical/blocker issues, security rating=A, reliability rating=A. Integrate sonar-scanner in CI, block PR merge if quality gate fails, set up webhook to PR status checks, document quality standards in team wiki

- [ ] TASK-214: Create Semgrep rules for custom security patterns
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `semgrep` `security` `custom-rules`
  - **Services:** all codebases
  - **Steps:** Write rules for: hardcoded secrets (API keys, passwords), SQL injection (string concatenation in queries), path traversal (unsanitized user input in file paths), insecure HTTP usage, weak crypto algorithms, unsafe deserialization. Test rules against known vulnerable code, tune to reduce false positives, add to CI pipeline, create rule documentation

- [ ] TASK-215: Add pre-commit hooks for gitleaks
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `gitleaks` `pre-commit` `secrets`
  - **Services:** all repositories
  - **Steps:** Install pre-commit framework, add gitleaks hook to .pre-commit-config.yaml, configure .gitleaks.toml with custom allowlists, test with synthetic secret commit, add CI check as backup (gitleaks detect --source .), document process for developers, scan full git history for existing leaks

- [ ] TASK-216: Generate SBOM (Syft) for all images
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `sbom` `syft` `supply-chain`
  - **Services:** all container images, CI/CD
  - **Steps:** Install Syft, generate SBOM in SPDX and CycloneDX format for each image, store SBOMs as CI artifacts, integrate with Grype for vulnerability scanning, add SBOM attestation to image registry (cosign), set up SBOM diff between versions to track dependency changes, document SBOM storage and retrieval process

- [ ] TASK-217: Set up OWASP dependency check in CI
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `owasp` `dependency-check` `security`
  - **Services:** all services, CI/CD
  - **Steps:** Add OWASP dependency-check plugin to build pipeline (Maven/Gradle/npm), configure to scan all dependencies, set CVSS threshold for failures (7.0), generate HTML and JSON reports, add suppression file for known false positives, set up scheduled full scans, track CVE remediation in backlog, block releases with unpatched Critical CVEs

- [ ] TASK-218: Configure code coverage thresholds
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `coverage` `jest` `quality`
  - **Services:** all services, CI/CD
  - **Steps:** Configure Jest coverage thresholds: statements>80%, branches>75%, functions>80%, lines>80%. Add coverage report to PR comments via CI, fail build if threshold not met, set up coverage trending dashboard (Codecov or Coveralls), create issue template for coverage exceptions, add coverage badge to README

- [ ] TASK-219: Create PR template with checklist
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `pr-template` `process` `checklist`
  - **Services:** all repositories
  - **Steps:** Create .github/PULL_REQUEST_TEMPLATE.md with sections: Description, Type of Change, Testing (unit/integration/e2e), Checklist (tests pass, lint clean, coverage met, security scan clean, docs updated, no secrets, DB migration tested, rollback plan documented), Screenshots for UI changes. Configure as default PR template for all repos

- [ ] TASK-220: Set up automated code review (SonarCloud)
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `sonarcloud` `code-review` `automation`
  - **Services:** SonarCloud, CI/CD
  - **Steps:** Connect repos to SonarCloud, configure quality profiles (Sonar way + custom), enable PR decoration (inline comments on new code), configure new code period (since last release), set up auto-assign reviewers for security hotspots, integrate with GitHub branch protection, document review workflow for team
