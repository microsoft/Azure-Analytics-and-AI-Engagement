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
$synapseWorkspaceName = "manufacturingdemo$init$random"
$sqlPoolName = "ManufacturingDW"
$concatString = "$init$random"
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$cosmos_account_name_mfgdemo = "cosmosdb-mfgdemo-$random$init" 

#uploading powerbi reports
RefreshTokens

Add-Content log.txt "------powerbi reports upload------"
Write-Host "-----------------powerbi reports upload ---------------"
Write-Host "Uploading power BI reports"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "../artifacts/reports" | Select BaseName 

foreach($name in $reports)
{
        $FilePath="../artifacts/reports/$($name.BaseName)"+".pbix"
        #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
        
        #write-host "Uploading PowerBI Report $name";
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName=$($name.BaseName)&nameConflict=CreateOrOverwrite";
		$fullyQualifiedPath=Resolve-Path -path $FilePath
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

        $result = Invoke-RestMethod -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"--$boundary`"" -Headers @{ Authorization="Bearer $powerbitoken" }
		Start-Sleep -s 5 
		
        Add-Content log.txt $result
        $reportId = $result.id;

        $temp = "" | select-object @{Name = "FileName"; Expression = {"$($name.BaseName)"}}, 
		@{Name = "Name"; Expression = {"$($name.BaseName)"}}, 
        @{Name = "PowerBIDataSetId"; Expression = {""}},
        @{Name = "ReportId"; Expression = {""}},
        @{Name = "SourceServer"; Expression = {"manufacturingdemo.sql.azuresynapse.net"}}, 
        @{Name = "SourceDatabase"; Expression = {"ManufacturingDW"}}
		                        
        # get dataset                         
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets";
        $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
		
        Add-Content log.txt $dataSets
        
        $temp.ReportId = $reportId;

        foreach($res in $dataSets.value)
        {
            if($res.name -eq $name.BaseName)
            {
                $temp.PowerBIDataSetId = $res.id;
            }
       }
                
       $reportList.Add($temp)
}
Start-Sleep -s 60

# $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports"
# $pbiResult = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
# Add-Content log.txt $pbiResult  

# foreach($r in $pbiResult.value)
# {
#     $report = $reportList | where {$_.Name -eq $r.name}
#     $report.ReportId = $r.id;
# }

RefreshTokens

#Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- pbi connections update---------"	
$powerBIDataSetConnectionTemplate = Get-Content -Path "../artifacts/templates/powerbi_dataset_connection.json"

#$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "HelloWorld.sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String
$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($synapseWorkspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String

$sourceServers = @("manufacturingdemor16gxwbbra4mtbmu.sql.azuresynapse.net", "manufacturingdemo.sql.azuresynapse.net", "dreamdemosynapse.sql.azuresynapse.net","manufacturingdemocjgnpnq4eqzbflgi.sql.azuresynapse.net", "manufacturingdemodemocwbennanrpo5s.sql.azuresynapse.net", "HelloWorld.sql.azuresynapse.net","manufacturingdemosep5n2tdtctkwpyjc.sql.azuresynapse.net")

foreach($report in $reportList)
{

    #skip some...cosmos or nothing to update.
    #campaign sales operations = COSMOS
    #Azure Cognitive Search = AZURE TABLE
    #anomaly detection with images = AZURE TABLE
    if ($report.Name -eq "sample_test" -or $report.Name -eq "Azure Cognitive Search" -or $report.Name -eq "Campaign Sales Operations" -or $report.Name -eq "anomaly detection with images" -or $report.Name -eq "6_Production Quality- HTAP Synapse Link")
    {
        if($report.Name -eq "anomaly detection with images")
		{
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"StorageAccount`",
									`"newValue`": `"$dataLakeAccountName`"
								}
							]
					}"
			$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
           $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"};
		}
		if($report.Name -eq "Azure Cognitive Search")
		{
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"KnowledgeStoreStorageAccount`",
									`"newValue`": `"$dataLakeAccountName`"
								},
								{
									`"name`": `"SkillsetName`",
									`"newValue`": `"osha-formrecogoutput-skillset`"
								}
							]
					}"
			$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
           $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"};
		}
		 if($report.Name -eq "6_Production Quality- HTAP Synapse Link")
		{
			$body = "
					{
						`"updateDetails`":
						[
							{
								`"name`": `"CosmosAccountName`",
								`"newValue`": `"https://$($cosmos_account_name_mfgdemo).documents.azure.com:443/`"
							},
							{
								`"name`": `"SynapseWarehouseDatabaseName`",
								`"newValue`": `"$($sqlPoolName)`"
							},
							{
								`"name`": `"SynapseWarehouseServerName`",
								`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
							}
						]
					}
					";
			$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
           $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"};
		}
    }
       
	Write-Host "Setting database connection for $($report.Name)"
    foreach($source in $sourceServers)
    {

        #ManufacturingDW
        $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $source).Replace("#SOURCE_DATABASE#", $report.SourceDatabase) |Out-String
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets/$($report.PowerBIDataSetId)/Default.UpdateDatasources";
        try
        {
            $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $powerBIReportDataSetConnectionUpdateRequest -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
            Add-Content log.txt $pbiResult  
        }
        catch
        {
        }
    }
	Start-Sleep -s 5
}
