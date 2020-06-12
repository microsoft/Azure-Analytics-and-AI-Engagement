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

$overallStateIsValid = $true

# PowerBI Connection
Write-Information "Connecting to PowerBI Service"
$credentialForPowerBI = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
Connect-PowerBIServiceAccount -Credential $credentialForPowerBI

Write-Information "Checking PowerBI Workspace"
$existingPowerBIWorkSpace = Get-PowerBIWorkspace -Filter "tolower(name) eq 'asa-exp'" 
if($existingPowerBIWorkSpace -eq $null){
    Write-Warning "PowerBI Workspace Not Found"
    $overallStateIsValid = $false
} else {
    $newPowerBIWorkSpace = $existingPowerBIWorkSpace
    Write-Warning "PowerBI Workspace Found"
}

$powerBIReports = [ordered]@{
    "1-CDP Vision Demo" = @{ 
            Category = "reports"
            Valid = $false
    }
    "2-Billion Rows Demo" = @{ 
            Category = "reports"
            Valid = $false
    }
    "Phase 2 CDP Vision Demo" = @{ 
            Category = "reports"
            Valid = $false
    }
}

if($overallStateIsValid -eq $true) {
    $allPowerBIReports= Get-PowerBIReport -WorkspaceId $newPowerBIWorkSpace.id

    foreach ($powerBIReportName in $powerBIReports.Keys) {
        Write-Information "Checking $($powerBIReportName) in $($powerBIReports[$powerBIReportName]["Category"])"
    
        foreach ($powerBIReportAvailable in $allPowerBIReports) {
            if($powerBIReportAvailable.Name -eq $powerBIReportName) {
                $powerBIReports[$powerBIReportName]["Valid"] = $true
                Write-Information "OK"
            }
        }
        if($powerBIReports[$powerBIReportName]["Valid"] -eq $false){
            Write-Warning "PowerBI Report named '$($powerBIReportName)' Not Found"
            $overallStateIsValid = $false;
        }
    }
} else {
    Write-Warning "Report validations did not execute. Reason: Workspace Not Found"
}

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

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*WWI-Lab*" -or $_.ResourceGroupName -like "*CDP-Demo*"}).ResourceGroupName
$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$global:logindomain = (Get-AzContext).Tenant.Id

$powerBIName = "asaexppowerbi$($uniqueId)"
$workspaceName = "asaexpworkspace$($uniqueId)"

$asaArtifacts = [ordered]@{
    "$($powerBIName)" = @{
            Category = "linkedServices"
            Valid = $false
    }
}

foreach ($asaArtifactName in $asaArtifacts.Keys) {
    try {
            Write-Information "Checking $($asaArtifactName) in $($asaArtifacts[$asaArtifactName]["Category"])"
            $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName]["Category"] -Name $asaArtifactName
            $asaArtifacts[$asaArtifactName]["Valid"] = $true
            Write-Information "OK"
    }
    catch { 
            Write-Warning "Not found!"
            $overallStateIsValid = $false
    }
}

# Checking data source settings for report '2-Billion Rows Demo'
if($newPowerBIWorkSpace -eq $null) {
    $overallStateIsValid = $false
    Write-Warning "Data source checks for reports did not execute. Reason: PowerBI Workspace not found."
} else {
    $foundId = (Get-PowerBIDataset -WorkspaceId $newPowerBIWorkSpace.id).where{( $_.Name -like '2-Billion Rows Demo' )}.id
    $foundDataSources =(Invoke-PowerBIRestMethod -Url "groups/$($newPowerBIWorkSpace.id)/datasets/$($foundId)/datasources" -Method Get ) | ConvertFrom-Json
    
    if($foundDataSources.value.connectionDetails.server -eq "asaexpworkspace$($uniqueId).sql.azuresynapse.net") {
        Write-Information "Data source for report '2-Billion Rows Demo' is set."
    } else {
        Write-Warning "Data source for report '2-Billion Rows Demo' is not set."
        $overallStateIsValid = $false
    }
}

Disconnect-PowerBIServiceAccount

if ($overallStateIsValid -eq $true) {
    Write-Information "Validation Passed"
} else {
    Write-Warning "Validation Failed - see log output"
}
