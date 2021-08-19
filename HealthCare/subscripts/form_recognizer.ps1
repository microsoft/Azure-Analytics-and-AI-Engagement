
#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$location = (Get-AzResourceGroup -Name $rgName).Location
$storageAccountName = $dataLakeAccountName
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "form-datasets" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime
$suffix = "$random-$init"
$forms_cogs_name = "cog-formrecognition-$suffix";
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_cogs_name

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
