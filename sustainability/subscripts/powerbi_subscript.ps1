function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
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
    Write-Host "Selecting the subscription : $selectedSubName "
	$title    = 'Subscription selection'
	$question = 'Are you sure you want to select this subscription for this lab?'
	$choices  = '&Yes', '&No'
	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
	if($decision -eq 0)
	{
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
	}
	else
	{
	$selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
	Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
	}
}

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$synapseWorkspaceName = "synapsesustain$init$random"
$sqlPoolName = "SustainabilityDW"
$cosmos_database_name_sustain = "sustainbusridershipdb"
$cosmosdb_sustainability_name = "cosmosdb-sustain-$random$init";
if($cosmosdb_sustainability_name.length -gt 43)
{
$cosmosdb_sustainability_name = $cosmosdb_sustainability_name.substring(0,43)
}


#uploading powerbi reports
Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI

#uploading powerbi reports
RefreshTokens

Add-Content log.txt "------powerbi reports upload------"
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

foreach($report in $reportList)
{
    if($report.name -eq "Master Images")
    {
        continue;
    }
    elseif($report.name -eq "Budget dashboard" -or $report.name -eq "Fleet Manager Dashboard" -or $report.name -eq "Mayor Dashboard" -or $report.name -eq  "Power Management" -or $report.name -eq "Realtime Air Quality Report Static" -or $report.name -eq "Transportation Head Dashboard" -or $report.name -eq "Twitter Report Static" -or $report.name -eq "Transport Deep Dive")
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
    elseif($report.name -eq "Sustainability Column Level Security (Azure Synapse)" -or $report.name -eq "Sustainability Row Level Security (Azure Synapse)")
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
    elseif($report.name -eq "Sustainability Dynamic Data Masking (Azure Synapse)")
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"ServerNew`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                                
                            },
                            {
                                `"name`": `"Pool`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
	}
    elseif($report.name -eq "Demand and Bus Frequency")
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"https://$($cosmosdb_sustainability_name).documents.azure.com:443/`"
                                
                            },
                            {
                                `"name`": `"Database`",
                                `"newValue`": `"$($cosmos_database_name_sustain)`"
                            }
                            ]
                            }"	
	}
    elseif($report.name -eq "NYC_AQI" -or $report.name -eq "Billion Rows Demo" )
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Connection_String`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                                
                            },
                            {
                                `"name`": `"Database_Name`",
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

#################
