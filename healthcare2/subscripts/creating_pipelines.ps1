function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if ($subs.GetType().IsArray -and $subs.length -gt 1) {
    $subOptions = [System.Collections.ArrayList]::new()
    for ($subIdx = 0; $subIdx -lt $subs.length; $subIdx++) {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    $title = 'Subscription selection'
    $question = 'Are you sure you want to select this subscription for this lab?'
    $choices = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
    else {
        $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
        $selectedSubName = $subs[$selectedSubIdx]
        Write-Host "Selecting the subscription : $selectedSubName "
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
}

$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
$concatString = "$init$random"
$synapseWorkspaceName = "synhealthcare2$concatString"
$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}


#creating Pipelines
    Add-Content log.txt "------pipelines------"
    Write-Host "-------Pipelines-----------"
    RefreshTokens
    $pipelines = Get-ChildItem "../artifacts/pipeline" | Select BaseName
    $pipelineList = New-Object System.Collections.ArrayList
    foreach ($name in $pipelines) {
        $FilePath = "../artifacts/pipeline/" + $name.BaseName + ".json"
        Write-Host "Creating pipeline : $($name.BaseName)"

        $item = Get-Content -Path $FilePath
        $item = $item.Replace("#DATA_LAKE_STORAGE_NAME#", $dataLakeAccountName)
        $defaultStorage = $synapseWorkspaceName + "-WorkspaceDefaultStorage"
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    
        #waiting for operation completion
        Start-Sleep -Seconds 10
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization = "Bearer $synapseToken" }
        Add-Content log.txt $result 
    }
