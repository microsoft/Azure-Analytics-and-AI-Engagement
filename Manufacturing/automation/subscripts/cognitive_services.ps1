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
$concatString = "$init$random"
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$cognitive_services_name = "dreamcognitiveservices$init"
$location = (Get-AzResourceGroup -Name $rgName).Location
$suffix = "$random-$init"

Add-Content log.txt "-----------------Cognitive Services ---------------"
Write-Host "----Cognitive Services ------"
RefreshTokens
#Custom Vision 
pip install -r ../artifacts/copyCV/requirements.txt
$sourceKey=""  #todo: find a way to get this securely

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cognitive_services_name -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

#hard hat project
$sourceProjectId=""
$destinationregion= "https://$($location).api.cognitive.microsoft.com"
$sourceregion= "https://westus2.api.cognitive.microsoft.com"
python ../artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

#welding helmet project
$sourceProjectId=""
python ../artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

#mask compliance project
$sourceProjectId=""
python ../artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

#product classification project
$sourceProjectId=""
python ../artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects"
$projects = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
			
foreach($project in $projects)
{
	$projectId=$project.id
	$projectName=$project.name
	if($projectName -eq "1_MFG__Helmet_PPE_Compliance")
	{
		(Get-Content -path ../artifacts/amlnotebooks/config.py -Raw) | Foreach-Object { $_ `
                -replace '#HARD_HAT_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path ../artifacts/amlnotebooks/config.py
	}
	elseif($projectName -eq "2_MFG__Welding_Helmet_PPE_Compliance")
	{
				(Get-Content -path ../artifacts/amlnotebooks/config.py -Raw) | Foreach-Object { $_ `
                -replace '#HELMET_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path ../artifacts/amlnotebooks/config.py
	}
	elseif($projectName -eq "3_MFG__Mask_PPE_Compliance")
	{
				(Get-Content -path ../artifacts/amlnotebooks/config.py -Raw) | Foreach-Object { $_ `
                -replace '#FACE_MASK_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path ../artifacts/amlnotebooks/config.py
	}
	elseif($projectName -eq "1_Defective_Product_Classification")
	{
				(Get-Content -path ../artifacts/amlnotebooks/config.py -Raw) | Foreach-Object { $_ `
                -replace '#QUALITY_CONTROL_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path ../artifacts/amlnotebooks/config.py
	}
	
	$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($project.id)/tags"
	$tags = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
	$tagList = New-Object System.Collections.ArrayList
	foreach($tag in $tags)
	{
		$tagList.Add($tag.id)
	}
	$body = "{
      `"selectedTags`": []
		}"
	$body=	$body |ConvertFrom-Json
	$body.selectedTags=$tagList	
	$body=	$body |ConvertTo-Json
	$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($projectId)/train"
	$Result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{"Training-key"="$($destinationKey)"}
	
	$url="https://$($location).api.cognitive.microsoft.com/customvision/v3.3/Training/projects/$($projectId)/iterations"
	$iterations=Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
	$iterationId=$iterations[0].id	
}
