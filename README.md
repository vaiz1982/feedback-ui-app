
feedback-ui-app/
├── frontend/
│   └── index.html
├── terraform/              ← unzip the contents here
│   ├── versions.tf
│   ├── variables.tf
│   ├── s3.tf
│   ├── cloudfront.tf
│   ├── dynamodb.tf
│   ├── iam.tf
│   ├── lambda.tf
│   ├── lambda/
│   │   └── lambda_function.py
│   ├── api_gateway.tf
│   ├── ses.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── .gitignore
│   └── README.md
├── .github/
│   └── workflows/
│       └── deploy.yaml
└── README.md









feetback submitted correctly!!!!1
<img width="1829" height="535" alt="Screenshot 2026-08-14 at 02 43 40" src="https://github.com/user-attachments/assets/cef2ac6a-4fdd-4041-901a-4a93123df070" />




timeStampUpdated!
<img width="1777" height="457" alt="Screenshot 2026-08-14 at 02 39 18" src="https://github.com/user-attachments/assets/27cf769f-13c4-48f7-a4ff-784783764dfd" />







LambdaMonitoringWorks
<img width="1145" height="920" alt="Screenshot 2026-08-14 at 02 40 19" src="https://github.com/user-attachments/assets/3a8ae19a-85df-490d-acd2-34f75b4dc2f4" />






























# feedback-ui-app
feedback-ui-app
# trigger
# trigger


# Serverless Feedback Collection System

A fully serverless feedback collection application built on AWS, featuring a static frontend, RESTful API, PDF attachment handling, persistent storage, and automated email notifications — deployed with a CI/CD pipeline via GitHub Actions.

**Live demo:** `https://dvudwljz7c6un.cloudfront.net`

---

## Architecture

```
User → CloudFront (CDN) → S3 (Private, static frontend)
                ↓ submit feedback (form + PDF)
        API Gateway → Lambda → S3 (PDF Storage)
                                    ↓
                              DynamoDB (feedback records)
                                    ↓
                              SES (email notification)

GitHub Actions → deploy frontend → S3 (Private)
```

The system is split into two halves:

- **Frontend**: A static HTML/CSS/JS feedback form served through CloudFront, backed by a private S3 bucket (no public bucket access — CloudFront reaches it via Origin Access Control).
- **Backend**: API Gateway routes POST requests to a Lambda function, which uploads the PDF to S3, writes a structured record to DynamoDB, and sends an email notification via SES.

---

## AWS Services Used

| Service | Role |
|---|---|
| **S3** (x2) | Private static site hosting + PDF attachment storage |
| **CloudFront** | CDN + reverse proxy in front of the private frontend bucket, HTTPS termination |
| **API Gateway** | REST API front door — routes HTTP requests to Lambda (`POST /submit`, `OPTIONS /submit`) |
| **Lambda** | Backend logic — parses the request, uploads PDF, writes DynamoDB record, triggers email |
| **DynamoDB** | NoSQL table storing feedback records (name, email, message, file URL, timestamp) |
| **SES** | Sends an HTML email notification to the admin on every new submission |
| **IAM** | Scoped execution role for Lambda with least-privilege permissions |
| **GitHub Actions** | CI/CD — automated frontend deployment to S3 + CloudFront cache invalidation on every push to `main` |

---

## What Was Built

### Frontend
- Responsive HTML feedback form (name, email, message, PDF attachment)
- Client-side JavaScript handles form submission, base64-encodes the PDF, and calls the API via `fetch()`
- Success/error modal feedback for the user
- Deployed to a **private** S3 bucket, served exclusively through CloudFront

### Backend (Lambda)
- Single Python 3.13 Lambda function (`SubmitFeetbackFunction`) handling:
  - **CORS preflight (`OPTIONS`)** — manually handled inline for compatibility with Lambda proxy integration
  - **Feedback submission (`POST`)**:
    - Parses JSON body from API Gateway proxy event
    - Decodes and uploads the base64 PDF to S3
    - Generates a pre-signed URL for the uploaded file (24-hour expiry)
    - Writes a structured record to DynamoDB (feedback ID, name, email, message, file URL, timestamp)
    - Sends a formatted HTML email via SES to the admin, including a clickable attachment link
  - Environment-variable driven configuration (table name, bucket name, admin email, region) — no hardcoded values

### API Gateway
- REST API (`FeetbackAPI`) with a `/submit` resource
- `POST` and `OPTIONS` methods, both using **Lambda proxy integration**
- Deployed to a `prod` stage

### CI/CD Pipeline (GitHub Actions)
- Workflow triggers on every push to `main` (plus manual `workflow_dispatch`)
- **`test` job**: validates HTML syntax before deploying (using `html5validator`, with a filter for known false-positive warnings)
- **`deploy` job** (runs only if tests pass):
  - Syncs the frontend to S3 (`aws s3 sync`)
  - Invalidates the CloudFront cache so users always see the latest version
- AWS credentials stored securely as GitHub repository secrets

---

## Key Problems Solved

Real infrastructure work always surfaces real bugs — here's what actually broke and how each was diagnosed and fixed:

| Issue | Root Cause | Fix |
|---|---|---|
| CORS / preflight failures | API Gateway route pointed at root `/` instead of `/submit`, and Lambda proxy integration was disabled | Corrected the frontend's API URL to include `/submit`; enabled Lambda proxy integration on both `POST` and `OPTIONS` methods |
| `AccessDenied` on S3 upload | Lambda's IAM execution role had no `s3:PutObject` permission | Attached a scoped inline policy granting `s3:PutObject` on the specific PDF bucket |
| `ValidationException` on DynamoDB write | A stray leading space in the `TABLE_NAME` environment variable failed DynamoDB's naming regex | Retyped the environment variable value manually to eliminate invisible whitespace |
| `AccessDeniedException` on DynamoDB write | Missing `dynamodb:PutItem` permission on the Lambda role | Added a scoped inline policy for `dynamodb:PutItem` on the specific table |
| CloudFront `AccessDenied` on root URL | No **Default Root Object** configured, so `/` had nothing to serve | Set `index.html` as the default root object in CloudFront distribution settings |
| GitHub Actions workflow not triggering | Workflow file was placed at `.github/deploy.yml` instead of the required `.github/workflows/` directory | Moved the file into the correct path so GitHub Actions could detect it |
| Emails landing in spam | Sending from a Gmail address via SES lacks proper SPF/DKIM alignment for a personal domain | Documented as expected behavior for a lab project; production fix would involve SES domain verification with a custom domain |

---

## Security Practices Applied

- **Private S3 buckets** — neither the frontend nor PDF storage bucket is publicly accessible; access is scoped via CloudFront Origin Access Control and Lambda's IAM role respectively
- **Least-privilege IAM** — Lambda's execution role was granted only the specific actions it needed (`s3:PutObject`, `dynamodb:PutItem`, `ses:SendEmail`) scoped to specific resource ARNs, not wildcard `*` access
- **HTTPS everywhere** — CloudFront terminates TLS for the frontend; API Gateway enforces HTTPS by default
- **No secrets in code** — AWS credentials for CI/CD live in GitHub encrypted secrets, never committed to the repository
- **CORS explicitly scoped** — response headers control which origins/methods can call the API

---

## Tech Stack

- **Backend**: Python 3.13 (AWS Lambda)
- **Infrastructure**: AWS (S3, CloudFront, API Gateway, Lambda, DynamoDB, SES, IAM)
- **CI/CD**: GitHub Actions
- **Frontend**: HTML5, CSS3, vanilla JavaScript

---

## Repository Structure

```
feedback-ui-app/
├── frontend/
│   └── index.html          # Feedback form (HTML + inline CSS/JS)
├── .github/
│   └── workflows/
│       └── deploy.yaml     # CI/CD pipeline (test + deploy)
└── README.md
```

---

## Future Improvements

- Move SES sending to a verified custom domain with SPF/DKIM to avoid spam filtering
- Add input validation and rate limiting on the API Gateway layer
- Add a DynamoDB-backed admin dashboard to view/search past submissions
- Add automated integration tests for the Lambda function (not just HTML validation)
- Bump GitHub Actions to `@v4` across the board for continued Node.js runtime support

---

*Built as a hands-on serverless architecture project — from initial S3/CloudFront setup through IAM permission debugging to a working CI/CD pipeline.*
