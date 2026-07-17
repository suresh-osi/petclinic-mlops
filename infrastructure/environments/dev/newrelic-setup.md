# NewRelic Integration Setup Guide

## Overview
This guide walks you through setting up NewRelic to access AWS CloudWatch logs and metrics for the PetClinic application.

The log forwarding Lambda uses a **custom Python 3.12 forwarder** (`nr-log-forwarder.zip`) that sends CloudWatch logs directly to the NewRelic Log API via HTTP POST using your license key. The zip must be present in `infrastructure/environments/dev/` before running `terraform apply`.

## Prerequisites
- NewRelic account (sign up at https://newrelic.com/)
- AWS account with appropriate permissions
- `nr-log-forwarder.zip` placed in `infrastructure/environments/dev/` (see Step 1 below)

## Step 1: Prepare the Lambda Zip

The Lambda function requires `nr-log-forwarder.zip` to be present at `infrastructure/environments/dev/nr-log-forwarder.zip` before deploying.

The custom forwarder source is in `infrastructure/environments/dev/nr-lambda-src/function.py`. To build the zip:

```bash
cd infrastructure/environments/dev/nr-lambda-src
zip -j ../nr-log-forwarder.zip function.py
```

> **Note:** `nr-log-forwarder.zip` is a build artifact and should be in `.gitignore` — do not commit it to source control.

## Step 2: Create the IAM Role and Lambda in AWS

1. Navigate to the **infrastructure/environments/dev** directory
2. Run Terraform to create all resources:

```bash
terraform init
terraform plan
terraform apply
```

Terraform will:
- Deploy the custom `nr-log-forwarder.zip` as Lambda function `NewRelic-PetClinic-LogForwarder` (Python 3.12)
- Set up CloudWatch subscription filters to forward logs in real time

3. After applying, note the output:
   - **AWS Account ID**
   - **NewRelic IAM Role ARN**

## Step 3: Configure NewRelic AWS Integration

1. Log in to your NewRelic account
2. Navigate to **Observability > Integrations > AWS**
3. Click **Add Integration**
4. Select the services you want to integrate:
   - CloudWatch Logs
   - CloudWatch Metrics
   - EC2
   - ALB
   - Other relevant services

5. When prompted for role configuration:
   - **External ID**: You'll generate this in NewRelic
   - **Role ARN**: Use the output from TerraForm: `NewRelic-CloudWatch-Integration-Role`

## Step 4: Configure NewRelic Variables in Terraform

1. In NewRelic, when adding the AWS integration, NewRelic will provide an External ID
2. Update your `terraform.tfvars` file with the non-sensitive values:
   ```hcl
   newrelic_external_id = "your-external-id-from-newrelic"
   newrelic_account_id  = "your-newrelic-account-id"
   ```

   Then supply the license key via environment variable — **do not put it in `terraform.tfvars`**:
   ```bash
   export TF_VAR_newrelic_license_key="NRAL-your-license-key"
   terraform apply
   ```

   | Variable | Description | Where to find it | How to supply |
   |----------|-------------|-----------------|---------------|
   | `newrelic_external_id` | Trust policy External ID | NewRelic AWS integration setup | `terraform.tfvars` |
   | `newrelic_account_id` | Your NewRelic account number | NewRelic account settings | `terraform.tfvars` |
   | `newrelic_license_key` | Ingest License Key for log **sending** | NewRelic API keys — type: INGEST-LICENSE (`NRAL-...`) | **Environment variable** `TF_VAR_newrelic_license_key` |
   | `newrelic_user_api_key` | User API Key for log **querying** | NewRelic API keys — type: User (`NRAK-...`) | `terraform.tfvars` (optional, for local querying only) |

   > **Security Note:** `newrelic_license_key` is marked `sensitive = true` in Terraform and the `terraform.tfvars` entry is intentionally left blank. Never commit a real key value to source control. Always pass it via the `TF_VAR_newrelic_license_key` environment variable or a secrets manager.

3. Run `terraform apply` again to update the role with the correct external ID

## Step 5: Configure CloudWatch Log Group in NewRelic

1. In NewRelic, navigate to **Logs > Configuration**
2. Add a new CloudWatch log integration
3. Select the log groups created by your application:
   - `petclinic/apache-access-logs`
   - `petclinic/apache-error-logs`
   - `petclinic/userdata-logs`
   - `petclinic/application-logs`

## Step 6: Verify Integration

1. Check **Logs** in NewRelic to see your CloudWatch logs
2. Check **Metrics** to see CloudWatch metrics
3. Query logs using NRQL:
   ```sql
   FROM Log SELECT * WHERE logGroup = 'petclinic/apache-access-logs' LIMIT 10
   ```

---

## Step 7: Set Up User API Key for Log Querying

The `newrelic_license_key` (ingest key, `NRAL-...`) is **write-only** — it sends data to New Relic but **cannot** query or read logs back.

To fetch logs programmatically (e.g. via Kiro AI), you need a **User API key** (`NRAK-...`).

### Create a User API Key

1. Log in to [one.newrelic.com](https://one.newrelic.com)
2. Click your name (top right) → **API Keys**
3. Click **Create a key**
4. Select type: **User**
5. Give it a name (e.g. `petclinic-query-key`)
6. Copy the key — it starts with `NRAK-`

### Add to terraform.tfvars

```hcl
newrelic_user_api_key = "NRAK-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

> **Note:** This key is for querying only. Keep it separate from the ingest license key.

### Query Logs via API

Using PowerShell:
```powershell
$headers = @{ "API-Key" = "NRAK-..."; "Content-Type" = "application/json" }
$body = '{"query":"{ actor { account(id: 8131360) { nrql(query: \"FROM Log SELECT message, logGroup, timestamp WHERE logGroup LIKE \\u0027petclinic/%\\u0027 SINCE 30 minutes ago LIMIT 20\") { results } } } }"}'
Invoke-RestMethod -Uri "https://api.newrelic.com/graphql" -Method POST -Headers $headers -Body $body
```

Using curl:
```bash
curl -s -X POST https://api.newrelic.com/graphql \
  -H "API-Key: NRAK-..." \
  -H "Content-Type: application/json" \
  -d '{"query":"{ actor { account(id: 8131360) { nrql(query: \"FROM Log SELECT message, logGroup, timestamp WHERE logGroup LIKE '"'"'petclinic/%'"'"' SINCE 30 minutes ago LIMIT 20\") { results } } } }"}'
```

### Available Log Groups

| Log Group | Contents |
|-----------|----------|
| `petclinic/application-logs` | Spring Boot application logs |
| `petclinic/userdata-logs` | EC2 startup and setup script logs |
| `petclinic/apache-access-logs` | Apache HTTP access logs |
| `petclinic/apache-error-logs` | Apache HTTP error logs |

### Useful NRQL Queries

```sql
-- All petclinic logs (last 30 minutes)
FROM Log SELECT message, logGroup, timestamp
WHERE logGroup LIKE 'petclinic/%'
SINCE 30 minutes ago LIMIT 50

-- Application startup logs
FROM Log SELECT message, timestamp
WHERE logGroup = 'petclinic/application-logs'
SINCE 1 hour ago LIMIT 50

-- Error logs across all groups
FROM Log SELECT message, logGroup, timestamp
WHERE logGroup LIKE 'petclinic/%' AND message LIKE '%ERROR%'
SINCE 1 hour ago LIMIT 20

-- Userdata/setup logs
FROM Log SELECT message, timestamp
WHERE logGroup = 'petclinic/userdata-logs'
SINCE 2 hours ago LIMIT 50
```

---

## IAM Role Permissions

The created IAM role includes permissions for:

- **CloudWatch Logs**: Read access to log groups and query logs
- **CloudWatch Metrics**: Read access to metrics and alarms
- **EC2**: Read access to instance metadata
- **ALB**: Read access to load balancer configuration
- **Lambda, RDS, ECS, S3**: Read access to relevant resources

## Security Notes

- The role uses a trust policy with a specific External ID
- The role is limited to read-only operations
- All AWS resources are accessible via the role policy

## Troubleshooting

### Role cannot be assumed
- Verify the External ID matches exactly in both AWS and NewRelic
- Check the trust policy in the IAM role

### Logs not appearing in NewRelic
- Verify the log group names in NewRelic integration settings
- Check CloudWatch console to confirm logs are being written
- Ensure the CloudWatch Agent is running on the EC2 instance

### Lambda zip not found / deployment fails
- Ensure `nr-log-forwarder.zip` exists at `infrastructure/environments/dev/nr-log-forwarder.zip` before running `terraform apply`
- Build it from source: `cd infrastructure/environments/dev/nr-lambda-src && zip -j ../nr-log-forwarder.zip function.py`
- Verify the zip contains `function.py` with a `lambda_handler` entry point

### Metrics not appearing
- Verify CloudWatch Agent configuration in userdata.sh
- Check CloudWatch console to confirm metrics are being published
