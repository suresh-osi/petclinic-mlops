# PetClinic Infrastructure - Dev Environment

This directory contains Terraform configuration for deploying the Spring PetClinic application to AWS.

## Current Configuration

### Variables

The following variables are currently defined in `variables.tf`:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `newrelic_license_key` | NewRelic Ingest License Key | (empty) | Yes |
| `newrelic_account_id` | NewRelic Account ID | `8131360` | No |
| `environment` | Environment name | `dev` | No |
| `alb_name` | Application Load Balancer name | `petclinic-alb` | No |
| `app_port` | Application server port | `8080` | No |
| `alb_listener_port` | ALB listener port | `80` | No |
| `health_check_path` | Health check endpoint | `/` | No |
| `ssh_cidr` | CIDR for SSH access | `0.0.0.0/0` | No |

### Deployed Resources

| Resource | Type | Description |
|----------|------|-------------|
| `aws_vpc.main` | VPC | Main VPC for infrastructure |
| `aws_subnet.public_1` | Subnet | Public subnet in AZ 1 |
| `aws_subnet.public_2` | Subnet | Public subnet in AZ 2 |
| `aws_internet_gateway.gw` | IGW | Internet gateway |
| `aws_route_table.rt` | Route Table | Routes for public subnets |
| `aws_security_group.alb_sg` | Security Group | ALB security group |
| `aws_security_group.ec2_sg` | Security Group | EC2 security group |
| `aws_lb.alb` | ALB | Application Load Balancer |
| `aws_lb_target_group.tg` | Target Group | ALB target group |
| `aws_lb_listener.listener` | Listener | ALB listener |
| `aws_instance.petclinic` | EC2 | Application server |
| `aws_lambda_function.newrelic_log_forwarder` | Lambda | NewRelic log forwarder |

### ALB Configuration

| Setting | Value |
|---------|-------|
| Listener Port | 80 (HTTP) |
| Target Port | 8080 |
| Health Check Path | `/` |
| Health Check Protocol | HTTP |

### Application Configuration

| Setting | Value |
|---------|-------|
| Runtime | Java 17, Spring Boot |
| Port | 8080 |
| Build Tool | Maven |
| Deployment | Direct on EC2 |

## Deployment

### Prerequisites

- Terraform >= 1.9
- AWS CLI configured with credentials
- NewRelic license key

### Deploy

```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

### Destroy

```bash
cd infrastructure/environments/dev
terraform destroy
```

## Validation

After deployment, verify:

```bash
# Get ALB DNS
terraform output alb_dns

# Test endpoint
curl http://<alb-dns>
```

Expected: HTTP 200 response

## Troubleshooting

See playbooks in `.kiro/playbooks/` for common issues:

- [ALB Health Check Failure](../.kiro/playbooks/alb-healthcheck-failure.md)
