function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#if they have many subs...
$subs = Get-AzSubscription | Select-Object -ExpandProperty Name

if($subs.GetType().IsArray -and $subs.length -gt 1)
{
    $subOptions = [System.Collections.ArrayList]::new()
    for($subIdx=0; $subIdx -lt $subs.length; $subIdx++)
    {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
}

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$search_srch_retail_name = "srch-retail-product-$suffix";
#Search service 
Write-Host "-----------------Search service ---------------"
RefreshTokens

Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $search_srch_retail_name
$primaryAdminKey = $adminKeyPair.Primary

# Create Index
Write-Host  "------Index----"
try {
Get-ChildItem "./artifacts/search" -Filter fabrikam-fashion.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$($search_srch_retail_name).search.windows.net/indexes?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
    } catch {
        Write-Host "Resource already Exists !"
}
Start-Sleep -s 10

$headers = @{
'api-key' = $primaryAdminKey
'Content-Type' = 'application/json' 
'Accept' = 'application/json' }
$url = "https://$search_srch_retail_name.search.windows.net/indexes/fabrikam-fashion/docs/index?api-version=2021-04-30-Preview"
$body = Get-Content -Raw -Path ./artifacts/search/data.json
Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body
