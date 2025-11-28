# Multi-stage build for Users API (Java Spring Boot)

# Build stage
FROM eclipse-temurin:8-jdk-alpine AS builder

# Install Maven and CA certificates
RUN apk add --no-cache maven ca-certificates

# Set working directory
WORKDIR /app

# Copy all source files
COPY pom.xml ./
COPY src src

# Build the application with updated SSL protocols
RUN mvn clean package -DskipTests -B -Dhttps.protocols=TLSv1.2

# Runtime stage
FROM eclipse-temurin:8-jre-alpine

# Install dumb-init and curl for proper signal handling and health checks
RUN apk add --no-cache dumb-init curl

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy the built JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Configure JVM options for containerized environment
ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Expose the application port
EXPOSE 8083

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8083/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]