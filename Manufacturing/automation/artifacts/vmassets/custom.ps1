param (
    [Parameter(Mandatory = $false)][string]$sku2_iot_hub_car,
    [Parameter(Mandatory = $false)][string]$sku2_iot_hub_telemetry,
    [Parameter(Mandatory = $false)][string]$sku2_iot_hub,
    [Parameter(Mandatory = $false)][string]$sku2_iot_hub_sendtohub
	)
	
# Install Az cli
#Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

# login using identity
az login --identity

#install iot hub extension
#az extension add --name azure-cli-iot-ext

#Create iot hub devices
az iot hub device-identity create -n $sku2_iot_hub_car -d race-car
az iot hub device-identity create -n $sku2_iot_hub_telemetry -d telemetry-data
az iot hub device-identity create -n $sku2_iot_hub -d data-device
az iot hub device-identity create -n $sku2_iot_hub_sendtohub -d send-to-hub

#get connection strings

$iot_device_connection_car = az iot hub device-identity show-connection-string --hub-name $sku2_iot_hub_car --device-id race-car | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_car.connectionString

$iot_device_connection_telemetry = az iot hub device-identity show-connection-string --hub-name $sku2_iot_hub_telemetry --device-id telemetry-data | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_telemetry.connectionString

$iot_device_connection = az iot hub device-identity show-connection-string --hub-name $sku2_iot_hub --device-id data-device | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection.connectionString

$iot_device_connection_sendtohub = az iot hub device-identity show-connection-string --hub-name $sku2_iot_hub_sendtohub --device-id send-to-hub | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_sendtohub.connectionString

#download the binary zip folders

Invoke-WebRequest https://aadlsstrgnpnq4eqzbflgite.blob.core.windows.net/publicassets/carTelemetry.zip -OutFile carTelemetry.zip
#extract
expand-archive -path "./carTelemetry.zip" -destinationpath "./carTelemetry"

Invoke-WebRequest https://aadlsstrgnpnq4eqzbflgite.blob.core.windows.net/publicassets/Telemetry.zip -OutFile Telemetry.zip
#extract
expand-archive -path "./Telemetry.zip" -destinationpath "./Telemetry"

Invoke-WebRequest https://aadlsstrgnpnq4eqzbflgite.blob.core.windows.net/publicassets/sku2.zip -OutFile sku2.zip
#extract
expand-archive -path "./sku2.zip" -destinationpath "./sku2"

Invoke-WebRequest https://aadlsstrgnpnq4eqzbflgite.blob.core.windows.net/publicassets/sendtohub.zip -OutFile sendtohub.zip
#extract
expand-archive -path "./sendtohub.zip" -destinationpath "./sendtohub"

#Replace connection string in config
(Get-Content -path carTelemetry/App.config -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_car.connectionString`	
        } | Set-Content -Path carTelemetry/App.config
		
(Get-Content -path Telemetry/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_telemetry.connectionString`	
        } | Set-Content -Path Telemetry/appsettings.json
		
(Get-Content -path sku2/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sku2.connectionString`	
        } | Set-Content -Path sku2/appsettings.json
		
(Get-Content -path sendtohub/App.config -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sendtohub.connectionString`	
        } | Set-Content -Path sendtohub/App.config

#run the 4 codes on the vm
cd carTelemetry
start-process SendMessageToIoTHub.exe
cd ..
cd sendtohub
start-process SendMessageToIoTHub.exe
cd ..
cd sku2
start-process DataGenerator.exe
cd ..
cd Telemetry
start-process DataGenerator.exe
cd ..

