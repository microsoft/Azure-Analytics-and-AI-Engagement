function Control-SQLPool {

        param(
        [parameter(Mandatory=$true)]
        [String]
        $SubscriptionId,
    
        [parameter(Mandatory=$true)]
        [String]
        $ResourceGroupName,
    
        [parameter(Mandatory=$true)]
        [String]
        $WorkspaceName,
    
        [parameter(Mandatory=$true)]
        [String]
        $SQLPoolName,
    
        [parameter(Mandatory=$true)]
        [String]
        $Action,
    
        [parameter(Mandatory=$false)]
        [String]
        $SKU
        )
    
        $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/sqlPools/$($SQLPoolName)#ACTION#?api-version=2019-06-01-preview"
        $method = "POST"
        $body = $null
    
        if (($Action.ToLowerInvariant() -eq "pause") -or ($Action.ToLowerInvariant() -eq "resume")) {
    
            $uri = $uri.Replace("#ACTION#", "/$($Action)")
    
        } elseif ($Action.ToLowerInvariant() -eq "scale") {
            
            $uri = $uri.Replace("#ACTION#", "")
            $method = "PATCH"
            $body = "{""sku"":{""name"":""$($SKU)""}}"
    
        } else {
            
            throw "The $($Action) control action is not supported."
    
        }
    
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method $method -Body $body -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
    
        return $result
    }

    function Get-SQLPool {

        param(
        [parameter(Mandatory=$true)]
        [String]
        $SubscriptionId,
    
        [parameter(Mandatory=$true)]
        [String]
        $ResourceGroupName,
    
        [parameter(Mandatory=$true)]
        [String]
        $WorkspaceName,
    
        [parameter(Mandatory=$true)]
        [String]
        $SQLPoolName
        )
    
        $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/sqlPools/$($SQLPoolName)?api-version=2019-06-01-preview"
    
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
    
        return $result
    }
    
    function Wait-ForSQLPool {

        param(
        [parameter(Mandatory=$true)]
        [String]
        $SubscriptionId,
    
        [parameter(Mandatory=$true)]
        [String]
        $ResourceGroupName,
    
        [parameter(Mandatory=$true)]
        [String]
        $WorkspaceName,
    
        [parameter(Mandatory=$true)]
        [String]
        $SQLPoolName,
    
        [parameter(Mandatory=$false)]
        [String]
        $TargetStatus
        )
    
        Write-Host "Waiting for any pending operation to be properly triggered..."
        Start-Sleep -Seconds 20
    
        $result = Get-SQLPool -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName
    
        if ($TargetStatus) {
            while ($result.properties.status -ne $TargetStatus) {
                Write-Host "Current status is $($result.properties.status). Waiting for $($TargetStatus) status..."
                Start-Sleep -Seconds 10
                $result = Get-SQLPool -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName
            }
        }
    
        Write-Host "The SQL pool has now the $($TargetStatus) status."
        return $result
    }
    
    function Execute-SQLScriptFile {

        param(
        [parameter(Mandatory=$true)]
        [String]
        $SQLScriptsPath,
    
        [parameter(Mandatory=$true)]
        [String]
        $WorkspaceName,
    
        [parameter(Mandatory=$true)]
        [String]
        $SQLPoolName,
    
        [parameter(Mandatory=$true)]
        [String]
        $FileName,
    
        [parameter(Mandatory=$false)]
        [Hashtable]
        $Parameters,
    
        [parameter(Mandatory=$false)]
        [Boolean]
        $ForceReturn,
    
        [parameter(Mandatory=$false)]
        [Boolean]
        $UseAPI = $false
        )
    
        $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/$($FileName).sql"
    
        if ($Parameters) {
            foreach ($key in $Parameters.Keys) {
                $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
            }
        }
    
        #https://aka.ms/vs/15/release/vc_redist.x64.exe 
        #https://www.microsoft.com/en-us/download/confirmation.aspx?id=56567
        #https://go.microsoft.com/fwlink/?linkid=2082790
    
        if ($UseAPI) {
            Execute-SQLQuery -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName -SQLQuery $sqlQuery -ForceReturn $ForceReturn
        } else {
            if ($ForceReturn) {
                Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $global:sqlPassword
                #& sqlcmd -S $sqlEndpoint -d $sqlPoolName -U $userName -P $password -G -I -Q $sqlQuery
            } else {
                Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $global:sqlPassword
                #& sqlcmd -S $sqlEndpoint -d $sqlPoolName -U $userName -P $password -G -I -Q $sqlQuery
            }
        }
    }
    
    function Execute-SQLQuery {

        param(
        [parameter(Mandatory=$true)]
        [String]
        $WorkspaceName,
    
        [parameter(Mandatory=$true)]
        [String]
        $SQLPoolName,
    
        [parameter(Mandatory=$true)]
        [String]
        $SQLQuery,
    
        [parameter(Mandatory=$false)]
        [Boolean]
        $ForceReturn
        )
    
        $uri = "https://$($WorkspaceName).sql.azuresynapse.net:1443/databases/$($SQLPoolName)/query?api-version=2018-08-01-preview&application=ArcadiaSqlEditor&topRows=5000&queryTimeoutInMinutes=59&allResultSets=true"
    
        $headers = @{ 
            Authorization="Bearer $($synapseSQLToken)"
        }
    
        if ($ForceReturn) {
            try {
                Ensure-ValidTokens
                $result = Invoke-WebRequest -Uri $uri -Method POST -Body $SQLQuery -Headers $headers -ContentType "application/x-www-form-urlencoded; charset=UTF-8" -UseBasicParsing -TimeoutSec 15
            } catch {}
            return
        }
    
        Ensure-ValidTokens
    
        $csrf = GetCSRF "Bearer $synapseSQLToken" "$($WorkspaceName).sql.azuresynapse.net:1443" 300000;
        $headers.add("X-CSRF-Signature", $csrf);
    
        $rawResult = Invoke-WebRequest -Uri $uri -Method POST -Body $SQLQuery -Headers $headers `
            -ContentType "application/x-www-form-urlencoded; charset=UTF-8" -UseBasicParsing
    
        $result = ConvertFrom-Json $rawResult.Content
    
        $errors = @()
        foreach ($partialResult in $result) {
            if (-not $partialResult.isSuccess) {
    
                $errors += $partialResult.message
            }
        }
        if ($errors.Count -gt 0) {
            throw (-join $errors)
        }
    
        return $result
    }
    
    function GetCSRF($token, $azurehost, $msTime)
    {
        $start = [Datetime]::UtcNow.tostring("yyyy-MM-ddTHH:mm:ssZ");
        $end = [Datetime]::UtcNow.AddMilliseconds($msTime).tostring("yyyy-MM-ddTHH:mm:ssZ");
    
        $rawsig = "not-before=$($start)`r`nnot-after=$($end)`r`nauthorization: $($token)`r`nhost: $($azurehost)`r`n";
    
        $signed = CallJavascript $rawsig $token;
    
        $sig = "$($signed); not-before=$($start); not-after=$($end); signed-headers=authorization,host"
    
        return $sig;
    }
    
    function CallJavascript($message, $secret)
    {
        Write-Host $message
        Write-Host $secret
        $url = "https://ciprian-hash.azurewebsites.net/hash.html"
     
        $ie = New-Object -COMObject InternetExplorer.Application
        $ie.visible = $true;
    
        $ie.Navigate($url)
        $ie.visible = $false;
     
        while($ie.Busy) 
        {
            start-sleep -m 100
        } 
    
        $inputs = $ie.Document.body.getElementsByTagName("input");
    
        $msgInput = $inputs | where {$_.name -eq "msg"}
        $secretInput = $inputs | where {$_.name -eq "secret"}
        $outputInput = $inputs | where {$_.name -eq "output"}
    
        $buttons = $ie.Document.body.getElementsByTagName("button");
        $btnGo = $buttons | where {$_.name -eq "btnGo"}
     
        $msgInput.value = $message.replace("`r","\r").replace("`n","\n");
        $secretInput.value = $secret;
        $btnGo.click();
        
        $ret = $outputInput.value;
        $ie.quit();
    
        if (!$ret)
        {
            write-host "Error getting CSRF" -ForegroundColor red;
        }
     
        return $ret;
    }

    
    function Assign-SynapseRole {

        param(    
        [parameter(Mandatory=$true)]
        [String]
        $WorkspaceName,
    
        [parameter(Mandatory=$true)]
        [String]
        $RoleId,
    
        [parameter(Mandatory=$true)]
        [String]
        $PrincipalId
        )
    
        $uri = "https://$($WorkspaceName).dev.azuresynapse.net/rbac/roleAssignments?api-version=2020-02-01-preview"
        $method = "POST"
    
        $id = $RoleId + "-" + $PrincipalId
        $body = "{ id: ""$id"", roleId: ""$RoleId"", principalId: ""$PrincipalId"" }"
    
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method $method -Body $body -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
        return $result
    }

    function Refresh-Token {
        param(
        [parameter(Mandatory=$true)]
        [String]
        $TokenType
        )
    
        if(Test-Path C:\LabFiles\AzureCreds.ps1){
            if ($TokenType -eq "Synapse") {
                $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                    -Method POST -Body $global:ropcBodySynapse -ContentType "application/x-www-form-urlencoded"
                $global:synapseToken = $result.access_token
            } elseif ($TokenType -eq "SynapseSQL") {
                $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                    -Method POST -Body $global:ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
                $global:synapseSQLToken = $result.access_token
            } elseif ($TokenType -eq "Management") {
                $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                    -Method POST -Body $global:ropcBodyManagement -ContentType "application/x-www-form-urlencoded"
                $global:managementToken = $result.access_token
            } elseif ($TokenType -eq "PowerBI") {
                $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                    -Method POST -Body $global:ropcBodyPowerBI -ContentType "application/x-www-form-urlencoded"
                $global:powerbitoken = $result.access_token
            }
            else {
                throw "The token type $($TokenType) is not supported."
            }
        } else {
            switch($TokenType) {
                "Synapse" {
                    $tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
                    $global:synapseToken = $tokenValue; 
                    break;
                }
                "SynapseSQL" {
                    $tokenValue = ((az account get-access-token --resource https://sql.azuresynapse.net) | ConvertFrom-Json).accessToken
                    $global:synapseSQLToken = $tokenValue; 
                    break;
                }
                "Management" {
                    $tokenValue = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
                    $global:managementToken = $tokenValue; 
                    break;
                }
                "PowerBI" {
                    $tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
                    $global:powerbitoken = $tokenValue; 
                    break;
                }
                default {throw "The token type $($TokenType) is not supported.";}
            }
        }
    }
    
    function Ensure-ValidTokens {
            
        for ($i = 0; $i -lt $tokenTimes.Count; $i++) {
            Ensure-ValidToken $($tokenTimes.Keys)[$i]
        }
    }
    
    
    function Ensure-ValidToken {
        param(
            [parameter(Mandatory=$true)]
            [String]
            $TokenName
        )
    
        $refTime = Get-Date
    
        if (($refTime - $tokenTimes[$TokenName]).TotalMinutes -gt 30) {
            Write-Host "Refreshing $($TokenName) token."
            Refresh-Token $TokenName
            $tokenTimes[$TokenName] = $refTime
        }
    }
    
#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
        if($subs.GetType().IsArray -and $subs.length -gt 1){
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

        $global:sqlPassword = Read-Host -Prompt "Enter the SQL Administrator password you used in the deployment" -AsSecureString
        $global:sqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($sqlPassword))

        $sqlScriptsPath = "..\sql"

$resourceGroups = az group list --query '[].name' -o tsv 

if($resourceGroups.GetType().IsArray -and $resourceGroups.length -gt 1){
    $rgOptions = [System.Collections.ArrayList]::new()
    for($rgIdx=0; $rgIdx -lt $resourceGroups.length; $rgIdx++){
        $optionName = $resourceGroups[$rgIdx]
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($optionName)", "Selects the $($resourceGroups[$rgIdx]) resource group."   
        $rgOptions.Add($opt)
    }
    $selectedRgIdx = $host.ui.PromptForChoice('Enter the desired Resource Group for this lab','Copy and paste the name of the resource group to make your choice.', $rgOptions.ToArray(),0)
    $resourceGroupName = $resourceGroups[$selectedRgIdx]
    Write-Host "Selecting the $resourceGroupName resource group"
}
else{
$resourceGroupName=$resourceGroups
Write-Host "Selecting the $resourceGroupName resource group"
}

$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$workspaceName = "asaexpworkspace$($uniqueId)"
$subscriptionId = (Get-AzContext).Subscription.Id
$sqlPoolName = "SQLPool01"
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asaexp.sql.labsqladmin"

Install-Module -Name SqlServer -f

Write-Host "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
        Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
        Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

Write-Host "Create tables in $($sqlPoolName)"

$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "01-create-tables" -Parameters $params 
$result

Write-Host "Create storade procedures in $($sqlPoolName)"

$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "04-create-stored-procedures" -Parameters $params 
$result

Write-Host "Loading data"

$dataTableList = New-Object System.Collections.ArrayList
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Dim_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Dim_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MillennialCustomers"}} , @{Name = "TABLE_NAME"; Expression = {"MillennialCustomers"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"sale"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Products"}} , @{Name = "TABLE_NAME"; Expression = {"Products"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"10millionrows"}} , @{Name = "TABLE_NAME"; Expression = {"IDS"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"department_visit_customer"}} , @{Name = "TABLE_NAME"; Expression = {"department_visit_customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Category"}} , @{Name = "TABLE_NAME"; Expression = {"Category"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProdChamp"}} , @{Name = "TABLE_NAME"; Expression = {"ProdChamp"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaigns"}} , @{Name = "TABLE_NAME"; Expression = {"Campaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignNew4"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignNew4"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerVisitF"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerVisitF"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinanceSales"}} , @{Name = "TABLE_NAME"; Expression = {"FinanceSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LocationAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"LocationAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink2"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductRecommendations"}} , @{Name = "TABLE_NAME"; Expression = {"ProductRecommendations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"BrandAwareness"}} , @{Name = "TABLE_NAME"; Expression = {"BrandAwareness"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMaster"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMaster"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesVsExpense"}} , @{Name = "TABLE_NAME"; Expression = {"SalesVsExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FPA"}} , @{Name = "TABLE_NAME"; Expression = {"FPA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Country"}} , @{Name = "TABLE_NAME"; Expression = {"Country"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Books"}} , @{Name = "TABLE_NAME"; Expression = {"Books"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"BookConsumption"}} , @{Name = "TABLE_NAME"; Expression = {"BookConsumption"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"EmailAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"EmailAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DimDate"}} , @{Name = "TABLE_NAME"; Expression = {"DimDate"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Popularity"}} , @{Name = "TABLE_NAME"; Expression = {"Popularity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinalRevenue"}} , @{Name = "TABLE_NAME"; Expression = {"FinalRevenue"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ConflictofInterest"}} , @{Name = "TABLE_NAME"; Expression = {"ConflictofInterest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SiteSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"SiteSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"BookList"}} , @{Name = "TABLE_NAME"; Expression = {"BookList"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"location_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"location_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DimData"}} , @{Name = "TABLE_NAME"; Expression = {"DimData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"salesPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"salesPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Customer_SalesLatest"}} , @{Name = "TABLE_NAME"; Expression = {"Customer_SalesLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"department_visit_customer"}} , @{Name = "TABLE_NAME"; Expression = {"department_visit_customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductRecommendations_Sparkv2"}} , @{Name = "TABLE_NAME"; Expression = {"ProductRecommendations_Sparkv2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

foreach ($dataTableLoad in $dataTableList) {
        Write-Host "Loading data for $($dataTableLoad.TABLE_NAME)"
        $result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "02-load-csv" -Parameters @{
                CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
                TABLE_NAME = $dataTableLoad.TABLE_NAME
                DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
         }
        $result
        Write-Host "Data for $($dataTableLoad.TABLE_NAME) loaded."
}
