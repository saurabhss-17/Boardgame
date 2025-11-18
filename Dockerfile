# Use Eclipse Temurin JRE 17 base image
FROM eclipse-temurin:17-jre

# Set working directory
WORKDIR /app

# Accept JAR path as build argument
ARG JAR_FILE=target/database_service_project-0.0.7.jar

# Copy the JAR file into the container
COPY ${JAR_FILE} app.jar

# Expose application port
EXPOSE 8080

# Optional: JVM options can be overridden at runtime
ENV JAVA_OPTS=""

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]