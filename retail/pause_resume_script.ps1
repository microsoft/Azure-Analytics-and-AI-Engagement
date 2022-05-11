#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode
$subs = Get-AzSubscription | Select-Object -ExpandProperty Name

if($subs.GetType().IsArray -and $subs.length -gt 1)
{
    $subOptions = [System.Collections.ArrayList]::new()
    for($subIdx=0; $subIdx -lt $subs.length; $subIdx++)
    {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
}

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"     
$synapseWorkspaceName = "synapseretail$init$random"
$sqlPoolName = "RetailDW"
$app_retaildemo_name = "retaildemo-app-$suffix";
$media_search_app_service_name = "app-media-search-$suffix"
$sites_adx_thermostat_realtime_name = "app-realtime-kpi-retail-$suffix"
$sites_app_product_search = "app-product-search-ui-$suffix"
$functionapptranscript = "func-app-media-transcript-$suffix"
$functionapplivestreaming = "func-app-livestreaming-$suffix"
$func_product_search_name = "func-app-product-search-$suffix"
$sites_app_multiling_retail_name = "multiling-retail-app-$suffix";
$sites_app_iotfoottraffic_sensor_name =  "iot-foottraffic-sensor-retail-app-$suffix";
$app_retail_qna_name = "qnamaker-app-$suffix",
$asa_name_retail = "retailasa-$suffix"
$title    = 'Choices'
$question = 'What would you like to do with the environment?'
$choices  = '&Pause', '&Resume'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
if($decision -eq 0)
{

write-host "Stopping SQL pool"
install-module Az.Synapse -f
#stop SQL
az synapse sql pool pause --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName
# stop ASA
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_retail 
write-host "Stopping Web apps"
#stop web apps
az webapp stop --name $app_retaildemo_name --resource-group $rgName
az webapp stop --name $functionapplivestreaming --resource-group $rgName 
az webapp stop --name $func_product_search_name --resource-group $rgName 
az webapp stop --name $media_search_app_service_name --resource-group $rgName
az webapp stop --name $sites_app_iotfoottraffic_sensor_name --resource-group $rgName
az webapp stop --name $sites_adx_thermostat_realtime_name --resource-group $rgName
az webapp stop --name $sites_app_product_search --resource-group $rgName
az webapp stop --name $functionapptranscript --resource-group $rgName
az webapp stop --name $sites_app_multiling_retail_name --resource-group $rgName
az webapp stop --name $app_retail_qna_name --resource-group $rgName
write-host "Pause operation successfull"
}

else
{

#Resume SQL
write-host "Starting Sql Pool"
az synapse sql pool resume --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName
# start ASA
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_retail -OutputStartMode 'JobStartTime'
#start web apps
write-host "Starting web apps"
az webapp start --name $app_retaildemo_name --resource-group $rgName
az webapp start --name $functionapplivestreaming --resource-group $rgName 
az webapp start --name $func_product_search_name --resource-group $rgName 
az webapp start --name $app_retaildemo_name --resource-group $rgName
az webapp start --name $media_search_app_service_name --resource-group $rgName
az webapp start --name $sites_app_iotfoottraffic_sensor_name --resource-group $rgName
az webapp start --name $sites_adx_thermostat_realtime_name --resource-group $rgName
az webapp start --name $sites_app_product_search --resource-group $rgName
az webapp start --name $functionapptranscript --resource-group $rgName
az webapp start --name $sites_app_multiling_retail_name --resource-group $rgName
az webapp start --name $app_retail_qna_name --resource-group $rgName
write-host "Resume operation successfull"
}