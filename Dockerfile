# Stage 1: Install Dependencies
FROM node:20-alpine AS dependencies

WORKDIR /app

# Copy only package.json and pnpm-lock.yaml to leverage Docker cache
COPY package*.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./
COPY lerna.json ./
COPY examples ./examples/
COPY packages ./packages/

# Install pnpm globally
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install
RUN cd examples/nextjs-playground && pnpm install



# Stage 2: Build Application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependencies from the previous stage
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/package*.json ./
COPY --from=dependencies /app/pnpm-lock.yaml ./
COPY --from=dependencies /app/pnpm-workspace.yaml ./
COPY --from=dependencies /app/lerna.json ./
COPY --from=dependencies /app/examples ./examples
COPY --from=dependencies /app/packages ./packages

# Copy application source code
COPY tsconfig.json ./


# Build the Next.js application for production.
RUN npm install -g pnpm
RUN pnpm run build
RUN cd examples/nextjs-playground && pnpm run build



# Stage 3: Runner (Production)
FROM node:20-alpine AS runner

WORKDIR /app/examples/nextjs-playground



# Copy only the necessary files from the builder stage.
COPY --from=builder /app/node_modules /app/node_modules

COPY --from=builder /app/examples/nextjs-playground/package.json ./package.json
COPY --from=builder /app/examples/nextjs-playground/.next ./.next
COPY --from=builder /app/examples/nextjs-playground/public ./public
COPY --from=builder /app/examples/nextjs-playground/next.config.ts ./
COPY --from=builder /app/examples/nextjs-playground/node_modules ./node_modules

ENV PATH=/app/examples/nextjs-playground/node_modules/.bin:$PATH

# Expose the port Next.js will run on.
EXPOSE 3000

# Start the Next.js server.
CMD ["npm", "start"]