# car-agent-infrastructure

> Terraform infrastructure for **Bilköpshjälpen** — a Swedish AI-powered car-buying assistant.  
> All resources deploy to `eu-north-1` (Stockholm) for GDPR data residency.

---

## Architecture at a glance

```
User
 │
 ▼
CloudFront (CDN) ──── S3 (frontend assets)
 │
 ▼
API Gateway (HTTP, JWT-authorised)
 ├── POST /auth/register   ──► auth-lambda         (registration)
 ├── POST /auth/callback   ──► auth-lambda         (login / token exchange)
 ├── POST /auth/refresh    ──► auth-lambda         (refresh access token)
 ├── POST /auth/logout     ──► auth-lambda         (logout)
 ├── GET  /profile         ──► profile-lambda      (read profile)
 ├── PUT  /profile         ──► profile-lambda      (update profile)
 ├── GET  /profile/pp-presigned-url ─► profile-lambda (S3 upload URL)
 ├── POST /invoke          ──► orchestrator-lambda → AgentCore (Bedrock)
 ├── POST /payment         ──► stripe-lambda       (Stripe checkout + webhooks)
 └── DELETE /account       ──► deletion-lambda     (GDPR erasure)
```

**Auth** — Cognito User Pool issues JWTs via Google OAuth. API Gateway validates every protected route via a JWT authoriser before the request reaches a Lambda. The `/auth/*` routes are intentionally public — they exist to produce the token.

**Data stores** — Three DynamoDB tables (cars, users, Stripe events), one S3 bucket for frontend assets, and one S3 bucket for profile pictures. All encrypted at rest with PITR enabled. CloudTrail logs every DynamoDB write for the audit trail required by GDPR Article 32.

**Email** — Amazon SES manages the `car-offers` contact list. Auth lambda adds subscribers on first login. Deletion lambda removes them as part of account erasure. Unsubscribe is handled natively by SES.

**AgentCore** — Runs on arm64 (AWS Bedrock AgentCore). Has its own isolated IAM role and ECR repo, separate from the shared Lambda role.

**CDN** — CloudFront sits in front of both S3 (frontend) and API Gateway. TLS terminates at CloudFront. ACM certificate lives in `us-east-1` per AWS requirement. DNS is managed by Route 53.

---

## Repo layout

```
.
├── config.tf                       # Root module — wires all child modules together
├── variables.tf                    # Root inputs: environment, Google OAuth secrets
├── outputs.tf                      # ECR URLs surfaced for CI/CD; S3 bucket name
├── prod.tfvars                     # Non-secret prod variable values
│
├── resources/
│   │
│   ├── storage/                    # Stateful resources — provision first, destroy last
│   │   ├── s3/                     # Frontend asset bucket — SSE-S3, all public access blocked
│   │   ├── s3-profile-pictures/    # Profile picture bucket — SSE-S3, CORS for presigned uploads
│   │   ├── dynamodb-car/           # Car listings table — PAY_PER_REQUEST, PITR, SSE
│   │   ├── dynamodb-user/          # User profiles table — PAY_PER_REQUEST, PITR, SSE
│   │   ├── dynamodb-stripe/        # Stripe webhook events — idempotency store, PITR, SSE
│   │   ├── cognito/                # User Pool + Google federated identity provider
│   │   ├── ses/                    # Domain identity, DKIM Route53 records, car-offers contact list
│   │   ├── cloudwatch/             # Shared log group — all Lambdas write here
│   │   ├── cloudtrail/             # Audit trail for all DynamoDB write events (GDPR §32)
│   │   ├── ecr-orchestrator-lambda/
│   │   ├── ecr-auth-lambda/
│   │   ├── ecr-deletion-lambda/
│   │   ├── ecr-stripe-lambda/
│   │   ├── ecr-profile-lambda/     # One ECR repo per Lambda image
│   │   └── ecr-agentcore/          # Separate ECR repo for AgentCore container
│   │
│   ├── security/                   # IAM roles and policies — least-privilege
│   │   ├── iam-lambda/             # Shared execution role for auth, orchestrator,
│   │   │                           #   deletion and stripe lambdas
│   │   │                           #   Grants: DynamoDB R/W, CloudWatch Logs,
│   │   │                           #           Cognito AdminDeleteUser, ses:* (scoped)
│   │   ├── iam-profile-lambda/     # Isolated role for profile lambda only
│   │   │                           #   Grants: DynamoDB R/W (user table), S3 R/W/Delete
│   │   │                           #           on profile-pictures/users/* + CloudWatch
│   │   └── iam-agentcore/          # Isolated role for AgentCore — ECR pull + CloudWatch
│   │
│   ├── compute/                    # Stateless workloads — depend on storage + security
│   │   ├── orchestrator-lambda/    # Routes user queries → AgentCore; reads car/user tables
│   │   ├── auth-lambda/            # Registration, OAuth login, token refresh, logout
│   │   ├── profile-lambda/         # Profile CRUD + presigned S3 URL for profile pictures
│   │   ├── deletion-lambda/        # GDPR erasure: DynamoDB, SES contact, Cognito, S3
│   │   ├── stripe-lambda/          # Checkout session creation + Stripe webhook handler
│   │   └── agentcore/              # Bedrock AgentCore service (arm64)
│   │
│   └── network/                    # Public-facing ingress layer — provision last
│       ├── api-gateway/            # HTTP API — routes, JWT authoriser, access logging,
│       │                           #            throttle (50 rps sustained / 100 burst)
│       ├── cloudfront/             # CDN — S3 origin (OAC) + API Gateway origin
│       ├── acm/                    # TLS certificate in us-east-1 (CloudFront requirement)
│       └── route53/                # Public hosted zone for bilköpshjälpen.se
│
└── .github/
    ├── workflows/
    │   ├── prod_cicd.yml           # Triggered on push to main → calls reusable workflow
    │   └── reusable_cicd.yml       # Three-job pipeline (see CI/CD section below)
    └── actions/
        ├── terraform-plan/         # Runs terraform plan, posts output as job summary
        ├── terraform-apply-ecr/    # Applies ECR-only targets, emits repo URLs as outputs
        ├── push-placeholder-image/ # Pushes a minimal image per Lambda so Terraform can
        │                           # create the function before real code is deployed
        └── deploy-frontend/        # Syncs Vite dist/ to S3 — skips if bucket already has
                                    # content to avoid overwriting a production build
```

---

## CI/CD pipeline

Split into three sequential jobs to solve a chicken-and-egg problem: Lambda functions require a container image in ECR before Terraform can create them.

```
Job 1 — terraform-ecr           plan + apply ECR repos only
         │  outputs: six ECR URLs
         │
Job 2 — push-images             matrix — 6 images pushed in parallel
         ├── orchestrator-lambda   linux/amd64
         ├── auth-lambda           linux/amd64
         ├── deletion-lambda       linux/arm64
         ├── stripe-lambda         linux/arm64
         ├── profile-lambda        linux/arm64
         └── agentcore             linux/arm64
         │
Job 3 — terraform-remaining     applies everything else + deploys frontend
         └── Lambdas, API Gateway, IAM, DynamoDB, S3, Cognito, SES,
             CloudFront, Route53, ACM, CloudTrail → Deploy Frontend
```

AWS authentication uses **OIDC** — no long-lived AWS keys are stored anywhere in GitHub.

The `deploy-frontend` step checks whether the S3 bucket already contains objects before uploading. If the application repo has already deployed a real build, the step skips entirely so the production `dist/` is never overwritten by a placeholder.

---

## Key design decisions

| Decision | Reason |
|---|---|
| All resources in `eu-north-1` | GDPR data residency — personal data stays in Sweden |
| ACM cert in `us-east-1` | AWS hard requirement for CloudFront certificates |
| No VPC | Fully serverless; all traffic is HTTPS; no security benefit at this scale |
| Shared Lambda IAM role | Auth, orchestrator, deletion and stripe have identical needs; profile lambda has its own role due to S3 access |
| `PAY_PER_REQUEST` on DynamoDB | No traffic baseline yet — eliminates over/under-provisioning risk |
| PITR on all tables | GDPR Article 32 — ability to restore personal data after accidental loss |
| CloudTrail on DynamoDB | Audit log of every write to personal-data tables — GDPR Article 30 records of processing |
| SES `ses:*` scoped to resource ARNs | Admin access to SES but locked to this app's domain identity and contact list only |
| Profile lambda dedicated IAM role | Only lambda that needs S3 access — isolated to prevent other lambdas inheriting bucket permissions |
| ECR `MUTABLE` tags | CI pushes `:latest` on every deploy; acceptable for a single-environment MVP |
| Presigned S3 URLs for profile pictures | Binary data never passes through Lambda — client uploads directly to S3 |

---

## Environments

Secrets (`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `OIDC_ROLE_ARN`) live in GitHub Actions Secrets — never in the repo. Non-secret values go in `<env>.tfvars`. The pipeline injects the correct file automatically via `-var-file=<env>.tfvars`.

| Resource naming | Pattern |
|---|---|
| Production | `car-agent-*-prod` |
| Development | `car-agent-*-dev` |
