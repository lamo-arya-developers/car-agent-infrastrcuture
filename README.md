# car-agent-infrastructure

> Terraform infrastructure for **Bilköpshjälpen** — a Swedish AI-powered car-buying assistant.  
> All resources deploy to `eu-north-1` (Stockholm) for GDPR data residency.

---

## Architecture at a glance

```
User
 │
 ▼
CloudFront ──── S3 (frontend assets)
 │
 ▼
API Gateway (HTTP, JWT-authorised)
 ├── POST /auth/callback   ──► auth-lambda         (login / token exchange)
 ├── POST /auth/refresh    ──► auth-lambda         (refresh access token)
 ├── POST /auth/logout     ──► auth-lambda         (logout)
 ├── POST /invoke          ──► orchestrator-lambda → AgentCore (Bedrock)
 ├── POST /payment         ──► stripe-lambda       (Stripe checkout)
 └── DELETE /account       ──► deletion-lambda     (GDPR erasure)
```

**Auth** — Cognito User Pool issues JWTs. API Gateway validates every protected route via a JWT authoriser before the request ever hits a Lambda.

**Data stores** — Three DynamoDB tables (cars, users, Stripe events) and one S3 bucket. All encrypted at rest with PITR enabled. CloudTrail logs every table write for the audit trail required by GDPR Article 32.

**AgentCore** — Runs on arm64 ECS (AWS Bedrock AgentCore). Has its own IAM role and ECR repo, isolated from the shared Lambda role.

---

## Repo layout

```
.
├── config.tf                     # Root module — wires all child modules together
├── variables.tf                  # Root inputs: environment, Google OAuth secrets
├── outputs.tf                    # ECR URLs surfaced for CI/CD; S3 bucket name
├── prod.tfvars                   # Non-secret prod variable values
│
├── resources/
│   │
│   ├── storage/                  # Stateful resources — provision first, destroy last
│   │   ├── s3/                   # Frontend asset bucket — versioning + SSE-S3
│   │   ├── dynamodb-car/         # Car listings table — PAY_PER_REQUEST, PITR, SSE
│   │   ├── dynamodb-user/        # User profiles table — PAY_PER_REQUEST, PITR, SSE
│   │   ├── dynamodb-stripe/      # Stripe webhook events — idempotency store
│   │   ├── cognito/              # User Pool + Google federated identity provider
│   │   ├── cloudwatch/           # Shared log group — all Lambdas write here
│   │   ├── cloudtrail/           # Audit trail for all DynamoDB write events (GDPR §32)
│   │   ├── ecr-orchestrator-lambda/
│   │   ├── ecr-auth-lambda/
│   │   ├── ecr-deletion-lambda/
│   │   ├── ecr-stripe-lambda/    # One ECR repo per Lambda image
│   │   └── ecr-agentcore/        # Separate ECR repo for AgentCore container
│   │
│   ├── security/                 # IAM roles and policies — least-privilege
│   │   ├── iam-lambda/           # Shared execution role for all four Lambdas
│   │   │                         #   Grants: DynamoDB R/W, S3 R/W, CloudWatch Logs,
│   │   │                         #           Cognito AdminDeleteUser, SES contact mgmt
│   │   └── iam-agentcore/        # Isolated role for AgentCore — ECR pull + CloudWatch
│   │
│   ├── compute/                  # Stateless workloads — depend on storage + security
│   │   ├── orchestrator-lambda/  # Routes user queries → AgentCore; reads car/user tables
│   │   ├── auth-lambda/          # OAuth callback, token refresh, logout via Cognito
│   │   ├── deletion-lambda/      # GDPR erasure: removes user row, Cognito account,
│   │   │                         #               SES contact, and S3 assets
│   │   ├── stripe-lambda/        # Stripe webhook handler + checkout session creator;
│   │   │                         #               writes events to dynamodb-stripe
│   │   └── agentcore/            # Bedrock AgentCore service (arm64)
│   │
│   └── network/                  # Public-facing ingress layer — provision last
│       ├── api-gateway/          # HTTP API — routes, JWT authoriser, access logging,
│       │                         #            throttle (50 rps burst / 100 max)
│       ├── cloudfront/           # CDN in front of S3 + API Gateway; OAC for S3
│       ├── acm/                  # TLS certificate — must live in us-east-1 (CF requirement)
│       └── route53/              # Public hosted zone for bilköpshjälpen.se
│
└── .github/
    ├── workflows/
    │   ├── prod_cicd.yml         # Triggered on push to main → calls reusable workflow
    │   └── reusable_cicd.yml     # Three-job pipeline (see CI/CD section below)
    └── actions/
        ├── terraform-plan/       # Runs terraform plan, posts output as job summary
        ├── terraform-apply-ecr/  # Applies ECR-only targets, emits repo URLs as outputs
        ├── push-placeholder-image/ # Builds & pushes a minimal image so Lambda can be
        │                           # created before real application code is deployed
        └── deploy-frontend/      # Syncs Vite dist/ to S3 (pending domain validation)
```

---

## CI/CD pipeline

Split into three sequential jobs to solve a chicken-and-egg problem: Lambda functions require a container image in ECR before they can be created by Terraform.

```
Job 1 — terraform-ecr           plan + apply ECR repos only
         │  outputs: five ECR URLs (orchestrator, auth, deletion, stripe, agentcore)
         │
Job 2 — push-images             matrix — 5 images pushed in parallel
         ├── orchestrator-lambda   linux/amd64
         ├── auth-lambda           linux/amd64
         ├── deletion-lambda       linux/arm64
         ├── stripe-lambda         linux/arm64
         └── agentcore             linux/arm64
         │
Job 3 — terraform-remaining     applies everything else
         └── Lambdas, API Gateway, IAM, DynamoDB, S3, Cognito, CloudTrail …
```

AWS authentication uses **OIDC** — no long-lived AWS keys are stored anywhere in GitHub.

---

## Key design decisions

| Decision | Reason |
|---|---|
| All resources in `eu-north-1` | GDPR data residency — personal data stays in Sweden |
| ACM cert in `us-east-1` | AWS hard requirement for CloudFront certificates |
| No VPC | Fully serverless; all traffic is HTTPS; VPC adds cost and complexity with no security benefit at this scale |
| Shared Lambda IAM role | Four Lambdas have identical permission needs at MVP scale; split when responsibilities diverge |
| `PAY_PER_REQUEST` on DynamoDB | No traffic baseline yet — eliminates over/under-provisioning risk |
| PITR on all tables | GDPR Article 32 requires ability to restore personal data after accidental loss |
| CloudTrail on DynamoDB | Audit log of every write to personal-data tables — supports GDPR Article 30 records of processing |
| ECR `MUTABLE` tags | CI pushes `:latest` on every deploy; acceptable for a single-environment MVP |

---

## Environments

Secrets (`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `OIDC_ROLE_ARN`) live in GitHub Actions Secrets — never in the repo. Non-secret values go in `<env>.tfvars`. The pipeline injects the right file automatically via `-var-file=<env>.tfvars`.

---

## Pending before going live

- [ ] Validate Route 53 hosted zone NS records at the domain registrar
- [ ] Uncomment `module.route53`, `module.acm`, `module.cloudfront` in `config.tf`
- [ ] Restore `Deploy Frontend` step in `reusable_cicd.yml`
- [ ] Restore `cloudfront_distribution_id` output in `outputs.tf`
- [ ] Provision SES domain identity + DKIM records + `car-offers` contact list
- [ ] Accept AWS Data Processing Addendum (required for GDPR controller–processor relationship)
