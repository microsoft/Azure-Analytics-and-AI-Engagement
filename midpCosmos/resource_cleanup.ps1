$rgName = read-host "Enter the resource Group Name to be deleted";
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

az group delete --no-wait --name $rgName
Write-Host "Deletion Completed"