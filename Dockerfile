# Multi-stage build for PetClinic Spring Boot application
FROM eclipse-temurin:17-jdk-jammy AS build

WORKDIR /app
COPY . .
RUN chmod +x mvnw && ./mvnw package -DskipTests --no-transfer-progress

# Runtime stage
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app
COPY --from=build /app/target/spring-petclinic-*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

ENTRYPOINT ["java", "-Xmx512m", "-jar", "app.jar", "--server.port=8080"]
