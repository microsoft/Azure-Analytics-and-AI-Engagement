#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

$rgName = read-host "Enter the resource Group Name";
$uniqueId = (Get-AzResource -ResourceGroupName $rgName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$synapseWorkspaceName = "asaexpworkspace$($uniqueId)"
$sqlPoolName = "SQLPool01"
$asaName="TweetsASA"


$title    = 'Choices'
$question = 'What would you like to do with the environment?'
$choices  = '&Pause', '&Resume'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if($decision -eq 0)
{
install-module Az.StreamAnalytics -f
#stop ASA
write-host "Stopping ASA jobs"
Stop-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asaName 
write-host "Stopping SQL pool"
install-module Az.Synapse -f
#stop SQL
az synapse sql pool pause --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName
write-host "Operation successfull"
}

else
{
#start ASA
write-host "Starting ASA jobs"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asaName -OutputStartMode 'JobStartTime'

#Resume SQL
write-host "Starting Sql Pool"
az synapse sql pool resume --name $SQLPoolName --resource-group $rgName --workspace-name $synapseWorkspaceName

write-host "Operation successfull"
}
