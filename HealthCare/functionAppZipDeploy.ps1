$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$PbiDatasetUrl = (Get-AzResourceGroup -Name $rgName).Tags["PbiDatasetUrl"]
$deploymentId = $init
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$functionappIomt="func-app-iomt-processor-$suffix"
$functionappMongoData = "func-app-mongo-data-$suffix"
az functionapp stop --name $functionappMongoData --resource-group $rgName
try{
az functionapp deployment source config-zip --resource-group $rgName --name $functionappMongoData --src "./artifacts/binaries/mongo_data.zip"
}
catch
{
az functionapp deployment source config-zip --resource-group $rgName --name $functionappMongoData --src "./artifacts/binaries/mongo_data.zip"
}
	
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$Storage_CS = "DefaultEndpointsProtocol=https;AccountName=" + $dataLakeAccountName + ";AccountKey="+ $storage_account_key + ";EndpointSuffix=core.windows.net"
Update-AzFunctionAppSetting -Name $functionappMongoData -ResourceGroupName $rgName -AppSetting @{"STORAGE_CONNECTION_STRING" = "$($Storage_CS)"}
az functionapp start --name $functionappMongoData --resource-group $rgName

az functionapp stop --name $functionappIomt --resource-group $rgName
try{
az functionapp deployment source config-zip --resource-group $rgName --name $functionappIomt --src "./artifacts/binaries/iomt_function_app.zip"	
}
catch{
az functionapp deployment source config-zip --resource-group $rgName --name $functionappIomt --src "./artifacts/binaries/iomt_function_app.zip"	
}
az functionapp start --name $functionappIomt --resource-group $rgName

az functionapp restart --name $functionappMongoData --resource-group $rgName
az functionapp restart --name $functionappIomt --resource-group $rgName

<#Start-Sleep -s 120
$FunctionApp = Get-AzWebApp -ResourceGroupName $rgName -Name $functionappMongoData
$FunctionKey = (Invoke-AzResourceAction -ResourceId "$($FunctionApp.Id)/functions/JsonProcessor" -Action listkeys -Force).default
$FunctionURL = "https://" + $FunctionApp.DefaultHostName + "/api/JsonProcessor?code=" + $FunctionKey
Invoke-RestMethod $FunctionURL -Method GET -Headers @{}
Start-Sleep -s 10 #>

#delete the mongo data uplaod function
<#az functionapp delete --name $functionappMongoData --resource-group $rgName
Remove-AzAppServicePlan -ResourceGroupName $rgName -Name $functionaspMongoData -f
Remove-AzStorageAccount -ResourceGroupName $rgName  -AccountName $functionstMongoData -f #>