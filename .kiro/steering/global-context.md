---
inclusion: always
---

# Enterprise DevOps Context

## Platform Overview

| Component | Technology |
|-----------|------------|
| Cloud | AWS |
| IaC | Terraform |
| Application | [Application Name] |
| Runtime | [Runtime Environment] |
| Deployment | [Deployment Method] |

---

## Core Operational Rules

### Infrastructure Management

* All infrastructure resources **must** be created and managed through Terraform
* Manual console changes are **prohibited** — all changes require Terraform + GitOps
* Infrastructure must be **idempotent** — `terraform apply` must be safe to run multiple times
* Resources must support **automated remediation** — avoid manual intervention patterns

### Incident Response

* **RCA (Root Cause Analysis) is mandatory** for all incidents
* AI must analyze Terraform code to identify root causes
* All remediation must be **Terraform-only** — no manual console fixes
* After remediation, **Git commit is required** before `terraform apply`

### Monitoring & Validation

* Health checks must be monitored via CloudWatch alarms
* All infrastructure changes require **validation testing**
* After `terraform apply`, validate:
  - Target group/instances show healthy status
  - Load balancer returns expected HTTP status
  - Application responds correctly

---

## GitOps Standards

All infrastructure changes must follow this workflow:

1. Create a feature branch: `git checkout -b fix/<issue-description>`
2. Make changes in Terraform files only
3. Run `terraform plan` to verify changes
4. Commit with format: `fix: <issue description>`
5. Push branch and create PR/MR
6. After merge, run `terraform apply`
7. Validate the fix with automated or manual tests

**Example commit message:**
```
fix: corrected load balancer health check path
```

---

## Terraform Standards

### File Organization

```
infrastructure/environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── terraform.tfstate
├── staging/
└── prod/
```

* Environment-specific configs: `infrastructure/environments/<env>/`
* Main files: `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars`
* State file: `terraform.tfstate` (managed remotely in production)

### Best Practices

* Use variables for all configurable values — never hardcode
* Reference resources via `aws_resource.name.id` syntax
* Use `depends_on` for explicit resource ordering when needed
* Always include `tags` block with `Name` and `Environment`
* Use `terraform plan` before `terraform apply`

### Security

* Never commit `terraform.tfvars` with secrets — use `.gitignore`
* Use `aws_security_group` ingress rules to restrict access
* Load balancer should expose only required ports
* Backend instances must allow traffic only from load balancer

---

## Application Standards

### Application Overview

* **Runtime**: [Runtime Environment]
* **Port**: [Application Port]
* **Build**: [Build Tool] (`[build_command]`)
* **Startup**: Started via userdata/init script
* **Health Endpoint**: [Health Check Path]

### Expected Behavior

* Application starts on configured port
* Health check returns HTTP 200
* No unexpected dependencies for basic health

---

## Common Failure Scenarios

| Scenario | Symptom | Root Cause | Remediation |
|----------|---------|------------|-------------|
| Wrong health check path | HTTP 503, targets unhealthy | Health check path mismatch | Update `terraform.tfvars` |
| Wrong target port | Connection timeout | Application port misconfiguration | Update `terraform.tfvars` |
| Security group misconfig | Connection refused | Backend SG blocks LB ingress | Update `security_groups.tf` |

---

## RCA Expectations

When investigating incidents, AI must generate:

1. **Incident Summary** — What's broken and impact
2. **Root Cause** — Why it happened (Terraform analysis)
3. **Impact Analysis** — Affected users/services
4. **Terraform Fix** — Specific code changes needed
5. **Validation Steps** — How to verify the fix
6. **Preventive Recommendation** — How to avoid recurrence

---

## Script Execution Rule

**NEVER run any script or Terraform command automatically** unless the user explicitly asks to run it.

- If the user says "fix", "update", "change", "correct" → make the code changes only, do NOT deploy or run scripts
- If the user says "deploy", "apply", "run", "execute" → then run the appropriate script
- Always wait for explicit instruction before executing any command

---

## Deploy Working Directory Rule

Whenever any deploy-related action is requested (e.g. "deploy the infrastructure", "deploy the infra", "apply", "provision"), the AI **must**:

1. **Always** run `bash deploy.sh` from `D:\Workspace\petclinic\scripts`
2. Never run `terraform apply` directly — always go through `deploy.sh`
3. Never run deploy scripts from a different directory unless explicitly instructed

Whenever any destroy-related action is requested (e.g. "destroy the infrastructure", "destroy the infra", "tear down"), the AI **must**:

1. **Always** run `bash destroy.sh` from `D:\Workspace\petclinic\scripts`
2. Never run `terraform destroy` directly — always go through `destroy.sh`

### Script Reference

| Action | Trigger Phrases | Script | Command |
|--------|----------------|--------|---------|
| Deploy / Apply | "deploy", "provision", "apply", "deploy infra", "deploy the infrastructure" | `deploy.sh` | `bash deploy.sh` (cwd: `D:\Workspace\petclinic\scripts`) |
| Destroy | "destroy", "tear down", "destroy infra", "destroy the infrastructure" | `destroy.sh` | `bash destroy.sh` (cwd: `D:\Workspace\petclinic\scripts`) |
| Validate | "validate", "check infra" | `validate.sh` | `bash validate.sh` (cwd: `D:\Workspace\petclinic\scripts`) |

**Example:**
```bash
cd D:\Workspace\petclinic\scripts
bash deploy.sh
```

For direct Terraform commands (`terraform plan`, `terraform init`), navigate to the environment directory:
```bash
cd D:\Workspace\petclinic\infrastructure\environments\dev
terraform plan
```

---

## AI Operational Behavior

AI responsibilities:

* Analyze Terraform code for misconfigurations
* Detect infrastructure drift from expected state
* Investigate outages using RCA methodology
* Generate Terraform-only remediation plans
* Validate infrastructure recovery after fixes
* Recommend preventive improvements

**Do:**
* Reference actual Terraform file paths
* Use exact variable names from `variables.tf`
* Include specific `terraform plan` and `terraform apply` commands
* Validate with appropriate test commands against service endpoint

**Do Not:**
* Suggest manual console changes
* Skip GitOps workflow for any change
* Omit validation steps from remediation
* Modify state files directly

---

## New Relic Log Fetching

**All New Relic log fetching scripts are located in `d:\Workspace\petclinic\scripts\`:**

| Script | Purpose |
|--------|---------|
| `fetch_latest_logs.py` | Fetch latest 100 log entries from last 15 minutes |
| `fetch_error_logs.py` | Fetch ERROR logs from the last hour |
| `fetch_nr_logs.py` | Fetch recent logs (30 min) |

### When User Asks for New Relic Logs

When the user says "get logs from New Relic", "fetch New Relic logs", or any variation:

1. **Run the Python script** from `d:\Workspace\petclinic\scripts\`:
   - `fetch_latest_logs.py` — get latest 100 logs from last 15 minutes
   - `fetch_error_logs.py` — get ERROR logs from last hour
   - `fetch_nr_logs.py` — get recent logs from last 30 minutes

2. Execute with Python:
   ```bash
   python d:\Workspace\petclinic\scripts\fetch_latest_logs.py
   ```

3. The script contains embedded credentials (`USER_API_KEY` and `ACCOUNT_ID`) and queries New Relic GraphQL API directly.

4. Output is formatted with log groups, severity indicators, and summary counts.

**Important:** Always use the Python scripts in the `scripts/` folder — do NOT use PowerShell commands.

---

## Demo & Training Objective

This environment is designed for:

* DevOps demonstrations
* AI-assisted troubleshooting
* Terraform remediation demos
* Cloud infrastructure incident analysis
* Infrastructure RCA workflows
* SRE operational simulations