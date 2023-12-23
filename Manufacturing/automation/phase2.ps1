$location = "westus2"
$forms_cogs_name = "forms-$suffix"
$text_translation_service_name = "Mutarjum-$suffix"
$searchName = "mfg-search-$init-$random"
$amlworkspacename = "amlws-$suffix"
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -Name $forms_cogs_name
$text_translation_service_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -Name $text_translation_service_name

$searchKey = (az search admin-key show --resource-group $rgName --service-name $searchName | ConvertFrom-Json).primarykey

# Custom Vision
pip install -r ./artifacts/copyCV/requirements.txt
$key = az cognitiveservices account keys list --name $customVisionName -g $rgName | ConvertFrom-Json
$destinationKey = $key.key1
$sourceKey = ""  # TODO: find a way to get this securely

# Hard hat project
$sourceProjectId = ""
$destinationregion = "https://$location.api.cognitive.microsoft.com"
$sourceregion = "https://westus2.api.cognitive.microsoft.com"
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

# Welding helmet project
$sourceProjectId = ""
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

# Mask compliance project
$sourceProjectId = ""
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

# Product classification project
$sourceProjectId = ""
$sourceKey = ""
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

$url = "https://$location.api.cognitive.microsoft.com/customvision/v3.2/training/projects"
$projects = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ "Training-key" = "$destinationKey" }
$resource = az resource show -g $rgName -n $customVisionName --resource-type "Microsoft.CognitiveServices/accounts" | ConvertFrom-Json
$resourceId = $resource.id
$configContent = Get-Content -Path artifacts/amlnotebooks/config.py -Raw
$configContent = $configContent -replace '#SUBSCRIPTION_ID#', $subscriptionId `
    -replace '#RESOURCE_GROUP#', $rgName `
    -replace '#WORKSPACE_NAME#', $amlworkspacename `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
    -replace '#FORM_SERVICE_NAME#', $forms_cogs_name `
    -replace '#APIM_KEY#', $forms_cogs_keys.Key1 `
    -replace '#MODEL_ID#', $modelId `
    -replace '#TRANSLATOR_NAME#', $text_translation_service_name `
    -replace '#TRANSLATION_KEY#', $text_translation_service_keys.Key1
$configContent | Set-Content -Path artifacts/amlnotebooks/config.py

foreach ($project in $projects) {
    $projectId = $project.id
    $projectName = $project.name
    if ($projectName -eq "1_MFG__Helmet_PPE_Compliance") {
        $configContent = $configContent -replace '#HARD_HAT_ID#', $projectId `
            -replace '#PREDICTION_KEY#', $destinationKey
        $configContent | Set-Content -Path artifacts/amlnotebooks/config.py
    } elseif ($projectName -eq "2_MFG__Welding_Helmet_PPE_Compliance") {
        $configContent = $configContent -replace '#HELMET_ID#', $projectId `
            -replace '#PREDICTION_KEY#', $destinationKey
        $configContent | Set-Content -Path artifacts/amlnotebooks/config.py
    } elseif ($projectName -eq "3_MFG__Mask_PPE_Compliance") {
        $configContent = $configContent -replace '#FACE_MASK_ID#', $projectId `
            -replace '#PREDICTION_KEY#', $destinationKey
        $configContent | Set-Content -Path artifacts/amlnotebooks/config.py
    } elseif ($projectName -eq "1_Defective_Product_Classification") {
        $configContent = $configContent -replace '#QUALITY_CONTROL_ID#', $projectId `
            -replace '#PREDICTION_KEY#', $destinationKey
        $configContent | Set-Content -Path artifacts/amlnotebooks/config.py
    }

    $url = "https://$location.api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($project.id)/tags"
    $tags = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ "Training-key" = "$destinationKey" }
    $tagList = [System.Collections.ArrayList]@()
    foreach ($tag in $tags) {
        $tagList.Add($tag.id)
    }
    $body = @{
        selectedTags = $tagList
    } | ConvertTo-Json
    $url = "https://$location.api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($projectId)/train"
    $Result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{"Training-key" = "$destinationKey"}

    $url = "https://$location.api.cognitive.microsoft.com/customvision/v3.3/Training/projects/$($projectId)/iterations"
    $iterations = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ "Training-key" = "$destinationKey" }
    $iterationId = $iterations[0].id
    $url = "https://$location.api.cognitive.microsoft.com/customvision/v3.3/Training/projects/$($projectId)/iterations/$($iterationId)/publish?publishName=Iteration1&predictionId=$($resourceId)"
    $body = "{}"
    # Adding retry attempts for publishing iterations
    $count = 0
    $Delay = 60
    $Maximum = 5
    do {
        $count++
        try {
            Write-Host "Attempt $($count) at publishing iteration"
            $Result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{"Training-key" = "$destinationKey"}
        } catch {
            Write-Error $_.Exception.InnerException.Message -ErrorAction Continue
            Write-Host "Sleeping for a minute"
            Start-Sleep -Seconds $Delay
        }
    } while ($count -lt $Maximum)
}

# AML Workspace
# Create AML workspace
az extension add -n azure-cli-ml
az ml workspace create -w $amlworkspacename -g $rgName
az ml computetarget create aks --name "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName

# Attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName

# Create and delete a compute instance to get the code folder created in the default store
az ml computetarget create computeinstance -n cpuShell -s "STANDARD_D3_V2" -v
# az ml computetarget delete -n cpuShell -v

# Get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

# Get file share and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context
$shareName = $share.Name
$shareName

# Create Users folder (it won't be there unless we launch the workspace in UI)
New-AzStorageDirectory -Context $storageAcct.Context -ShareName $shareName -Path "Users"

# Copy notebooks to ML workspace
$notebooks = Get-ChildItem "./artifacts/amlnotebooks" | Select-Object BaseName
foreach ($notebook in $notebooks) {
    if ($notebook.BaseName -eq "config") {
        $source = "./artifacts/amlnotebooks/" + $notebook.BaseName + ".py"
        $path = "/Users/" + $notebook.BaseName + ".py"
    } else {
        $source = "./artifacts/amlnotebooks/" + $notebook.BaseName + ".ipynb"
        $path = "/Users/" + $notebook.BaseName + ".ipynb"
    }

    Set-AzStorageFileContent `
        -Context $storageAcct.Context `
        -ShareName $shareName `
        -Source $source `
        -Path $path
}

az ml computetarget delete -n cpuShell -v
