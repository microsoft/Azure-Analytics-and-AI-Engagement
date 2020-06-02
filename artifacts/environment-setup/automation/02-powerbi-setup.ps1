Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

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
New-PowerBIReport -Path ".\artifacts\exports\powerbi\2. Billion Rows Demo.pbix" -Name "2-Billion Rows Demo.pbix" -ConflictAction CreateOrOverwrite -WorkspaceId $newPowerBIWorkSpace.id

# Invoke-PowerBIRestMethod -Url 'groups/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/datasets/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/tables/xxxxxx/rows' -Method Delete

Disconnect-PowerBIServiceAccount

