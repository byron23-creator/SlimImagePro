# ============================================================
# STAGE 1 — Builder
# Uses node:18-alpine to install production dependencies only
# ============================================================
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency manifests first (layer-cache optimization)
COPY app/package.json ./

# Install ONLY production dependencies (no devDependencies, no scripts)
RUN npm install --omit=dev --ignore-scripts && \
    npm cache clean --force

# Copy application source
COPY app/server.js ./

# ============================================================
# STAGE 2 — Runtime
# Uses the minimal node:18-alpine image (no build tools)
# Upgrades all OS packages to patch known CVEs (e.g. OpenSSL)
# Removes npm/yarn (not needed at runtime) to eliminate their
# bundled dependency vulnerabilities
# ============================================================
FROM node:18-alpine AS runtime

# Upgrade all Alpine packages to get latest security patches
# (fixes libcrypto3/libssl3 OpenSSL CVEs)
RUN apk update && apk upgrade --no-cache && rm -rf /var/cache/apk/*

# Remove npm and yarn — not needed at runtime, eliminates their
# bundled CVEs (tar, cross-spawn, glob, minimatch, etc.)
RUN npm uninstall -g npm && \
    rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /opt/yarn-v* \
           /usr/local/bin/yarn \
           /usr/local/bin/yarnpkg

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only the production artifacts from the builder stage
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/server.js ./
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

# Drop to non-root user
USER appuser

# Expose application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "server.js"]
