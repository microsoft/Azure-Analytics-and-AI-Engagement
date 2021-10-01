$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","I accept the license agreement."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","I do not accept and wish to stop execution."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "Agreement"
$message = "By typing [Y], I hereby confirm that I have read the license ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/license.md ) and disclaimers ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/README.md ) and hereby accept the terms of the license and agree that the terms and conditions set forth therein govern my use of the code made available hereunder. (Type [Y] for Yes or [N] for No and press enter)"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
if($result -eq 1)
{
write-host "Thank you. Please ensure you delete the resources created with template to avoid further cost implications."
}

else
{

function Check-HttpRedirect($uri)
{
    $httpReq = [system.net.HttpWebRequest]::Create($uri)
    $httpReq.Accept = "text/html, application/xhtml+xml, */*"
    $httpReq.method = "GET"   
    $httpReq.AllowAutoRedirect = $false;
    
    #use them all...
    #[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls;

    $global:httpCode = -1;
    
    $response = "";            

    try
    {
        $res = $httpReq.GetResponse();

        $statusCode = $res.StatusCode.ToString();
        $global:httpCode = [int]$res.StatusCode;
        $cookieC = $res.Cookies;
        $resHeaders = $res.Headers;  
        $global:rescontentLength = $res.ContentLength;
        $global:location = $null;
                                
        try
        {
            $global:location = $res.Headers["Location"].ToString();
            return $global:location;
        }
        catch
        {
        }

        return $null;

    }
    catch
    {
        $res2 = $_.Exception.InnerException.Response;
        $global:httpCode = $_.Exception.InnerException.HResult;
        $global:httperror = $_.exception.message;

        try
        {
            $global:location = $res2.Headers["Location"].ToString();
            return $global:location;
        }
        catch
        {
        }
    } 

    return $null;
}

function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api --output json) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net --output json) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com --output json) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com --output json) | ConvertFrom-Json).accessToken
}

function ReplaceTokensInFile($ht, $filePath)
{
    $template = Get-Content -Raw -Path $filePath
	
    foreach ($paramName in $ht.Keys) 
    {
		$template = $template.Replace($paramName, $ht[$paramName])
	}

    return $template;
}

function GetAccessTokens($context)
{
    $global:synapseToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://dev.azuresynapse.net").AccessToken
    $global:synapseSQLToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://sql.azuresynapse.net").AccessToken
    $global:managementToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.azure.com").AccessToken
    $global:powerbitoken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://analysis.windows.net/powerbi/api").AccessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

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
$id_scope = read-host "Enter the ID scope from IoT Central Device";
$registration_id = read-host "Enter the Device ID from IoT Central Device";
$symmetric_key = read-host "Enter the Primary key from IoT Central Device";

$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$PbiDatasetUrl = (Get-AzResourceGroup -Name $rgName).Tags["PbiDatasetUrl"]
$deploymentId = $init

$eventhub_evh_ns_high_speed_datagen_healthcare = "evh-highspeed-$suffix"
$eventhub_evh_namespace_healthcare = "evh-namespace-$suffix"
$cpuShell = "cpuShell$init"
$synapseWorkspaceName = "synapsehealthcare$init$random"
$sqlPoolName = "HealthCareDW"
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$sqlUser = "labsqladmin"

$healthcareasa = "asa-healthcare-$suffix"
$highspeedasa = "asa-high-speed-datagen-healthcare-$suffix"
$concatString = "$random$init"

$cosmos_account_name_heathcare = "cosmosdb-healthcare-$concatString"
if($cosmos_account_name_heathcare.length -gt 43 )
{
$cosmos_account_name_heathcare = $cosmos_account_name_heathcare.substring(0,43)
}
$cosmos_database_name_healthcare = "healthcare"


$cosmos_mongo_account_name_heathcare = "cosmos-healthcare-mongodb-$concatString" 
if($cosmos_mongo_account_name_heathcare.length -gt 43 )
{
$cosmos_mongo_account_name_heathcare = $cosmos_mongo_account_name_heathcare.substring(0,43)
}
$cosmos_mongo_database_name_heathcare = "healthdata"

$functionappformrecognizer = "func-app-formrecognizer-$suffix"
$functionappIomt="func-app-iomt-processor-$suffix"
$functionappMongoData = "func-app-mongo-data-$suffix"
$app_name_iomt_simulator = "app-iomt-simulator-$suffix"
$app_name_demohealthcare = "app-demohealthcare-$suffix"
$app_name_healthcaresearch = "app-healthcaresearch-$suffix"

$ai_name_healthcaresearch = "app-appi-healthcaresearch-$suffix"

$functionaspMongoData = "func-asp-mongo-data-$suffix"
$functionstMongoData = "stmongodata"+($concatString.substring(0,13))

$sparkPoolName = "HealthCare"
$healthcare_poc_app_service_name = $app_name_demohealthcare
$wideworldimporters_app_service_name = "wideworldimporters-$suffix"

$location = (Get-AzResourceGroup -Name $rgName).Location
$storageAccountName = $dataLakeAccountName

$forms_cogs_name = "cog-formrecognition-$suffix";
$forms_cogs_v2_name = "cog-formrecognitionv2-$suffix";

$searchName = "srch-healthcaredemo-$suffix";
$searchNameCovid = "srch-covidsearch-$suffix";

$keyVaultName = "kv-$init";

$cognitive_services_name = "cog-healthcare-$init"

$text_translation_service_name = "healthcareTA-$suffix"
$text_translation_service_healthcare_analytics_name = "ta-healthcare-analytics-$suffix"

$amlworkspacename = "amlws-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show --output json) | ConvertFrom-Json).UserPrincipalName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_cogs_name
#$text_translation_service_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $text_translation_service_name
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName  --output json | ConvertFrom-Json).primarykey;


$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

Write-Host "Setting Key Vault Access Policy"
#Import-Module Az.KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

#$sqlPassword = $(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword").SecretValueText
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name_heathcare -g $rgName --output json | ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

$cosmos_account_key_mongo=az cosmosdb keys list -n $cosmos_mongo_account_name_heathcare -g $rgName  --output json |ConvertFrom-Json
$cosmos_account_key_mongo=$cosmos_account_key_mongo.primarymasterkey

###################################################################
New-Item log.txt

Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI

RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "form-datasets" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime
#download azcopy command
if ([System.Environment]::OSVersion.Platform -eq "Unix")
{
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
        tar -xf "azCopy.tar.gz"
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName

        if ($azCopyCommand.count -gt 1)
        {
            $azCopyCommand = $azCopyCommand[0];
        }

        cd $azCopyCommand
        chmod +x azcopy
        cd ..
        $azCopyCommand += "\azcopy"
}
else
{
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
        Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName

        if ($azCopyCommand.count -gt 1)
        {
            $azCopyCommand = $azCopyCommand[0];
        }

        $azCopyCommand += "\azcopy"
}
 
#Uploading to storage containers
Add-Content log.txt "-----------Uploading to storage containers-----------------"
Write-Host "----Uploading to storage containers-----"
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$containers=Get-ChildItem "./artifacts/storageassets" | Select BaseName

foreach($container in $containers)
{
    $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
    $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
    & $azCopyCommand copy "./artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
}

RefreshTokens
 
$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/webappassets/$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/webappassets" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/customcsv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "predictiveanalytics" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/predictiveanalytics$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/predictiveanalytics" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "marketingdata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/marketingdata$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/marketingdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "saphana-finance-data" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/saphana-finance-data$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/saphana-finance-data" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "healthcare-assets" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/healthcare-assets$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/healthcare-vm-assets" $destinationUri --recursive


#Form Recognizer
Add-Content log.txt "-----------------Form Recognizer---------------"
Write-Host "-----Form Recognizer-----"
#Replace values in create_model.py
(Get-Content -path artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
				-replace '#LOCATION#', $location`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "form-datasets"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_keys.Key1`
			} | Set-Content -Path artifacts/formrecognizer/create_model.py
			
$modelUrl = python "./artifacts/formrecognizer/create_model.py"
$modelId= $modelUrl.split("/")
$modelId = $modelId[7]


Add-Content log.txt "-----------------Cognitive Services ---------------"
Write-Host "----Cognitive Services ------"
RefreshTokens
#Custom Vision 
pip install -r ./artifacts/copyCV/requirements.txt
$sourceKey="0ea6df654a9f47a4b9a3da65988f461e"  #todo: find a way to get this securely

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cognitive_services_name -g $rgName --output json |ConvertFrom-json
$destinationKey=$key.key1

#CT scan project
$sourceProjectId="7b58bba3-f88e-43c8-bdf9-8cd62e6c4a37"
$destinationregion= "https://$($location).api.cognitive.microsoft.com"
#$destinationregion= "https://$($cognitive_services_name).cognitiveservices.azure.com/"
$sourceregion= "https://westus2.api.cognitive.microsoft.com"
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

#Hospital mask project
$sourceProjectId="7f83145b-8f94-4198-b9eb-3bab1d813fc5"
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

#mask compliance project
$sourceProjectId="68971cc7-bcd6-415f-b0c5-2dfa25c82c36"
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion


$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects"
$projects = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$storage_account_connection_string = "DefaultEndpointsProtocol=https;AccountName=" + $dataLakeAccountName + ";AccountKey="+ $storage_account_key + ";EndpointSuffix=core.windows.net"

(Get-Content -path artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT_CONNECTION_STRING#', $storage_account_connection_string`
				-replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
				-replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key`
				-replace '#LOCATION#', $location`
				-replace '#FORM_RECOGNIZER_NAME#', $forms_cogs_name`
				-replace '#FORM_RECOGNIZER_MODEL_ID#', $modelId`
                -replace '#COGNITIVE_SERVICES_NAME#', $cognitive_services_name`
			} | Set-Content -Path artifacts/amlnotebooks/GlobalVariables.py
			
foreach($project in $projects)
{
	$projectId=$project.id
	$projectName=$project.name
	if($projectName -eq "CT-Scan-Classification")
	{
		(Get-Content -path artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#PROJECT_CTSCAN_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path artifacts/amlnotebooks/GlobalVariables.py
	}
	elseif($projectName -eq "Hospital_Safety_Mask_Detection")
	{
				(Get-Content -path artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#PROJECT_FACE_MASK_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path artifacts/amlnotebooks/GlobalVariables.py
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


#######################################################
	
#make zip for app service deployment
#Compress-Archive -Path "./wideworldimporters/*" -DestinationPath "./wideworldimporters.zip"

<#
#deploy iomt webjob
$user = az webapp deployment list-publishing-profiles -n $app_name_iomt_simulator -g $rgName `
    --query "[?publishMethod=='MSDeploy'].userName" -o tsv

$pass = az webapp deployment list-publishing-profiles -n $app_name_iomt_simulator -g $rgName `
    --query "[?publishMethod=='MSDeploy'].userPWD" -o tsv
	
$creds = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
$basicAuthValue = "Basic $encodedCreds"
$ZipHeaders = @{
    Authorization = $basicAuthValue
    "Content-Disposition" = "attachment; filename=app.py"
}

# upload the job using the Kudu WebJobs API
Invoke-WebRequest -Uri https://$app_name_iomt_simulator.scm.azurewebsites.net/api/triggeredwebjobs/iomt_simulator -Headers $ZipHeaders `
    -InFile "iomt_simulator.zip" -ContentType "application/zip" -Method Put
#start the job
	$Headers = @{
    Authorization = $basicAuthValue
}
$resp = Invoke-WebRequest -Uri https://$app_name_iomt_simulator.scm.azurewebsites.net/api/triggeredwebjobs/iomt_simulator/run -Headers $Headers `
    -Method Post -ContentType "multipart/form-data"
	 #>

RefreshTokens
Add-Content log.txt "------asa powerbi connection-----"
Write-Host "----asa powerbi connection-----"
#connecting asa and powerbi

$principal=az resource show -g $rgName -n $healthcareasa --resource-type "Microsoft.StreamAnalytics/streamingjobs"  --output json |ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

#start ASA
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $healthcareasa -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $highspeedasa -OutputStartMode 'JobStartTime'

Add-Content log.txt "------sql schema-----"
Write-Host "----sql schema------"
RefreshTokens
#creating sql schema
Write-Host "Create tables in $($sqlPoolName)"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

#$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
(Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                -replace '#SQL_PASSWORD#', $sqlPassword`		
        } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [BillingStaff] FOR LOGIN [BillingStaff] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [ChiefOperatingManager] FOR LOGIN [ChiefOperatingManager] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [CareManagerLosAngeles] FOR LOGIN [CareManagerLosAngeles] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [CareManagerMiami] FOR LOGIN [CareManagerMiami] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [CareManager] FOR LOGIN [CareManager] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery  = "CREATE DATABASE HealthCareSqlOnDemand"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database master -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result	
 
(Get-Content -path "$($SQLScriptsPath)/sqlOnDemandSchema.sql" -Raw) | Foreach-Object { $_ `
                -replace '#COSMOS_ACCOUNT_MONGO#', $cosmos_mongo_account_name_heathcare`
				-replace '#COSMOS_KEY_MONGO#', $cosmos_account_key_mongo`
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`            
        } | Set-Content -Path "$($SQLScriptsPath)/sqlOnDemandSchema.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqlOnDemandSchema.sql"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database HealthCareSqlOnDemand -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result	
 
#uploading Sql Scripts
Add-Content log.txt "-----------uploading Sql Scripts-----------------"
Write-Host "----uploading Sql Scripts------"
RefreshTokens
$scripts=Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
$TemplatesPath="./artifacts/templates";	

foreach ($name in $scripts) 
{
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sqlOnDemandSchema" )
    {
        continue;
    }

    $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
    $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
    $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
    $jsonItem = ConvertFrom-Json $item 
    $ScriptFileName="./artifacts/sqlscripts/"+$name.BaseName+".sql"
    
    $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
    $query = $query.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
     $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $query = $query.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_heathcare)
    $query = $query.Replace("#COSMOS_KEY#", $cosmos_account_key)
    $query = $query.Replace("#COSMOS_ACCOUNT_MONGO#", $cosmos_mongo_account_name_heathcare)
    $query = $query.Replace("#COSMOS_KEY_MONGO#", $cosmos_account_key_mongo)
    $query = $query.Replace("#LOCATION#", $location)
	
    if ($Parameters -ne $null) 
    {
        foreach ($key in $Parameters.Keys) 
        {
            $query = $query.Replace("#$($key)#", $Parameters[$key])
        }
    }

    $query = ConvertFrom-Json (ConvertTo-Json $query)
    $jsonItem.properties.content.query = $query
    $item = ConvertTo-Json $jsonItem -Depth 100
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
}
 
Add-Content log.txt "------linked Services------"
Write-Host "----linked Services------"
#Creating linked services
RefreshTokens

$templatepath="./artifacts/templates/"

##cosmos linked services
$filepath=$templatepath+"HealthCareCosmosDb.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_heathcare).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name_healthcare)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/HealthCareCosmosDb?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##Datalake linked services
$filepath=$templatepath+"HealthCareDataLakeStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/HealthCareDataLakeStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##IOT Datalake linked services
$filepath=$templatepath+"IOT Data.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/IOT Data?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
   
 ##Staging Datalake linked services
$filepath=$templatepath+"Staging.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Staging?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

 ##synapsehealthcare Datalake linked services
$filepath=$templatepath+"synapsehealthcaredev-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synapsehealthcaredev-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##blob linked services
$filepath=$templatepath+"tweetstoblob.json"
$itemTemplate = Get-Content -Path $filepath
$name=$dataLakeAccountName+"blob"
$blobLinkedService=$name
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/tweetstoblob?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##sql pool linked services
$filepath=$templatepath+"HealthCareSynapse.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/HealthCareSynapse?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

 ##  synapse sql pool linked services
$filepath=$templatepath+"synapsehealthcaredev-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synapsehealthcaredev-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##sap hana linked services
$filepath=$templatepath+"SapHana.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

## Dynamics linked services
$filepath=$templatepath+"DynamicsHealthCare.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/DynamicsHealthCare?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
 ##powerbi linked services
$filepath=$templatepath+"powerbi_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "HealthCareDemo").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/powerbi_linked_service?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

 ##Teradata linked services
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "Teradata").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

 ##Oracle linked services
$filepath=$templatepath+"Oracle.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "Oracle").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Oracle?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# AutoResolveIntegrationRuntime
    $FilePathRT="./artifacts/templates/AutoResolveIntegrationRuntime.json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
 Add-Content log.txt $result

# SelfHostedIntegrationRuntime
$integrationRuntimePath="./artifacts/IntergationRuntimes";	
$integrationRuntimes=Get-ChildItem "./artifacts/IntergationRuntimes" | Select BaseName
foreach ($integrationRuntime in $integrationRuntimes) 
{
    $FilePathRT="$($integrationRuntimePath)/$($integrationRuntime.BaseName).json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/$($integrationRuntime.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
    Add-Content log.txt $result
}

#Creating Datasets
Add-Content log.txt "------datasets------"
Write-Host "Creating Datasets"
RefreshTokens
$DatasetsPath="./artifacts/datasets";	
$datasets=Get-ChildItem "./artifacts/datasets" | Select BaseName
foreach ($dataset in $datasets) 
{
    Write-Host "Creating dataset $($dataset.BaseName)"
	$LinkedServiceName=$datasets[$dataset.BaseName]
	$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset.BaseName).json"
	$item = $itemTemplate #.Replace("#LINKED_SERVICE_NAME#", $LinkedServiceName)
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	Add-Content log.txt $result
}
 
#Creating spark notebooks
Add-Content log.txt "--------------Spark Notebooks---------------"
Write-Host "Creating Spark notebooks..."
RefreshTokens
$notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $rgName
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
		"#SPARK_POOL_NAME#" = $sparkPoolName
		"#STORAGE_ACCOUNT_KEY#" = $storage_account_key
		"#COSMOS_LINKED_SERVICE#" = $cosmos_account_name_heathcare
		"#STORAGE_ACCOUNT_NAME#" = $dataLakeAccountName
		"#SEARCH_KEY#" = $searchKey
		"#SEARCH_NAME#" = $searchName
		"#MODEL_ID#"=$modelId
		"#LOCATION#"=$location
		"#APIM_KEY#"=$forms_cogs_keys.Key1
}

foreach($name in $notebooks)
{
	$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
	foreach ($paramName in $cellParams.Keys) 
    {
		$template = $template.Replace($paramName, $cellParams[$paramName])
	}
	$template=$template.Replace("#NOTEBOOK_NAME#",$name.BaseName)
    $jsonItem = ConvertFrom-Json $template
	$path="./artifacts/notebooks/"+$name.BaseName+".ipynb"
	$notebook=Get-Content -Raw -Path $path
	$jsonNotebook = ConvertFrom-Json $notebook
	$jsonItem.properties.cells = $jsonNotebook.cells
	
    if ($CellParams) 
    {
        foreach ($cellParamName in $cellParams.Keys) 
        {
            foreach ($cell in $jsonItem.properties.cells) 
            {
                for ($i = 0; $i -lt $cell.source.Count; $i++) 
                {
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
	#$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}	

#creating Dataflows
Add-Content log.txt "------dataflows-----"
RefreshTokens
# $params = @{
        # LOAD_TO_SYNAPSE = "AzureSynapseAnalyticsTable8"
        # LOAD_TO_AZURE_SYNAPSE = "AzureSynapseAnalyticsTable9"
        # DATA_FROM_SAP_HANA = "DelimitedText1"
# }
$workloadDataflows = [ordered]@{
        HealthCare_Ingest_data_from_SAPHANA_to_Azure_Synapse = "HealthCare_Ingest_data_from_SAPHANA_to_Azure_Synapse"
		HealthCare_IOMT_Dataflow="HealthCare_IOMT_Dataflow"
		IngestData_Dynamics365_To_Synapse="IngestData_Dynamics365_To_Synapse"
}

$DataflowPath="./artifacts/dataflows"

foreach ($dataflow in $workloadDataflows.Keys) 
{
		$Name=$workloadDataflows[$dataflow]
        Write-Host "Creating dataflow $($workloadDataflows[$dataflow])"
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

#creating Pipelines
Add-Content log.txt "------pipelines------"
Write-Host "-------Creating pipelines-----------"
RefreshTokens
$pipelines=Get-ChildItem "./artifacts/pipelines" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
    $FilePath="./artifacts/pipelines/"+$name.BaseName+".json"
    
    $temp = "" | select-object @{Name = "FileName"; Expression = {$name.BaseName}} , @{Name = "Name"; Expression = {$name.BaseName.ToUpper()}}, @{Name = "PowerBIReportName"; Expression = {""}}
    $pipelineList.Add($temp)
    $item = Get-Content -Path $FilePath
    $item=$item.Replace("#DATA_LAKE_STORAGE_NAME#",$dataLakeAccountName)
    #$item=$item.Replace("#BLOB_LINKED_SERVICE#",$blobLinkedService)
    $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
    #$item=$item.Replace("#DEFAULT_STORAGE#",$defaultStorage)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
    Start-Sleep -Seconds 10
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    Add-Content log.txt $result 
}

#uploading powerbi reports
RefreshTokens

Add-Content log.txt "------powerbi reports upload------"
Write-Host "-----------------powerbi reports upload ---------------"
Write-Host "Uploading power BI reports"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "./artifacts/reports" | Select BaseName 

foreach($name in $reports)
{
        $FilePath="./artifacts/reports/$($name.BaseName)"+".pbix"
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

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports"
$pbiResult = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
Add-Content log.txt $pbiResult  

foreach($r in $pbiResult.value)
{
    $report = $reportList | where {$_.Name -eq $r.name}
    $report.ReportId = $r.id;
}

#$cogSvcForms = Get-AzCongnitiveServicesAccount -resourcegroupname $rgName -Name $form_cogs_name;

Add-Content log.txt "------uploading sql data------"
Write-Host  "-----------------Uploading sql data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RoleNew"}} , @{Name = "TABLE_NAME"; Expression = {"RoleNew"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PatientInformation"}} , @{Name = "TABLE_NAME"; Expression = {"PatientInformation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics_New"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiPatient"}} , @{Name = "TABLE_NAME"; Expression = {"pbiPatient"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiDepartment"}} , @{Name = "TABLE_NAME"; Expression = {"pbiDepartment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiManagementEmployee"}} , @{Name = "TABLE_NAME"; Expression = {"pbiManagementEmployee"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaignreport_Top5hospitalsbysatisfactionscore"}} , @{Name = "TABLE_NAME"; Expression = {"Campaignreport_Top5hospitalsbysatisfactionscore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GlobalOverviewReport_Bed Occupancy"}} , @{Name = "TABLE_NAME"; Expression = {"GlobalOverviewReport_Bed Occupancy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GlobalOverviewReport_Margin Rate"}} , @{Name = "TABLE_NAME"; Expression = {"GlobalOverviewReport_Margin Rate"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GlobalOverviewReport_Patient Experience"}} , @{Name = "TABLE_NAME"; Expression = {"GlobalOverviewReport_Patient Experience"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiHospitalMetaData"}} , @{Name = "TABLE_NAME"; Expression = {"pbiHospitalMetaData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiHospitalInfo"}} , @{Name = "TABLE_NAME"; Expression = {"pbiHospitalInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiWaitTimeForecast"}} , @{Name = "TABLE_NAME"; Expression = {"PbiWaitTimeForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBedOccupancyForecasted"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBedOccupancyForecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiReadmissionPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiReadmissionPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Miamihospitaloverview_Bed Occupancy"}} , @{Name = "TABLE_NAME"; Expression = {"Miamihospitaloverview_Bed Occupancy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"USHeaderMapReport"}} , @{Name = "TABLE_NAME"; Expression = {"USHeaderMapReport"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerSalesHana"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerSalesHana"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HospitalEmpPIIData"}} , @{Name = "TABLE_NAME"; Expression = {"HospitalEmpPIIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynPatient"}} , @{Name = "TABLE_NAME"; Expression = {"synpatient"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HealthCare-FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"HealthCare-FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Healthcare-Iomt-Data"}} , @{Name = "TABLE_NAME"; Expression = {"Healthcare-Iomt-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HealthCare-iomt-parameterized"}} , @{Name = "TABLE_NAME"; Expression = {"HealthCare-iomt-parameterized"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"healthcare-pcr-json"}} , @{Name = "TABLE_NAME"; Expression = {"healthcare-pcr-json"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"healthcare-tablevalued"}} , @{Name = "TABLE_NAME"; Expression = {"healthcare-tablevalued"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Healthcare-Twitter-Data"}} , @{Name = "TABLE_NAME"; Expression = {"Healthcare-Twitter-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Iot-Iomt-Data"}} , @{Name = "TABLE_NAME"; Expression = {"Iot-Iomt-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PatientInformation"}} , @{Name = "TABLE_NAME"; Expression = {"PatientInformation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynCondition"}} , @{Name = "TABLE_NAME"; Expression = {"SynCondition"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynObservation"}} , @{Name = "TABLE_NAME"; Expression = {"SynObservation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynapseLinkLabData"}} , @{Name = "TABLE_NAME"; Expression = {"SynapseLinkLabData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp) 

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynthiaPatient"}} , @{Name = "TABLE_NAME"; Expression = {"SynthiaPatient"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynthiaEncounter"}} , @{Name = "TABLE_NAME"; Expression = {"SynthiaEncounter"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiPatientSurvey"}} , @{Name = "TABLE_NAME"; Expression = {"pbiPatientSurvey"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Observations"}} , @{Name = "TABLE_NAME"; Expression = {"Observations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynEncounter"}} , @{Name = "TABLE_NAME"; Expression = {"SynEncounter"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynPatientsFinal"}} , @{Name = "TABLE_NAME"; Expression = {"SynPatientsFinal"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)


$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
foreach ($dataTableLoad in $dataTableList) {
    Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
    $sqlQuery = Get-Content -Raw -Path "./artifacts/templates/load_csv.sql"
    $sqlquery = $sqlquery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $Parameters =@{
            CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
     }
    foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
    Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Write-output "Data for $($dataTableLoad.TABLE_NAME) loaded."
}

#Search service 
Write-Host "-----------------Search service ---------------"
Add-Content log.txt "-----------------Search service ---------------"
RefreshTokens
# Create Search Service
#$sku = "Standard"
#New-AzSearchService -Name $searchName -ResourceGroupName $rgName -Sku $sku -Location $location

# Create search query key
Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
$queryKey = "QueryKey"
New-AzSearchQueryKey -Name $queryKey -ServiceName $searchName -ResourceGroupName $rgName

# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $searchName
$primaryAdminKey = $adminKeyPair.Primary

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cognitive_services_name -g $rgName --output json |ConvertFrom-json
$destinationKey=$key.key1

# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $storageAccountName -ResourceGroupName $rgName)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($storageAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net"

#resource id of cognitive_services_name
$resource=az resource show -g $rgName -n $cognitive_services_name --resource-type "Microsoft.CognitiveServices/accounts" --output json |ConvertFrom-Json
$resourceId=$resource.id

# Create Index
Get-ChildItem "artifacts/search" -Filter hospitalincidentsearch-index.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexes?api-version=2020-06-30"
            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

# Create Datasource endpoint
Get-ChildItem "artifacts/search" -Filter search_datasource.json |
        ForEach-Object {
            $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("#STORAGE_CONNECTION#", $storageConnectionString)
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

             $url = "https://$searchName.search.windows.net/datasources?api-version=2020-06-30"
             Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in search_skillset.json
(Get-Content -path artifacts/search/search_skillset.json -Raw) | Foreach-Object { $_ `
				-replace '#RESOURCE_ID#', $resourceId`
				-replace '#STORAGEACCOUNTNAME#', $storageAccountName`
				-replace '#STORAGEKEY#', $storageKey`
				-replace '#COGNITIVE_API_KEY#', $destinationKey`
			} | Set-Content -Path artifacts/search/search_skillset.json

# Creat Skillset
Get-ChildItem "artifacts/search" -Filter search_skillset.json |
        ForEach-Object {
            $skillsetDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/skillsets?api-version=2020-06-30"
            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $skillsetDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

# Create Indexers
Get-ChildItem "artifacts/search" -Filter search_indexer.json |
        ForEach-Object {
            $indexerDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexers?api-version=2020-06-30"
            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
        }
		
	
Write-Host  "-----------------AML Workspace ---------------"
Add-Content log.txt "-----------------AML Workspace ---------------"
RefreshTokens
#AML Workspace
#create aml workspace
az extension add -n azure-cli-ml

az ml workspace create -w $amlworkspacename -g $rgName

#attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName -e aml

#create and delete a compute instance to get the code folder created in default store
az ml computetarget create computeinstance -n $cpuShell -s "STANDARD_DS2_V2" -v
#az ml computetarget delete -n $cpuShell -v

#get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

#get fileshare and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Context $storageAcct.Context 
$shareName = $share[0].Name

#create Users folder ( it wont be there unless we launch the workspace in UI)
New-AzStorageDirectory -Context $storageAcct.Context -ShareName $shareName -Path "Users"

#copy notebooks to ml workspace
$notebooks=Get-ChildItem "./artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "GlobalVariables")
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path="/Users/"+$notebook.BaseName+".py"
	}
	else
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}

$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
$shareName = $share.Name
$notebooks=Get-ChildItem "./artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "GlobalVariables")
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path="/Users/"+$notebook.BaseName+".py"
	}
	else
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}
#create aks compute
#az ml computetarget create aks --name  "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName
az ml computetarget delete -n $cpuShell -v

RefreshTokens

#Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- pbi connections update---------"	
$powerBIDataSetConnectionTemplate = Get-Content -Path "./artifacts/templates/powerbi_dataset_connection.json"

$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($synapseWorkspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String

#$sourceServers = @("manufacturingdemor16gxwbbra4mtbmu.sql.azuresynapse.net", "manufacturingdemo.sql.azuresynapse.net", "dreamdemosynapse.sql.azuresynapse.net","manufacturingdemocjgnpnq4eqzbflgi.sql.azuresynapse.net", "manufacturingdemodemocwbennanrpo5s.sql.azuresynapse.net", "HelloWorld.sql.azuresynapse.net","manufacturingdemosep5n2tdtctkwpyjc.sql.azuresynapse.net")

foreach($report in $reportList)
{

    #skip some...cosmos or nothing to update.
    #campaign sales operations = COSMOS
    #Azure Cognitive Search = AZURE TABLE
    #anomaly detection with images = AZURE TABLE
    if($report.name -eq "1 SQL On-demand decompostion tree")
	{
		$body = "{
			`"updateDetails`": [
								{
									`"name`": `"SynapseHealthcaredb`",
									`"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"HealthCareSqlOnDemand`"
								}
								]
								}"
	}
	
	if($report.name -eq "3 HealthCare Dynamic Data Masking (Azure Synapse)" -or $report.name -eq "4 HealthCare Column Level Security (Azure Synapse)" -or $report.name -eq "5 HealthCare Row Level Security (Azure Synapse)" -or $report.name -eq "CT Scan Anomaly Detection Report")
	{	
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"SynapseHealthcareserver`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"	
    }
    	
	if($report.name -eq "Consolidated Report")
	{
	
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"HealthcareSynapsedb`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"	
	}
	
	if($report.name -eq "Global overview tiles")
	{
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"HalathcareSynapse`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"
	}
	if($report.name -eq "HealthCare Predctive Analytics_V1" -or $report.name -eq "Miami hospital overview")
	{
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"HealthcareSynapse`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"
	}
	if($report.name -eq "healthcare term index")
	{								
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"SkillsetName`",
									`"newValue`": `"hospitalincidentsearch-skillset`"
								},
								{
									`"name`": `"ContentField`",
									`"newValue`": `"final_narrative`"
								},
								{
									`"name`": `"EnrichmentGranularityLevel`",
									`"newValue`": `"Sentences`"
								},
								{
									`"name`": `"KnowledgeStoreStorageAccount`",
									`"newValue`": `"$datalakeaccountname`"
								},
								{
									`"name`": `"ColumnHeaderSampleSize`",
									`"newValue`": `"50`"
								}
								]
								}"
	}
	if($report.name -eq "HTAP-Lab-Data")
	{	
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"ParmDatabase1`",
									`"newValue`": `"$sqlPoolName`"
								},
								{
									`"name`": `"ParmDatabaseonDemand`",
									`"newValue`": `"HealthCareSqlOnDemand`"
								},
								{
									`"name`": `"ParmHealthCare`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"ParmHealthCareOnDemand`",
									`"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
								},
								]
								}"
	}

    if($report.name -eq "Bed Occupancy Report" -or $report.name -eq "Operational_Analytics_Healthcare_v1" )
	{
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"Healthcareserver`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"
	}
		if($report.name -eq "US Map with header")
	{
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"SynapseDB`",
									`"newValue`": `"$sqlPoolName`"
								},
								{
									`"name`": `"HealthcareSynapse`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"	
    }								
			
    if($report.name -eq "Healthcare Dashbaord Images-Final" -or $report.name -eq "healthcare-operational-analytics")
    {
       continue;     
	}

    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"} -ErrorAction SilentlyContinue;
		
    start-sleep -s 5
}

Write-Host  "-----------------Uploading Cosmos Data Started--------------"
#uploading Cosmos data
Add-Content log.txt "-----------------uploading Cosmos data--------------"
RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmos_account_name_heathcare
$databaseName = $cosmos_database_name_healthcare
$cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $rgName
    $path="./artifacts/cosmos/"+$name.BaseName+".json"
    $document=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $document
	#$newRU=4000
	#az cosmosdb sql container throughput update -a $cosmosDbAccountName -g $rgName -d $databaseName -n $collection --throughput $newRU
	
    foreach($json in $document)
    {
        $key=$json.SyntheticPartitionKey
        $id = New-Guid
       if(![bool]($json.PSobject.Properties.name -eq "id"))
       {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
       if(![bool]($json.PSobject.Properties.name -eq "SyntheticPartitionKey"))
       {$json | Add-Member -MemberType NoteProperty -Name 'SyntheticPartitionKey' -Value $id}
        $body=ConvertTo-Json $json
        New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }
	
	#$newRU=400
	#az cosmosdb sql container throughput update -a $cosmosDbAccountName -g $rgName -d $databaseName -n $collection --throughput $newRU
} 

Write-Host  "-----------------Uploading Cosmos Data Complete--------------"

Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------deploy poc web app ---------------"
RefreshTokens
$app = Get-AzADApplication -DisplayName "hcare Demo $deploymentid"
$clientsecpwd ="Smoothie@Smoothie@2020"
$secret = ConvertTo-SecureString -String $clientsecpwd -AsPlainText -Force

if (!$app)
{
    $app = New-AzADApplication -DisplayName "hcare Demo $deploymentId" -IdentifierUris "http://fabmedical-sp-$deploymentId" -Password $secret;
}

$appId = $app.ApplicationId;
$objectId = $app.ObjectId;

$sp = Get-AzADServicePrincipal -ApplicationId $appId;

if (!$sp)
{
    $sp = New-AzADServicePrincipal -ApplicationId $appId -DisplayName "http://fabmedical-sp-$deploymentId" -Scope "/subscriptions/$subscriptionId" -Role "Admin";
}

#https://docs.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal
#Allow service principals to user PowerBI APIS must be enabled - https://app.powerbi.com/admin-portal/tenantSettings?language=en-U
#add PowerBI App to workspace as an admin to group
$url = "https://api.powerbi.com/v1.0/myorg/groups";
$result = Invoke-WebRequest -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
$homeCluster = $result.Headers["home-cluster-uri"]
#$homeCluser = "https://wabi-west-us-redirect.analysis.windows.net";

$url = "$homeCluster/metadata/tenantsettings"
$post = "{`"featureSwitches`":[{`"switchId`":306,`"switchName`":`"ServicePrincipalAccess`",`"isEnabled`":true,`"isGranular`":true,`"allowedSecurityGroups`":[],`"deniedSecurityGroups`":[]}],`"properties`":[{`"tenantSettingName`":`"ServicePrincipalAccess`",`"properties`":{`"HideServicePrincipalsNotification`":`"false`"}}]}"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $powerbiToken")
$headers.Add("X-PowerBI-User-Admin", "true")
#$result = Invoke-RestMethod -Uri $url -Method PUT -body $post -ContentType "application/json" -Headers $headers -ea SilentlyContinue;

#add PowerBI App to workspace as an admin to group
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/users";
$post = "{
    `"identifier`":`"$($sp.Id)`",
    `"groupUserAccessRight`":`"Admin`",
    `"principalType`":`"App`"
    }";

$result = Invoke-RestMethod -Uri $url -Method POST -body $post -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;

#get the power bi app...
$powerBIApp = Get-AzADServicePrincipal -DisplayNameBeginsWith "Power BI Service"
$powerBiAppId = $powerBIApp.Id;

#setup powerBI app...
$url = "https://graph.microsoft.com/beta/OAuth2PermissionGrants";
$post = "{
    `"clientId`":`"$appId`",
    `"consentType`":`"AllPrincipals`",
    `"resourceId`":`"$powerBiAppId`",
    `"scope`":`"Dataset.ReadWrite.All Dashboard.Read.All Report.Read.All Group.Read Group.Read.All Content.Create Metadata.View_Any Dataset.Read.All Data.Alter_Any`",
    `"expiryTime`":`"2021-03-29T14:35:32.4943409+03:00`",
    `"startTime`":`"2020-03-29T14:35:32.4933413+03:00`"
    }";

$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $graphtoken" } -ea SilentlyContinue;

#setup powerBI app...
$url = "https://graph.microsoft.com/beta/OAuth2PermissionGrants";
$post = "{
    `"clientId`":`"$appId`",
    `"consentType`":`"AllPrincipals`",
    `"resourceId`":`"$powerBiAppId`",
    `"scope`":`"User.Read Directory.AccessAsUser.All`",
    `"expiryTime`":`"2021-03-29T14:35:32.4943409+03:00`",
    `"startTime`":`"2020-03-29T14:35:32.4933413+03:00`"
    }";

$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $graphtoken" } -ea SilentlyContinue;

$zips = @("iomt_simulator","demohealthcare_web_app")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

(Get-Content -path demohealthcare_web_app/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path demohealthcare_web_app/appsettings.json
(Get-Content -path demohealthcare_web_app/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`
				-replace '#SERVER_NAME#', $healthcare_poc_app_service_name`			
        } | Set-Content -Path demohealthcare_web_app/wwwroot/config.js	

        #update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable
$ht.add("#STORAGE_ACCOUNT#", $dataLakeAccountName)
$ht.add("#WORKSPACE_ID#", $wsId)
$ht.add("#APP_ID#", $appId)
$ht.add("#APP_SECRET#", $sqlPassword)
$ht.add("#TENANT_ID#", $tenantId)
$ht.add("#SEARCH_QUERY_KEY#", $searchKey)
$ht.add("#SEARCH_SERVICE#", $searchName)
$ht.add("#HEALTHCARE_TERM_INDEX#", $($reportList | where {$_.Name -eq "healthcare term index"}).ReportId)
$ht.add("#CONSOLIDATED_REPORT#", $($reportList | where {$_.Name -eq "Consolidated Report"}).ReportId)
$ht.add("#MIAMI_HOSPITAL_OVERVIEW#", $($reportList | where {$_.Name -eq "Miami hospital overview"}).ReportId)
$ht.add("#GLOBAL_OVERVIEW_TILES#", $($reportList | where {$_.Name -eq "Global overview tiles"}).ReportId)
$ht.add("#HTAP_LAB_DATA#", $($reportList | where {$_.Name -eq "HTAP-Lab-Data"}).ReportId)
$ht.add("#CT_SCAN_ANOMALY_DETECTION_REPORT#", $($reportList | where {$_.Name -eq "CT Scan Anomaly Detection Report"}).ReportId)
$ht.add("#US_MAP_WITH_HEADER#", $($reportList | where {$_.Name -eq "US Map with header"}).ReportId)
$ht.add("#HEALTHCARE_PREDCTIVE_ANALYTICS_V1#", $($reportList | where {$_.Name -eq "HealthCare Predctive Analytics_V1"}).ReportId)

$filePath = "./demohealthcare_web_app/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./demohealthcare_web_app/*" -DestinationPath "./demohealthcare_web_app.zip"

az webapp stop --name $healthcare_poc_app_service_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $healthcare_poc_app_service_name --src "./demohealthcare_web_app.zip"
}
catch
{
}

az webapp start --name $healthcare_poc_app_service_name --resource-group $rgName

Write-Host  "-----------------Deploying iomt data gen web app--------------"
Add-Content log.txt "-----------------Web apps zip deploy--------------"
RefreshTokens

#$app_insights_instrumentation_key_demohealthcare = $(Get-AzApplicationInsights -ResourceGroupName $rgName -Name $ai_name_demohealthcare).InstrumentationKey

#Replace connection string in config
(Get-Content -path iomt_simulator/configMain.json -Raw) | Foreach-Object { $_ `
                -replace '#ID_SCOPE#', $id_scope`
                -replace '#DEVICE_KEY#', $symmetric_key`
				-replace '#DEVICE_ID#', $registration_id`		     
} | Set-Content -Path iomt_simulator/configMain.json

(Get-Content -path iomt_simulator/config.json -Raw) | Foreach-Object { $_ `
				-replace '#POWERBI_STREAMING_DATASET_URL#', $PbiDatasetUrl`				
} | Set-Content -Path iomt_simulator/config.json

# deploy the codes on app services  
Write-Information "Deploying web app"
cd iomt_simulator
az webapp up --resource-group $rgName --name $app_name_iomt_simulator
cd ..
Start-Sleep -s 10
az webapp start  --name $app_name_iomt_simulator --resource-group $rgName

foreach($zip in $zips)
{
	if($zip -eq "demohealthcare_web_app")
	{
    remove-item -path "./$($zip).zip" -recurse -force
	}
    remove-item -path "./$($zip)" -recurse -force
}

#function apps
Write-Host "----function apps zip deploy------"

az webapp stop --name $functionappMongoData --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionappMongoData --src "./artifacts/binaries/mongo_data.zip"	
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$Storage_CS = "DefaultEndpointsProtocol=https;AccountName=" + $dataLakeAccountName + ";AccountKey="+ $storage_account_key + ";EndpointSuffix=core.windows.net"
Update-AzFunctionAppSetting -Name $functionappMongoData -ResourceGroupName $rgName -AppSetting @{"STORAGE_CONNECTION_STRING" = "$($Storage_CS)"}
az webapp start --name $functionappMongoData --resource-group $rgName

az webapp stop --name $functionappIomt --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionappIomt --src "./artifacts/binaries/iomt_function_app.zip"	
az webapp start --name $functionappIomt --resource-group $rgName

az webapp restart --name $functionappMongoData --resource-group $rgName
az webapp restart --name $functionappIomt --resource-group $rgName  
<#
Start-Sleep -s 100
$FunctionApp = Get-AzWebApp -ResourceGroupName $rgName -Name $functionappMongoData
$FunctionKey = (Invoke-AzResourceAction -ResourceId "$($FunctionApp.Id)/functions/JsonProcessor" -Action listkeys -Force).default
$FunctionURL = "https://" + $FunctionApp.DefaultHostName + "/api/JsonProcessor?code=" + $FunctionKey
try{
Invoke-RestMethod $FunctionURL -Method GET -Headers @{}
Start-Sleep -s 30 
#delete the mongo data uplaod function
az functionapp delete --name $functionappMongoData --resource-group $rgName
Remove-AzAppServicePlan -ResourceGroupName $rgName -Name $functionaspMongoData -f
Remove-AzStorageAccount -ResourceGroupName $rgName  -AccountName $functionstMongoData -f  
}
catch
{
Write-Host "Please click this URL : " $FunctionURL
}#>

$FunctionURL = "https://" + $app_name_iomt_simulator+ ".azurewebsites.net/"
try{
Invoke-RestMethod $FunctionURL -Method GET -Headers @{}
}
catch
{
Write-Host "Please click this URL : " $FunctionURL
}

Add-Content log.txt "-----------------Execution Complete---------------"
Write-Host  "-----------------Execution Complete----------------"

}
