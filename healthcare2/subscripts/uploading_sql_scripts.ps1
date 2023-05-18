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
    $Region = (Get-AzResourceGroup -Name $rgName).Location
    $init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
    $random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
    $suffix = "$random-$init"
    $concatString = "$init$random"
    $synapseWorkspaceName = "synhealthcare2$concatString"
    $sqlPoolName = "HealthcareDW"
    $dataLakeAccountName = "sthealthcare2$concatString"
    if($dataLakeAccountName.length -gt 24)
    {
    $dataLakeAccountName = $dataLakeAccountName.substring(0,24)
    }
    $sqlUser = "labsqladmin"
    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
    $cosmos_healthcare2_name = "cosmos-healthcare2-$random$init"
    if ($cosmos_healthcare2_name.length -gt 43) {
        $cosmos_healthcare2_name = $cosmos_healthcare2_name.substring(0, 43)
    }
    #Cosmos keys
    $cosmos_account_key = az cosmosdb keys list -n $cosmos_healthcare2_name -g $rgName | ConvertFrom-Json
    $cosmos_account_key = $cosmos_account_key.primarymasterkey
    

    #uploading Sql Scripts
    Add-Content log.txt "-----------uploading Sql Script-----------------"
    Write-Host "----Sql Scripts------"
    RefreshTokens
    $scripts = Get-ChildItem "../artifacts/sqlscripts" | Select BaseName
    $TemplatesPath = "../artifacts/templates";	
    
    $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
    $sasTokenAcc = New-AzStorageAccountSASToken -Context $dataLakeContext -Service Blob -ResourceType Service -Permission rwdl

    foreach ($name in $scripts) {
        if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "storedProcedure" -or $name.BaseName -eq "viewDedicatedPool" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql_user_hc2" -or $name.BaseName -eq "configurableTableQuery") {
            continue;
        }
        $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
        $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
        $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
        $jsonItem = ConvertFrom-Json $item 
        $ScriptFileName = "../artifacts/sqlscripts/" + $name.BaseName + ".sql"
    
        $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
        $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
        $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmos_healthcare2_name)
        $query = $query.Replace("#COSMOSDB_ACCOUNT_KEY#", $cosmos_account_key)
        $query = $query.Replace("#REGION#", $Region)
        $query = $query.Replace("#SAS_TOKEN#", $sasTokenAcc)
	
        if ($Parameters -ne $null) {
            foreach ($key in $Parameters.Keys) {
                $query = $query.Replace("#$($key)#", $Parameters[$key])
            }
        }

        Write-Host "Uploading Sql Script : $($name.BaseName)"
        $query = ConvertFrom-Json (ConvertTo-Json $query)
        $jsonItem.properties.content.query = $query
        $item = ConvertTo-Json $jsonItem -Depth 100
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
        Add-Content log.txt $result
    }
