function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$accounts_transqna_retail_name = "transqna-retail-$suffix";
$workflows_LogicApp_retail_name = "logicapp-retail-$suffix"
$accounts_qnamaker_name= "qnamaker-$suffix";
$sites_app_multiling_retail_name = "multiling-retail-app-$suffix";

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$cog_translator_key =  Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $accounts_transqna_retail_name

#########################
RefreshTokens
Add-Content log.txt "----QnA maker-----"
Write-Host "----QnA maker-----"

$qna_maker_keys = az cognitiveservices account keys list --name  $accounts_qnamaker_name -g $rgname| Convertfrom-Json
$qna_maker_key = $qna_maker_keys.key1
(Get-Content -path ../artifacts/qnamaker/knowledge_base.py -Raw) | Foreach-Object { $_ `
                -replace '#QNA_MAKER_KEY#', $qna_maker_key`
				-replace '#QNA_MAKER_NAME#', $accounts_qnamaker_name`
			} | Set-Content -Path ./knowledge_base1.py
			
$qna_key = python3 ./knowledge_base1.py | ConvertFrom-Json

Add-Content log.txt "----logic App-----"
Write-Host "----logic App----"

$translator_key=$cog_translator_key.Key1
$KBKey=$qna_key.KBKey
$KBID=$qna_key.KBID

az deployment group create  --resource-group $rgName  --template-file '../artifacts/qnamaker/logicapp.json' --parameters workflows_logicapp_retail=$workflows_LogicApp_retail_name translationKey=$translator_key KBKey=$KBKey qnaMakerResource=$accounts_qnamaker_name KBID=$KBID location=$location
Start-Sleep -Seconds 20
$logic_callback_details = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $rgName -Name $workflows_LogicApp_retail_name -TriggerName "manual"
$logic_callback_url = $logic_callback_details.Value

$config = az webapp config appsettings set -g $rgName -n $sites_app_multiling_retail_name --settings LogiAppURL=$logic_callback_url
