$rgName = Read-Host "Enter the Resource Group Name to be deleted"
$subs = Get-AzSubscription | Select-Object -ExpandProperty Name

if ($subs.Count -gt 1) {
    $subOptions = @()
    for ($subIdx = 0; $subIdx -lt $subs.Count; $subIdx++) {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription"
        $subOptions += $opt
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice', $subOptions, 0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName | Out-Null
    az account set --subscription $selectedSubName | Out-Null
}

az group delete --no-wait --name $rgName
Write-Host "Deletion Completed"
