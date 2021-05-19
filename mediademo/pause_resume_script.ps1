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

$synapseWorkspaceName = "synapsemedia$init$random"
$sqlPoolName = "MediaDW"
$functionapplivestreaming="func-app-media-livestreaming-$suffix"
$functionapptranscript = "func-app-media-transcript-$suffix"
$functionapprecommender="func-app-media-recommendation-$suffix"
$functionappmodelbuilder="func-app-model-builder-$suffix"
$media_poc_app_service_name = "app-demomedia-$suffix"
$media_search_app_service_name = "app-media-search-$suffix"
$title    = 'Choices'
$question = 'What would you like to do with the environment?'
$choices  = '&Pause', '&Resume'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if($decision -eq 0)
{

write-host "Stopping SQL pool"
install-module Az.Synapse -f
#stop SQL
az synapse sql pool pause --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName

write-host "Stopping Web apps"
#stop web apps
az webapp stop --name $media_poc_app_service_name --resource-group $rgName
az webapp stop --name $media_search_app_service_name --resource-group $rgName

write-host "Stopping Function apps"
#stop function apps
az webapp stop --name $functionapplivestreaming --resource-group $rgName
az webapp stop --name $functionapptranscript --resource-group $rgName
az webapp stop --name $functionapprecommender --resource-group $rgName
az webapp stop --name $functionappmodelbuilder --resource-group $rgName

write-host "Operation successfull"
}

else
{

#Resume SQL
write-host "Starting Sql Pool"
az synapse sql pool resume --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName

#start web apps
write-host "Starting web apps"
az webapp start --name $media_poc_app_service_name --resource-group $rgName
az webapp start --name $media_search_app_service_name --resource-group $rgName

#start function apps
write-host "Starting Function apps"
az webapp start --name $functionapplivestreaming --resource-group $rgName
az webapp start --name $functionapptranscript --resource-group $rgName
az webapp start --name $functionapprecommender --resource-group $rgName
az webapp start --name $functionappmodelbuilder --resource-group $rgName

write-host "Operation successfull"
}
