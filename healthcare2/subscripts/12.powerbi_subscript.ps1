function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

function ReplaceTokensInFile($ht, $filePath) {
    $template = Get-Content -Raw -Path $filePath
    
    foreach ($paramName in $ht.Keys) {
        $template = $template.Replace($paramName, $ht[$paramName])
    }

    return $template;
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
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$concatString = "$init$random"
$synapseWorkspaceName = "synhealthcare2$concatString"
$sqlPoolName = "HealthcareDW"
$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

## powerbi
Add-Content log.txt "------powerbi reports upload------"
Write-Host "------------Powerbi Reports Upload------------"
#Connect-PowerBIServiceAccount
RefreshTokens
$reportList = New-Object System.Collections.ArrayList
$reports = Get-ChildItem "../artifacts/reports" | Select BaseName 
foreach ($name in $reports) {
    $FilePath = "../artifacts/reports/$($name.BaseName)" + ".pbix"
    #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
    
    write-host "Uploading PowerBI Report : $($name.BaseName)";
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName=$($name.BaseName)&nameConflict=CreateOrOverwrite";
    $fullyQualifiedPath = Resolve-Path -path $FilePath
    $fileBytes = [System.IO.File]::ReadAllBytes($fullyQualifiedPath);
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

    $result = Invoke-RestMethod -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"--$boundary`"" -Headers @{ Authorization = "Bearer $powerbitoken" }
    Start-Sleep -s 5 
    
    Add-Content log.txt $result
    $reportId = $result.id;

    $temp = "" | select-object @{Name = "FileName"; Expression = { "$($name.BaseName)" } }, 
    @{Name = "Name"; Expression = { "$($name.BaseName)" } }, 
    @{Name = "PowerBIDataSetId"; Expression = { "" } },
    @{Name = "ReportId"; Expression = { "" } },
    @{Name = "SourceServer"; Expression = { "" } }, 
    @{Name = "SourceDatabase"; Expression = { "" } }
                            
    # get dataset                         
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets";
    $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
    
    Add-Content log.txt $dataSets
    
    $temp.ReportId = $reportId;

    foreach ($res in $dataSets.value) {
        if ($res.name -eq $name.BaseName) {
            $temp.PowerBIDataSetId = $res.id;
        }
    }
            
    $list = $reportList.Add($temp)
}
Start-Sleep -s 30

##Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "---------PBI connections update---------"	

RefreshTokens
foreach ($report in $reportList) {
    if ($report.name -eq "ER Wait Time KPIs" -or $report.name -eq "ER Wait Time KPIs 1" -or $report.name -eq "Healthcare - Before and After dashboard GIF" -or $report.name -eq "Healthcare chicklets" -or $report.name -eq "Healthcare Dashbaord Images-Final" -or $report.name -eq "Reports with Dashboard GIF" -or $report.name -eq "Healthcare - Call Center Power BI-After (with recc Script)") {
        continue;
    }
    elseif ($report.name -eq "Healthcare - Bed Occupancy ") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database_Name`",
                                `"newValue`": `"$($sqlPoolName)`"
                            },
                            {
                                `"name`": `"Serverless`",
                                `"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database_Serverless`",
                                `"newValue`": `"SQLServerlessPool`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "3 HealthCare Dynamic Data Masking (Azure Synapse)" -or $report.name -eq "4 HealthCare Column Level Security (Azure Synapse)" -or $report.name -eq "5 HealthCare Row Level Security (Azure Synapse)" -or $report.name -eq "Healthcare - HTAP-Lab-Data" -or $report.name -eq "Healthcare Miami Hospital Overview") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Healthcare FHIR") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server_Name`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"DB_Name`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Healthcare - Call Center Power BI Before" -or $report.name -eq "Healthcare - Call Center Power BI-After") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server_Name`",
                                `"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"DB_Name`",
                                `"newValue`": `"SQLServerlessPool`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Healthcare - Patients Profile report") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database_ChatBot`",
                                `"newValue`": `"$($sqlPoolName)`"
                            },
                            {
                                `"name`": `"SQL_Server`",
                                `"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database`",
                                `"newValue`": `"SQLServerlessPool`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Healthcare - US Map" -or $report.name -eq "Healthcare Global overview tiles") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database`",
                                `"newValue`": `"SQLServerlessPool`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Healthcare Consolidated Report") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server_Name`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database_Name`",
                                `"newValue`": `"$($sqlPoolName)`"
                            },
                            {
                                `"name`": `"BlobStorage`",
                                `"newValue`": `"https://$($dataLakeAccountName).blob.core.windows.net/consolidated-report`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Healthcare Global Occupational Safety Report") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Blob Location`",
                                `"newValue`": `"https://$($dataLakeAccountName).dfs.core.windows.net/healthcare-reports/`"
                            },
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"Database`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Healthcare Patient Overview") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Blob Storage`",
                                `"newValue`": `"https://$($dataLakeAccountName).blob.core.windows.net/healthcare-reports`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Static Realtime Healthcare analytics") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server_Gen2`",
                                `"newValue`": `"https://$($dataLakeAccountName).dfs.core.windows.net/healthcare-reports/`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "Payor Dashboard report") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Blob Server`",
                                `"newValue`": `"https://$($dataLakeAccountName).blob.core.windows.net/healthcare-reports`"
                            }
                            ]
                            }"	
    }
    elseif ($report.name -eq "HealthCare Predctive Analytics_V1") {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Healthcare_server`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                            },
                            {
                                `"name`": `"HealthcareDW`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
    }

    Write-Host "PBI connections updating for report : $($report.name)"	
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $powerbitoken" } -ErrorAction SilentlyContinue;
    
    start-sleep -s 5
}
