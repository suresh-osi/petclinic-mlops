# ALB Health Check Failure Playbook

| Field | Value |
|-------|-------|
| **Playbook Name** | ALB Health Check Failure |
| **Severity Level** | P2 — Service degraded, partial outage |
| **Runbook Owner** | DevOps Team |
| **Last Updated** | 2025-07-15 |
| **Related Services** | AWS ALB, EC2, Security Groups |
| **Auto-Remediation Available** | No — requires human review |

---

## Executive Summary

ALB target group reports unhealthy targets, resulting in HTTP 503 responses. The application is unreachable via the load balancer.

---

## Symptoms

* HTTP 503 from ALB DNS
* Target group shows targets as unhealthy in AWS Console
* Application UI not loading
* CloudWatch `UnHealthyHostCount` metric > 0

---

## Architecture Reference

| Component | Configuration | Terraform Reference |
|-----------|---------------|---------------------|
| ALB Listener | HTTP port | `aws_lb_listener.listener.port` |
| EC2 App Port | Application port | `var.app_port` |
| Health Check Path | Health endpoint | `var.health_check_path` |
| ALB Name | Load balancer name | `aws_lb.alb.name` |
| Target Group | Target group name | `aws_lb_target_group.tg.name` |
| EC2 SG Inbound | Port from ALB SG | `aws_security_group.ec2_sg` |

---

## Investigation Steps

### 1. Check ALB Target Group Health
- Go to EC2 → Target Groups → [Target Group Name]
- Verify target health status and failure reason
- Check `Last status reason` for specific error (e.g., "Request timeout", "Health checks failed", "Connection refused")

### 2. Validate Health Check Configuration
- In `infrastructure/environments/dev/alb.tf`, locate the `health_check` block
- Confirm `path` matches `var.health_check_path` (or hardcoded value)
- Confirm the health check protocol matches the application protocol (HTTP vs HTTPS)
- Verify the health check port is set to `traffic-port` or the correct port

### 3. Verify Application Port Configuration
- ALB listener forwards to the target group port (typically `var.app_port`)
- EC2 security group (`ec2_sg`) must allow inbound on the application port from ALB security group
- Verify the ingress rule references the ALB security group ID, not a hardcoded CIDR

### 4. Check EC2 Application Availability
- SSH into EC2 instance
- Test the health check endpoint: `curl -v http://localhost:<app_port><health_check_path>`
- Expected: HTTP 200 response
- Test the main application endpoint: `curl -v http://localhost:<app_port>/`
- Expected: Application responds

### 5. Check EC2 App Logs
- Check systemd journal: `sudo journalctl -u <service-name> --no-pager -n 100`
- Check application log files: `sudo tail -f /var/log/<application>/<application>.log`
- Look for startup errors, port binding failures, or configuration errors

### 6. Verify Security Group Rules
- Check ALB security group allows inbound on listener port (e.g., 80) from required CIDR
- Check EC2 security group allows inbound on application port from ALB security group
- Check all security groups allow outbound traffic

### 7. Verify Route Table Configuration
- Check public subnets have route to Internet Gateway (0.0.0.0/0 → igw-xxx)
- Verify route table is associated with correct subnets

---

## Common Root Causes

### Scenario 1 — Wrong Health Check Path
- **Symptom**: HTTP 503, targets unhealthy, health check returns 404
- **Cause**: `health_check_path` does not match actual application endpoint, or the path was hardcoded to an incorrect value (e.g., `/nonexistent-health-check`) in `alb.tf` instead of referencing `var.health_check_path`
- **Fix**: Ensure `alb.tf` uses `path = var.health_check_path` and set the correct value in `infrastructure/environments/dev/terraform.tfvars` → `health_check_path = "/"`

### Scenario 2 — Wrong Target Port
- **Symptom**: Connection timeout on health check
- **Cause**: `app_port` variable not matching actual application port
- **Fix**: Update `infrastructure/environments/dev/terraform.tfvars` → set `app_port` to correct port

### Scenario 3 — Security Group Misconfiguration
- **Symptom**: Connection refused, health check fails immediately
- **Cause**: EC2 security group not allowing inbound from ALB security group on application port
- **Fix**: Update `infrastructure/environments/dev/security_groups.tf` → EC2 SG ingress must reference ALB SG ID

### Scenario 4 — Application Not Running
- **Symptom**: Health check times out or connection refused
- **Cause**: Application process not started or crashed
- **Fix**: Check application logs and restart service via userdata script or manual intervention

### Scenario 5 — Route Table Misconfiguration
- **Symptom**: No internet access from EC2, health checks fail
- **Cause**: Public subnet route table missing IGW route
- **Fix**: Update `infrastructure/environments/dev/vpc.tf` → add route to IGW

### Scenario 6 — Wrong Health Check Protocol
- **Symptom**: Health check fails with SSL/TLS errors
- **Cause**: ALB configured for HTTPS but app only supports HTTP (or vice versa)
- **Fix**: Ensure `health_check.protocol` matches application protocol

---

## Remediation

### Step 1 — Identify the Misconfiguration

```bash
# Navigate to environment directory
cd infrastructure/environments/dev

# Review current variable values
cat terraform.tfvars

# Review ALB configuration
cat alb.tf | grep -A 10 "health_check"

# Review security group configuration
cat security_groups.tf
```

### Step 2 — Review Terraform Code

Check `infrastructure/environments/dev/alb.tf` for health check configuration:
```hcl
health_check = {
  enabled             = true
  healthy_threshold   = 2
  interval            = 30
  matcher             = "200"
  path                = var.health_check_path
  port                = "traffic-port"
  protocol            = "HTTP"
  timeout             = 5
  unhealthy_threshold = 3
}
```

### Step 3 — Apply the Fix

Edit `infrastructure/environments/dev/terraform.tfvars` with correct values:
```hcl
health_check_path = "/correct-path"
app_port          = <correct-port>
```

Or fix `security_groups.tf` to reference ALB SG:
```hcl
ingress {
  from_port   = var.app_port
  to_port     = var.app_port
  protocol    = "tcp"
  security_groups = [aws_security_group.alb_sg.id]
}
```

### Step 4 — Plan and Apply

```bash
cd infrastructure/environments/dev
terraform plan
terraform apply
```

---

## Validation

After applying the fix, validate recovery:

```bash
# Get ALB DNS from Terraform output
terraform output alb_dns

# Test HTTP response
curl -I http://<alb-dns>

# Verify target health
terraform output target_group_name
```

Expected result: `HTTP/1.1 200 OK`

Also verify in AWS Console:
- Target group → Targets → Status: **healthy**
- CloudWatch → Metrics → ALB → `UnHealthyHostCount` = 0

---

## Escalation Path

| Severity | Action | Contact |
|----------|--------|---------|
| P2 (Service Degraded) | Notify DevOps Team | #devops-alerts channel |
| P1 (Complete Outage) | Escalate to Engineering Lead | PagerDuty |

---

## Timeline Tracking

| Event | Timestamp | Action |
|-------|-----------|--------|
| Incident Detected | | |
| Investigation Started | | |
| Root Cause Identified | | |
| Remediation Started | | |
| Service Restored | | |
| Post-Incident Review | | Schedule within 72 hours |

---

## Post-Incident Review (PIR)

Trigger a PIR when:
- Incident duration > 30 minutes
- Multiple root causes identified
- Remediation required multiple team members

PIR output should include:
- Timeline of events
- Root cause analysis
- Impact assessment
- Action items for prevention

---

## GitOps Requirements

All remediation changes must follow the GitOps workflow:

```bash
git checkout -b fix/alb-healthcheck-path
git add infrastructure/environments/dev/terraform.tfvars
git commit -m "fix: corrected ALB health check path"
git push -u origin fix/alb-healthcheck-path
```

---

## Preventive Recommendations

* Pin `health_check_path` explicitly in `terraform.tfvars` — do not rely on variable defaults
* Add ALB health check monitoring via CloudWatch alarm on `UnHealthyHostCount`
* Include a post-deploy validation step in `scripts/deploy.sh` that curls the ALB endpoint
* Add Terraform validation in CI/CD pipeline to catch misconfigurations before apply
* Use Terraform `validation` blocks to enforce correct health check paths
* Configure health check thresholds appropriately (not too aggressive)

---

## Related Playbooks

* [EC2 Application Failure](../playbooks/ec2-application-failure.md)
* [Security Group Misconfiguration](../playbooks/security-group-misconfiguration.md)
* [VPC Routing Issues](../playbooks/vpc-routing-issues.md)