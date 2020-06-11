![](https://github.com/Microsoft/MCW-Template-Cloud-Workshop/raw/master/Media/ms-cloud-workshop.png "Microsoft Cloud Workshops")

<div class="MCWHeader1">
Azure Synapse Analytics Wide World Importers (WWI) Demo, Lab and POC
</div>

<div class="MCWHeader2">
Before the hands-on lab setup guide
</div>

<div class="MCWHeader3">
May 2020
</div>

Information in this document, including URL and other Internet Web site references, is subject to change without notice. Unless otherwise noted, the example companies, organizations, products, domain names, e-mail addresses, logos, people, places, and events depicted herein are fictitious, and no association with any real company, organization, product, domain name, e-mail address, logo, person, place or event is intended or should be inferred. Complying with all applicable copyright laws is the responsibility of the user. Without limiting the rights under copyright, no part of this document may be reproduced, stored in or introduced into a retrieval system, or transmitted in any form or by any means (electronic, mechanical, photocopying, recording, or otherwise), or for any purpose, without the express written permission of Microsoft Corporation.

Microsoft may have patents, patent applications, trademarks, copyrights, or other intellectual property rights covering subject matter in this document. Except as expressly provided in any written license agreement from Microsoft, the furnishing of this document does not give you any license to these patents, trademarks, copyrights, or other intellectual property.

The names of manufacturers, products, or URLs are provided for informational purposes only and Microsoft makes no representations and warranties, either expressed, implied, or statutory, regarding these manufacturers or the use of the products with any Microsoft technologies. The inclusion of a manufacturer or product does not imply endorsement of Microsoft of the manufacturer or product. Links may be provided to third party sites. Such sites are not under the control of Microsoft and Microsoft is not responsible for the contents of any linked site or any link contained in a linked site, or any changes or updates to such sites. Microsoft is not responsible for webcasting or any other form of transmission received from any linked site. Microsoft is providing these links to you only as a convenience, and the inclusion of any link does not imply endorsement of Microsoft of the site or the products contained therein.

© 2020 Microsoft Corporation. All rights reserved.

Microsoft and the trademarks listed at <https://www.microsoft.com/en-us/legal/intellectualproperty/Trademarks/Usage/General.aspx> are trademarks of the Microsoft group of companies. All other trademarks are property of their respective owners.

**Contents**

<!-- TOC -->

- [Azure Synapse Analytics WWI lab setup guide](#azure-synapse-analytics-wwi-lab-setup-guide)
  - [Requirements](#requirements)
  - [Before the hands-on lab](#before-the-hands-on-lab)
    - [Task 1: Create a resource group in Azure](#task-1-create-a-resource-group-in-azure)
    - [Task 2: Create Azure Synapse Analytics workspace](#task-2-create-azure-synapse-analytics-workspace)
    - [Task 3: Download lab artifacts](#task-3-download-lab-artifacts)
    - [Task 4: Establish a user context](#task-4-establish-a-user-context)
    - [Task 5: Run environment setup PowerShell script](#task-5-run-environment-setup-powershell-script)

<!-- /TOC -->

# Azure Synapse Analytics WWI lab setup guide

## Requirements

1. An Azure Account with the ability to create an Azure Synapse Workspace
2. A PowerBI Pro or Premium account to host Power BI reports.

## Before the hands-on lab

### Task 1: Create a resource group in Azure

1. Log into the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, select the **+ Create a resource** tile.

    ![A portion of the Azure Portal home screen is displayed with the + Create a resource tile highlighted.](media/bhol_createaresource.png)

3. In the **Search the Marketplace** text box, type **Resource group** and press the **Enter** key.

    ![On the new resource screen Resource group is entered as a search term.](media/bhol_searchmarketplaceresourcegroup.png)

4. Select the **Create** button on the **Resource group** overview page.

5. On the **Create a resource group** screen, select your desired Subscription and Region. For Resource group, enter **Synapse-WWI-Lab**, then select the **Review + Create** button.

    ![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](media/bhol_resourcegroupform.png)

6. Select the **Create** button once validation has passed.

### Task 2: Create Azure Synapse Analytics workspace

1. Deploy the workspace through the following Azure ARM template (press the button below):

    <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsolliancenet%2Fazure-synapse-wwi-lab%2Fmaster%2Fartifacts%2Fenvironment-setup%2Fautomation%2F00-asa-workspace-core.json%3Ftoken%3DAAWYR62FS2TMH3GYFSFQE2263X2AM" target="_blank"><img src="http://azuredeploy.net/deploybutton.png" /></a>

2. On the **Custom deployment** form, select your desired subscription and select **Synapse-WWI-Lab** for the **Resource group**. Also provide a **Unique Suffix**. Finally, provide a strong **SQL Administrator Login Password**. Remember this password value, you'll be needing it!

    ![The Custom deployment form is displayed with example data populated.](media/bhol_customdeploymentform.png)
  
    > **Important**: The `location` field under 'Settings' will list the Azure regions where Azure Synapse Analytics (Preview) is available as of June 2020. This will help you find a region where the service is available without being limited to where the resource group is defined.

3. Check the **I agree to the terms and conditions stated above**, then select the **Purchase** button. The provisioning of your deployment resources will take approximately 10 minutes.

    > **Note**: You may experience a deployment step failing in regards to Role Assignment. This error may safely be ignored.

### Task 3: Download lab artifacts

1. In the Azure Portal, open the Azure Cloud Shell by selecting its icon from the right side of the top toolbar.

    ![A portion of the Azure Portal taskbar is displayed with the Cloud Shell icon highlighted.](media/bhol_azurecloudshellmenu.png)

    > **Note**: If you are prompted to create a storage account for the Cloud Shell, agree to have it created.

2. In the Cloud Shell window, enter the following command to clone the repository files.

    ```PowerShell
    git clone https://github.com/solliancenet/azure-synapse-wwi-lab.git synapse-wwi
    ```
    
    ![The Azure Portal with Cloud shell opened. Git clone command is typed into the cloud shell terminal ready for execution.](media/cloud-shell-git-clone.png)

3. Keep the Cloud Shell open.

### Task 4: Establish a user context

1. In the Cloud Shell, execute the following command:

    ```cli
    az login
    ```

2. A message will be displayed asking you to open a new tab in your web browser, navigate to [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and enter the code you have been given for authentication.

   ![A message is displayed indicating to enter an authentication code on the device login page.](media/bhol_devicelogin.png)

   ![A dialog is shown requesting the entry of a code.](media/bhol_clicodescreen.png)

3. Once complete, you may close the tab from the previous step and return to the Cloud Shell.

   ![The JSON result showing the subscription details.](media/shell-login-result.png)

### Task 5: Run environment setup PowerShell script

When executing the script below, it is important to let the scripts run to completion. Some tasks may take longer than others to run. When a script completes execution, you will be returned to a command prompt. The total runtime of all steps in this task will take approximately 10 minutes.

1. In the Cloud Shell, change the current directory to the **automation** folder of the cloned repository by executing the following:

    ```PowerShell
    cd './synapse-wwi/artifacts/environment-setup/automation'
    ```

2. Execute the **01-environment-setup.ps1** script by executing the following command:

    ```PowerShell
    ./01-environment-setup.ps1
    ```

    You may be prompted to enter the name of your desired Azure Subscription. You can copy and paste the value from the list to select one.   

    You will also be prompted for the following information for this script:

    | Prompt |
    |--------|
    | Enter the SQL Administrator password you used in the deployment |

    ![The Azure Cloud Shell window is displayed with a sample of the output from the preceding command.](media/bhol_sampleshelloutput.png)

3. Sign in into the [Power BI Portal](https://powerbi.microsoft.com/en-us/) using your Azure credentials.

4. From the hamburger menu select **Workspaces** to access the list of workspaces available to you. Select the workspace named `asa-exp{your-unique-id}`.

![The workspaces button from the hamburger menu is selected to list workspaces available. The workspace named asa-exp followed by your unique suffix is selected.](media/powerbi_workspace_selection.png)

5. Select the **Settings** icon from the top right bar, and select **Settings** again to navigate to the settings page.

![The settings button on the Power BI portal clicked and the Settings selection on the context menu selected.](media/powerbi_settings_menu.png)

6. Select **datasets** tab to access the list of datasets available. Then select `2-Billion Rows Demo` dataset to access its settings. From the settings page open **Data source credentials** and select **Edit credentials**.

![The datasets tab is selected. From the list of datasets 2-Billion Rows Demo is selected. Edit credentials will be selected next. ](media/powerbi_datasource_credentials.png)

7. Select **OAuth2** for the **Authentication method** and select **Sign In** to complete the process.

![From the list of authentication methods OAuth2 is picked. The sign in button is selected. ](media/powerbi_datasource_credentials-update.png)

You should follow all steps provided *before* performing proceeding to the following activities.
