function New-PowerBIWS($name)
{
    $body = "{`"name`": `"$name`"}";
    $url = "https://api.powerbi.com/v1.0/myorg/groups";
    $result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $global:powerbitoken" };
    return $result.id
}

function Update-PowerBIDatasetConnection($wsid, $dataSetId, $powerBIDataSetConnectionUpdateRequest)
{
    Write-Information "Setting database connection for $($dataSetId)"

    if ($dataSetId)
    {
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/datasets/$dataSetId/Default.UpdateDatasources";
        $result = Invoke-RestMethod -Uri $url -Method POST -Body $powerBIDataSetConnectionUpdateRequest -ContentType "application/json" -Headers @{ Authorization="Bearer $global:powerbitoken" };
    }
    else
    {
        write-host "No report found called $dataSetId";
    }
}

function Get-PowerBIDatasetId($wsid, $name)
{
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/datasets";
    $result = Invoke-RestMethod  -Uri $url -Method GET -Headers @{ Authorization="Bearer $global:powerbitoken" };

    foreach($res in $result.value)
    {
        if($res.name -eq $name)
        {
            return $res.id;
        }
    }
}

function Get-PowerBIWorkspaceId($name)
{
    $url = "https://api.powerbi.com/v1.0/myorg/groups?`$filter=tolower%28name%29%20eq%20%27$name%27&$top=100";
    $result = Invoke-RestMethod  -Uri $url -Method GET -Headers @{ Authorization="Bearer $global:powerbitoken" };
    return $result.value[0].id;
}

function Upload-PowerBIReport($wsId, $name, $filePath)
{
    write-host "Uploading PowerBI Report $name";

    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName=$name&nameConflict=CreateOrOverwrite";

    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath);
    $fileEnc = [system.text.encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes);
    $boundary = [System.Guid]::NewGuid().ToString(); 
    $LF = "`r`n";

    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data",
        "",
        $fileEnc,
        "--$boundary--$LF" 
    ) -join $LF

    $result = Invoke-RestMethod  -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers @{ Authorization="Bearer $global:powerbitoken" }
    $reportId = $result.id;
    return $reportId;
}

function Create-PowerBILinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceId
    )

    $powerBITemplate = Get-Content -Path "$($TemplatesPath)/powerbi_linked_service.json"
    $powerBI = $powerBITemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#POWERBI_WORKSPACE_ID#", $WorkspaceId)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $powerBI -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 
    return $result
}

function Wait-ForOperation {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$false)]
    [String]
    $OperationId
    )

    if ([string]::IsNullOrWhiteSpace($OperationId)) {
        Write-Information "Cannot wait on an empty operation id."
        return
    }

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/operationResults/$($OperationId)?api-version=2019-06-01-preview"
    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }

    while ($result.status -ne $null) {
        
        if ($result.status -eq "Failed") {
            throw $result.error
        }

        Write-Information "Waiting for operation to complete (status is $($result.status))..."
        Start-Sleep -Seconds 10
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    }

    return $result
}

function Refresh-Token {
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TokenType
    )

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
            Write-Information "Refreshing $($TokenName) token."
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
        
        $templatesPath = "..\templates"

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
    Write-Information "Selecting the $resourceGroupName resource group"
}
else{
$resourceGroupName=$resourceGroups
Write-Information "Selecting the $resourceGroupName resource group"
}

$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")

$asaName="TweetsASA"
$principal=az resource show -g $resourceGroupName -n $asaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
$wsId=Read-Host "Enter your powerBi workspace Id entered during template deployment"
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Contributor
$keyVaultName = "asaexpkeyvault$($uniqueId)"

Write-Information "Starting PowerBI Artifact Provisioning"

#$wsname = "asa-exp-$uniqueId";

#$wsid = Get-PowerBIWorkspaceId $wsname;

#if (!$wsid)
#{
 #   $wsid = New-PowerBIWS $wsname;
#}

Write-Information "Uploading PowerBI Reports"

$reportList = New-Object System.Collections.ArrayList
$temp = "" | select-object @{Name = "FileName"; Expression = {"1. CDP Vision Demo"}}, 
                                @{Name = "Name"; Expression = {"1-CDP Vision Demo"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}}, 
                                @{Name = "SourceServer"; Expression = {"cdpvisionworkspace.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"AzureSynapseDW"}}
$reportList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"2. Billion Rows Demo"}}, 
                                @{Name = "Name"; Expression = {"2-Billion Rows Demo"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}}, 
                                @{Name = "SourceServer"; Expression = {"cdpvisionworkspace.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"AzureSynapseDW"}}
$reportList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"Phase2_CDP_Vision_Demo"}}, 
                                @{Name = "Name"; Expression = {"1-Phase2 CDP Vision Demo"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}},
                                @{Name = "SourceServer"; Expression = {"asaexpworkspacewwi543.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"SQLPool01"}}
$reportList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"images"}}, 
                                @{Name = "Name"; Expression = {"Dashboard-Images"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}}
$reportList.Add($temp)

$powerBIDataSetConnectionTemplate = Get-Content -Path "$templatesPath/powerbi_dataset_connection.json"
$powerBIName = "asaexppowerbi$($uniqueId)"
$workspaceName = "asaexpworkspace$($uniqueId)"

foreach ($powerBIReport in $reportList) {

    Write-Information "Uploading $($powerBIReport.Name) Report"

    $i = Get-Item -Path "$reportsPath/$($powerBIReport.FileName).pbix"
    $reportId = Upload-PowerBIReport $wsId $powerBIReport.Name $i.fullname
    #Giving some time to the PowerBI Servic to process the upload.
    Start-Sleep -s 5
    $powerBIReport.PowerBIDataSetId = Get-PowerBIDatasetId $wsid $powerBIReport.Name
}

Write-Information "Create PowerBI linked service $($keyVaultName)"
$powerBIDataSetConnectionTemplate = Get-Content -Path "$templatesPath/powerbi_dataset_connection.json"

$result = Create-PowerBILinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $powerBIName -WorkspaceId $wsid
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Refresh-Token -TokenType PowerBI

Write-Information "Setting PowerBI Report Data Connections" 

<# WARNING : Make sure Connection Changes are executed after report uploads are completed. 
             Based on testing so far, findings indicate that there has to be an unknown amount 
             of time between the two operations. Having those operations sequentially run in a 
             single loop resulted in inconsistent results. Pushing the two activities far away 
             from each other in separate loops helped. #>

$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "asaexpworkspace$($uniqueId).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", "SQLPool01") |Out-String

foreach ($powerBIReport in $reportList) {
        if($powerBIReport.Name -ne "Dashboard-Images")
        {
                Write-Information "Setting database connection for $($powerBIReport.Name)"
                $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $powerBIReport.SourceServer).Replace("#SOURCE_DATABASE#", $powerBIReport.SourceDatabase) |Out-String
                Update-PowerBIDatasetConnection $wsId $powerBIReport.PowerBIDataSetId $powerBIReportDataSetConnectionUpdateRequest;
        }
}