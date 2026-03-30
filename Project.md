# ECS Threat Composer — AWS Infrastructure Project

A production-grade AWS deployment of the open-source [Threat Composer](https://awslabs.github.io/threat-composer/) tool, built to demonstrate end-to-end DevOps and Platform Engineering skills. The application is containerised, hosted on AWS ECS Fargate, and provisioned entirely via Terraform with a fully automated CI/CD pipeline using GitHub Actions.

**Live URL:** [https://tm.sc-threat-composer.com](https://tm.sc-threat-composer.com)

---

## Tools & Technologies

| Category | Tools |
|---|---|
| Cloud | AWS (ECS Fargate, ALB, ECR, ACM, Route 53, VPC) |
| IaC | Terraform (modular) |
| Containerisation | Docker (multi-stage build) |
| CI/CD | GitHub Actions with OIDC |
| DNS | Cloudflare + Route 53 |
| Source Control | Git / GitHub |

---

## Directory Structure
```
ECS_Project-CC/
├── app/                          # React/TypeScript application source
│   ├── src/                      # Application source code
│   ├── public/                   # Static assets
│   ├── Dockerfile                # Multi-stage Docker build
│   ├── .dockerignore
│   ├── package.json
│   └── yarn.lock
├── Terraform/                    # All infrastructure as code
│   ├── main.tf                   # Root module — calls all child modules
│   ├── provider.tf               # AWS provider configuration
│   ├── backend.tf                # Remote state (S3 + DynamoDB)
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/                  # VPC, subnets, IGW, NAT, route tables
│       ├── securitygroups/       # ALB and ECS security groups
│       ├── ecr/                  # ECR repository
│       ├── alb/                  # ALB, target group, listeners
│       ├── ecs/                  # ECS cluster, task definition, service
│       ├── acm/                  # ACM certificate + DNS validation
│       └── dns/                  # Route 53 hosted zone
├── .github/
│   └── workflows/
│       ├── dockerpush.yml        # Build & push Docker image to ECR
│       ├── terraformapply.yml    # Terraform init, plan, apply
│       ├── terraformdestroy.yml  # Terraform destroy
│       └── healthcheck.yml       # Post-deploy health check
├── clickops.md                   # ClickOps guide (manual steps before Terraform)
├── .gitignore
└── README.md
```

---

## Architecture

![Architecture Diagram](./VPC_Architecture_for_ECS.png)

### Key Infrastructure

- **VPC** — Custom VPC (`10.0.0.0/16`) across 2 Availability Zones with public and private subnet separation
- **Public subnets** (`10.0.1.0/24`, `10.0.2.0/24`) — Host the ALB and Internet Gateway
- **Private subnets** (`10.0.3.0/24`, `10.0.4.0/24`) — Host ECS Fargate tasks, accessed via NAT Gateway
- **Application Load Balancer** — Internet-facing, listens on HTTP:80 and HTTPS:443, forwards to ECS target group on port 3000
- **ECS Fargate** — Serverless container runtime; 1 vCPU / 2GB RAM, no EC2 instances to manage
- **ECR** — Private container registry (`ecr-threatmod`) with immutable image tags
- **ACM** — TLS certificate for `tm.sc-threat-composer.com`, validated via DNS
- **Route 53** — Public hosted zone for `sc-threat-composer.com`
- **Cloudflare** — DNS provider; CNAME record points `tm` subdomain to ALB DNS name
- **Security Groups** — ALB SG allows inbound 80/443 from internet; ECS SG allows port 3000 from ALB SG only (least privilege)

---

## Docker

The application is containerised using a **multi-stage Dockerfile** to minimise the final image size and attack surface.

**Stage 1 — Builder**
- Base image: `node:18-alpine`
- Installs dependencies via `yarn install`
- Compiles the React/TypeScript app with `yarn build`, producing static files in `/app/build`

**Stage 2 — Runtime**
- Base image: `node:18-alpine`
- Copies only the compiled `build/` output from the builder stage — no source code or `node_modules` in the final image
- Installs `serve` to host the static files
- Runs as a **non-root user** (`nonroot`) for container security hardening
- Exposes port `3000`
```bash
# Build locally
docker build -t threatmod ./app

# Run locally
docker run -p 3000:3000 threatmod
```

---

## Terraform

Infrastructure is fully provisioned via **modular Terraform**, following production best practices.

**Remote State**
Terraform state is stored in an S3 bucket with DynamoDB state locking, preventing concurrent apply conflicts.
```hcl
terraform {
  backend "s3" {
    bucket         = "sc-terraform-statee"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "sc-terraform-state-lock"
    encrypt        = true
  }
}
```

**Module Structure**
Each AWS component is a reusable module with typed `variables.tf` inputs and `outputs.tf` exports. Modules communicate via outputs — for example, the ECS module receives subnet IDs from the VPC module and security group IDs from the security groups module.
```bash
# Deploy infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# Tear down
terraform destroy -auto-approve
```

---

## GitHub Actions CI/CD

Three separate workflows handle different stages of the pipeline, all authenticated to AWS via **OIDC** — no static credentials stored anywhere.

### `dockerpush.yml` — triggers on push to `main`
1. Checkout code
2. Authenticate to AWS via OIDC (`github-actions-role`)
3. Login to ECR
4. Build Docker image tagged with the git commit SHA
5. Push to ECR

### `terraformapply.yml` — triggered manually (`workflow_dispatch`)
1. Checkout code
2. Authenticate to AWS via OIDC
3. `terraform init` — initialises remote backend
4. `terraform plan` — shows planned changes
5. `terraform apply -auto-approve` — provisions infrastructure

### `terraformdestroy.yml` — triggered manually (`workflow_dispatch`)
1. Authenticate to AWS via OIDC
2. `terraform init`
3. `terraform destroy -auto-approve`

### `healthcheck.yml` — triggered manually (`workflow_dispatch`)
Curls the live URL and fails the pipeline if the app is unreachable.
```yaml
- name: Health check
  run: |
    if curl --fail https://tm.sc-threat-composer.com/health; then
      echo "Health check passed - app is up"
    else
      echo "Health check failed - app is down"
      exit 1
    fi
```

**OIDC Authentication**
Rather than storing static AWS access keys as GitHub Secrets, the pipeline uses OpenID Connect. GitHub generates a short-lived token per workflow run, and AWS verifies it against a trust policy scoped to this specific repository and branch.

---

## Local App Setup
```bash
# Clone the repo
git clone https://github.com/ShurayeemC/ECS-Project-SC.git
cd ECS-Project-SC/app

# Install dependencies
yarn install

# Run locally
yarn start
```

App runs at: [http://localhost:3000/workspaces/default/dashboard](http://localhost:3000/workspaces/default/dashboard)

To run via Docker:
```bash
docker build -t threatmod ./app
docker run -p 3000:3000 threatmod
# Visit http://localhost:3000
```

---

## Live URL

[https://tm.sc-threat-composer.com](https://tm.sc-threat-composer.com)