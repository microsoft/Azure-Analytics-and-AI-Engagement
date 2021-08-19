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
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$synapseWorkspaceName = "synapsehealthcare$init$random"

#creating Pipelines
Add-Content log.txt "------pipelines------"
Write-Host "-------Creating pipelines-----------"
RefreshTokens
$pipelines=Get-ChildItem "./artifacts/pipelines" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
    $FilePath="./artifacts/pipelines/"+$name.BaseName+".json"
    
    $temp = "" | select-object @{Name = "FileName"; Expression = {$name.BaseName}} , @{Name = "Name"; Expression = {$name.BaseName.ToUpper()}}, @{Name = "PowerBIReportName"; Expression = {""}}
    $pipelineList.Add($temp)
    $item = Get-Content -Path $FilePath
    $item=$item.Replace("#DATA_LAKE_STORAGE_NAME#",$dataLakeAccountName)
    #$item=$item.Replace("#BLOB_LINKED_SERVICE#",$blobLinkedService)
    $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
    #$item=$item.Replace("#DEFAULT_STORAGE#",$defaultStorage)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
    Start-Sleep -Seconds 10
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    Add-Content log.txt $result 
}
