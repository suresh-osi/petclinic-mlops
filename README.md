# Spring PetClinic Sample Application [![Build Status](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml/badge.svg)](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml)[![Build Status](https://github.com/spring-projects/spring-petclinic/actions/workflows/gradle-build.yml/badge.svg)](https://github.com/spring-projects/spring-petclinic/actions/workflows/gradle-build.yml)

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/spring-projects/spring-petclinic) [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=7517918)

## Understanding the Spring Petclinic application with a few diagrams

See the presentation here:  
[Spring Petclinic Sample Application (legacy slides)](https://speakerdeck.com/michaelisvy/spring-petclinic-sample-application?slide=20)

> **Note:** These slides refer to a legacy, pre–Spring Boot version of Petclinic and may not reflect the current Spring Boot–based implementation.  
> For up-to-date information, please refer to this repository and its documentation.


## Run Petclinic locally

Spring Petclinic is a [Spring Boot](https://spring.io/guides/gs/spring-boot) application built using [Maven](https://spring.io/guides/gs/maven/) or [Gradle](https://spring.io/guides/gs/gradle/).
Java 17 or later is required for the build, and the application can run with Java 17 or newer.

You first need to clone the project locally:

```bash
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
```
If you are using Maven, you can start the application on the command-line as follows:

```bash
./mvnw spring-boot:run
```
With Gradle, the command is as follows:

```bash
./gradlew bootRun
```

You can then access the Petclinic at <http://localhost:8080/>.

<img width="1042" alt="petclinic-screenshot" src="https://cloud.githubusercontent.com/assets/838318/19727082/2aee6d6c-9b8e-11e6-81fe-e889a5ddfded.png">

You can, of course, run Petclinic in your favorite IDE.
See below for more details.

## Building a Container

There is no `Dockerfile` in this project. You can build a container image (if you have a docker daemon) using the Spring Boot build plugin:

## Running the Container Image

```bash
./mvnw spring-boot:build-image
docker images | grep petclinic
docker run -p 8080:8080 docker.io/library/spring-petclinic:latest
```

## In case you find a bug/suggested improvement for Spring Petclinic

Our issue tracker is available [here](https://github.com/spring-projects/spring-petclinic/issues).

## Database configuration

In its default configuration, Petclinic uses an in-memory database (H2) which
gets populated at startup with data. The h2 console is exposed at `http://localhost:8080/h2-console`,
and it is possible to inspect the content of the database using the `jdbc:h2:mem:<uuid>` URL. The UUID is printed at startup to the console.

A similar setup is provided for MySQL and PostgreSQL if a persistent database configuration is needed. Note that whenever the database type changes, the app needs to run with a different profile: `spring.profiles.active=mysql` for MySQL or `spring.profiles.active=postgres` for PostgreSQL. See the [Spring Boot documentation](https://docs.spring.io/spring-boot/how-to/properties-and-configuration.html#howto.properties-and-configuration.set-active-spring-profiles) for more detail on how to set the active profile.

You can start MySQL or PostgreSQL locally with whatever installer works for your OS or use docker:

```bash
docker run -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:9.6
```

or

```bash
docker run -e POSTGRES_USER=petclinic -e POSTGRES_PASSWORD=petclinic -e POSTGRES_DB=petclinic -p 5432:5432 postgres:18.3
```

Further documentation is provided for [MySQL](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/resources/db/mysql/petclinic_db_setup_mysql.txt)
and [PostgreSQL](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/resources/db/postgres/petclinic_db_setup_postgres.txt).

Instead of vanilla `docker` you can also use the provided `docker-compose.yml` file to start the database containers. Each one has a service named after the Spring profile:

```bash
docker compose up mysql
```

or

```bash
docker compose up postgres
```

## Test Applications

At development time we recommend you use the test applications set up as `main()` methods in `PetClinicIntegrationTests` (using the default H2 database and also adding Spring Boot Devtools), `MySqlTestApplication` and `PostgresIntegrationTests`. These are set up so that you can run the apps in your IDE to get fast feedback and also run the same classes as integration tests against the respective database. The MySql integration tests use Testcontainers to start the database in a Docker container, and the Postgres tests use Docker Compose to do the same thing.

## Compiling the CSS

There is a `petclinic.css` in `src/main/resources/static/resources/css`. It was generated from the `petclinic.scss` source, combined with the [Bootstrap](https://getbootstrap.com/) library. If you make changes to the `scss`, or upgrade Bootstrap, you will need to re-compile the CSS resources using the Maven profile "css", i.e. `./mvnw package -P css`. There is no build profile for Gradle to compile the CSS.

## Working with Petclinic in your IDE

### Prerequisites

The following items should be installed in your system:

- Java 17 or newer (full JDK, not a JRE)
- [Git command line tool](https://help.github.com/articles/set-up-git)
- Your preferred IDE
  - Eclipse with the m2e plugin. Note: when m2e is available, there is a m2 icon in `Help -> About` dialog. If m2e is
  not there, follow the installation process [here](https://www.eclipse.org/m2e/)
  - [Spring Tools Suite](https://spring.io/tools) (STS)
  - [IntelliJ IDEA](https://www.jetbrains.com/idea/)
  - [VS Code](https://code.visualstudio.com)

### Steps

1. On the command line run:

    ```bash
    git clone https://github.com/spring-projects/spring-petclinic.git
    ```

1. Inside Eclipse or STS:

    Open the project via `File -> Import -> Maven -> Existing Maven project`, then select the root directory of the cloned repo.

    Then either build on the command line `./mvnw generate-resources` or use the Eclipse launcher (right-click on project and `Run As -> Maven install`) to generate the CSS. Run the application's main method by right-clicking on it and choosing `Run As -> Java Application`.

1. Inside IntelliJ IDEA:

    In the main menu, choose `File -> Open` and select the Petclinic [pom.xml](pom.xml). Click on the `Open` button.

    - CSS files are generated from the Maven build. You can build them on the command line `./mvnw generate-resources` or right-click on the `spring-petclinic` project then `Maven -> Generates sources and Update Folders`.

    - A run configuration named `PetClinicApplication` should have been created for you if you're using a recent Ultimate version. Otherwise, run the application by right-clicking on the `PetClinicApplication` main class and choosing `Run 'PetClinicApplication'`.

1. Navigate to the Petclinic

    Visit [http://localhost:8080](http://localhost:8080) in your browser.

## Looking for something in particular?

|Spring Boot Configuration | Class or Java property files  |
|--------------------------|---|
|The Main Class | [PetClinicApplication](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/java/org/springframework/samples/petclinic/PetClinicApplication.java) |
|Properties Files | [application.properties](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/resources) |
|Caching | [CacheConfiguration](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/java/org/springframework/samples/petclinic/system/CacheConfiguration.java) |

## Interesting Spring Petclinic branches and forks

The Spring Petclinic "main" branch in the [spring-projects](https://github.com/spring-projects/spring-petclinic)
GitHub org is the "canonical" implementation based on Spring Boot and Thymeleaf. There are
[quite a few forks](https://spring-petclinic.github.io/docs/forks.html) in the GitHub org
[spring-petclinic](https://github.com/spring-petclinic). If you are interested in using a different technology stack to implement the Pet Clinic, please join the community there.

## Interaction with other open-source projects

One of the best parts about working on the Spring Petclinic application is that we have the opportunity to work in direct contact with many Open Source projects. We found bugs/suggested improvements on various topics such as Spring, Spring Data, Bean Validation and even Eclipse! In many cases, they've been fixed/implemented in just a few days.
Here is a list of them:

| Name | Issue |
|------|-------|
| Spring JDBC: simplify usage of NamedParameterJdbcTemplate | [SPR-10256](https://github.com/spring-projects/spring-framework/issues/14889) and [SPR-10257](https://github.com/spring-projects/spring-framework/issues/14890) |
| Bean Validation / Hibernate Validator: simplify Maven dependencies and backward compatibility |[HV-790](https://hibernate.atlassian.net/browse/HV-790) and [HV-792](https://hibernate.atlassian.net/browse/HV-792) |
| Spring Data: provide more flexibility when working with JPQL queries | [DATAJPA-292](https://github.com/spring-projects/spring-data-jpa/issues/704) |

## Contributing

The [issue tracker](https://github.com/spring-projects/spring-petclinic/issues) is the preferred channel for bug reports, feature requests and submitting pull requests.

For pull requests, editor preferences are available in the [editor config](.editorconfig) for easy use in common text editors. Read more and download plugins at <https://editorconfig.org>. All commits must include a __Signed-off-by__ trailer at the end of each commit message to indicate that the contributor agrees to the Developer Certificate of Origin.
For additional details, please refer to the blog post [Hello DCO, Goodbye CLA: Simplifying Contributions to Spring](https://spring.io/blog/2025/01/06/hello-dco-goodbye-cla-simplifying-contributions-to-spring).

## AWS Infrastructure (Terraform)

The `infrastructure/environments/dev/` directory contains Terraform configuration for deploying PetClinic to AWS.

### Terraform File Structure

**Dev environment** (`infrastructure/environments/dev/`):

| File | Contents |
|------|----------|
| `vpc.tf` | VPC, subnets, internet gateway, route tables, and route table associations |
| `main.tf` | Security groups, EC2 instance, ALB, target group, and listener |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output values (e.g., ALB DNS name) |
| `provider.tf` | AWS provider configuration |
| `userdata.sh` | EC2 bootstrap script — installs Java 17, clones the repo, builds and starts the app |

**MLOps environment** (`infrastructure/environments/mlops/`):

| File | Contents |
|------|----------|
| `provider.tf` | AWS provider configuration (`hashicorp/aws ~> 5.0`, region via variable) |

### Architecture

| Component | Details |
|-----------|---------|
| VPC | `10.0.0.0/16`, DNS support enabled |
| Subnets | Two public (`10.0.1.0/24`, `10.0.2.0/24`) across `ap-south-1a` and `ap-south-1b` |
| EC2 | Ubuntu 22.04, runs the Spring Boot JAR directly on port 8080 |
| ALB | Public-facing, HTTP port 80, forwards to EC2 port 8080 |
| Target Group | Port 8080, HTTP health checks |

### CI/CD Pipeline & EKS (MLOps Environment)

CI/CD (CodePipeline + CodeBuild), EKS, and SageMaker resources are managed in the separate MLOps environment at `infrastructure/environments/mlops/`. They are not part of the dev environment.

### Configurable Variables

All infrastructure settings are parameterized in `variables.tf`. You can override any of these in `terraform.tfvars` or via `-var` flags.

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `ap-south-1` | AWS region to deploy resources |
| `instance_type` | `t3.small` | EC2 instance type |
| `vpc_cidr` | `10.0.0.0/16` | CIDR block for the VPC |
| `public_subnet_1_cidr` | `10.0.1.0/24` | CIDR block for public subnet 1 |
| `public_subnet_2_cidr` | `10.0.2.0/24` | CIDR block for public subnet 2 |
| `availability_zone_1` | `ap-south-1a` | AZ for public subnet 1 |
| `availability_zone_2` | `ap-south-1b` | AZ for public subnet 2 |
| `app_port` | `8080` | Port the application listens on |
| `alb_listener_port` | `80` | Port the ALB listener exposes |
| `health_check_path` | `/` | ALB target group health check path |
| `alb_name` | `petclinic-alb` | Name of the Application Load Balancer |
| `target_group_name` | `petclinic-tg` | Name of the ALB target group |
| `ec2_name_tag` | `petclinic-server` | Name tag applied to the EC2 instance |
| `ssh_cidr` | `0.0.0.0/0` | CIDR allowed for SSH access |
| `ubuntu_ami_owner` | `099720109477` | AWS account ID of the Ubuntu AMI owner (Canonical) |
| `ubuntu_ami_filter` | `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*` | Name filter for the Ubuntu AMI lookup |
| `internet_route_cidr` | `0.0.0.0/0` | Destination CIDR for the default internet route in the VPC route table |
| `alb_ingress_cidr` | `0.0.0.0/0` | CIDR block allowed for ALB HTTP ingress |
| `alb_egress_cidr` | `0.0.0.0/0` | CIDR block allowed for ALB egress |
| `ec2_egress_cidr` | `0.0.0.0/0` | CIDR block allowed for EC2 egress |
| `newrelic_external_id` | `""` | External ID for NewRelic IAM role trust policy |
| `newrelic_license_key` | `""` | NewRelic Ingest License Key for log forwarding (sensitive) |
| `newrelic_account_id` | `8131360` | NewRelic Account ID |
| `newrelic_user_api_key` | `"<YOUR_NRAK_API_KEY>"` | NewRelic User API Key for querying logs (starts with `NRAK-`) |

Example — deploy to a different region with a larger instance:

```bash
terraform apply -var="aws_region=us-east-1" -var="instance_type=t3.small"
```

### Terraform State Backend

Terraform state is stored remotely in S3 for the dev environment:

| Setting | Value |
|---------|-------|
| Bucket | `petclinic-tfstate-633426742056` |
| Key | `environments/dev/terraform.tfstate` |
| Region | `ap-south-1` |
| Encryption | Enabled (SSE) |

> **Note:** The S3 bucket must exist before running `terraform init`. State locking is not configured — consider adding a DynamoDB lock table for team environments.

### MLOps Environment

A separate Terraform environment at `infrastructure/environments/mlops/` hosts the MLOps-specific infrastructure in `us-east-1`. It provisions its own VPC, EKS cluster, and SageMaker resources independently from the dev environment.

| Setting | Value |
|---------|-------|
| Provider | `hashicorp/aws ~> 5.0` |
| Region | `us-east-1` (via `var.aws_region`) |

**MLOps Terraform files:**

| File | Contents |
|------|----------|
| `main.tf` | Data sources (caller identity, ECR authorization) |
| `provider.tf` | AWS provider configuration |
| `variables.tf` | Input variable declarations |
| `vpc.tf` | VPC, public/private subnets, IGW, NAT gateway, route tables |
| `eks.tf` | EKS cluster, node group, and IAM roles |
| `ecr.tf` | ECR repositories for ML containers |
| `sagemaker.tf` | SageMaker endpoint configuration |
| `codepipeline.tf` | CodePipeline, CodeBuild projects, and IAM roles (conditionally deployed) |
| `monitoring.tf` | CloudWatch dashboard and alarms |

**Conditional Resources — CodePipeline:**

The CodePipeline and its IAM role are only created when `var.codestar_connection_arn` is set to a non-empty value. This allows the base infrastructure (EKS, ECR, SageMaker) to be provisioned without requiring a GitHub CodeStar connection upfront.

To enable the CI/CD pipeline, set the variable in `terraform.tfvars`:

```hcl
codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:123456789012:connection/your-connection-id"
```

The pipeline tracks the `master` branch by default (configured via `github_branch` in `terraform.tfvars`). To change the tracked branch, update:

```hcl
github_branch = "master"  # branch that triggers the pipeline
```

When the connection ARN is not set, the `codepipeline_name` output will display `"not-deployed (set codestar_connection_arn first)"`.

**MLOps Architecture:**

| Component | Details |
|-----------|---------|
| VPC | `10.1.0.0/16`, DNS support enabled |
| Subnets | Two public (`10.1.1.0/24`, `10.1.2.0/24`) + two private (`10.1.3.0/24`, `10.1.4.0/24`) in `us-east-1a` / `us-east-1b` |
| EKS Cluster | `petclinic-eks-cluster`, Kubernetes 1.31, public + private endpoint access |
| EKS Node Group | `petclinic-mlops-nodes`, workers in private subnets, auto-scaling (1–3 nodes, `t3.micro`) |
| NAT Gateway | Provides internet access for EKS nodes in private subnets |
| SageMaker Endpoint | `petclinic-predict-endpoint` for ML inference |

**EKS Node IAM Permissions (MLOps):**
- `AmazonEKSWorkerNodePolicy` — basic EKS node operations
- `AmazonEKS_CNI_Policy` — VPC CNI networking
- `AmazonEC2ContainerRegistryReadOnly` — pull images from ECR
- Custom policy: `sagemaker:InvokeEndpoint` — allows EKS pods to call the SageMaker prediction endpoint

**Deploy MLOps environment:**

```bash
cd infrastructure/environments/mlops
terraform init
terraform plan
terraform apply
```

**Key difference from dev environment:** The MLOps EKS cluster is always provisioned (no `deploy_eks` flag) since it's the primary compute layer for running the PetClinic application alongside ML inference workloads.

### Deploying

```bash
cd infrastructure/environments/dev
terraform init   # initializes and configures the S3 backend
terraform apply
```

### Security Groups

Security group rules are fully parameterized and controlled through `variables.tf`.

**ALB Security Group (`alb_sg`)**

| Direction | Port | Source | Controlled by |
|-----------|------|--------|---------------|
| Inbound | `var.alb_listener_port` (default: 80) | `0.0.0.0/0` | `alb_listener_port` variable |
| Outbound | All | `0.0.0.0/0` | — |

**EC2 Security Group (`ec2_sg`)**

| Direction | Port | Source | Controlled by |
|-----------|------|--------|---------------|
| Inbound | `var.app_port` (default: 8080) | ALB security group only | `app_port` variable |
| Inbound | 22 (SSH) | `var.ssh_cidr` (default: `0.0.0.0/0`) | `ssh_cidr` variable |
| Outbound | All | `0.0.0.0/0` | — |

To restrict SSH access to a specific IP range, set `ssh_cidr` in `terraform.tfvars`:

```hcl
ssh_cidr = "203.0.113.0/24"
```

### Health Check

> ⚠️ **Intentional Misconfiguration (Demo/Training):** The health check path in `alb.tf` is currently hardcoded to `/nonexistent-health-check` instead of referencing `var.health_check_path`. This causes ALB targets to report unhealthy and results in HTTP 503 responses — the intended broken state for RCA training.
>
> **Root cause:** `alb.tf` uses `path = "/nonexistent-health-check"` instead of `path = var.health_check_path`.
>
> **Fix:** Restore `alb.tf` to use `path = var.health_check_path`, then ensure `terraform.tfvars` has `health_check_path = "/"`. See the [ALB Health Check Failure Playbook](.kiro/playbooks/alb-healthcheck-failure.md) for the full RCA and remediation steps.

When correctly configured, the ALB target group health check uses path `/`, which maps to the Spring PetClinic root endpoint and returns HTTP 200, ensuring ALB targets report healthy after the application starts.

### NewRelic Integration

NewRelic can be integrated with this infrastructure for log monitoring. Two key types are used:

| Key Type | Variable | Prefix | Purpose |
|----------|----------|--------|---------|
| **Ingest Key** | `newrelic_license_key` | `NRAL-...` | Send logs/metrics TO New Relic (write-only) |
| **User API Key** | `newrelic_user_api_key` | `NRAK-...` | Query logs FROM New Relic (read) |

#### Enable Log Forwarding (CloudWatch → NewRelic)

1. Follow the setup steps in [`newrelic-setup.md`](infrastructure/environments/dev/newrelic-setup.md)
2. Set the required variables in `terraform.tfvars`:

```hcl
newrelic_external_id = "YOUR-EXTERNAL-ID-HERE"
newrelic_account_id  = "YOUR-ACCOUNT-ID"
```

3. For the license key (sensitive), use an environment variable:

```bash
export TF_VAR_newrelic_license_key="YOUR-LICENSE-KEY"
terraform apply
```

The NewRelic CloudWatch integration role ARN is available in Terraform outputs after apply.

#### Query Logs from New Relic

To query logs programmatically or in the New Relic UI, add your User API Key:

```hcl
newrelic_user_api_key = "NRAK-YOUR-USER-API-KEY"
```

**Note:**
- `newrelic_license_key` is marked `sensitive = true` — never commit it to source control
- `newrelic_user_api_key` is for read-only queries — use for debugging and log exploration
- With an empty `newrelic_external_id` (the default), the IAM trust policy will not allow NewRelic to assume the role

For more details, see the [NewRelic AWS integration documentation](https://docs.newrelic.com/docs/aws-integrations/).

## License

The Spring PetClinic sample application is released under version 2.0 of the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).
### Security Groups

Security group rules are fully parameterized and controlled through `variables.tf`.

**ALB Security Group (`alb_sg`)**

| Direction | Port | Source | Controlled by |
|-----------|------|--------|---------------|
| Inbound | `var.alb_listener_port` (default: 80) | `0.0.0.0/0` | `alb_listener_port` variable |
| Outbound | All | `0.0.0.0/0` | — |

**EC2 Security Group (`ec2_sg`)**

| Direction | Port | Source | Controlled by |
|-----------|------|--------|---------------|
| Inbound | `var.app_port` (default: 8080) | ALB security group only | `app_port` variable |
| Inbound | 22 (SSH) | `var.ssh_cidr` (default: `0.0.0.0/0`) | `ssh_cidr` variable |
| Outbound | All | `0.0.0.0/0` | — |

**Security Best Practice:**
The EC2 security group is configured to accept inbound traffic on the application port **only from the ALB security group**, not from public CIDR blocks. This restricts direct access to the EC2 instance and ensures all traffic flows through the load balancer.

To restrict SSH access to a specific IP range, set `ssh_cidr` in `terraform.tfvars`:

```hcl
ssh_cidr = "203.0.113.0/24"
```# petclinic-mlops
