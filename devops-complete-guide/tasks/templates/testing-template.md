# Test Plan Template

Use this for planning and tracking test execution.

---

# TEST-XXX: [Test Plan Title]

**Date:** YYYY-MM-DD  
**Type:** unit / integration / e2e / load / security / chaos / smoke  
**Service(s):** [list]  
**Environment:** dev / staging / production  
**Status:** planned / in_progress / passed / failed / blocked  

---

## 1. Objective

[What are we testing and why?]

## 2. Scope

### In Scope
- [ ] Test area 1
- [ ] Test area 2

### Out of Scope
- [ ] Area not covered
- [ ] Area not covered

## 3. Test Cases

| # | Test Case | Type | Expected | Actual | Status |
|---|-----------|------|----------|--------|--------|
| 1 | | | | | pass/fail |
| 2 | | | | | pass/fail |
| 3 | | | | | pass/fail |

## 4. Preconditions

- [ ] Service deployed to [environment]
- [ ] Test data seeded
- [ ] Dependencies available

## 5. Test Data

| Scenario | Input | Expected Output |
|----------|-------|-----------------|
| Happy path | | |
| Edge case | | |
| Error case | | |

## 6. Execution Log

| Date | Tester | Tests Run | Passed | Failed | Notes |
|------|--------|-----------|--------|--------|-------|
| | | | | | |

## 7. Results Summary

- **Total test cases:** X
- **Passed:** X
- **Failed:** X
- **Blocked:** X
- **Pass rate:** X%

## 8. Issues Found

| # | Issue | Severity | Status | Related Task |
|---|-------|----------|--------|--------------|
| 1 | | | | TASK-XXX |

## 9. Sign-off

| Role | Name | Date | Approved |
|------|------|------|----------|
| Tester | | | |
| Reviewer | | | |
