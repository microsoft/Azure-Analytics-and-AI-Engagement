# Azure Synapse Manufacturing Setup Guide

## Requirements

1. An Azure Account with the ability to create an Azure Synapse Workspace
2. A PowerBI Pro or Premium account to host Power BI reports.

## Before starting

### Task 1: Create a resource group in Azure

1. Log into the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, select the **+ Create a resource** tile.

    ![A portion of the Azure Portal home screen is displayed with the + Create a resource tile highlighted.](../CDP-Retail/media/bhol_createaresource.png)

3. In the **Search the Marketplace** text box, type **Resource group** and press the **Enter** key.

    ![On the new resource screen Resource group is entered as a search term.](../CDP-Retail/media/bhol_searchmarketplaceresourcegroup.png)

4. Select the **Create** button on the **Resource group** overview page.

5. On the **Create a resource group** screen, select your desired Subscription and Region. For Resource group, enter **Synapse-WWI-Lab**, then select the **Review + Create** button.

    ![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](../CDP-Retail/media/bhol_resourcegroupform.png)

6. Select the **Create** button once validation has passed.

### Task 2: Deploy the ARM Template

1. Deploy the Azure resources through the following Azure ARM template (press the button below):

    <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FAzure-Analytics-and-AI-Engagement%2Freal-time%2F
Manufacturing%2Fautomation%2FmainTemplate-shell.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png" /></a>

2. On the **Custom deployment** form, select your desired subscription.
3. Enter a resource group name.
4. Provide a **Unique Suffix**.
5. Enter the target PowerBI Workspace.  You can get this by browsing to https://app.powerbi.com/, selecting a workspace and then copying the id in the address url.

    ![A portion of the Power BI workspace to highlight the workspace ID.](media/PBI-Workspace-ID-Screen2.png)

6. Finally, provide a strong **SQL Administrator Login Password**.

    ![The Custom deployment form is displayed with example data populated.](media/Custom-Template-Deployment-Screen1.png)
  
    > **Important**: The `location` field under 'Settings' will list the Azure regions where Azure Synapse Analytics (Preview) is available as of June 2020. This will help you find a region where the service is available without being limited to where the resource group is defined.

7. Check the **I agree to the terms and conditions stated above**
8. Select the **Purchase** button.

> **NOTE** The provisioning of your deployment resources will take approximately 20 minutes.

9. Confirm that the deployment has succeeded before proceeding to the next step
    
    ![A portion of the Azure Portal to confirm that the deployment has succeeded.](media/Template-Deployment-Done-Screen6.png)

### Task 3: Run the script in Azure Cloud Shell 

1. Open the Azure Portal
2. In the Azure Portal, open the Azure Cloud Shell by selecting its icon from the right side of the top toolbar.

    ![A portion of the Azure Portal taskbar is displayed with the Cloud Shell icon highlighted.](media/azure-cloudshell-menu-screen4.png)

    > **Note**: If you are prompted to choose a shell, select **Powershell**, and if asked to create a storage account for the Cloud Shell, agree to have it created.
    
    ![Cloud Shell storage account creation screen is shown. Create storage button is selected.](media/cloud-shell-storage.png)

4. From the shell, run the following command to pull the demo repository:

    ```PowerShell
    git clone -b real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git MfgAI
    ```
    
    ![Git clone command to pull down the demo repository](media/Git-Clone-Command-Screen11.png)
    
    > **Note**: When executing the script below, it is important to let the scripts run to completion. Some tasks may take longer than others to run. When a script completes     execution, you will be returned to a command prompt. The total runtime of all steps in this task will take approximately 15 minutes.

5. Run the `manufacturingSetup-shell` script

    ```PowerShell
    cd 'MfgAI/Manufacturing/automation'
    ./manufacturingSetup-shell.ps1
    ```
    
6. Click on the link provided in the shell console. It will open a new browser window, provide the code to get authenticated

![Authentication link and device code](media/Device-Authentication-Screen7.png)

![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

7. You will get another set of code to authenticate the device

![Authentication link and device code](media/Device-Authentication-Screen7a.png)

![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

8. You will now be prompted to enter the resource group name in the cloud shell 

![Enter the resource group name](media/RG-Name-Screen10.png)

9. Pass the final set of authentication codes provided on the cloud shell 

![Authentication link and device code](media/Device-Authentication-Screen7b.png)

![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

    > **Note**: Make sure to provide the device code in time before it gets expired and let the script run till completion.

### Task 4: Configuration

1. TODO
