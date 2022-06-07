function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$sites_app_multiling_retail_name = "multiling-retail-app-$suffix";
$bot_qnamaker_retail_name= "botmultilingual-$suffix";
$asp_multiling_retail_name = "multiling-retail-asp-$suffix";

Write-Host "----Bot and multilingual App----"

$app = az ad app create --display-name $sites_app_multiling_retail_name | ConvertFrom-Json
$appId = $app.appId

$appCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$appPassword = $appCredential.password

az deployment group create --resource-group $rgName --template-file "../artifacts/qnamaker/bot-multiling-template.json" --parameters appId=$appId appSecret=$appPassword botId=$bot_qnamaker_retail_name newWebAppName=$sites_app_multiling_retail_name newAppServicePlanName=$asp_multiling_retail_name appServicePlanLocation=$rglocation

az webapp deployment source config-zip --resource-group $rgName --name $sites_app_multiling_retail_name --src "../artifacts/qnamaker/chatbot.zip"
az webapp start --name $sites_app_multiling_retail_name --resource-group $rgName 

$bot_detail = az bot webchat show --name $bot_qnamaker_retail_name --resource-group $rgName --with-secrets true | ConvertFrom-Json
$bot_key = $bot_detail.properties.properties.sites[0].key

$bot_key