[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
if (Get-Command 'az' -errorAction SilentlyContinue) {
        Write-Host `
            "Azure CLI is installed." `
            -ForegroundColor Green
    }
    else {
        Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindows" -OutFile .\AzureCLI.msi 
		Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
    }
if (Get-Command 'Invoke-Sqlcmd' -errorAction SilentlyContinue) {
        Write-Host `
            "SQL Cmdlet is installed." `
            -ForegroundColor Green
    }
    else {
       
            Install-Module -Name SqlServer -force
            
    }
if (Get-Command 'Invoke-Sqlcmd' -errorAction SilentlyContinue) {
        Write-Host `
            "SQL Cmdlet is installed." `
            -ForegroundColor Green
    }
    else {
       
            Install-Module -Name Az -AllowClobber -force
	    Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
            
    }
if(Get-Command 'git' -erroraction SilentlyContinue){
}
else
{
     $gitExePath = "C:\Program Files\Git\bin\git.exe"

    foreach ($asset in (Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest).assets) {
        if ($asset.name -match 'Git-\d*\.\d*\.\d*-64-bit\.exe') {
            $dlurl = $asset.browser_download_url
            $newver = $asset.name
        }
    }

    try {
        $ProgressPreference = 'SilentlyContinue'

        if (!(Test-Path $gitExePath)) {
            Write-Host "`nDownloading latest stable git..." -ForegroundColor Yellow
            Remove-Item -Force $env:TEMP\git-stable.exe -ErrorAction SilentlyContinue
            Invoke-WebRequest -Uri $dlurl -OutFile $env:TEMP\git-stable.exe

            Write-Host "`nInstalling git..." -ForegroundColor Yellow
            Start-Process -Wait $env:TEMP\git-stable.exe -ArgumentList /silent
        }
        else {
            $updateneeded = $false
            Write-Host "`ngit is already installed. Check if possible update..." -ForegroundColor Yellow
            (git version) -match "(\d*\.\d*\.\d*)" | Out-Null
            $installedversion = $matches[0].split('.')
            $newver -match "(\d*\.\d*\.\d*)" | Out-Null
            $newversion = $matches[0].split('.')

            if (($newversion[0] -gt $installedversion[0]) -or ($newversion[0] -eq $installedversion[0] -and $newversion[1] -gt $installedversion[1]) -or ($newversion[0] -eq $installedversion[0] -and $newversion[1] -eq $installedversion[1] -and $newversion[2] -gt $installedversion[2])) {
                $updateneeded = $true
            }

            if ($updateneeded) {

                Write-Host "`nUpdate available. Downloading latest stable git..." -ForegroundColor Yellow
                Remove-Item -Force $env:TEMP\git-stable.exe -ErrorAction SilentlyContinue
                Invoke-WebRequest -Uri $dlurl -OutFile $env:TEMP\git-stable.exe

                Write-Host "`nInstalling update..." -ForegroundColor Yellow
                $sshagentrunning = get-process ssh-agent -ErrorAction SilentlyContinue
                if ($sshagentrunning) {
                    Write-Host "`nKilling ssh-agent..." -ForegroundColor Yellow
                    Stop-Process $sshagentrunning.Id
                }

                Start-Process -Wait $env:TEMP\git-stable.exe -ArgumentList /silent
            } else {
                Write-Host "`nNo update available. Already running latest version..." -ForegroundColor Yellow
            }

        }
            Write-Host "`nInstallation complete!`n`n" -ForegroundColor Green
    }
    finally {
        $ProgressPreference = 'Continue'
    }
}
if(Get-Command 'Login-PowerBI'-erroraction SilentlyContinue){
}
else
{
Install-Module -Name MicrosoftPowerBIMgmt -Force

}

if (Get-Command 'python' -errorAction SilentlyContinue) {
       Write-Host `
           "Python is installed." `
           -ForegroundColor Green
   }
   else {
       [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

		Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.7.0/python-3.7.0.exe" -OutFile "c:/python-3.7.0.exe"

		c:/python-3.7.0.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
   }
