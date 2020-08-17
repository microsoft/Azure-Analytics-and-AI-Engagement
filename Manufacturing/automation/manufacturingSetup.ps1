param (
	[Parameter(Mandatory = $false)][string]$azure_login_id,
    [Parameter(Mandatory = $false)][string]$azure_login_password,
    [Parameter(Mandatory = $false)][string]$iot_hub_car,
    [Parameter(Mandatory = $false)][string]$iot_hub_telemetry,
    [Parameter(Mandatory = $false)][string]$iot_hub,
    [Parameter(Mandatory = $false)][string]$iot_hub_sendtohub,
	[Parameter(Mandatory = $false)][string]$synapseWorkspaceName,
	[Parameter(Mandatory = $false)][string]$wsId,
	[Parameter(Mandatory = $false)][string]$sqlPoolName,
	[Parameter(Mandatory = $false)][string]$dataLakeAccountName,
	[Parameter(Mandatory = $false)][string]$sqlUser,
	[Parameter(Mandatory = $false)][string]$sqlPassword,
	[Parameter(Mandatory = $false)][string]$resourceGroup,
	[Parameter(Mandatory = $false)][string]$mfgasaName,
	[Parameter(Mandatory = $false)][string]$carasaName,
	[Parameter(Mandatory = $false)][string]$cosmos_account_name_mfgdemo,
	[Parameter(Mandatory = $false)][string]$cosmos_database_name_mfgdemo_manufacturing,
	[Parameter(Mandatory = $false)][string]$mfgasaCosmosDBName,
	[Parameter(Mandatory = $false)][string]$mfgASATelemetryName,
	[Parameter(Mandatory = $false)][string]$app_name_telemetry_car,
	[Parameter(Mandatory = $false)][string]$app_name_telemetry,
	[Parameter(Mandatory = $false)][string]$app_name_hub,
	[Parameter(Mandatory = $false)][string]$app_name_sendtohub,
	[Parameter(Mandatory = $false)][string]$ai_name_telemetry_car,
	[Parameter(Mandatory = $false)][string]$ai_name_telemetry,
	[Parameter(Mandatory = $false)][string]$ai_name_hub,
	[Parameter(Mandatory = $false)][string]$ai_name_sendtohub,
	[Parameter(Mandatory = $false)][string]$sparkPoolName

	)

# Install Az cli
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")


# login using identity
az login --identity

#install iot hub extension
az extension add --name azure-cli-iot-ext



#Create iot hub devices
az iot hub device-identity create -n $iot_hub_car -d race-car
az iot hub device-identity create -n $iot_hub_telemetry -d telemetry-data
az iot hub device-identity create -n $iot_hub -d data-device
az iot hub device-identity create -n $iot_hub_sendtohub -d send-to-hub

#get connection strings

$iot_device_connection_car = az iot hub device-identity show-connection-string --hub-name $iot_hub_car --device-id race-car | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_car.connectionString

$iot_device_connection_telemetry = az iot hub device-identity show-connection-string --hub-name $iot_hub_telemetry --device-id telemetry-data | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_telemetry.connectionString

$iot_device_connection_sku2 = az iot hub device-identity show-connection-string --hub-name $iot_hub --device-id data-device | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_sku2.connectionString

$iot_device_connection_sendtohub = az iot hub device-identity show-connection-string --hub-name $iot_hub_sendtohub --device-id send-to-hub | Out-String | ConvertFrom-Json
Write-Host $iot_device_connection_sendtohub.connectionString

#get App insights instrumentation keys

$app_insights_instrumentation_key_car = az resource show -g $resourceGroup -n $ai_name_telemetry_car --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_car 

$app_insights_instrumentation_key_telemetry = az resource show -g $resourceGroup -n $ai_name_telemetry --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_telemetry

$app_insights_instrumentation_key_sku2 = az resource show -g $resourceGroup -n $ai_name_hub --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_sku2

$app_insights_instrumentation_key_sendtohub = az resource show -g $resourceGroup -n $ai_name_sendtohub --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey | Out-String | ConvertFrom-Json
Write-Host $app_insights_instrumentation_key_sendtohub


#download the binary zip folders

#Invoke-WebRequest https://publicassetstoragexor.blob.core.windows.net/assets/carTelemetry.zip -OutFile carTelemetry.zip
##extract
expand-archive -path "./artifacts/datagenerator/carTelemetry.zip" -destinationpath "./carTelemetry"
#
#Invoke-WebRequesthttps://publicassetstoragexor.blob.core.windows.net/assets/datagenTelemetry.zip -OutFile datagenTelemetry.zip
##extract
expand-archive -path "./artifacts/datagenerator/datagenTelemetry.zip" -destinationpath "./datagenTelemetry"
#
#Invoke-WebRequest https://publicassetstoragexor.blob.core.windows.net/assets/sku2.zip -OutFile sku2.zip
##extract
expand-archive -path "./artifacts/datagenerator/sku2.zip" -destinationpath "./sku2"
#
#Invoke-WebRequest https://publicassetstoragexor.blob.core.windows.net/assets/sendtohub.zip -OutFile sendtohub.zip
##extract
expand-archive -path "./artifacts/datagenerator/sendtohub.zip" -destinationpath "./sendtohub"
#
#Invoke-WebRequest https://publicassetstoragexor.blob.core.windows.net/assets/artifacts.zip -OutFile artifacts.zip
##extract
#expand-archive -path "./artifacts.zip" -destinationpath "./artifacts"

#Replace connection string in config

(Get-Content -path carTelemetry/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_car.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_car`				
        } | Set-Content -Path carTelemetry/appsettings.json
		
(Get-Content -path datagenTelemetry/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_telemetry.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_telemetry`				
        } | Set-Content -Path datagenTelemetry/appsettings.json
		
(Get-Content -path sku2/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sku2.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_sku2`				
        } | Set-Content -Path sku2/appsettings.json
		
(Get-Content -path sendtohub/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sendtohub.connectionString`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_sendtohub`				
        } | Set-Content -Path sendtohub/appsettings.json
		
#make zip for app service deployment

Compress-Archive -Path "./carTelemetry/*" -DestinationPath "./carTelemetry.zip"
Compress-Archive -Path "./sendtohub/*" -DestinationPath "./sendtohub.zip"
Compress-Archive -Path "./sku2/*" -DestinationPath "./sku2.zip"
Compress-Archive -Path "./datagenTelemetry/*" -DestinationPath "./datagenTelemetry.zip"

# deploy the codes on app services

az webapp stop --name $app_name_telemetry_car --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_telemetry_car --src "./carTelemetry.zip"
az webapp start --name $app_name_telemetry_car --resource-group $resourceGroup

az webapp stop --name $app_name_telemetry --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_telemetry --src "./datagenTelemetry.zip"
az webapp start --name $app_name_telemetry --resource-group $resourceGroup

az webapp stop --name $app_name_hub --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_hub --src "./sku2.zip"
az webapp start --name $app_name_hub --resource-group $resourceGroup

az webapp stop --name $app_name_sendtohub --resource-group $resourceGroup
az webapp deployment source config-zip --resource-group $resourceGroup --name $app_name_sendtohub --src "./sendtohub.zip"
az webapp start --name $app_name_sendtohub --resource-group $resourceGroup

#run the 4 codes on the vm
#cd carTelemetry
#start-process SendToHub.exe
#cd ..
#cd sendtohub
#start-process SendMessageToIoTHub.exe
#cd ..
#cd sku2
#start-process DataGenerator.exe
#cd ..
#cd Telemetry
#start-process DataGenerator.exe
#cd ..

#uploading Cosmos data
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
Connect-AzAccount -identity

$cosmosDbAccountName = $cosmos_account_name_mfgdemo
$databaseName = $cosmos_database_name_mfgdemo_manufacturing
$cosmos=Get-ChildItem "./artifacts/cosmos" | Select BaseName 
foreach($name in $cosmos)
	{
$collection = $name.BaseName
$cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $resourceGroup    
#New-CosmosDbCollection -Context $cosmosDbContext -Id $collection -OfferThroughput 400 -PartitionKey 'PartitionKey' -DefaultTimeToLive 604800
$path="./artifacts/cosmos/"+$name.BaseName+".json"
$document=Get-Content -Raw -Path $path
$document=ConvertFrom-Json $document
foreach($json in $document)
{
 $key=$json.SyntheticPartitionKey
 $id = New-Guid
 $json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id
 $body=ConvertTo-Json $json
 New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
 }
 } 

az login -u $azure_login_id -p $azure_login_password
$subscriptionId=az account show|ConvertFrom-Json
$subscriptionId=$subscriptionId.Id
$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue;

New-Item log.txt
Add-Content log.txt "------asa powerbi connvection-----"
#connecting asa and powerbi
$principal=az resource show -g $resourceGroup -n $mfgasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs" |ConvertFrom-Json
$principalId=$principal.identity.principalId
$uri="https://api.powerbi.com/v1.0/myorg/groups/$wsId/users"
$body=@"
{
  "identifier": "$principalId",
  "principalType": "App",
  "groupUserAccessRight": "Admin"
}
"@
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
Add-Content log.txt $result
$principal=az resource show -g $resourceGroup -n $raceasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs" |ConvertFrom-Json
$principalId=$principal.identity.principalId
$uri="https://api.powerbi.com/v1.0/myorg/groups/$wsId/users"
$body=@"
{
  "identifier": "$principalId",
  "principalType": "App",
  "groupUserAccessRight": "Admin"
}
"@
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
Add-Content log.txt $result


Add-Content log.txt "------sql schema-----"
 #creating sql schema
Install-Module -Force -Name SqlServer
Write-Information "Create tables in $($sqlPoolName)"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"

 $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
 Add-Content log.txt $result
 
 Add-Content log.txt "------linked Services------"
 #Creating linked services
 ##cosmos linked services
 $cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name_mfgdemo -g $resourceGroup |ConvertFrom-Json
 $cosmos_account_key=$cosmos_account_key.primarymasterkey
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"cosmos_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name_mfgdemo_manufacturing)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($cosmos_account_name_mfgdemo)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##Datalake linked services
 $storage_account_key=az storage account keys list -g $resourceGroup -n $dataLakeAccountName |ConvertFrom-Json
 $storage_account_key=$storage_account_key[0].value
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"data_lake_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($dataLakeAccountName)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##blob linked services
 $storage_account_key=az storage account keys list -g $resourceGroup -n $dataLakeAccountName |ConvertFrom-Json
 $storage_account_key=$storage_account_key[0].value
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"blob_storage_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $name=$dataLakeAccountName+"blob"
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $name).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($name)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##powerbi linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"powerbi_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "ManufacturingDemo").Replace("#WORKSPACE_ID#", $wsId)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/ManufacturingDemo?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 ##sql pool linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"sql_pool_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $sqlPoolName).Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($sqlPoolName)?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
  ##sap hana linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"sap_hana_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "SapHana")
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
  ##teradata linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"teradata_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "TeraData")
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/TeraData?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
   ##oracle linked services
 $templatepath="./artifacts/templates/"
 $filepath=$templatepath+"oracle_linked_service.json"
 $itemTemplate = Get-Content -Path $filepath
 $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "oracle")
 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/oracle?api-version=2019-06-01-preview"
 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 Add-Content log.txt $result
 
 #Creating Datasets
 Add-Content log.txt "------datasets------"
 Write-Information "Creating Datasets"
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
		
		
		}
$DatasetsPath="./artifacts/datasets";	
foreach ($dataset in $datasets.Keys) {
        Write-Information "Creating dataset $($dataset)"
		$LinkedServiceName=$datasets[$dataset]
		$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset).json"
		$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $LinkedServiceName)
		$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset)?api-version=2019-06-01-preview"
		$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
		Add-Content log.txt $result
		}
 
#Creating spark notebooks
Add-Content log.txt "------Notebooks------"
Write-Information "Creating Spark notebooks..."
$notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 
$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $resourceGroup
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
		"#SPARK_POOL_NAME#"       = $sparkPoolName
}
foreach($name in $notebooks)
	{
		$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
		foreach ($paramName in $cellParams.Keys) {
			$template = $template.Replace($paramName, $cellParams[$paramName])
		}
		$jsonItem = ConvertFrom-Json $template
	    $path="./artifacts/notebooks/"+$name.BaseName+".ipynb"
		$notebook=Get-Content -Raw -Path $path
		$jsonNotebook = ConvertFrom-Json $notebook
		$jsonItem.properties.cells = $jsonNotebook.cells
		if ($CellParams) {
        foreach ($cellParamName in $cellParams.Keys) {
            foreach ($cell in $jsonItem.properties.cells) {
                for ($i = 0; $i -lt $cell.source.Count; $i++) {
                    $cell.source[$i] = $cell.source[$i].Replace($cellParamName, $CellParams[$cellParamName])
                }
            }
        }
    }
	     $item = ConvertTo-Json $jsonItem -Depth 100
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name.BaseName)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
		 #waiting for operation completion
		 Start-Sleep -Seconds 10
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
		 Add-Content log.txt $result
	}	


#creating Dataflows
Add-Content log.txt "------dataflows-----"
# $params = @{
        # LOAD_TO_SYNAPSE = "AzureSynapseAnalyticsTable8"
        # LOAD_TO_AZURE_SYNAPSE = "AzureSynapseAnalyticsTable9"
        # DATA_FROM_SAP_HANA = "DelimitedText1"
# }
$workloadDataflows = [ordered]@{
        MFG_Ingest_data_from_SAP_HANA_to_Azure_Synapse = "1 MFG Ingest data from SAP HANA to Azure Synapse"
		Ingest_data_from_SAP_HANA_to_Common_Data_Service="2 Ingest data from SAP HANA to Common Data Service"
		MFGDataFlowADLStoSynapse="2 MFGDataFlowADLStoSynapse"
		MFG_IoT_dataflow="7 MFG IoT_dataflow"
		MFGCosmosdbquality="MFGCosmosdbquality"
}
$DataflowPath="./artifacts/dataflows"
foreach ($dataflow in $workloadDataflows.Keys) 
{
		$Name=$workloadDataflows[$dataflow]
        Write-Information "Creating dataflow $($workloadDataflows[$dataflow])"
		 $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
    # if ($params -ne $null) {
        # foreach ($key in $params.Keys) {
            # $item = $item.Replace("#$($key)#", $params[$key])
        # }
    # }
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
        #waiting for operation completion
		 Start-Sleep -Seconds 10
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
		 Add-Content log.txt $result
}

#uploading powerbi reports
Add-Content log.txt "------powerbi reports------"
Write-Information "Uploading power BI reports"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "./artifacts/reports" | Select BaseName 
foreach($name in $reports)
{
        $FilePath="./artifacts/reports/"+$name.BaseName+".pbix"
        #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
        
        #write-host "Uploading PowerBI Report $name";
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName$($name.BaseName)&nameConflict=CreateOrOverwrite";
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
        $result = Invoke-RestMethod -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers @{ Authorization="Bearer $powerbitoken" }
		Start-Sleep -s 5 
		Add-Content log.txt $result
        #$reportId = $result.id;
        
        $temp = "" | select-object @{Name = "Name"; Expression = {$name.BaseName}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}},
                                @{Name = "SourceServer"; Expression = {"cdpvisionworkspace.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"AzureSynapseDW"}}
                                
        # get dataset                         
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/datasets";
        $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
		Add-Content log.txt $dataSets
        foreach($res in $dataSets.value)
        {
        if($set.name -eq $name.BaseName)
        {
            $temp.PowerBIDataSetId= $set.id;
        }
       }
                
        $reportList.Add($temp)
        Start-Sleep -s 5    
        
}



#creating Pipelines
Add-Content log.txt "------pipelines------"
Write-Information "Creating pipelines"
$pipelines=Get-ChildItem "./artifacts/pipelines" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
	$FilePath="./artifacts/pipelines/"+$name.BaseName+".json"
	$temp = "" | select-object @{Name = "FileName"; Expression = {$name.BaseName}} , @{Name = "Name"; Expression = {$name.BaseName.ToUpper()}}, @{Name = "PowerBIReportName"; Expression = {""}}
	$pipelineList.Add($temp)
	 $item = Get-Content -Path $FilePath
	 $item=$item.Replace("#DATA_LAKE_STORAGE_NAME #",$dataLakeAccountName)
	 $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
	 $item=$item.Replace("#DEFAULT_STORAGE#",$defaultStorage)
	 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
     $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	 #waiting for operation completion
		 Start-Sleep -Seconds 10
		 $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
		 $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
		 Add-Content log.txt $result
	 
}



#Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections------"
Write-Information "Uploading power BI reports"	
$powerBIDataSetConnectionTemplate = Get-Content -Path "./artifacts/templates/powerbi_dataset_connection.json"
$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($synapseWorkspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String
foreach($report in $reportList)
{
   Write-Information "Setting database connection for $($report.Name)"
   $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $powerBIReport.SourceServer).Replace("#SOURCE_DATABASE#", $powerBIReport.SourceDatabase) |Out-String
   $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/datasets/$report.PowerBIDataSetId/Default.UpdateDatasources";
    $result = Invoke-RestMethod -Uri $url -Method POST -Body $powerBIReportDataSetConnectionUpdateRequest -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" };
	Add-Content log.txt $result
   
}


#Install stream-analytics extension
az extension add --name stream-analytics
#start ASA
az stream-analytics job start --resource-group $resourceGroup --name $mfgASATelemetryName --output-start-mode JobStartTime
az stream-analytics job start --resource-group $resourceGroup --name $mfgasaName --output-start-mode JobStartTime
az stream-analytics job start --resource-group $resourceGroup --name $carasaName --output-start-mode JobStartTime
az stream-analytics job start --resource-group $resourceGroup --name $mfgasaCosmosDBName --output-start-mode JobStartTime
