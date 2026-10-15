# syntax=docker/dockerfile:1
# =============================================================================
#  Dockerfile - Multi-stage build for Spring Boot / Java 21 / Gradle
# =============================================================================

# ---------- Stage 1: build - compile & package with Gradle + JDK 21 ----------
FROM gradle:8.14-jdk21-alpine AS build
WORKDIR /workspace

# Copy build scripts first to leverage Docker layer caching for dependencies
COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon -q

# Copy source and build the executable JAR (skip tests)
COPY src ./src
RUN gradle bootJar -x test --no-daemon -q

# ---------- Stage 2: runtime - minimal JRE 21 image + JAR only ----------
FROM eclipse-temurin:21-jre-alpine

ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION}

WORKDIR /app

# Create non-root user and group for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build --chown=appuser:appgroup /workspace/build/libs/app.jar /app/app.jar
USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
