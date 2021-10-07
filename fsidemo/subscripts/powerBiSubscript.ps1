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
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$synapseWorkspaceName = "synapsefsi$init$random"
$sqlPoolName = "FsiDW"

#uploading powerbi reports
Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI

RefreshTokens

Write-Host "-----------------powerbi reports upload ---------------"
Write-Host "Uploading power BI reports"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "../artifacts/reports" | Select BaseName 

$reportUrl = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports"

$response = Invoke-RestMethod -Uri $reportUrl -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };

$uploadedReportList = New-Object 'System.Collections.Generic.HashSet[string]';

foreach ($item in $response.value) {
    $uploadedReportList.Add($item.name)
}

foreach($name in $reports)
{

    if ($uploadedReportList.Contains($name.BaseName)) {
        continue;
    }

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

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports"
$pbiResult = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;

foreach($r in $pbiResult.value)
{
    $report = $reportList | where {$_.Name -eq $r.name}
    $report.ReportId = $r.id;
}

#Establish powerbi reports dataset connections
Write-Host "--------- pbi connections update---------"	

foreach($report in $reportList)
{
      if($report.name -eq "Fsi Demo Master Images" -or $report.name -eq "Realtime Operational Analytics Static" -or $report.name -eq "Realtime Twitter Analytics"  -or $report.name -eq "Chief Risk Officer Realtime" -or $report.name -eq "Chief Risk Officer After Dashboard Realtime"  -or $report.name -eq "FSI Realtime KPI" -or $report.name -eq "FSI CCO Realtime Before" -or $report.name -eq "Head of Financial Intelligence Realtime"  -or $report.name -eq "Head of Financial Intelligence After Dashboard Realtime" -or $report.name -eq "Global overview tiles" -or $report.name -eq "FSI-Chicklets"  -or $report.name -eq "FSITwitterreport" -or $report.name -eq "ESGDashboardV2_KPIandGraphs" -or $report.name -eq "FarmBeats Analytics" -or $report.name -eq "Master Images for FSI Dashboardpbix_v2")
    {
       continue;     
	}
	elseif($report.name -eq "ESG Metrics for Woodgrove" -or $report.name -eq  "FSI Incident Report" -or $report.name -eq "FSI HTAP" -or $report.name -eq "ESG Report Synapse Import Mode" -or $report.name -eq "Geospatial Fraud Detection Miami" -or $report.name -eq "Finance Report" -or $report.name -eq "globalmarkets" -or $report.name -eq "FSI CCO Dashboard"  -or $report.name -eq "FSI CEO Dashboard" -or $report.name -eq  "Company Insight KPIs" -or $report.name -eq "US Map with header" -or $report.name -eq "MSCI report" -or $report.name -eq "FSI Predictive Analytics")
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

	Write-Host "PBI connections updating for report : $($report.name)"	
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"} -ErrorAction SilentlyContinue;
		
    start-sleep -s 5
}
