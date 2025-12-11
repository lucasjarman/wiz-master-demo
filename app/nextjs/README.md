# Wiz React2Shell Demo App

A deliberately vulnerable Next.js application designed to demonstrate **React Server Components (RSC) Remote Code Execution (RCE)**.

## ⚠️ Intentionally Vulnerable
This repository contains a vulnerable implementation of Next.js for educational and demonstration purposes.
**DO NOT DEPLOY TO PRODUCTION.**

### Vulnerability Details
We utilize specific "Canary" and "Release Candidate" versions of Next.js and React to guarantee the exploitability of the `React2Shell` vulnerability.

-   **Next.js**: `15.0.0-canary.160`
-   **React**: `19.0.0-rc-66855b96-20241106`

These versions contain known issues in how the server deserializes flight data, allowing for RCE when specific payloads are sent to Server Actions.

## Features
-   **RCE Sink**: A "Debug Console" that executes shell commands.
-   **Cloud Recon**: A `/data` page that attempts to list S3 buckets (demonstrating IAM abuse).
-   **Persistence Check**: A `/status` page that checks for files created by an attacker.

## Running Locally

```bash
# Install dependencies (requires legacy-peer-deps due to RC versions)
npm install --legacy-peer-deps

# Run dev server
npm run dev
```
