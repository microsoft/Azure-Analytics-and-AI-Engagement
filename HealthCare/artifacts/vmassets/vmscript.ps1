param (
    [Parameter(Mandatory = $false)][string]$eventhub_evh_ns_high_speed_datagen_name,
	[Parameter(Mandatory = $false)][string]$rgName,
	[Parameter(Mandatory = $false)][string]$evh_highe_speed_cs
	)
	
# Install Az cli
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# login using identity
#az login --identity

#$eventhub_high_speed_datagen_name = $eventhub_evh_ns_high_speed_datagen_name
#$eventhub_high_speed_datagen_cs = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $eventhub_high_speed_datagen_name --name RootManageSharedAccessKey | Out-String | ConvertFrom-Json
#$eventhub_high_speed_datagen_cs = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $eventhub_high_speed_datagen_name --eventhub-name evh-high-speed-datagen-healthcare --name asa-policy-manage-demo | Out-String | ConvertFrom-Json	
$eventhub_high_speed_datagen_cs = $evh_highe_speed_cs
$cs = $eventhub_high_speed_datagen_cs -replace ".{44}$"
$csFinal = $cs+"TransportType=Amqp"
expand-archive -path "./highspeed-datagen.zip" -destinationpath "./highspeed-datagen" -force

	  (Get-Content -path highspeed-datagen/SensorEventGenerator.exe.config -Raw) | Foreach-Object { $_ `
               -replace '#EVENTHUB_CONNECTION#', $csFinal`
				-replace '#EVENTHUB_NAME#', 'evh-high-speed-datagen-healthcare'`				
       } | Set-Content -Path highspeed-datagen/SensorEventGenerator.exe.config