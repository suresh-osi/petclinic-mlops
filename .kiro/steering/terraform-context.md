---
inclusion: always
---

# Terraform Infrastructure Context

## Platform Overview

| Component | Technology |
|-----------|------------|
| Cloud | AWS |
| IaC | Terraform |
| Application | [Application Name] |
| Runtime | [Runtime Environment] |
| Deployment | [Deployment Method] |

---

## Infrastructure Components

| Component | Terraform Resource | Description |
|-----------|-------------------|-------------|
| VPC | `aws_vpc` | Main VPC for infrastructure |
| Public Subnets | `aws_subnet` | Subnets across availability zones |
| Route Tables | `aws_route_table` | Routes for subnets |
| Internet Gateway | `aws_internet_gateway` | Internet connectivity |
| Security Groups | `aws_security_group` | Network ACLs |
| Compute | `aws_instance` / `aws_launch_template` | Application servers |
| Load Balancer | `aws_lb` | Application or Network Load Balancer |
| Target Groups | `aws_lb_target_group` | Health check and routing |
| Listener | `aws_lb_listener` | Traffic routing rules |

---

## Terraform Standards

### Infrastructure Rules

* All resources **must** be created through Terraform
* Manual console changes are **prohibited**
* Infrastructure must be **idempotent**
* Resources must support **automated remediation**
* State files must be stored remotely in production

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

### Best Practices

* Use variables for all configurable values — never hardcode
* Reference resources via `aws_resource.name.id` syntax
* Use `depends_on` for explicit resource ordering when needed
* Always include `tags` block with `Name` and `Environment`
* Use `terraform plan` before `terraform apply`

---

## Networking Standards

### Load Balancer Configuration

| Setting | Value |
|---------|-------|
| Listener Port | [Port] |
| Target Port | [Port] |
| Health Check Path | [Health Endpoint] |
| Health Check Protocol | HTTP/HTTPS |

**Rules:**
* Load balancer must expose configured listener port
* Load balancer forwards traffic to backend instances
* Target groups must use health checks
* Health checks must match application's actual endpoints

### Security Group Rules

#### Load Balancer Security Group

| Direction | Port | Protocol | Source | Description |
|-----------|------|----------|--------|-------------|
| Inbound | [Port] | TCP | Configured CIDR | Inbound traffic |
| Outbound | All | All | 0.0.0.0/0 | All outbound |

**Denied:**
* Direct SSH access to load balancer

#### Backend Instance Security Group

| Direction | Port | Protocol | Source | Description |
|-----------|------|----------|--------|-------------|
| Inbound | [Port] | TCP | LB Security Group | From LB only |
| Inbound | [SSH Port] | TCP | Configured CIDR | SSH for troubleshooting |
| Outbound | All | All | 0.0.0.0/0 | All outbound |

---

## Application Standards

### Application Configuration

| Setting | Value |
|---------|-------|
| Runtime | [Runtime Environment] |
| Framework | [Framework Name] |
| Build Tool | [Build Tool] |
| Port | [Application Port] |
| Health Endpoint | [Health Check Path] |
| Deployment | [Deployment Method] |

**Startup:**
* Application started through userdata/init script
* [Containerization status]
* Build tool builds artifact locally

**Expected Behavior:**
* Application starts on configured port
* Health check returns HTTP 200
* No external dependencies required for basic health

---

## Incident Investigation Rules

When application is unavailable, AI must validate:

1. **Load balancer listener configuration** — Port and protocol
2. **Target group health** — Check `UnHealthyHostCount` metric
3. **Health check path** — Must match application endpoint
4. **Backend application availability** — SSH and test local connectivity
5. **Security group rules** — Backend allows traffic from LB security group
6. **Route table configuration** — Subnets route to IGW/NAT
7. **Terraform resource dependencies** — Verify `depends_on` and references

---

## Common Failure Scenarios

| Scenario | Symptom | Root Cause | Remediation |
|----------|---------|------------|-------------|
| Wrong health check path | HTTP 503, targets unhealthy | Health check path mismatch | Update `terraform.tfvars` → correct health check path |
| Wrong target port | Connection timeout | Port misconfiguration | Update `terraform.tfvars` → correct port |
| Security group misconfig | Connection refused | Backend SG blocks LB ingress | Update `security_groups.tf` → allow port from LB SG |
| Route table misconfig | No internet access | Missing IGW/NAT route | Update `vpc.tf` → add route |
| UserData failure | App not starting | Script errors | Check userdata/init script and logs |

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

## Terraform Remediation Rules

When fixing infrastructure:

**Do:**
* Modify Terraform files only
* Use `terraform plan` before `terraform apply`
* Preserve resource integrity — avoid `replace` when possible
* Update `terraform.tfvars` for configuration changes
* Run `terraform apply` after Git commit

**Do Not:**
* Make manual AWS Console changes
* Skip `terraform plan`
* Commit `terraform.tfvars` with secrets
* Use `terraform destroy` without approval

---

## GitOps Standards

All infrastructure changes require:

1. **Git branch creation** — `git checkout -b fix/<issue>`
2. **Git commit** — Format: `fix: <issue description>`
3. **Terraform apply** — `terraform apply` after merge
4. **Validation testing** — Confirm fix with test command or console

**Example workflow:**
```bash
git checkout -b fix/<issue>
# Edit terraform.tfvars
git add infrastructure/environments/dev/terraform.tfvars
git commit -m "fix: corrected [issue]"
git push -u origin fix/<issue>
```

---

## Validation Rules

After remediation, AI must validate:

| Check | Command | Expected Result |
|-------|---------|-----------------|
| Target group healthy | AWS Console → Target Groups | Status: healthy |
| Load balancer accessible | `curl -I http://<lb-dns>` | HTTP 200 OK |
| Application functional | API/Browser access | Service responds correctly |

**Validation command example:**
```bash
curl -I http://<lb-dns>
```

Expected result: `HTTP/1.1 200 OK`

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
* Validate with test commands against load balancer DNS
* Check `terraform.tfstate` for resource IDs when needed

**Do Not:**
* Suggest manual AWS Console changes
* Recommend containerization unless explicitly requested
* Skip GitOps workflow for any change
* Omit validation steps from remediation
* Modify state files directly

---

## Demo & Training Objective

This environment is designed for:

* DevOps demonstrations
* AI-assisted troubleshooting
* Terraform remediation demos
* AWS incident analysis
* Infrastructure RCA workflows
* SRE operational simulations

**Key Learning Outcomes:**
* Understanding Terraform state management
* GitOps workflow for infrastructure changes
* RCA methodology for cloud incidents
* Security group troubleshooting
* Load balancer and target group health checks