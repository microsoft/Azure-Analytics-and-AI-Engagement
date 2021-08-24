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
$sqlPoolName = "ManufacturingDW"
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$cosmos_account_name_mfgdemo = "cosmosdb-mfgdemo-$random$init" 
$synapseWorkspaceName = "manufacturingdemo$init$random"

RefreshTokens
 
#Creating Datasets
Add-Content log.txt "------datasets------"
Write-Host "Creating Datasets"
$datasets = @{
    CosmosIoTToADLS = $dataLakeAccountName
	AzureSynapseAnalyticsTable1=$sqlPoolName
	MfgSAPHanaDataset=$sqlPoolName
	historical_drill=$dataLakeAccountName
	MFGAzureSynapseDrill=$sqlPoolName
	MachineInstanceSynapse=$sqlPoolName
	MFGIoTHistoricalSynapse=$sqlPoolName
	MfgIoTSynapseSink=$sqlPoolName
	MfgLocationSynapse=$sqlPoolName
	MfgOperationDataset=$sqlPoolName
	mfgcosmosdbqualityds=$cosmos_account_name_mfgdemo
	tblcosmosdbqualityds=$sqlPoolName
	SapHanaSalesData="SapHana"
	SAPSourceDataset="SapHana"
	MarketingDB_Processed=$dataLakeAccountName
	MarketingDB_Stage=$dataLakeAccountName
	MfgCampaignSynapseAnalyticsOutput=$sqlPoolName
	Teradata_MarketingDB="TeraData"
	TeradataMarketingDB="TeraData"
	MfgSalesdatasetsink=$sqlPoolName
	Oracle_SalesDB="oracle"
	OracleSalesDB="oracle"
	CosmosDbSqlApiCollection1=$cosmos_account_name_mfgdemo
	DS_AzureSynapse_Telemetry=$sqlPoolName
	IotData=$dataLakeAccountName
	ArchiveTwitterParquet=$dataLakeAccountName
	DeleteTweeterFiles=$dataLakeAccountName
	DS_MFG_AzureSynapse_TwitterAnalytics=$sqlPoolName
	TweetsParquet=$dataLakeAccountName
	MFGazuresyanapseDW=$sqlPoolName
	MFGParquettoSynapseSource=$dataLakeAccountName
	AzureSynapseAnalyticsTable6=$sqlPoolName
	AzureSynapseAnalyticsTable7=$sqlPoolName
	AzureSynapseAnalyticsTable8=$sqlPoolName
	AzureSynapseAnalyticsTable9=$sqlPoolName
	AzureSynapseAnalyticsTable10=$sqlPoolName
	CustomCampaignproducts=$dataLakeAccountName
	Custom_CampaignData=$sqlPoolName
	Custom_CampaignData_bubble=$sqlPoolName
	Custom_Campaignproducts=$sqlPoolName
	Custom_Product=$sqlPoolName
	CustomCampaignData=$dataLakeAccountName
	CustomCampaignData_Bubble=$dataLakeAccountName
	CustomProduct=$dataLakeAccountName
	Sales=$dataLakeAccountName
	SalesData=$sqlPoolName
}

$DatasetsPath="../artifacts/datasets";	

foreach ($dataset in $datasets.Keys) 
{
    Write-Host "Creating dataset $($dataset)"
	$LinkedServiceName=$datasets[$dataset]
	$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset).json"
	$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $LinkedServiceName)
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	Add-Content log.txt $result
}
