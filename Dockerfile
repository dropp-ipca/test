# Base stage 
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# Install stage 
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
RUN cd /temp/dev && bun install --frozen-lockfile

RUN mkdir -p /temp/prod
COPY package.json bun.lockb /temp/prod/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# Build stage
FROM base AS builder
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

ENV NODE_ENV=production
RUN bun test
RUN bun run build

# Release stage
FROM oven/bun:1-alpine AS release
WORKDIR /usr/src/app

COPY --from=install /temp/prod/node_modules node_modules
COPY --from=builder /usr/src/app/server.ts .
COPY --from=builder /usr/src/app/package.json .

USER bun
ENV NODE_ENV=production
ENV BUN_ENV=production

EXPOSE 3000/tcp

# Health check 
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bun run server.ts health || exit 1

ENTRYPOINT [ "bun", "run", "server.ts" ]