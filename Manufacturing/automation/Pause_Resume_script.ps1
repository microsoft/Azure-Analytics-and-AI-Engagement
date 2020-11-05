#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$mfgasaName = "mfgasa-$suffix"
$carasaName = "race-car-asa-$suffix"
$mfgasaCosmosDBName = "mfgasaCosmosDB-$suffix"
$mfgASATelemetryName = "mfgASATelemetry-$suffix"
$synapseWorkspaceName = "manufacturingdemo$init$random"
$sqlPoolName = "ManufacturingDW"
$app_name_telemetry_car = "car-telemetry-app-$suffix"
$app_name_telemetry = "datagen-telemetry-app-$suffix"
$app_name_hub = "sku2-telemetry-app-$suffix"
$app_name_sendtohub = "sendtohub-telemetry-app-$suffix"
$manufacturing_poc_app_service_name = "manufacturing-poc-$suffix"
$wideworldimporters_app_service_name = "wideworldimporters-$suffix"


$title    = 'Choices'
$question = 'What would you like to do with the environment?'
$choices  = '&Pause', '&Resume'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if($decision -eq 0)
{
install-module Az.StreamAnalytics -f
#stop ASA
write-host "Stopping ASA jobs"
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgASATelemetryName 
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaName 
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $carasaName 
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaCosmosDBName 

write-host "Stopping SQL pool"
install-module Az.Synapse -f
#stop SQL
az synapse sql pool pause --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName

write-host "Stopping Web apps"
#stop web apps
az webapp stop --name $app_name_telemetry_car --resource-group $rgName
az webapp stop --name $app_name_telemetry --resource-group $rgName
az webapp stop --name $app_name_hub --resource-group $rgName
az webapp stop --name $app_name_sendtohub --resource-group $rgName
az webapp stop --name $wideworldimporters_app_service_name --resource-group $rgName
az webapp stop --name $manufacturing_poc_app_service_name --resource-group $rgName

write-host "Operation successfull"
}

else
{
#start ASA
write-host "Starting ASA jobs"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgASATelemetryName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $carasaName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaCosmosDBName -OutputStartMode 'JobStartTime'

#Resume SQL
write-host "Starting Sql Pool"
az synapse sql pool pause --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName

#start web apps
write-host "Starting web apps"
az webapp start --name $app_name_telemetry_car --resource-group $rgName
az webapp start --name $app_name_telemetry --resource-group $rgName
az webapp start --name $app_name_hub --resource-group $rgName
az webapp start --name $app_name_sendtohub --resource-group $rgName
az webapp start --name $wideworldimporters_app_service_name --resource-group $rgName
az webapp start --name $manufacturing_poc_app_service_name --resource-group $rgName
write-host "Operation successfull"
}
