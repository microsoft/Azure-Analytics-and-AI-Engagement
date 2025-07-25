@echo off
setlocal

rem Get the directory where the script is located
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

echo Starting PostgreSQL container...
docker run -d --name assets-postgres -e POSTGRES_DB=assets_manager -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:latest

echo Starting RabbitMQ container...
docker run -d --name assets-rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:management

echo Waiting for services to start...
timeout /t 10 /nobreak

rem Create logs directory if it doesn't exist
if not exist "%PROJECT_ROOT%\logs" mkdir "%PROJECT_ROOT%\logs"

rem Create pids directory if it doesn't exist
if not exist "%PROJECT_ROOT%\pids" mkdir "%PROJECT_ROOT%\pids"

echo Starting web module...
cd /d "%PROJECT_ROOT%\web"
start "Web Module" cmd /k "%PROJECT_ROOT%\mvnw.cmd clean spring-boot:run -Dspring-boot.run.jvmArguments=-Dspring.pid.file=%PROJECT_ROOT%\pids\web.pid -Dspring-boot.run.profiles=dev"

echo Starting worker module...
cd /d "%PROJECT_ROOT%\worker"
start "Worker Module" cmd /k "%PROJECT_ROOT%\mvnw.cmd clean spring-boot:run -Dspring-boot.run.jvmArguments=-Dspring.pid.file=%PROJECT_ROOT%\pids\worker.pid -Dspring-boot.run.profiles=dev"

echo Web application: http://localhost:8080
echo RabbitMQ Management: http://localhost:15672 (guest/guest)
