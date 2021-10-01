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

#will be done as part of the cloud shell start - README

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

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$amlworkspacename = "amlws-$suffix"
$cpuShell = "cpuShell$init"
	
Write-Host  "-----------------AML Workspace ---------------"
Add-Content log.txt "-----------------AML Workspace ---------------"
RefreshTokens
#AML Workspace
#create aml workspace
az extension add -n azure-cli-ml

az ml workspace create -w $amlworkspacename -g $rgName

#attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName -e aml

#create and delete a compute instance to get the code folder created in default store
az ml computetarget create computeinstance -n $cpuShell -s "STANDARD_DS2_V2" -v
#az ml computetarget delete -n $cpuShell -v

#get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

#get fileshare and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Context $storageAcct.Context 
$shareName = $share[0].Name

#create Users folder ( it wont be there unless we launch the workspace in UI)
New-AzStorageDirectory -Context $storageAcct.Context -ShareName $shareName -Path "Users"

#copy notebooks to ml workspace
$notebooks=Get-ChildItem "../artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "GlobalVariables")
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path="/Users/"+$notebook.BaseName+".py"
	}
	else
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}

$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
$shareName = $share.Name
$notebooks=Get-ChildItem "../artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "GlobalVariables")
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path="/Users/"+$notebook.BaseName+".py"
	}
	else
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}
#create aks compute
#az ml computetarget create aks --name  "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName
az ml computetarget delete -n $cpuShell -v
