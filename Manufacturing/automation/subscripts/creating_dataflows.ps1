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
$synapseWorkspaceName = "manufacturingdemo$init$random"

RefreshTokens

#creating Dataflows
Add-Content log.txt "------dataflows-----"

$workloadDataflows = [ordered]@{
        MFG_Ingest_data_from_SAP_HANA_to_Azure_Synapse = "1 MFG Ingest data from SAP HANA to Azure Synapse"
		Ingest_data_from_SAP_HANA_to_Common_Data_Service="2 Ingest data from SAP HANA to Common Data Service"
		MFGDataFlowADLStoSynapse="2 MFGDataFlowADLStoSynapse"
		MFG_IoT_dataflow="7 MFG IoT_dataflow"
		MFGCosmosdbquality="MFGCosmosdbquality"
}

$DataflowPath="../artifacts/dataflows"

foreach ($dataflow in $workloadDataflows.Keys) 
{
		$Name=$workloadDataflows[$dataflow]
        Write-Host "Creating dataflow $($workloadDataflows[$dataflow])"
		 $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
	Start-Sleep -Seconds 10

	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}
