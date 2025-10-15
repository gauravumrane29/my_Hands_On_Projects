# Multi-stage Docker build for Java microservice
FROM maven:3.9.4-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy POM file first to leverage Docker layer caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Production stage
FROM eclipse-temurin:17-jre-alpine

# Install curl for health checks and create logs directory
RUN apk add --no-cache curl && \
    addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Create logs directory
RUN mkdir -p /app/logs && \
    chown -R appuser:appgroup /app

# Copy JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]