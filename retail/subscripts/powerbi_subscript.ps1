function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$deploymentId = $init
$synapseWorkspaceName = "synapseretail$init$random"
$sqlPoolName = "RetailDW"

#uploading powerbi reports
Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI

#uploading powerbi reports
RefreshTokens

Write-Host "------------Powerbi Reports Upload ------------"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "../artifacts/reports" | Select BaseName 
foreach($name in $reports)
{
        $FilePath="../artifacts/reports/$($name.BaseName)"+".pbix"
        #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
        
        write-host "Uploading PowerBI Report : $($name.BaseName)";
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
        @{Name = "SourceServer"; Expression = {""}}, 
        @{Name = "SourceDatabase"; Expression = {""}}
		                        
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
                
      $list = $reportList.Add($temp)
}
Start-Sleep -s 60

##Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- PBI connections update---------"	

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$sasTokenAcc = New-AzureStorageAccountSASToken -Context $dataLakeContext -Permission rwdl

foreach($report in $reportList)
{
    if($report.name -eq "Dashboard-Images"  -or $report.name -eq "ADX Thermostat and Occupancy" -or $report.name -eq "Retail Dynamic Data Masking (Azure Synapse)" -or $report.name -eq "ADX dashboard 8AM" -or $report.name -eq "CEO Dec" -or $report.name -eq "CEO May" -or $report.name -eq "CEO Nov" -or $report.name -eq "CEO Oct" -or $report.name -eq "CEO Sep" -or $report.name -eq "Datbase template PBI" -or $report.name -eq "VP Dashboard" -or $report.name -eq "Global Occupational Safety Report")
    {
        continue;
    }
    elseif($report.name -eq "Acquisition Impact Report")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server_Name`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"DB_Name`",
									`"newValue`": `"$($sqlPoolName)`"
								},
								{
									`"name`": `"Source_LakeDB`",
									`"newValue`": `"$($synapseWorkspaceName)`"
								},
								{
									`"name`": `"LakeDB`",
									`"newValue`": `"WWImportersConstosoRetailLakeDB`"
								}
								]
								}"	
	}
	elseif($report.name -eq "Revenue and Profiability")
	{
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
    elseif($report.name -eq "CCO Report" )
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server1`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database1`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "CDP Vision Report" -or $report.name -eq "US Map with header" -or $report.name -eq "Customer Segmentation" -or $report.name -eq "ESG Report Final" -or $report.name -eq  "globalmarkets" -or $report.name -eq "Retail Group CEO KPI" -or $report.name -eq "Location Analytics" -or $report.name -eq "World Map" -or $report.name -eq "Campaign Analytics" -or $report.name -eq "Retail Predictive Analytics")
    {
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
    elseif($report.name -eq  "Product Recommendation" -or $report.name -eq "Campaign Analytics Deep Dive")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"ServerName`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
	elseif($report.name -eq "Retail Column Level Security (Azure Synapse)" -or $report.name -eq "Retail Row Level Security (Azure Synapse)")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"servername`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
	elseif($report.name -eq "Global Occupational Safety Report")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"KnowledgeStoreStorageAccount`",
									`"newValue`": `"$($dataLakeAccountName)`"
								},
								{
									`"name`": `"StorageAccountSasUri`",
									`"newValue`": `"$($sasTokenAcc)`"
								}
								]
								}"	
	}
	
	 

	Write-Host "PBI connections updating for report : $($report.name)"	
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"} -ErrorAction SilentlyContinue;
		
    start-sleep -s 5
}
