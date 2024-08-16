# Stage 1: Build the application
FROM maven:3.9.8-openjdk-11-slim AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the pom.xml file into the container
COPY pom.xml .

# Download the dependencies
RUN mvn clean dependency:go-offline

# Copy the source code and package the application
COPY src src
RUN mvn package -DskipTests

# Stage 2: Create the final runtime image
FROM adoptopenjdk/openjdk11:alpine-slim

# Create a volume to store temporary files (optional)
VOLUME /tmp

# Create a non-root user and group for running the application
RUN addgroup --system javauser && adduser -S -s /bin/false -G javauser javauser

# Set the working directory
WORKDIR /app

# Copy the JAR file from the build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership of the application files to the non-root user
RUN chown -R javauser:javauser /app

# Switch to the non-root user
USER javauser

# Specify the command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

RUN ping -c 4 google.com

#COPY /path/to/local/.m2 /root/.m2

#COPY settings.xml /root/.m2/settings.xml

# Copy a custom settings.xml with a mirror configuration
COPY settings.xml /root/.m2/settings.xml

# Example of running with retry
RUN mvn -fae --fail-at-end --batch-mode clean dependency:go-offline || \
    (echo "Retrying Maven command after failure..." && sleep 5 && mvn clean dependency:go-offline)

