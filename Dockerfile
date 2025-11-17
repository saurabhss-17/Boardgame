FROM eclipse-temurin:17-jre
WORKDIR /app
ARG JAR=target/database_service_project-0.0.7.jar
COPY ${JAR} app.jar
EXPOSE 8080
ENV JAVA_OPTS=""
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]
