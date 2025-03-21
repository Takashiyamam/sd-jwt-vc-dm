# Use the official Node.js 20 image.
FROM node:20-alpine AS builder

# Set the working directory in the container.
WORKDIR /app

# Install pnpm globally.
RUN npm install -g pnpm

# Copy package.json and pnpm-lock.yaml to the container.
COPY package*.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./
COPY lerna.json ./
COPY tsconfig.json ./
COPY examples ./examples/
COPY packages ./packages/

# Install dependencies using pnpm.
RUN pnpm install
# RUN cd examples/nextjs-playground && pnpm install

# Build the Next.js application for production.
RUN pnpm run build

# Use a smaller Node.js image for the production environment.
FROM node:20-alpine AS runner

# Set the working directory.
WORKDIR /app

# Install pnpm globally.
RUN npm install -g pnpm

# Copy only the necessary files from the builder stage.
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/examples/nextjs-playground/.next ./.next
COPY --from=builder /app/examples/nextjs-playground/public ./public
COPY --from=builder /app/examples/nextjs-playground/next.config.ts ./

# Install only the production dependencies.
RUN pnpm install --production

# Expose the port Next.js will run on.
EXPOSE 3000

# Start the Next.js server.
CMD ["pnpm", "start"]