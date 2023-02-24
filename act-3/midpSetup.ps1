$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "I accept the license agreement."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "I do not accept and wish to stop execution."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "Agreement"
$message = "By typing [Y], I hereby confirm that I have read the license ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/license.md ) and disclaimers ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/README.md ) and hereby accept the terms of the license and agree that the terms and conditions set forth therein govern my use of the code made available hereunder. (Type [Y] for Yes or [N] for No and press enter)"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
if ($result -eq 1) {
    write-host "Thank you. Please ensure you delete the resources created with template to avoid further cost implications."
} else {

az login

#for powershell...
Connect-AzAccount -DeviceCode

$starttime = get-date
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

$response = az ad signed-in-user show | ConvertFrom-Json
$date = get-date
$demoType = "Act-3"
$body = '{"demoType":"#demoType#","userPrincipalName":"#userPrincipalName#","displayName":"#displayName#","companyName":"#companyName#","mail":"#mail#","date":"#date#"}'
$body = $body.Replace("#userPrincipalName#", $response.userPrincipalName)
$body = $body.Replace("#displayName#", $response.displayName)
$body = $body.Replace("#companyName#", $response.companyName)
$body = $body.Replace("#mail#", $response.mail)
$body = $body.Replace("#date#", $date)
$body = $body.Replace("#demoType#", $demoType)

$uri = "https://registerddibuser.azurewebsites.net/api/registeruser?code=pTrmFDqp25iVSxrJ/ykJ5l0xeTOg5nxio9MjZedaXwiEH8oh3NeqMg=="
$result = Invoke-RestMethod  -Uri $uri -Method POST -Body $body -Headers @{} -ContentType "application/json"

$rgName = read-host "Enter the resource Group Name";
$Region = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
$suffix = "$random-$init"
$cognitive_service = "wwi-cog-$suffix"
$app_midp_3_name = "app-midp-3-$suffix"
$app_midp_3_cbc_name = "app-midp-3-cbc-$suffix"

#get list of keys - cognitiveservices
$key = az cognitiveservices account keys list --name $cognitive_service -g $rgName|ConvertFrom-json
$cognitiveKey = $key.key1

$cognitive_account = Get-AzCognitiveServicesAccount -ResourceGroupName $rgName -Name $cognitive_service
$cognitiveEndpoint = $cognitive_account.Endpoint

#Web app
Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------Deploy web app---------------"

$zips = @("midp-act3")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

(Get-Content -path midp-act3/appsettings.json -Raw) | Foreach-Object { $_ `
    -replace '#COGNITIVE_SERVICE_ENDPOINT#', $cognitiveEndpoint`
    -replace '#COGNITIVE_SERVICE_KEY#', $cognitiveKey`
    -replace '#REGION#', $Region
} | Set-Content -Path midp-act3/appsettings.json

Compress-Archive -Path "./midp-act3/*" -DestinationPath "./midp-act3.zip" -Update

az webapp stop --name $app_midp_3_name --resource-group $rgName
try {
    az webapp deployment source config-zip --resource-group $rgName --name $app_midp_3_name --src "./midp-act3.zip"
}
catch {
}
az webapp stop --name $app_midp_3_cbc_name --resource-group $rgName
try {
    az webapp deployment source config-zip --resource-group $rgName --name $app_midp_3_cbc_name --src "./artifacts/binaries/midp-act3-cbc.zip"
}
catch {
}

az webapp start --name $app_midp_3_name --resource-group $rgName
az webapp start --name $app_midp_3_cbc_name --resource-group $rgName

$endtime = get-date
$executiontime = $endtime - $starttime
Write-Host "Execution Time - "$executiontime.TotalMinutes
Add-Content log.txt "-----------------Execution Complete---------------"
}