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
function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

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

az login

#for powershell...
Connect-AzAccount -DeviceCode
$starttime=get-date
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

$response=az ad signed-in-user show | ConvertFrom-Json
$date=get-date
$demoType="Retail 2.0"
$body= '{"demoType":"#demoType#","userPrincipalName":"#userPrincipalName#","displayName":"#displayName#","companyName":"#companyName#","mail":"#mail#","date":"#date#"}'
$body = $body.Replace("#userPrincipalName#", $response.userPrincipalName)
$body = $body.Replace("#displayName#", $response.displayName)
$body = $body.Replace("#companyName#", $response.companyName)
$body = $body.Replace("#mail#", $response.mail)
$body = $body.Replace("#date#", $date)
$body = $body.Replace("#demoType#", $demoType)

$uri ="https://registerddibuser.azurewebsites.net/api/registeruser?code=pTrmFDqp25iVSxrJ/ykJ5l0xeTOg5nxio9MjZedaXwiEH8oh3NeqMg=="
$result = Invoke-RestMethod  -Uri $uri -Method POST -Body $body -Headers @{} -ContentType "application/json"

[string]$suffix =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})
$rgName = "analyticsSolution-$suffix"
# $preferred_list = "australiaeast","centralus","southcentralus","eastus2","northeurope","southeastasia","uksouth","westeurope","westus","westus2"
# $locations = Get-AzLocation | Where-Object {
#     $_.Providers -contains "Microsoft.Synapse" -and
#     $_.Providers -contains "Microsoft.Sql" -and
#     $_.Providers -contains "Microsoft.Storage" -and
#     $_.Providers -contains "Microsoft.Compute" -and
#     $_.Location -in $preferred_list
# }
# $max_index = $locations.Count - 1
# $rand = (0..$max_index) | Get-Random
$Region = read-host "Enter the region for deployment"    
$cpuShell = "cpuShell$suffix"
$synapseWorkspaceName = "synapse$suffix"
$sqlPoolName = "LabDW"
$sparkPoolName="LabPool"
$dataLakeAccountName = "storage$suffix"
$dataLakeFsName="storagefs$suffix"
$amlworkspacename = "amlws-$suffix"
$databricks_name="databricks$suffix"
$databricks_rgname="databricks-rg$suffix"
$sqlserver="mssql$suffix"
$sqlDatabaseName="LabDb"
$sqlUser = "labsqladmin";
$accounts_purview_analytics_name = "purviewanalytics$suffix"
$purviewCollectionName1 = "ADLS"
$purviewCollectionName2 = "AzureSynapseAnalytics"
$purviewCollectionName3 = "AzureSQLDatabase"
$purviewCollectionName4 = "PowerBI"
$namespaces_adx_thermostat_occupancy_name = "adx-thermostat-occupancy-$suffix"
$sites_adx_thermostat_realtime_name = "app-realtime-kpi-analytics-$suffix"
$serverfarm_adx_thermostat_realtime_name = "asp-realtime-kpi-analytics-$suffix"
$app_midpdemo_name = "app-midp-$suffix"
$asp_midpdemo_name = "asp-midp-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$usercred = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
$complexPassword = 0
$SqlPassword=""
while ($complexPassword -ne 1)
{
    $SqlPassword = Read-Host "Enter a password to use for the $sqlUser login.
    `The password must meet complexity requirements:
    ` - Minimum 8 characters. 
    ` - At least one upper case English letter [A-Z]
    ` - At least one lower case English letter [a-z]
    ` - At least one digit [0-9]
    ` - At least one special character (!,@,#,%,^,&,$)
    ` "

    if(($SqlPassword -cmatch '[a-z]') -and ($SqlPassword -cmatch '[A-Z]') -and ($SqlPassword -match '\d') -and ($SqlPassword.length -ge 8) -and ($SqlPassword -match '!|@|#|%|^|&|$'))
    {
        $complexPassword = 1
	  Write-Output "Password $SqlPassword accepted. Make sure you remember this!"
    }
    else
    {
        Write-Output "$SqlPassword does not meet the compexity requirements."
    }
}
$wsId =  Read-Host "Enter your PowerBI workspace Id"
RefreshTokens

Add-Content log.txt "------powerbi reports upload------"
Write-Host "------------Powerbi Reports Upload ------------"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "./artifacts/reports" | Select BaseName 
foreach($name in $reports)
{
        $FilePath="./artifacts/reports/$($name.BaseName)"+".pbix"
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
Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
  -TemplateFile "mainTemplate.json" `
  -Mode Complete `
  -synapse_workspace_name $synapseWorkspaceName `
  -mssql_database_name $sqlDatabaseName `
  -mssql_server_name $sqlserver `
  -sql_administrator_login_id $sqlUser `
  -sql_administrator_login_password $sqlPassword `
  -location $Region `
  -databricks_workspace_name $databricks_name `
  -databricks_managed_resource_group_name $databricks_rgname `
  -mssql_administrator_login $sqlUser `
  -storage_account_name $dataLakeAccountName `
  -default_data_lake_storage_file_system_name $sqlUser `
  -sql_compute_name $sqlPoolName `
  -spark_compute_name $sparkPoolName `
  -accounts_purview_analytics_name $accounts_purview_analytics_name `
  -app_midpdemo_name $app_midpdemo_name `
  -asp_midpdemo_name $asp_midpdemo_name `
  -sites_adx_thermostat_realtime_name $sites_adx_thermostat_realtime_name `
  -serverfarm_adx_thermostat_realtime_name $serverfarm_adx_thermostat_realtime_name `
  -namespaces_adx_thermostat_occupancy_name $namespaces_adx_thermostat_occupancy_name `
  -Force

$kustoPoolName = "analyticskp$suffix"
$kustoDatabaseName = "AnalyticsDB"

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value

$thermostat_telemetry_Realtime_URL =  ""
$occupancy_data_Realtime_URL =  ""

RefreshTokens
Write-Host "-----Enable Transparent Data Encryption----------"
$result = New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile "./artifacts/templates/transparentDataEncryption.json" -workspace_name_synapse $synapseWorkspaceName -sql_compute_name $sqlPoolName -ErrorAction SilentlyContinue

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
}else{
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
Write-Host "----Uploading to Storage Containers-----"

$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

RefreshTokens

$destinationSasKey = New-AzStorageContainerSASToken -Container "assets" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/assets$($destinationSasKey)"
& $azCopyCommand copy "https://midp.blob.core.windows.net/assets" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "campaign-data" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/campaign-data$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/campaign-data" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "customer-data" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customer-data$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/customer-data" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "customer-sales" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customer-sales$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/customer-sales" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "data" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/data$($destinationSasKey)"
& $azCopyCommand copy "https://midp.blob.core.windows.net/data" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "data-source" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/data-source$($destinationSasKey)"
& $azCopyCommand copy "https://midp.blob.core.windows.net/data-source" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "delta-files" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/delta-files$($destinationSasKey)"
& $azCopyCommand copy "https://midp.blob.core.windows.net/delta-files" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "deltatable" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/deltatable$($destinationSasKey)"
& $azCopyCommand copy "https://midp.blob.core.windows.net/deltatable" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "analyticsdemo" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/analyticsdemo$($destinationSasKey)"
& $azCopyCommand copy "https://midp.blob.core.windows.net/analyticsdemo" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "presentation" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/presentation$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/presentation" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "sales-data" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/sales-data$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/sales-data" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "salestransactiondata" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/salestransactiondata$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/salestransactiondata" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "staging" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/staging$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/staging" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "syndatamigrate" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/syndatamigrate$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/syndatamigrate" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "synlogging" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/synlogging$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/synlogging" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "twitter-data-historical" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/twitter-data-historical$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/twitter-data-historical" $destinationUri --recursive

# $destinationSasKey = New-AzStorageContainerSASToken -Container "twitter-gold-staging" -Context $dataLakeContext -Permission rwdl
# $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/twitter-gold-staging$($destinationSasKey)"
# & $azCopyCommand copy "https://midp.blob.core.windows.net/twitter-gold-staging" $destinationUri --recursive
$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $usercred -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

#databricks
Add-Content log.txt "------databricks------"
Write-Host "--------- Databricks---------"
$dbswsId = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_name" `
        --query id -o tsv)

##Get databricks workspaceId
# $workspaceId = $(az resource show `
#         --resource-type Microsoft.Databricks/workspaces `
#         -g "$rgName" `
#         -n "$databricks_name" `
#         --query properties.workspaceId -o tsv)

# Get a token for the global Databricks application.
# The resource ID is fixed and never changes.
$token_response = $(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json) | ConvertFrom-Json
$token = $token_response.accessToken

# Get a token for the Azure management API
$token_response = $(az account get-access-token --resource https://management.core.windows.net/ --output json) | ConvertFrom-Json
$azToken = $token_response.accessToken

#fetch workspace URL
$workspaceUrl = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_name" `
        --query properties.workspaceUrl -o tsv)

$uri = "https://$($workspaceUrl)/api/2.0/token/create"
$baseUrl = 'https://' + $workspaceUrl
# You can also generate a PAT token. Note the quota limit of 600 tokens.
$body = '{"lifetime_seconds": 100000, "comment": "Ranatest" }';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")
$headers.Add("X-Databricks-Azure-SP-Management-Token", "$azToken")
$headers.Add("X-Databricks-Azure-Workspace-Resource-Id", "$dbswsId")
$pat_token = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Header $headers 
$pat_token = $pat_token.token_value
#Create a dir in dbfs & workspace to store the scipt files and init file
$requestHeaders = @{
    Authorization  = "Bearer" + " " + $pat_token
    "Content-Type" = "application/json"
}

# # to create forder in the databricks workspace
# $body = '{"path": "dbfs:/FileStore/Campaign_Analytics" }';
# #get job list
# $endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
# Invoke-RestMethod $endPoint `
#     -Method Post `
#     -Headers $requestHeaders `
#     -Body $body

# to create a new cluster
$body =    '{
    "autoscale": {
        "min_workers": 2,
        "max_workers": 8
    },
    "cluster_name": "GTM Cluster",
    "spark_version": "11.2.x-cpu-ml-scala2.12",
    "azure_attributes": {
        "first_on_demand": 1,
        "availability": "ON_DEMAND_AZURE",
        "spot_bid_max_price": -1
    },
    "node_type_id": "Standard_DS3_v2",
    "driver_node_type_id": "Standard_DS3_v2",
    "autotermination_minutes": 120,
    "enable_elastic_disk": true,
    "runtime_engine": "STANDARD"
}'

$endPoint = $baseURL + "/api/2.0/clusters/create"
$clusterId_1 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$clusterId_1 = $clusterId_1.cluster_id

$body =    '{
    "autoscale": {
        "min_workers": 2,
        "max_workers": 8
    },
    "cluster_name": "GTM Cluster - All Purpose",
    "spark_version": "11.2.x-scala2.12",
    "azure_attributes": {
        "first_on_demand": 1,
        "availability": "ON_DEMAND_AZURE",
        "spot_bid_max_price": -1
    },
    "node_type_id": "Standard_D4s_v5",
    "driver_node_type_id": "Standard_D4s_v5",
    "autotermination_minutes": 120,
    "enable_elastic_disk": true,
    "runtime_engine": "PHOTON"
}'

$endPoint = $baseURL + "/api/2.0/clusters/create"
$clusterId_2 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$clusterId_2 = $clusterId_2.cluster_id
$tenant=get-aztenant
$tenantid=$tenant.id
$app = az ad app create --display-name "midp" | ConvertFrom-Json
$clientId = $app.appId
$appCredential = az ad app credential reset --id $clientId | ConvertFrom-Json
$clientsecpwd = $appCredential.password
$appid=az ad app show --id $clientid|ConvertFrom-Json
$appid=$appid.appid
az ad sp create --id $clientId | Out-Null
$principalId = az ad sp show --id $clientId --query "id" -o tsv
New-AzRoleAssignment -Objectid $principalId -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
(Get-Content -path "artifacts/databricks/ADB_Initial_Setup.ipynb" -Raw) | Foreach-Object { $_ `
        -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
		-replace '#TENANT_ID#', $tenantid `
		-replace '#APP_SECRET#', $clientsecpwd `
		-replace '#APP_ID#', $appid `
} | Set-Content -Path "artifacts/databricks/ADB_Initial_Setup.ipynb"

(Get-Content -path "artifacts/databricks/ML Solutions in OneBox.ipynb" -Raw) | Foreach-Object { $_ `
        -replace '#AML_WORKSPACE_NAME#', $amlworkspacename `
        -replace '#SUBSCRIPTION_ID#', $subscriptionId `
        -replace '#RESOURCE_GROUP_NAME#', $rgName `
        -replace '#LOCATION#', $Region `
        -replace '#DATABRICKS_TOKEN#', $pat_token `
        -replace '#WORKSPACE_URL#', $workspaceUrl `
} | Set-Content -Path "artifacts/databricks/ML Solutions in OneBox.ipynb"

$files = Get-ChildItem -path "artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
Set-Location ./artifacts/databricks
foreach ($name in $files.name) {
    if($name -eq "01_campaign_analytics_DLT.ipynb" -or $name -eq "02_Twitter_Sentiment_Score_Pred_Custom_ML_Model.ipynb" -or $name -eq "03_Sentiment_Analytics_On_Delta_Live_Tables.ipynb")
    {
            $fileContent = get-content -raw $name
            $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
            $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
            $requestHeaders = @{
                Authorization = "Bearer" + " " + $pat_token
                        }
                $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
            #get job list
            $endPoint = $baseURL +  "/api/2.0/workspace/import"
            Invoke-RestMethod $endPoint `
                -ContentType 'application/json' `
                -Method Post `
                -Headers $requestHeaders `
                -Body $body
    }
    elseif($name -eq "04_SQL_Analytics_On_Delta_Live_Tables.ipynb" -or $name -eq "ADB_Initial_Setup.ipynb")
    { 
        $fileContent = get-content -raw $name
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
        $requestHeaders = @{
            Authorization = "Bearer" + " " + $pat_token
        }
        $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
        #get job list
        $endPoint = $baseURL +  "/api/2.0/workspace/import"
        Invoke-RestMethod $endPoint `
            -ContentType 'application/json' `
            -Method Post `
            -Headers $requestHeaders `
            -Body $body
    } 
    elseif($name -eq "Campaign Powered by Twitter.ipynb" -or $name -eq "ML Solutions in OneBox.ipynb" -or $name -eq "Retail Sales Data Prep Using Spark DLT.ipynb")
    { 
        $fileContent = get-content -raw $name
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
        $requestHeaders = @{
            Authorization = "Bearer" + " " + $pat_token
        }
        $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
        #get job list
        $endPoint = $baseURL +  "/api/2.0/workspace/import"
        Invoke-RestMethod $endPoint `
            -ContentType 'application/json' `
            -Method Post `
            -Headers $requestHeaders `
            -Body $body
    } 
}
Set-Location ../../

Add-Content log.txt "-----Ms Sql-----"
Write-Host "----Ms Sql----"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/SalesTrans Table Generate Script.sql"
$sqlEndpoint="$($sqlserver).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlDatabaseName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

#uploading Sql Scripts
Add-Content log.txt "-----------uploading Sql Script-----------------"
Write-Host "----Sql Scripts------"
RefreshTokens
$scripts=Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
$TemplatesPath="./artifacts/templates";	
$name = "1 Query Campaign And Twitter Data Using The T-SQL Language" 

$item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
$item = $item.Replace("#SQL_SCRIPT_NAME#", $name)
$item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
$jsonItem = ConvertFrom-Json $item 
$ScriptFileName="./artifacts/sqlscripts/"+$name+".sql"

$query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
$query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
	
if ($Parameters -ne $null) 
{
    foreach ($key in $Parameters.Keys) 
    {
        $query = $query.Replace("#$($key)#", $Parameters[$key])
    }
}

Write-Host "Uploading Sql Script : $($name)"
$query = ConvertFrom-Json (ConvertTo-Json $query)
$jsonItem.properties.content.query = $query
$item = ConvertTo-Json $jsonItem -Depth 100
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

## Running a sql script in Sql serverless Pool
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$sasTokenAcc = New-AzStorageAccountSASToken -Context $dataLakeContext -Service Blob -ResourceType Service -Permission rwdl

$name = "2 Create External Table In Serverless Pool"
$ScriptFileName="./artifacts/sqlscripts/"+$name+".sql"

$sqlQuery  = "Create DATABASE AnalyticsServerlessPool"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
try {
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
} catch {
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
}
Add-Content log.txt $result	
 
$query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
$query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$query = $query.Replace("#SAS_TOKEN#", $sasTokenAcc)
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database AnalyticsServerlessPool -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result	

#Azure Purview
Write-Host "-----------------Azure Purview---------------"
RefreshTokens

#create collections
$body = @{
    parentCollection = @{
      referenceName = $accounts_purview_analytics_name
    }
  }
  
  $body = $body | ConvertTo-Json
  
  RefreshTokens
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/account/collections/$($purviewCollectionName1)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  RefreshTokens
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/account/collections/$($purviewCollectionName2)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  RefreshTokens
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/account/collections/$($purviewCollectionName3)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  RefreshTokens
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/account/collections/$($purviewCollectionName4)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  #create sources
  $body = @{
        kind = "AdlsGen2"
        properties = @{
            collection = @{
                referenceName = $purviewCollectionName1
                type = 'CollectionReference'
            }
            location = $Region
            endpoint = "https://${dataLakeAccountName}.dfs.core.windows.net/"
            resourceGroup = $rgName
            resourceName = $dataLakeAccountName
            subscriptionId = $subscriptionId
        }
    }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/scan/datasources/AzureDataLakeStorage?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  $body = @{
    kind = "AzureSynapseWorkspace"
    properties = @{
      dedicatedSqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
      serverlessSqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
      subscriptionId = $subscriptionId
      resourceGroup = $rgName
      location = $Region
      resourceName = $synapseWorkspaceName
      collection = @{
        type = "CollectionReference"
        referenceName = $purviewCollectionName2
      }
    }
  }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/scan/datasources/AzureSynapseAnalytics?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  # 6. Create a Source (Azure SQL Database)
    $body = @{
        kind = "AzureSqlDatabase"
        properties = @{
            collection = @{
                referenceName = $purviewCollectionName3
                type = 'CollectionReference'
            }
            location = $Region
            resourceGroup = $rgName
            resourceName = $sqlserver
            serverEndpoint = "${sqlserver}.database.windows.net"
            subscriptionId = $subscriptionId
        }
    }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/scan/datasources/AzureSqlDatabase?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  $body = @{
    kind = "PowerBI"
    properties = @{
      tenant = $tenantId
      collection = @{
        type = "CollectionReference"
        referenceName = $purviewCollectionName4
      }
    }
  }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_analytics_name).purview.azure.com/scan/datasources/PowerBI?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"  


Add-Content log.txt "------linked Services------"
Write-Host "----linked Services------"
#Creating linked services
RefreshTokens
$templatepath="./artifacts/linkedService/"

# AutoResolveIntegrationRuntime
$FilePathRT="./artifacts/linkedService/AutoResolveIntegrationRuntime.json" 
$itemRT = Get-Content -Path $FilePathRT
$uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Add-Content log.txt $result

# AzureBlobStorage
Write-Host "Creating linked Service: AzureBlobStorage"
$filepath=$templatepath+"AzureBlobStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureBlobStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# # AzureDatabricksAnalyticsSolutions
# Write-Host "Creating linked Service: AzureDatabricksAnalyticsSolutions"
# $filepath=$templatepath+"AzureDatabricksAnalyticsSolutions.json"
# $itemTemplate = Get-Content -Path $filepath
# $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token)
# $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksAnalyticsSolutions?api-version=2019-06-01-preview"
# $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
# Add-Content log.txt $result          

# # AzureDatabricksDeltaLake
# Write-Host "Creating linked Service: AzureDatabricksDeltaLake"
# $filepath=$templatepath+"AzureDatabricksDeltaLake.json"
# $itemTemplate = Get-Content -Path $filepath
# $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId_1)
# $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksDeltaLake?api-version=2019-06-01-preview"
# $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
# Add-Content log.txt $result

# # AzureDatabricksDeltaLakeTwitterData
# Write-Host "Creating linked Service: AzureDatabricksDeltaLakeTwitterData"
# $filepath=$templatepath+"AzureDatabricksDeltaLakeTwitterData.json"
# $itemTemplate = Get-Content -Path $filepath
# $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId_1)
# $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksDeltaLakeTwitterData?api-version=2019-06-01-preview"
# $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
# Add-Content log.txt $result

# AzureSqlDatabase
Write-Host "Creating linked Service: AzureSqlDatabase"
$filepath=$templatepath+"AzureSqlDatabase.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#SERVER_NAME#", $mssql_server_name).Replace("#DATABASE_NAME#", $sqlDatabaseName).Replace("#USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSqlDatabase?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# AzureDataLakeStorageTwitterData
Write-Host "Creating linked Service: AzureDataLakeStorageTwitterData"
$filepath=$templatepath+"AzureDataLakeStorageTwitterData.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDataLakeStorageTwitterData?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# OracleDB linked services
Write-Host "Creating linked Service: OracleDB"
$filepath=$templatepath+"OracleDB.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/OracleDB?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# Snowflake linked services
Write-Host "Creating linked Service: Snowflake"
$filepath=$templatepath+"Snowflake.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Snowflake?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# syn-analyticssolutionsdev-01-WorkspaceDefaultSqlServer
Write-Host "Creating linked Service: syn-analyticssolutionsdev-01-WorkspaceDefaultSqlServer"
$filepath=$templatepath+"syn-analyticssolutionsdev-01-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/syn-analyticssolutionsdev-01-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# syn-analyticssolutionsdev-01-WorkspaceDefaultStorage
Write-Host "Creating linked Service: syn-analyticssolutionsdev-01-WorkspaceDefaultStorage"
$filepath=$templatepath+"syn-analyticssolutionsdev-01-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/syn-analyticssolutionsdev-01-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# Teradata linked services
Write-Host "Creating linked Service: Teradata"
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

#Creating Datasets
Add-Content log.txt "------datasets------"
Write-Host "--------Datasets--------"
RefreshTokens
$DatasetsPath="./artifacts/dataset";	
$datasets=Get-ChildItem "./artifacts/dataset" | Select BaseName
foreach ($dataset in $datasets) 
{
    Write-Host "Creating dataset : $($dataset.BaseName)"
	$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset.BaseName).json"
	$item = $itemTemplate
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	Add-Content log.txt $result
}
 
# #Creating spark notebooks
# Add-Content log.txt "--------------Spark Notebooks---------------"
# Write-Host "--------Spark notebooks--------"
# RefreshTokens
# $notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 

# $cellParams = [ordered]@{
#     "#SQL_POOL_NAME#"       = $sqlPoolName
#     "#SUBSCRIPTION_ID#"     = $subscriptionId
#     "#RESOURCE_GROUP_NAME#" = $rgName
#     "#WORKSPACE_NAME#"  = $synapseWorkspaceName
#     "#DATA_LAKE_NAME#" = $dataLakeAccountName
#     "#SPARK_POOL_NAME#" = $sparkPoolName
#     "#STORAGE_ACCOUNT_KEY#" = $storage_account_key
#     "#STORAGE_ACCOUNT_NAME#" = $dataLakeAccountName
#     "#LOCATION#"=$Region
#     "#ML_WORKSPACE_NAME#"=$amlworkspacename
# }

# foreach($name in $notebooks)
# {
# 	$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
# 	foreach ($paramName in $cellParams.Keys) 
#     {
# 		$template = $template.Replace($paramName, $cellParams[$paramName])
# 	}
# 	$template=$template.Replace("#NOTEBOOK_NAME#",$name.BaseName)
#     $jsonItem = ConvertFrom-Json $template
# 	$path="./artifacts/notebooks/"+$name.BaseName+".ipynb"
# 	$notebook=Get-Content -Raw -Path $path
# 	$jsonNotebook = ConvertFrom-Json $notebook
# 	$jsonItem.properties.cells = $jsonNotebook.cells
	
#     if ($CellParams) 
#     {
#         foreach ($cellParamName in $cellParams.Keys) 
#         {
#             foreach ($cell in $jsonItem.properties.cells) 
#             {
#                 for ($i = 0; $i -lt $cell.source.Count; $i++) 
#                 {
#                     $cell.source[$i] = $cell.source[$i].Replace($cellParamName, $CellParams[$cellParamName])
#                 }
#             }
#         }
#     }

#     Write-Host "Creating notebook : $($name.BaseName)"
# 	$item = ConvertTo-Json $jsonItem -Depth 100
# 	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name.BaseName)?api-version=2019-06-01-preview"
# 	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
# 	#waiting for operation completion
# 	Start-Sleep -Seconds 10
# 	Add-Content log.txt $result
# }

# #creating Dataflows
# Add-Content log.txt "------Dataflows-----"
# Write-Host "--------Dataflows--------"
# RefreshTokens
# $workloadDataflows = Get-ChildItem "./artifacts/dataflow" | Select BaseName 

# $DataflowPath="./artifacts/dataflow"

# foreach ($dataflow in $workloadDataflows) 
# {
#     $Name=$dataflow.BaseName
#     Write-Host "Creating dataflow : $($Name)"
#     $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
# 	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
# 	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
#     #waiting for operation completion
# 	Start-Sleep -Seconds 10
# 	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
# 	$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
# 	Add-Content log.txt $result
# }

#creating Pipelines
Add-Content log.txt "------pipelines------"
Write-Host "-------Pipelines-----------"
RefreshTokens
$pipelines=Get-ChildItem "./artifacts/pipeline" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
    $FilePath="./artifacts/pipeline/"+$name.BaseName+".json"
    Write-Host "Creating pipeline : $($name.BaseName)"

    $item = Get-Content -Path $FilePath
    $item=$item.Replace("#DATA_LAKE_STORAGE_NAME#",$dataLakeAccountName)
    $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
    Start-Sleep -Seconds 10
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    Add-Content log.txt $result 
}

#creating Triggers
Add-Content log.txt "------triggers------"
Write-Host "-------Triggers-----------"
RefreshTokens
$triggers=Get-ChildItem "./artifacts/trigger" | Select BaseName
foreach($name in $triggers)
{
    $FilePath="./artifacts/trigger/"+$name.BaseName+".json"
    Write-Host "Creating trigger : $($name.BaseName)"

    $item = Get-Content -Path $FilePath
    $item=$item.Replace("#STORAGE_ACCOUNT_NAME#",$dataLakeAccountName).Replace("#RESOURCE_GROUP_NAME#",$rgName).Replace("#SUBSCRIPTION_ID#",$subscriptionId)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/triggers/$($name.BaseName)?api-version=2020-12-01"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"

    #waiting for operation completion
    Start-Sleep -Seconds 10
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    Add-Content log.txt $result 
}

#uploading Sql Scripts
Add-Content log.txt "-----------uploading KQL Scripts-----------------"
Write-Host "----KQL Scripts------"
RefreshTokens
$scripts=Get-ChildItem "./artifacts/kqlscripts" | Select BaseName

foreach ($name in $scripts) 
{
    $ScriptFileName="./artifacts/kqlscripts/"+$name.BaseName+".kql"
    Write-Host "Uploading Kql Script : $($name.BaseName)"
    New-AzSynapseKqlScript -WorkspaceName $synapseWorkspaceName -DefinitionFile $ScriptFileName
}

Write-Host  "-----------------AML Workspace ---------------"
Add-Content log.txt "-----------AML Workspace -------------"
RefreshTokens

#create aml workspace
az extension add -n azure-cli-ml
az ml workspace create -n $amlworkspacename -g $rgName

#attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName -e aml
start-sleep -s 10

#create and delete a compute instance to get the code folder created in default store
az ml computetarget create computeinstance -n $cpuShell -s "STANDARD_DS2_V2" -v

#get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

#delete aks compute
az ml computetarget delete -n $cpuShell -v

#Web app
Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------Deploy web app ---------------"
RefreshTokens

$zips = @("app-adx-thermostat-realtime", "app-midp")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

RefreshTokens

$spname="Midp Demo $deploymentId"

$app = az ad app create --display-name $spname | ConvertFrom-Json
$appId = $app.appId

$mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$clientsecpwd = $mainAppCredential.password

az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "id" -o tsv
start-sleep -s 60

(Get-Content -path app-midp/appsettings.json -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId`
    -replace '#APP_ID#', $appId`
    -replace '#APP_SECRET#', $clientsecpwd`
    -replace '#TENANT_ID#', $tenantId`
} | Set-Content -Path app-midp/appsettings.json

Compress-Archive -Path "./app-midp/*" -DestinationPath "./app-midp.zip"

az webapp stop --name $app_midpdemo_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $app_midpdemo_name --src "./app-midp.zip"
}
catch
{
}
az webapp start  --name $app_midpdemo_name --resource-group $rgName

foreach($zip in $zips)
{
    if ($zip -eq  "app-midp" ) 
    {
        remove-item -path "./$($zip).zip" -recurse -force
    }
    if ($zip -eq "app-midp" ) 
    {
        continue;
    }
    remove-item -path "./$($zip)" -recurse -force
}

# ADX Thermostat Realtime
$occupancy_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name occupancy --name occupancy | ConvertFrom-Json
$occupancy_endpoint = $occupancy_endpoint.primaryConnectionString
$thermostat_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name thermostat --name thermostat | ConvertFrom-Json
$thermostat_endpoint = $thermostat_endpoint.primaryConnectionString

$occupancyDataConfig = '{\"main_data_frequency_seconds\":5,\"urlStringEventhub\":\"'+$occupancy_endpoint+'\",\"EventhubName\":\"occupancy\",\"urlPowerBI\":\"'+$occupancy_data_Realtime_URL+'\",\"data\":[{\"BatteryLevel\":{\"minValue\":0,\"maxValue\":100}},{\"visitors_cnt\":{\"minValue\":20,\"maxValue\":50}},{\"visitors_in\":{\"minValue\":0,\"maxValue\":10}},{\"visitors_out\":{\"minValue\":0,\"maxValue\":10}},{\"avg_aisle_time_spent\":{\"minValue\":20,\"maxValue\":30}},{\"avg_dwell_time\":{\"minValue\":5,\"maxValue\":15}}]}'
 	
$thermostatTelemetryConfig = '{\"main_data_frequency_seconds\":5,\"urlStringEventhub\":\"'+$thermostat_endpoint+'\",\"EventhubName\":\"thermostat\",\"urlPowerBI\":\"'+$thermostat_telemetry_Realtime_URL+'\",\"data\":[{\"BatteryLevel\":{\"minValue\":0,\"maxValue\":100}},{\"Temp\":{\"minValue\":60.0,\"maxValue\":74.0}},{\"Temp_UoM\":{\"minValue\":\"F\",\"maxValue\":\"F\"}}]}'
 
$config = az webapp config appsettings set -g $rgName  -n $sites_adx_thermostat_realtime_name --settings occupancyDataConfig=$occupancyDataConfig
$config = az webapp config appsettings set -g $rgName -n $sites_adx_thermostat_realtime_name --settings thermostatTelemetryConfig=$thermostatTelemetryConfig

Write-Information "Deploying ADX Thermostat Realtime App"
cd app-adx-thermostat-realtime
az webapp up --resource-group $rgName --name $sites_adx_thermostat_realtime_name --plan $serverfarm_adx_thermostat_realtime_name --location $Region
cd ..
Start-Sleep -s 10

az webapp start --name $sites_adx_thermostat_realtime_name --resource-group $rgName
$endtime=get-date
$executiontime=$endtime-$starttime
Write-Host "Execution Time"$executiontime.TotalMinutes
Add-Content log.txt "-----------------Execution Complete---------------"

Add-Content log.txt "------Data Explorer Creation-----"
Write-Host "----Data Explorer Creation-----"
New-AzSynapseKustoPool -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -Name $kustoPoolName -Location $Region -SkuName "Compute optimized" -SkuSize Small

New-AzSynapseKustoPoolDatabase -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -KustoPoolName $kustoPoolName -DatabaseName $kustoDatabaseName -Kind "ReadWrite" -Location $Region


Write-Host  "-----------------Execution Complete----------------"
}