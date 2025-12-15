FROM node:20-alpine

# Install dependencies (curl needed for OAST callbacks, aws-cli for S3 access)
RUN apk add --no-cache libc6-compat curl aws-cli bash

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Disable telemetry
ENV NEXT_TELEMETRY_DISABLED=1

# IMPORTANT: Dev mode required for CVE-2025-66478 RCE to work
ENV NODE_ENV=development

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Run in dev mode (required for RCE exploit)
CMD ["npm", "run", "dev"]
