# ClickOps Guide — ECS Threat Composer Deployment
> This guide documents the manual AWS console steps used to deploy the Threat Composer app on ECS Fargate with HTTPS. These steps were completed before recreating the infrastructure in Terraform.

---

## 1. VPC & Networking

1. Created a custom VPC with CIDR `10.0.0.0/16`
2. Created 4 subnets — 2 public and 2 private, spread across 2 Availability Zones (`eu-west-2a` and `eu-west-2b`) for high availability
3. Created an Internet Gateway (IGW) and attached it to the VPC to allow public internet traffic
4. Created 2 NAT Gateways — one in each public subnet — so private subnet resources can access the internet without being publicly exposed
5. Created 2 route tables:
   - **Public route table** — associated with both public subnets, with a route sending `0.0.0.0/0` to the IGW
   - **Private route table** — associated with both private subnets, with a route sending `0.0.0.0/0` to the NAT Gateway

---

## 2. ECR

1. Created a private ECR repository called `ecr-threatmod` with immutable tags and AES-256 encryption
2. Built the Docker image locally using a multi-stage Dockerfile
3. Authenticated Docker to ECR using `aws ecr get-login-password`
4. Tagged the image with the ECR URI and pushed it as `v1.0.0`

---

## 3. ECS

1. Created an ECS cluster called `sc-cluster` using Fargate launch type
2. Created an IAM task execution role (`ecsTaskExecutionRole`) with the `AmazonECSTaskExecutionRolePolicy` managed policy — this allows ECS to pull images from ECR and write logs to CloudWatch
3. Created a task definition with:
   - Launch type: Fargate
   - CPU: 0.5 vCPU / Memory: 1GB
   - Container name: `ecr-threatmod`
   - Container port: `3000` (where the app listens)
   - Execution role: `ecsTaskExecutionRole`
4. Created an ECS service with 1 desired task, attached to the ALB target group

---

## 4. Security Groups

Two security groups were created:

**ALB Security Group (`alb-clickops`)**
- Inbound: HTTP port `80` from `0.0.0.0/0`
- Inbound: HTTPS port `443` from `0.0.0.0/0`
- Outbound: All traffic

**ECS Task Security Group (`ecs-clickops`)**
- Inbound: Custom TCP port `3000` from the ALB security group only (least privilege)
- Outbound: All traffic

---

## 5. ALB (Application Load Balancer)

1. Created an ALB called `scthreatmod-alb` — internet-facing, attached to both public subnets
2. Created a target group (`ecsalb-TG`) with:
   - Target type: IP (required for Fargate)
   - Protocol: HTTP / Port: 3000
   - Health check path: `/`
3. Created two listeners:
   - **HTTP:80** — redirects to HTTPS:443
   - **HTTPS:443** — forwards to the target group, with the ACM certificate attached

---

## 6. ACM (Certificate Manager)

1. Requested a public TLS certificate for `tm.sc-threat-composer.com`
2. Selected DNS validation
3. Added the CNAME validation record to Cloudflare DNS (proxy status: DNS only)
4. Waited for the certificate status to change to **Issued**
5. Attached the certificate to the HTTPS listener on the ALB

---

## 7. DNS (Route 53 + Cloudflare)

1. Created a public hosted zone in Route 53 for `sc-threat-composer.com`
2. Since the domain was registered on Cloudflare's free plan (nameserver changes not available), a CNAME record was added directly in Cloudflare:
   - **Name**: `tm`
   - **Target**: ALB DNS name
   - **Proxy status**: DNS only (orange cloud off)
3. This routes `https://tm.sc-threat-composer.com` → ALB → ECS tasks

---

## 8. Verification

Once all resources were in place, the app was accessible at:

**`https://tm.sc-threat-composer.com`**

After verifying the deployment, all resources were torn down via `terraform destroy` and recreated using Terraform modules.