# Stage 1: Build the application
FROM adoptopenjdk/openjdk11:alpine-slim as build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and the pom.xml file into the container
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download the dependencies and build the application
RUN ./mvnw dependency:go-offline

# Copy the source code and package the application
COPY src src
RUN ./mvnw package -DskipTests

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
