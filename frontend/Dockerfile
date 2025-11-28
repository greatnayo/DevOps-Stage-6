# Multi-stage build for Vue.js frontend
# Stage 1: Build the application
FROM node:14-alpine AS build-stage

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine AS production-stage

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built application from build stage
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Copy nginx configuration template and entrypoint script
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Make entrypoint script executable
RUN chmod +x /docker-entrypoint.sh

# Expose port 80
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]