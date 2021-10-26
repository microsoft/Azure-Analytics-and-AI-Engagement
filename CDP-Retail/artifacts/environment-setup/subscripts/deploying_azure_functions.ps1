  function RefreshTokens()
{
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell.
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

$resourceGroupName = read-host "Enter the resource Group Name";
$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$twitterFunction="twifunction$($uniqueId)"
$locationFunction="locfunction$($uniqueId)"

$currentDir = pwd
$subPath = $currentDir.path -replace ".{10}$"
$zipPathLocFunc = $subPath+"functions/LocationAnalytics_Publish_Package.zip"
$zipPathTwitFunc = $subPath+"functions/Twitter_Function_Publish_Package.zip"

RefreshTokens
Write-Host "Deploying Azure functions"

Publish-AzWebapp -ResourceGroupName $resourceGroupName -Name $twitterFunction -ArchivePath $zipPathTwitFunc
Publish-AzWebapp -ResourceGroupName $resourceGroupName -Name $locationFunction -ArchivePath $zipPathLocFunc

#az functionapp deployment source config-zip `
       # --resource-group $resourceGroupName `
       # --name $twitterFunction `
        #--src "../functions/Twitter_Function_Publish_Package.zip"
		
#az functionapp deployment source config-zip `
       # --resource-group $resourceGroupName `
      #  --name $locationFunction `
       # --src "../functions/LocationAnalytics_Publish_Package.zip"
