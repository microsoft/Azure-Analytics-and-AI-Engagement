Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

$templatesPath = ".\artifacts\environment-setup\templates"

# TODO: Keep all required configuration in C:\LabFiles\AzureCreds.ps1 file
. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                                              # READ FROM FILE
$password = $AzurePassword                                              # READ FROM FILE
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

#Install-Module -Name MicrosoftPowerBIMgmt
#Install-Module -Name MicrosoftPowerBIMgmt.Profile

Import-Module MicrosoftPowerBIMgmt
Import-Module MicrosoftPowerBIMgmt.Profile

# PowerBI Connection
Write-Information "Connecting to PowerBI Service"
$credentialForPowerBI = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
Connect-PowerBIServiceAccount -Credential $credentialForPowerBI

Write-Information "Creating PowerBI Workspace"
$existingPowerBIWorkSpace = Get-PowerBIWorkspace -Filter "tolower(name) eq 'asa-exp'" 
if($existingPowerBIWorkSpace -eq $null){
    $newPowerBIWorkSpace = New-PowerBIWorkspace -Name "ASA-EXP"
} else {
    $newPowerBIWorkSpace = $existingPowerBIWorkSpace
}

Write-Information "Uploading PowerBI Reports"
New-PowerBIReport -Path ".\artifacts\exports\powerbi\1. CDP Vision Demo.pbix" -Name "1-CDP Vision Demo" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id
$newReport = New-PowerBIReport -Path ".\artifacts\exports\powerbi\2. Billion Rows Demo.pbix" -Name "2-Billion Rows Demo.pbix" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id

# Invoke-PowerBIRestMethod -Url 'groups/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/datasets/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/tables/xxxxxx/rows' -Method Delete

Disconnect-PowerBIServiceAccount

# Synapse Linked Service for PowerBI
$clientId = $TokenGeneratorClientId       # READ FROM FILE

$ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
$global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
$global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
$global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
    Synapse    = (Get-Date -Year 1)
    SynapseSQL = (Get-Date -Year 1)
    Management = (Get-Date -Year 1)
}

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*WWI-Lab*" }).ResourceGroupName
$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$global:logindomain = (Get-AzContext).Tenant.Id

$powerBIName = "asaexppowerbi$($uniqueId)"
$workspaceName = "asaexpworkspace$($uniqueId)"

Write-Information "Create PowerBI linked service $($keyVaultName)"

$result = Create-PowerBILinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $powerBIName -WorkspaceId $newPowerBIWorkSpace.id
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Setting PowerBI Database Connection"

$foundId = (Get-PowerBIDataset -WorkspaceId $newPowerBIWorkSpace.id).where{( $_.Name -like '2-Billion Rows Demo' )}.id

$powerBIDataSetConnectionTemplate = Get-Content -Path "$($templatesPath)/powerbi_dataset_connection.json"
$powerNIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#SERVER#", "asaexpworkspace$($uniqueId).sql.azuresynapse.net").Replace("#DATABASE#", "SQLPool01") |Out-String

#https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/updatedatasources
Invoke-PowerBIRestMethod -Url "groups/$($newPowerBIWorkSpace.id)/datasets/$($foundId)/Default.UpdateDatasources" -Method Post -Body $powerNIDataSetConnectionUpdateRequest
