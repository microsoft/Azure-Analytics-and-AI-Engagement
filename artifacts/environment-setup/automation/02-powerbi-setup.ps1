$IsCloudLabs = Test-Path C:\LabFiles\AzureCreds.ps1;
$InformationPreference = "Continue"

if($IsCloudLabs){
    Remove-Module solliance-synapse-automation
    Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"
    $templatesPath = ".\artifacts\environment-setup\templates"

    . C:\LabFiles\AzureCreds.ps1

    $userName = $AzureUserName                                              # READ FROM FILE
    $password = $AzurePassword                                              # READ FROM FILE
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $clientId = $TokenGeneratorClientId       # READ FROM FILE
} else {
    az login

    Remove-Module solliance-synapse-automation
    Import-Module "..\solliance-synapse-automation"
    $templatesPath = "..\templates"

    #Different approach to run automation in Cloud Shell
    $subs = Get-AzSubscription | Select-Object -ExpandProperty Name
    if($subs.GetType().IsArray -and $subs.length -gt 1){
            $subOptions = [System.Collections.ArrayList]::new()
            for($subIdx=0; $subIdx -lt $subs.length; $subIdx++){
                    $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
                    $subOptions.Add($opt)
            }
            $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
            $selectedSubName = $subs[$selectedSubIdx]
            Write-Information "Selecting the $selectedSubName subscription"
            Select-AzSubscription -SubscriptionName $selectedSubName
    }
    
    $userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
    $sqlPassword = Read-Host -Prompt "Enter the SQL Administrator password you used in the deployment" -AsSecureString
    $sqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($sqlPassword))
}

if (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt) {
    Write-Host "MicrosoftPowerBIMgmt Module exists"
} else {
    Install-Module -Name MicrosoftPowerBIMgmt
}
if (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt.Profile) {
    Write-Host "MicrosoftPowerBIMgmt.Profile Module exists"
} else {
    Install-Module -Name 
}

Import-Module MicrosoftPowerBIMgmt
Import-Module MicrosoftPowerBIMgmt.Profile

# PowerBI Connection
Write-Information "Connecting to PowerBI Service"
if($IsCloudLabs){
    $credentialForPowerBI = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
    Connect-PowerBIServiceAccount -Credential $credentialForPowerBI
} else {
    Connect-PowerBIServiceAccount
}

Write-Information "Creating PowerBI Workspace"
$existingPowerBIWorkSpace = Get-PowerBIWorkspace -Filter "tolower(name) eq 'asa-exp'" 
if($existingPowerBIWorkSpace -eq $null){
    $newPowerBIWorkSpace = New-PowerBIWorkspace -Name "ASA-EXP"
} else {
    $newPowerBIWorkSpace = $existingPowerBIWorkSpace
}

Write-Information "Uploading PowerBI Reports"
if($IsCloudLabs){
    New-PowerBIReport -Path ".\artifacts\environment-setup\reports\1. CDP Vision Demo.pbix" -Name "1-CDP Vision Demo" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id
    New-PowerBIReport -Path ".\artifacts\environment-setup\reports\2. Billion Rows Demo.pbix" -Name "2-Billion Rows Demo.pbix" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id
    New-PowerBIReport -Path ".\artifacts\environment-setup\reports\(Phase 2) CDP Vision Demo v1.pbix" -Name "Phase 2 CDP Vision Demo.pbix" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id
} else {
    New-PowerBIReport -Path "Synapse-WWI/artifacts/environment-setup/reports/1. CDP Vision Demo.pbix" -Name "1-CDP Vision Demo" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id
    New-PowerBIReport -Path "Synapse-WWI/artifacts/environment-setup/reports/2. Billion Rows Demo.pbix" -Name "2-Billion Rows Demo.pbix" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id
    New-PowerBIReport -Path "Synapse-WWI/artifacts/environment-setup/reports/(Phase 2) CDP Vision Demo v1.pbix" -Name "Phase 2 CDP Vision Demo.pbix" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id 
}

# Synapse Linked Service for PowerBI

if($IsCloudLabs){
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
    Connect-AzAccount -Credential $cred | Out-Null

    $ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
    $global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
    $global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
    $global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"
} else {

}

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
    Synapse    = (Get-Date -Year 1)
    SynapseSQL = (Get-Date -Year 1)
    Management = (Get-Date -Year 1)
}

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*WWI-Lab*" -or $_.ResourceGroupName -like "*CDP-Demo*"}).ResourceGroupName
$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$global:logindomain = (Get-AzContext).Tenant.Id

$powerBIName = "asaexppowerbi$($uniqueId)"
$workspaceName = "asaexpworkspace$($uniqueId)"

Write-Information "Create PowerBI linked service $($keyVaultName)"

$result = Create-PowerBILinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $powerBIName -WorkspaceId $newPowerBIWorkSpace.id
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Setting PowerBI Database Connection"

$powerBIReports = [ordered]@{
    "2-Billion Rows Demo" = @{ 
            Category = "reports"
            Valid = $false
    }
    "Phase 2 CDP Vision Demo" = @{ 
            Category = "reports"
            Valid = $false
    }
}

$powerBIDataSetConnectionTemplate = Get-Content -Path "$($templatesPath)/powerbi_dataset_connection.json"

foreach ($powerBIReportName in $powerBIReports.Keys) {
    Write-Information "Setting database connection for $($powerBIReportName)"
    $foundId = (Get-PowerBIDataset -WorkspaceId $newPowerBIWorkSpace.id).where{( $_.Name -like $powerBIReportName )}.id
    $powerNIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#SERVER#", "asaexpworkspace$($uniqueId).sql.azuresynapse.net").Replace("#DATABASE#", "SQLPool01") |Out-String
    
    #https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/updatedatasources
    Invoke-PowerBIRestMethod -Url "groups/$($newPowerBIWorkSpace.id)/datasets/$($foundId)/Default.UpdateDatasources" -Method Post -Body $powerNIDataSetConnectionUpdateRequest
}

Disconnect-PowerBIServiceAccount