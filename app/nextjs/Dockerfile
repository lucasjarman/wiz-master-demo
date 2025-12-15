FROM node:20-alpine

# Install tools needed for exploit demo (curl for OAST, aws-cli for S3, bash for shell commands)
RUN apk add --no-cache libc6-compat curl aws-cli bash

WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json* ./
RUN npm ci

# Copy source code and build
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# CVE-2025-66478 RCE works in both dev and prod modes
ENV NODE_ENV=production
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["npm", "start"]
