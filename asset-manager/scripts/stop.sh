#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "Stopping Java processes..."

# Check if web PID file exists and stop the process
if [ -f "$PROJECT_ROOT/pids/web.pid" ]; then
    WEB_PID=$(cat "$PROJECT_ROOT/pids/web.pid")
    echo "Stopping web module with PID: $WEB_PID"
    kill -9 $WEB_PID 2>/dev/null || echo "Process not found"
    rm "$PROJECT_ROOT/pids/web.pid"
else
    echo "Web PID file not found, the service may not be running."
fi

# Check if worker PID file exists and stop the process
if [ -f "$PROJECT_ROOT/pids/worker.pid" ]; then
    WORKER_PID=$(cat "$PROJECT_ROOT/pids/worker.pid")
    echo "Stopping worker module with PID: $WORKER_PID"
    kill -9 $WORKER_PID 2>/dev/null || echo "Process not found"
    rm "$PROJECT_ROOT/pids/worker.pid"
else
    echo "Worker PID file not found, the service may not be running."
fi

echo "Stopping and removing Docker containers..."
docker stop assets-postgres assets-rabbitmq 2>/dev/null
docker rm assets-postgres assets-rabbitmq 2>/dev/null

echo "All services stopped!"