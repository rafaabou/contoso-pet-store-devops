# Task Management System

A Notion/Jira-style task tracking system for real-world DevOps/DevSecOps/sysadmin work.

## How It Works

### File Structure
```
TASKS.md                    ← Master kanban board (all tasks)
tasks/
├── README.md               ← This file
├── templates/              ← Copy-paste templates
│   ├── daily-template.md
│   ├── task-template.md
│   ├── debugging-template.md
│   ├── testing-template.md
│   └── sprint-template.md
├── daily/                  ← Daily standup logs
│   └── YYYY-MM-DD.md
├── categories/             ← Tasks grouped by type
│   ├── debugging.md        ← Incident investigation & fixes
│   ├── security.md         ← CVE patches, access reviews, policy
│   ├── deployment.md       ← Releases, rollbacks, hotfixes
│   ├── infrastructure.md   ← Terraform, Ansible, cluster mgmt
│   ├── monitoring.md       ← Alerts, dashboards, SLOs
│   ├── testing.md          ← Validation, chaos, load tests
│   ├── code-quality.md     ← Linting, scans, reviews
│   └── documentation.md    ← Runbooks, ADRs, READMEs
└── sprints/                ← 2-week sprint plans
    ├── sprint-01.md
    ├── sprint-02.md
    └── sprint-03.md
```

### Task ID Format
`TASK-XXX` where XXX is a zero-padded number (001-230+).

### Priority Levels
| Level | Meaning | Response Time |
|-------|---------|---------------|
| **P0** | Production down / data loss risk | Fix immediately |
| **P1** | Degraded service / security vulnerability | Fix within 4 hours |
| **P2** | Non-urgent improvement / maintenance | Fix within 1 week |
| **P3** | Nice-to-have / technical debt | Fix when convenient |

### Status Flow
```
backlog → todo → in_progress → review → done
                                  ↓
                              blocked (with blocker note)
```

### Daily Workflow
1. **Morning**: Open `tasks/daily/YYYY-MM-DD.md`, list today's focus tasks
2. **During work**: Log start/end times in the time table
3. **When blocked**: Add to blockers section, create new task if needed
4. **End of day**: Mark completed tasks, write summary, update sprint file
5. **Weekly**: Review sprint progress, adjust priorities

### Category Tags
`debugging` `security` `deployment` `infrastructure` `monitoring` `testing` `code-quality` `documentation`

### Creating New Tasks
1. Copy `templates/task-template.md`
2. Fill in all fields
3. Append to the relevant `categories/*.md` file
4. Add to `TASKS.md` kanban board
5. Assign to current sprint if applicable

### Quick Commands
```bash
# View all P0 tasks
grep -A5 "Priority: P0" TASKS.md

# View today's tasks
cat tasks/daily/$(date +%Y-%m-%d).md

# Count tasks by status
grep -c "\- \[ \]" TASKS.md    # incomplete
grep -c "\- \[x\]" TASKS.md    # complete

# Find tasks for a specific service
grep -i "order-service" tasks/categories/*.md
```
