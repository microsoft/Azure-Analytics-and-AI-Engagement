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
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"

$synapseWorkspaceName = "synapsehealthcare$init$random"
$sqlPoolName = "HealthCareDW"
$healthcareasa = "asa-healthcare-$suffix"
$highspeedasa = "asa-high-speed-datagen-healthcare-$suffix"
$app_name_iomt_simulator = "app-iomt-simulator-$suffix"
$app_name_demohealthcare = "app-demohealthcare-$suffix"
$eventhub_evh_ns_high_speed_datagen_healthcare = "evh-highspeed-$suffix"
$functionappIomt="func-app-iomt-processor-$suffix"
$functionappMongoData = "func-app-mongo-data-$suffix"

$title    = 'Choices'
$question = 'What would you like to do with the environment?'
$choices  = '&Pause', '&Resume'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if($decision -eq 0)
{
install-module Az.StreamAnalytics -f
#stop ASA
write-host "Stopping ASA jobs"
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $healthcareasa 
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $highspeedasa 


write-host "Stopping SQL pool"
install-module Az.Synapse -f
#stop SQL
az synapse sql pool pause --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName

write-host "Stopping Web apps"
#stop web apps
az webapp stop --name $app_name_iomt_simulator --resource-group $rgName
az webapp stop --name $app_name_demohealthcare --resource-group $rgName

write-host "Stopping Function apps"
#stop function apps
az webapp stop --name $functionappIomt --resource-group $rgName
az webapp stop --name $functionappMongoData --resource-group $rgName

az eventhubs namespace update --resource-group $rgName --name $eventhub_evh_ns_high_speed_datagen_healthcare --capacity 1 --enable-auto-inflate true --enable-kafka true --maximum-throughput-units 20

write-host "Operation successfull"
}

else
{
#start ASA
write-host "Starting ASA jobs"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $healthcareasa -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $highspeedasa -OutputStartMode 'JobStartTime'

#Resume SQL
write-host "Starting Sql Pool"
az synapse sql pool resume --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName

#start web apps
write-host "Starting web apps"
az webapp start --name $app_name_demohealthcare --resource-group $rgName
az webapp start --name $app_name_iomt_simulator --resource-group $rgName

#start function apps
write-host "Starting Function apps"
az webapp start --name $functionappIomt --resource-group $rgName
az webapp start --name $functionappMongoData --resource-group $rgName

write-host "Operation successfull"
}
