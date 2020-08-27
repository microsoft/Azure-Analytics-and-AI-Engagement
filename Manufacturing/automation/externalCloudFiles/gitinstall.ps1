param (
    [Parameter(Mandatory = $false)][string]$iot_hub_car,
    [Parameter(Mandatory = $false)][string]$iot_hub_telemetry,
    [Parameter(Mandatory = $false)][string]$iot_hub,
    [Parameter(Mandatory = $false)][string]$iot_hub_sendtohub,
	[Parameter(Mandatory = $false)][string]$synapseWorkspaceName,
	[Parameter(Mandatory = $false)][string]$wsId,
	[Parameter(Mandatory = $false)][string]$sqlPoolName,
	[Parameter(Mandatory = $false)][string]$dataLakeAccountName,
	[Parameter(Mandatory = $false)][string]$sqlUser,
	[Parameter(Mandatory = $false)][string]$sqlPassword,
	[Parameter(Mandatory = $false)][string]$resourceGroup,
	[Parameter(Mandatory = $false)][string]$mfgasaName,
	[Parameter(Mandatory = $false)][string]$carasaName,
	[Parameter(Mandatory = $false)][string]$cosmos_account_name_mfgdemo,
	[Parameter(Mandatory = $false)][string]$cosmos_database_name_mfgdemo_manufacturing,
	[Parameter(Mandatory = $false)][string]$mfgasaCosmosDBName ,
	[Parameter(Mandatory = $false)][string]$mfgASATelemetryName,
	[Parameter(Mandatory = $false)][string]$azure_login_id,
	[Parameter(Mandatory = $false)][string]$azure_login_password,
	[Parameter(Mandatory = $false)][string]$app_name_telemetry_car,
	[Parameter(Mandatory = $false)][string]$app_name_telemetry,
	[Parameter(Mandatory = $false)][string]$app_name_hub,
	[Parameter(Mandatory = $false)][string]$app_name_sendtohub,
	[Parameter(Mandatory = $false)][string]$ai_name_telemetry_car,
	[Parameter(Mandatory = $false)][string]$ai_name_telemetry,
	[Parameter(Mandatory = $false)][string]$ai_name_hub,
	[Parameter(Mandatory = $false)][string]$ai_name_sendtohub,
	[Parameter(Mandatory = $false)][string]$sparkPoolName,
	[Parameter(Mandatory = $false)][string]$manufacturing_poc_app_service_name,
	[Parameter(Mandatory = $false)][string]$wideworldimporters_app_service_name
	)

$asset = "Git-2.28.0-64-bit.exe"
$installer = "$env:temp\$($asset)"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.28.0.windows.1/Git-2.28.0-64-bit.exe -OutFile $installer
$git_install_inf = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.9\Downloads\0\gitsetup"
$install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
Start-Process -FilePath $installer -ArgumentList $install_args -Wait
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
#git clone https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git 
git clone --branch real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git
cd ./Azure-Analytics-and-AI-Engagement/Manufacturing/automation
./manufacturingSetup.ps1 -iot_hub_car $iot_hub_car -iot_hub_telemetry $iot_hub_telemetry  -iot_hub $iot_hub  -iot_hub_sendtohub $iot_hub_sendtohub -synapseWorkspaceName $synapseWorkspaceName  -wsId $wsId  -sqlPoolName $sqlPoolName  -dataLakeAccountName $dataLakeAccountName  -sqlUser $sqlUser  -sqlPassword $sqlPassword  -resourceGroup $resourceGroup  -mfgasaName $mfgasaName  -carasaName $carasaName  -cosmos_account_name_mfgdemo $cosmos_account_name_mfgdemo  -cosmos_database_name_mfgdemo_manufacturing $cosmos_database_name_mfgdemo_manufacturing  -mfgasaCosmosDBName $mfgasaCosmosDBName  -mfgASATelemetryName $mfgASATelemetryName -azure_login_id $azure_login_id -azure_login_password $azure_login_password  -app_name_telemetry_car $app_name_telemetry_car  -app_name_telemetry $app_name_telemetry  -app_name_hub $app_name_hub  -app_name_sendtohub $app_name_sendtohub  -ai_name_telemetry_car $ai_name_telemetry_car  -ai_name_telemetry $ai_name_telemetry  -ai_name_hub $ai_name_hub  -ai_name_sendtohub $ai_name_sendtohub -sparkPoolName $sparkPoolName -manufacturing_poc_app_service_name $manufacturing_poc_app_service_name -wideworldimporters_app_service_name $wideworldimporters_app_service_name