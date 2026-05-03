# Bilköpshjälpen — API Reference

> **Base URL:** `https://xn--bilkpshjlpen-ncb1w.se`  
> **Actual BaseURL:** `https://bilköpshäjlpen.se`   
> **Protocol:** HTTPS only  
> **Format:** All request and response bodies are JSON  
> **Throttle:** 50 requests/sec sustained · 100 burst

---

## Authentication

Protected routes require a Cognito-issued JWT passed as a Bearer token. JWT validation is handled entirely by API Gateway before the request reaches any Lambda — a missing or expired token returns `401` without invoking the function.

| Symbol | Meaning |
|---|---|
| 🔓 | No authentication required |
| 🔒 | JWT required (`Authorization: Bearer <token>`) |

---

## Required headers

All requests with a body require `Content-Type`. JWT-protected routes additionally require `Authorization`.

```
Content-Type: application/json
Authorization: Bearer <access_token>   ← JWT-protected routes only
```

> The `/auth/*` routes are intentionally public — their job is to produce the JWT in the first place. Requiring a token to obtain a token would be circular. API Gateway validates the `Authorization` header only on routes where `authorization_type = JWT`; public routes bypass token validation entirely.

### Full example — authenticated request

```http
POST /invoke HTTP/1.1
Host: xn--bilkpshjlpen-ncb1w.se
Content-Type: application/json
Authorization: Bearer eyJraWQiOiJ...

{
  "message": "Show me SUVs under 300 000 kr"
}
```

### Full example — public request

```http
POST /auth/refresh HTTP/1.1
Host: xn--bilkpshjlpen-ncb1w.se
Content-Type: application/json

{
  "refresh_token": "eyJjdHkiOiJ..."
}
```

---

## Auth Lambda

Handles registration, login, token refresh, and logout. All routes are public — no JWT required.

---

### POST /auth/register 🔓

Creates a new Cognito user and stores the user profile in DynamoDB.

**Request**
```json
{
  "email": "user@example.com",
  "password": "string",
  "first_name": "string",
  "last_name": "string"
}
```

**Response `200`**
```json
{
  "message": "Registration successful"
}
```

---

### POST /auth/callback 🔓

Exchanges an OAuth authorization code for access and refresh tokens. Called after a successful Google OAuth redirect.

**Request**
```json
{
  "code": "string"
}
```

**Response `200`**
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_in": 3600
}
```

---

### POST /auth/refresh 🔓

Exchanges a refresh token for a new access token without requiring the user to log in again.

**Request**
```json
{
  "refresh_token": "string"
}
```

**Response `200`**
```json
{
  "access_token": "string",
  "expires_in": 3600
}
```

---

### POST /auth/logout 🔓

Invalidates the user's current session in Cognito.

**Request**
```json
{
  "refresh_token": "string"
}
```

**Response `200`**
```json
{
  "message": "Logged out successfully"
}
```

---

## Profile Lambda

Handles user profile reads, updates, and profile picture upload URL generation. All routes require a valid JWT.

---

### GET /profile 🔒

Returns the authenticated user's profile record from DynamoDB.

**Response `200`**
```json
{
  "user_id": "string",
  "email": "string",
  "first_name": "string",
  "last_name": "string",
  "profile_picture_key": "users/{user_id}/{filename}",
  "subscription_plan": "string",
  "created_at": "ISO8601"
}
```

---

### PUT /profile 🔒

Updates one or more fields on the authenticated user's profile. Send only the fields you want to change. Set a field to `null` to clear it.

**Request**
```json
{
  "first_name": "string",
  "last_name": "string | null",
  "profile_picture_key": "string | null"
}
```

**Response `200`**
```json
{
  "message": "Profile updated"
}
```

---

### GET /profile/pp-presigned-url 🔒

Generates a short-lived presigned S3 `PUT` URL. The client uses this URL to upload a profile picture directly to S3 — the file never passes through the Lambda.

**Query parameters**

| Parameter | Required | Description |
|---|---|---|
| `filename` | Yes | The filename including extension e.g. `avatar.jpg` |

**Response `200`**
```json
{
  "upload_url": "https://s3.eu-north-1.amazonaws.com/...",
  "key": "users/{user_id}/{filename}",
  "expires_in": 300
}
```

> After a successful upload, call `PUT /profile` with the returned `key` to persist the reference on the user's profile.

---

## Orchestrator Lambda

Handles all AI agent interactions. Routes user messages to AWS Bedrock AgentCore and returns the agent's response.

---

### POST /invoke 🔒

Sends a message to the AI car-buying assistant and returns its response.

**Request**
```json
{
  "message": "string"
}
```

**Response `200`**
```json
{
  "response": "string",
  "session_id": "string"
}
```

---

## Stripe Lambda

Handles payment processing and Stripe webhook events.

---

### POST /payment 🔒

Creates a Stripe checkout session for the requested subscription plan and returns a redirect URL. Also handles incoming Stripe webhook events on the same route — Stripe webhook calls are verified by signature before processing.

**Request — Checkout session**
```json
{
  "plan": "string"
}
```

**Response `200` — Checkout session**
```json
{
  "checkout_url": "https://checkout.stripe.com/..."
}
```

**Request — Stripe webhook**

Raw Stripe event payload with `Stripe-Signature` header. Verified before processing.

**Response `200` — Webhook acknowledged**
```json
{
  "received": true
}
```

---

## Deletion Lambda

Permanently deletes the authenticated user's account and all associated data across every system.

---

### DELETE /account 🔒

Triggers full GDPR-compliant account erasure. Removes the user from DynamoDB, SES contact list, and Cognito. This action is irreversible.

**Request**

No body required. Identity is derived entirely from the JWT.

**Response `200`**
```json
{
  "message": "Account deleted"
}
```

---

## Error responses

All lambdas return errors in a consistent shape.

```json
{
  "error": "string",
  "message": "string"
}
```

| Status | Meaning |
|---|---|
| `400` | Bad request — missing or invalid fields |
| `401` | Unauthorized — missing, expired, or invalid JWT |
| `403` | Forbidden — valid JWT but insufficient permissions |
| `404` | Resource not found |
| `409` | Conflict — e.g. email already registered |
| `500` | Internal server error |
