function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

#remove-item MfgAI -recurse -force
#git clone -b real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git MfgAI

#cd 'MfgAI/Manufacturing/automation'

#if they have many subs...
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

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$suffix = "$random-$init"
$mfgasaName = "mfgasa-$suffix"
$carasaName = "race-car-asa-$suffix"
$mfgASATelemetryName = "mfgASATelemetry-$suffix"
$mfgasaCosmosDBName = "mfgasaCosmosDB-$suffix"

RefreshTokens
Add-Content log.txt "------asa powerbi connection-----"
Write-Host "----asa powerbi connection-----"
#connecting asa and powerbi
Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI
$principal=az resource show -g $rgName -n $mfgasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

$principal=az resource show -g $rgName -n $carasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

#start ASA
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgASATelemetryName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $carasaName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaCosmosDBName -OutputStartMode 'JobStartTime'
