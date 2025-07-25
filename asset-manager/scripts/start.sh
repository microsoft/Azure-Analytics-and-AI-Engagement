#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "Starting PostgreSQL container..."
docker run -d --name assets-postgres \
    -e POSTGRES_DB=assets_manager \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -p 5432:5432 postgres:latest

echo "Starting RabbitMQ container..."
docker run -d --name assets-rabbitmq \
    -p 5672:5672 \
    -p 15672:15672 \
    rabbitmq:management

echo "Waiting for services to start..."
sleep 10

# Create logs directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/logs"

# Create pids directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/pids"

echo "Starting web module..."
cd "$PROJECT_ROOT/web" && "$PROJECT_ROOT/mvnw" clean spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.pid.file=$PROJECT_ROOT/pids/web.pid" -Dspring-boot.run.profiles=dev > "$PROJECT_ROOT/logs/web.log" 2>&1 &

echo "Starting worker module..."
cd "$PROJECT_ROOT/worker" && "$PROJECT_ROOT/mvnw" clean spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.pid.file=$PROJECT_ROOT/pids/worker.pid" -Dspring-boot.run.profiles=dev > "$PROJECT_ROOT/logs/worker.log" 2>&1 &

echo "All services started! Check logs directory for output."
echo "Web application: http://localhost:8080"
echo "RabbitMQ Management: http://localhost:15672 (guest/guest)"