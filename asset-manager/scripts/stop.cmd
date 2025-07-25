@echo off
setlocal enabledelayedexpansion

rem Get the directory where the script is located
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

echo Stopping Java processes...

rem Check if web PID file exists and stop the process
if exist "%PROJECT_ROOT%\pids\web.pid" (
    set /p WEB_PID=<"%PROJECT_ROOT%\pids\web.pid"
    call :trim WEB_PID
    if defined WEB_PID (
        if !WEB_PID! GTR 0 (
            echo Stopping web module with PID: !WEB_PID!
            taskkill /F /PID !WEB_PID! 2>nul
            if !ERRORLEVEL! EQU 0 (
                echo Web process successfully stopped.
            ) else (
                echo Failed to stop web process, it may have already terminated.
            )
        ) else (
            echo Invalid web PID found in file.
        )
    ) else (
        echo Empty web PID file found.
    )
    del "%PROJECT_ROOT%\pids\web.pid"
) else (
    echo Web PID file not found, the service may not be running.
)

rem Check if worker PID file exists and stop the process
if exist "%PROJECT_ROOT%\pids\worker.pid" (
    set /p WORKER_PID=<"%PROJECT_ROOT%\pids\worker.pid"
    call :trim WORKER_PID
    if defined WORKER_PID (
        if !WORKER_PID! GTR 0 (
            echo Stopping worker module with PID: !WORKER_PID!
            taskkill /F /PID !WORKER_PID! 2>nul
            if !ERRORLEVEL! EQU 0 (
                echo Worker process successfully stopped.
            ) else (
                echo Failed to stop worker process, it may have already terminated.
            )
        ) else (
            echo Invalid worker PID found in file.
        )
    ) else (
        echo Empty worker PID file found.
    )
    del "%PROJECT_ROOT%\pids\worker.pid"
) else (
    echo Worker PID file not found, the service may not be running.
)

echo Stopping and removing Docker containers...
docker stop assets-postgres assets-rabbitmq 2>nul
docker rm assets-postgres assets-rabbitmq 2>nul

echo All services stopped!
goto :eof

:trim
rem Remove leading and trailing whitespace from variable
setlocal enabledelayedexpansion
set "var=!%1!"
for /f "tokens=* delims= " %%a in ("!var!") do set "var=%%a"
:loop
if "!var:~-1!"==" " set "var=!var:~0,-1!" & goto loop
endlocal & set "%1=%var%"
goto :eof
