@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Must be run with administrator privileges
    pause
    exit
)

@echo on

REM 1. choco
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command " [System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

REM 2. Virtualbox
C:\ProgramData\chocolatey\bin\choco.exe install -y virtualbox --version 7.0.14

REM 3. Vagrant
C:\ProgramData\chocolatey\bin\choco.exe install -y vagrant

REM 4. Tabby
C:\ProgramData\chocolatey\bin\choco.exe install -y tabby

REM 5. Postman
C:\ProgramData\chocolatey\bin\choco.exe install -y postman

REM 6. typora
C:\ProgramData\chocolatey\bin\choco.exe install -y typora

REM 7. OpenLens
C:\ProgramData\chocolatey\bin\choco.exe install -y openlens

REM 8. Git
C:\ProgramData\chocolatey\bin\choco.exe install -y git

REM 9. VSCode
C:\ProgramData\chocolatey\bin\choco.exe install -y vscode

set /p DUMMY=All done!!
