function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if ($subs.GetType().IsArray -and $subs.length -gt 1) {
    $subOptions = [System.Collections.ArrayList]::new()
    for ($subIdx = 0; $subIdx -lt $subs.length; $subIdx++) {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    $title = 'Subscription selection'
    $question = 'Are you sure you want to select this subscription for this lab?'
    $choices = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
    else {
        $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
        $selectedSubName = $subs[$selectedSubIdx]
        Write-Host "Selecting the subscription : $selectedSubName "
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
}

$rgName = read-host "Enter the resource Group Name";
$Region = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
$suffix = "$random-$init"
$concatString = "$init$random"
$cpuShell = "healthcare-compute"
$forms_healthcare2_name = "form-healthcare2-$suffix"
$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$amlworkspacename = "aml-hc2-$suffix"
$cosmos_healthcare2_name = "cosmos-healthcare2-$random$init"
if ($cosmos_healthcare2_name.length -gt 43) {
    $cosmos_healthcare2_name = $cosmos_healthcare2_name.substring(0, 43)
}
$openAIResource = "openAIservicehc2$concatString"
if($openAIResource.length -gt 24)
{
$openAIResource = $openAIResource.substring(0,24)
}

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value

$forms_hc2_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_healthcare2_name

#retrieving openai endpoint
$openAIEndpoint = az cognitiveservices account show -n $openAIResource -g $rgName | jq -r .properties.endpoint

#retirieving primary key
$openAIPrimaryKey = az cognitiveservices account keys list -n $openAIResource -g $rgName | jq -r .key1

#Form Recognizer
Add-Content log.txt "-------------Form Recognizer--------------"
Write-Host "-----Form Recognizer-----"

$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$startingTime = Get-Date
$endingTime = $startingTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "patientintakeform" -Context $dataLakeContext -Permission rwdl -StartTime $startingTime -ExpiryTime $endingTime

#Replace values in create_model.py
(Get-Content -path ../artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
                -replace '#LOCATION#', $Region`
                -replace '#FORM_RECOGNIZER_NAME#', $forms_healthcare2_name`
                -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
                -replace '#CONTAINER_NAME#', "patientintakeform"`
                -replace '#SAS_TOKEN#', $sasToken`
                -replace '#APIM_KEY#',  $forms_hc2_keys.Key1`
            } | Set-Content -Path ../artifacts/formrecognizer/create_model1.py
            
$modelUrl = python "../artifacts/formrecognizer/create_model1.py"
$modelId = $modelUrl.split("/")
$modelId = $modelId[7]

Write-Host  "-----------------AML Workspace ---------------"
Add-Content log.txt "-----------AML Workspace -------------"
RefreshTokens

$forms_hc2_endpoint = "https://"+$forms_healthcare2_name+".cognitiveservices.azure.com/"

#delpoying a model
$openAIModel = az cognitiveservices account deployment create -g $rgName -n $openAIResource --deployment-name "text-davinci-003" --model-name "text-davinci-003" --model-version "1" --model-format OpenAI --scale-settings-scale-type "Standard"

$filepath="../artifacts/amlnotebooks/Configurable.py"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key).Replace("#FORM_RECOGNIZER_ENDPOINT#", $forms_hc2_endpoint).Replace("#FORM_RECOGNIZER_API_KEY#", $forms_hc2_keys.Key1).Replace("#FORM_RECOGNIZER_MODEL_ID#", $modelId)
$filepath="../artifacts/amlnotebooks/GlobalVariables.py"
Set-Content -Path $filepath -Value $item

$filepath="../artifacts/amlnotebooks/config.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#OPENAI_API_ENDPOINT#", $openAIEndpoint).Replace("#OPENAI_API_KEY#", $openAIPrimaryKey)
$filepath="../artifacts/amlnotebooks/config.json"
Set-Content -Path $filepath -Value $item

# #deleting a model from openai
# az cognitiveservices account deployment delete -g $myResourceGroupName -n $myResourceName --deployment-name MyModel

# #deleting openai resource
# az cognitiveservices account delete --name MyopenAIResource -g OAIResourceGroup

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

#get fileshare and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
$shareName = $share[0].Name
$notebooks = Get-ChildItem "../artifacts/amlnotebooks" | Select BaseName
foreach ($notebook in $notebooks) {

    if($notebook.BaseName -eq "GlobalVariables")
    {
        $source="../artifacts/amlnotebooks/"+$notebook.BaseName+".py"
        $path=$notebook.BaseName+".py"
    } 
    elseif($notebook.BaseName -eq "config")
    {
        $source="../artifacts/amlnotebooks/"+$notebook.BaseName+".json"
        $path=$notebook.BaseName+".json"
    } 
    elseif($notebook.BaseName -eq "Configurable")
    {
        continue;
    } 
    else {
        $source = "../artifacts/amlnotebooks/" + $notebook.BaseName + ".ipynb"
        $path = $notebook.BaseName + ".ipynb"
    }

    Write-Host " Uplaoding AML assets : $($notebook.BaseName)"
    Set-AzStorageFileContent `
        -Context $storageAcct.Context `
        -ShareName $shareName `
        -Source $source `
        -Path $path
}

#delete aks compute
az ml computetarget delete -n $cpuShell -v
