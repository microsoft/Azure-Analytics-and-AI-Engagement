$rgName = read-host "Enter the resource Group Name to be deleted";

az group delete --no-wait --name $rgName
Write-Host "Deletion Completed"