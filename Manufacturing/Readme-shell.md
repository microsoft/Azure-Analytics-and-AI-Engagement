# Azure Synapse Manufacturing Setup Guide


**Contents**

<!-- TOC -->

- [Azure Synapse Analytics WWI setup guide](#azure-synapse-analytics-wwi-setup-guide)
  - [Requirements](#requirements)
  - [Before Starting](#before-starting)
    - [Task 1: Create a resource group in Azure](#task-1-create-a-resource-group-in-azure)
    - [Task 2: Power BI workspace creation](#task-2-power-bi-workspace-creation)
    - [Task 3: Deploy the ARM Template](#task-3-deploy-the-arm-template)
    - [Task 4: Run the Cloud Shell](#task-4-run-the-cloud-shell)
    - [Task 5: Power BI Dashboard creation ](#task-5-power-bi-dashboard-creation)
    - [Task 6: Working with Power BI to create real-time reports](#task-6-working-with-power-bi-to-create-real-time-reports)
    
<!-- /TOC -->

## Requirements

1. An Azure Account with the ability to create an Azure Synapse Workspace.
2. A Power BI Pro or Premium account to host Power BI reports.
3. Please note that you can run only one deployment at a given point of time and need to wait for the completion. You should not run multiple deployments in parallel as that will cause deployment failures.
4. Please ensure selection of correct region where desired Azure Services are available. In case certain services are not available, deployment may fail. [Azure Services Global Availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=all) for understanding target services availablity.
5. Please ensure that in environment code, you don't use any special characters. Use environment code as only lowercase alphabets, and unique in your environment.
6. Please ensure that you select the right Resource Group Name. The name we have given here is a sample name and you may need to customize the same if any resource group with same name already exists in your Subscription.

> **Note:** Please log in to Azure and Power BI using the same credentials.

## Before starting

### Task 1: Create a resource group in Azure

1. **Log into** the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, **select** the '+ Create a resource' tile.

    ![A portion of the Azure Portal home screen is displayed with the + Create a resource tile highlighted.](media/create-a-resource.png)

3. In the **Search the Marketplace** text box, type 'Resource Group' and **press** the Enter key.

    ![On the new resource screen Resource group is entered as a search term.](../CDP-Retail/media/bhol_searchmarketplaceresourcegroup.png)

4. **Select** the create button on the 'Resource Group' overview page.

	![A portion of the Azure Portal home screen is displayed with Create Resource Group tile](media/create-resource-group.png)
	
5. On the 'Create a resource group' screen, **select** your desired Subscription. For Resource group, **type** 'Synapse-WWI-Lab'. **Select** your desired Region. **Click** the 'Review + Create' button.

    ![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](media/resourcegroup-form.png)

6. Click the **Create** button once all entries have been validated.

    ![Create Resource Group with the final validation passed.](media/create-rg-validated.png)

### Task 2: Power BI Workspace creation

1. **Open** Power BI Services in a new tab using the following link:  https://app.powerbi.com/

3. **Sign in**, to your Power BI account using Power BI Pro account.

> **Note:** Please use the same credentials for Power BI which you will be using for Azure Account.

![Sign in to Power BI.](media/PowerBI-Services-SignIn.png)

4. **Click** on 'Workspaces'.

5. Then **click** on the 'Create a workspace’ tab.

> **Note:** Please create a Workspace by the name 'Engagement Accelerators – Manufacturing'.

![Create Power BI Workspace.](media/Create-Workspace.png)

6. **Copy** the Workspace GUID or ID. You can get this by browsing to https://app.powerbi.com/, selecting the workspace, and then copying the GUID from the address URL.
> **Note:** This workspace ID will be used during ARM template deployment.

![Copy the workspace id.](media/Workspace-ID.png)

### Task 3: Deploy the ARM Template

1. On the Readme file, **right-click** on 'Deploy to Azure' button and open the link in a new tab to **deploy** the Azure resources that you created in [Task 1](#task-1-create-a-resource-group-in-azure) with an Azure ARM Template

    <a href='https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FAzure-Analytics-and-AI-Engagement%2Freal-time%2FManufacturing%2Fautomation%2FmainTemplate-shell.json' target='_blank'><img src='http://azuredeploy.net/deploybutton.png' /></a>

2. On the Custom deployment form, **select** your desired Subscription.
3. **Type** the resource group name 'Synapse-WWI-Lab' created in [Task 1](#task-1-create-a-resource-group-in-azure).
4. **Select** Region where you want to deploy.
5. **Provide** Environment code.
6. **Enter** a strong SQL Administrator Login Password and set this aside for later use.
7. **Enter** the Power BI Workspace ID created in [Task 2](#task-2-power-bi-workspace-creation) in the 'Pbi_workspace_id' field.
8. **Select** Location from the dropdown. Please ensure that this is the same location you selected in Step #4 above.
9. **Click** 'Review + Create' button.
> **NOTE** The provisioning of your deployment resources will take approximately 10-15 minutes.

   ![The Custom deployment form is displayed with example data populated.](media/Custom-Template-Deployment-Screen1.png)

10. **Click** the 'Create' button once the template has been validated.

   ![Creating the template after validation.](media/template-validated-create.png)

11. **Stay** on the same page and wait for the deployment to complete.
    
    ![A portion of the Azure Portal to confirm that the deployment is in progress.](media/template-deployment-progress.png)
    
12. **Select** 'Go to resource group' button once your deployment is complete.

    ![A portion of the Azure Portal to confirm that the deployment is in progress.](media/Template-Deployment-Done-Screen6.png)
    
### Task 4: Run the Cloud Shell 

1. In the 'Resource group' section, **open** the Azure Cloud Shell by selecting its icon from the top toolbar.

    ![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/azure-cloudshell-menu-screen4.png)

    > **Note**: If you are prompted to choose a shell, **select** PowerShell, and if asked to **create** a 'storage account' for the Azure Cloud Shell, agree to have it created.
    
    ![Azure Cloud Shell storage account creation screen is shown. Create storage button is selected.](media/cloud-shell-storage.png)

2. In the Azure Cloud Shell window, **enter** the following command to clone the repository files.

    ```PowerShell
    git clone -b real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git MfgAI
    ```
    
    ![Git clone command to pull down the demo repository](media/Git-Clone-Command-Screen11.png)
    
    > **Note**: When executing the script below, it is important to let the scripts run to completion. Some tasks may take longer than others to run. When a script completes     execution, you will be returned to PowerShell prompt. The total runtime of all steps in this task will take approximately 15 minutes.

3. Execute the `manufacturingSetup-shell.ps1` script by executing the following commands:

    ```PowerShell
    cd 'MfgAI/Manufacturing/automation'
    ./manufacturingSetup-shell.ps1
    ```
  
     ![Commands to run the PowerShell script](media/executing-shell-script.png)
  
4. From the Azure Cloud Shell, **Copy** the Authentication Code and **copy** link shown (https://microsoft.com/devicelogin). Open this link in new tab in your browser. **Paste** the code the you copied earlier on the browser screen and **press** 'Enter'.

     ![Authentication link and device code](media/Device-Authentication-Screen7.png)

     ![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

5. **Select** the same user to authenticate which you used for signing in to the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

     ![Select the user account which you want to authenticate.](media/pick-account-to-login.png)

6. **Close** the browser tab and navigate back to the 'Resource group' window.

7. You will get another code to authenticate Azure PowerShell script for creating reports in Power BI. **Copy** the code and **copy** the link provided in the shell (https://microsoft.com/devicelogin). Open this link in your browser. **Enter** the code the you copied from the shell and press Enter.

     ![Authentication link and device code](media/Device-Authentication-Screen7a.png)

     ![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

8. Again **select** the same user to authenticate which you used for signing in to the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

     ![Select the user account which you want to authenticate.](media/pick-account-to-login.png)

9. **Close** the browser tab and navigate back to the 'Resource group' window.

10. While you are waiting for processes to get completed in Azure Cloud Shell, you'll be asked for entering code thrice (Please see Step #4 above). This is necessary for performing installation of various Azure Services and preloading content in Synapse SQL Pool tables.

> **Note**: You may be prompted to choose a subscription after the above mentioned step in case you have multiple subscriptions associated with your account. 

11. You will now be prompted to enter the resource group name in the Azure Cloud Shell. Enter the name of the resource group that you created in [Task 1](#task-1-create-a-resource-group-in-azure) above (Synapse-WWI-Lab).

     ![Enter the resource group name](media/RG-Name-Screen10.png)

12. You will be asked for Security code once again, as was in Step #4 above. Please follow the same procedure as done in Step #4.

     ![Authentication link and device code](media/Device-Authentication-Screen7b.png)

     ![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

13. Once again, **select** the same user to authenticate which you used for signing in to the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

     ![Select the user account which you want to authenticate.](media/pick-account-to-login.png)

14. **Close** the browser tab and navigate back to the 'Resource group' window.

 > **Note**: Make sure to provide the device code before it expires and let the script run till completion.

### Task 5: Power BI Dashboard creation

1. **Open** Power BI Services in a new tab using following link https://app.powerbi.com/

2. **Sign in** to Power BI account using 'Power BI Pro account'.

> **Note**: Please use the same credentials for Power BI that you used for 'Azure ARM + PowerShell' deployment.

![Sign in to Power BI Services.](media/PowerBI-Services-SignIn.png)

3. Assuming [Task 4](#task-4-run-the-cloud-shell) got completed successfully and the template has been deployed, you will be able to see a set of reports in the reports tab of Power BI, real-time datasets in dataset tab.
The image below shows the Reports tab in Power BI. We can then create a Power BI dashboard by pinning visuals from these reports.

> **Note:** A Dashboard is a collection of tiles/visualization which are pinned from different reports to a single page.

![Screenshot to view the reports tab.](media/Reports-Tab.png)

To **authenticate** the Power BI reports to access the datasources:

4. **Click** the 'Settings' icon on top right-side corner.

5. **Select** 'Settings'.

![Authenticate Power BI Reports.](media/Authenticate-PowerBI.png)

6. **Go to** 'Datasets' tab.

![Go to Datasets.](media/Goto-DataSets.png)

7. **Select** 'Campaign – Option C' Report.
8. **Expand** Data source credentials.
9. **Click** Edit credentials.

![Select Campaign.](media/Select-Campaign.png)

10. The 'Configure Campaign - Option C' dialogue box will pop up.
11. **Enter** Username as 'ManufacturingUser'.
12. **Enter** the same password which was used for Azure deployment.
13. **Click** Sign in.


![Configure Campaign.](media/Configure-Campaign.png)


**Follow these steps to create the Power BI dashboard:**

14. **Select** the workspace 'Engagement Accelerators-Manufacturing'.

![Select Power BI workspace.](media/Selecting-PowerBI-Workspace.png)

15. **Click** on '+Create' button on the top-left navigation bar.
16. **Select** the 'Dashboard' option from the drop-down menu.

![Create Dashboard.](media/Create-Dashboard.png)

17. **Name** the dashboard 'Engagement Accelerators Dashboard' and **click** “create”.
18. This new Dashboard will appear in the Dashboard section (of the Power BI workspace).

![Create Dashboard further steps.](media/Create-Dashboard1.png)

**Do the following to pin visuals to the dashboard you just created:**

19. **Click** on the 'Reports' section/tab.

![Check the reports tab.](media/Reports-Tab1.png)

20. In the 'Reports' section, there will be a list of all the published reports.
21. **Select/Click** on 'Campaign - Option C' report.

![Browse the reports created.](media/Campaign-Reports.png)

22. On the 'Campaign – Option C' report page, **select** the 'Revenue Vs Target' visual and **click** the pin icon.

![Pin visualization on the dashboard.](media/Pin-Visualization.png)

23. **Select** 'Existing dashboard' radio button.
24. **From** 'select existing dashboard' dropdown, **select** 'Engagement Accelerators Dashboard'.
25. **Click** 'Pin'.
26. The visual will be pinned and visible on the dashboard.
27. Similarly, different visuals from different reports can be pinned to the same dashboard.

![Further steps to pin visualization on the dashboard.](media/Pin-To-Dashboard.png)

28. To pin any image on the dashboard, **select** the report 'Dashboard Images' which has images on it from the reports section.

![Further steps to pin visualization on the dashboard.](media/Dashboard-Images.png)

29. In the Dashboard Images report, **select** any image and then **click** on the pin icon.

![Further steps to pin visualization on the dashboard.](media/Pin-Images.png)

30. **Select** Existing Dashboard radio button and select the 'Engagement Accelerators' dashboard. 
31. **Click** on Pin.
32. The image will be pinned and visible on the Dashboard.
33. Similarly, more images can be pinned to this Dashboard by repeating this process.

![Further steps to pin visualization on the dashboard.](media/Pin-To-Dashboard1.png)

34. To view to the pinned visuals, **click** on the 'Dashboards' section.
35. **Select** 'Engagement Accelerators Dashboard'. This will launch the Dashboard, and you can view the pinned visuals on it.

![Further steps to pin visualization on the dashboard.](media/Refer-Visuals.png)

36. **Refer** the screenshot of the sample Dashboard below and pin the visuals to replicate the following look and feel.

![Further steps to pin visualization on the dashboard.](media/Dashboard1.png)

37. Follow the same procedure to pin the 'Predictive maintenance and Safety Analytics' pillar tiles to the Dashboard using the 'anomaly detection with images' report. See steps #29 to #36 above.

![Further steps to pin visualization on the dashboard.](media/Dashboard2.png)

38. We can achieve the look of the Dashboard below by pining visuals and images from different reports to the same Dashboard (you can also tweak with different elements such as backgrounds and themes).

> **Note:** Real-time reports will not be deployed as part of the ARM Template deployment. For that we need to create real-time reports [(See Task 6)](#task-6-working-with-power-bi-to-create-real-time-reports).

![Further steps to pin visualization on the dashboard.](media/Dashboard3.png)


### Task 6: Working with Power BI to create real-time reports

'Racing Cars' and 'Milling canning' datasets will be automatically created when Azure Stream Analytics jobs start sending data into Power BI services.
 Once the Dataset has been created in the Power BI workspace, (by Azure Cloud Shell commands executed in [Task 3](#task-3-deploy-the-arm-template) above) follow the next steps to create the Power BI report 'Racing Cars- A'.

1. **Click** on '+Create' button present on the top navigation bar.
2. **Select** 'Report' option from the drop-down menu.

!['Report' option from the drop-down menu.](media/report_option.png)

3. **Enter** 'Racing' in the search bar.
4. **Select** the 'Racing Cars' dataset.

!['Racing Cars' dataset in the workspace created.](media/racing_cars_dataset.png)

5. **Select** the Card icon from Visualization tray to **create** the 'Active Sensors' visualization which is the 'Average' of 'Active Sensors'.

![Card icon from Visualization tray.](media/card_icon.png)

6. **Select** the 'ActiveSensors' field from 'race-cars' Dataset.
7. **Select** drop-down next to 'ActiveSensors'.
8. **Select** 'Average' from the drop-down to get the average of 'ActiveSensors'.

![Avg of ActiveSensors.](media/avg_active_sensors.png)

9. With Card visual selected, **select** the format tab.
10. **Turn on** the Title.
11. **Enter** 'Active Sensors' as the title for the card.

![Card Visual selected.](media/active_sensors.png)

12. **Turn on** Background and change the background color of the card.
Similarly, the color of the KPI value and title value can be changed from the Data label and Title sections respectively. You can use the Hex code #00222F to achieve the background color of the visual.

![Turn on background.](media/Background-Dark.png)

All other visuals of the report can be created by following a similar process. By following the same process for the 'milling canning' Dataset we can create the following real-time reports
- Milling Canning report
- Maintenance and Cost Analytics
- Miami Racing Cars
 
Once these real-time reports are ready we can pin them to the dashboard (by following the procedure explained in [Task 5](#task-5-power-bi-dashboard-creation)) to finally achieve the following look and feel.

![Real-time Reports.](media/report_visuals.png)  
