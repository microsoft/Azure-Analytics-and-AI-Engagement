function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$healthcareasa = "asa-healthcare-$suffix"
$highspeedasa = "asa-high-speed-datagen-healthcare-$suffix"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]

RefreshTokens
Add-Content log.txt "------asa powerbi connection-----"
Write-Host "----asa powerbi connection-----"
#connecting asa and powerbi

$principal=az resource show -g $rgName -n $healthcareasa --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

#start ASA
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $healthcareasa -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $highspeedasa -OutputStartMode 'JobStartTime'
    