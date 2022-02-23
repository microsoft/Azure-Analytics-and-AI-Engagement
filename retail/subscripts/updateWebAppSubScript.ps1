az login
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
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$app_retaildemo_name = "retaildemo-app-$suffix";

Compress-Archive -Path "../snackable-poc/*" -DestinationPath "../snackable-poc.zip"

az webapp stop --name $app_retaildemo_name --resource-group $rgName

try{
az webapp deployment source config-zip --resource-group $rgName --name $app_retaildemo_name --src "../snackable-poc.zip"
}
catch
{
}

az webapp start --name $app_retaildemo_name --resource-group $rgName
remove-item -path "../snackable-poc.zip" -recurse -force