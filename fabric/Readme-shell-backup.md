# Fabric DREAM Demo in a Box Setup Guide

## What is it?
DREAM Demos in a Box (DDiB) are packaged Industry Scenario DREAM Demos with ARM templates (with a demo web app, Power BI reports, Synapse resources, AML Notebooks etc.) that can be deployed in a customer’s subscription using the CAPE tool in a few hours.  Partners can also deploy DREAM Demos in their own subscriptions using DDiB.

## Objective & Intent
Partners can deploy DREAM Demos in their own Azure subscriptions and show live demos to customers. 
In partnership with Microsoft sellers, partners can deploy the Industry scenario DREAM demos into customer subscriptions. 
Customers can play,  get hands-on experience navigating through the demo environment in their own subscription and show to their own stakeholders
**Before You Begin**

## :exclamation:IMPORTANT NOTES:  

  1. **Please read the [license agreement](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) and [disclaimer](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/disclaimer.md) before proceeding, as your access to and use of the code made available hereunder is subject to the terms and conditions made available therein.**
  2. Without limiting the terms of the [license](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) , any Partner distribution of the Software (whether directly or indirectly) may only be made through Microsoft’s Customer Acceleration Portal for Engagements (“CAPE”). CAPE is accessible by Microsoft employees. For more information about the CAPE process, please connect with your local Data & AI specialist or CSA/GBB.
  3. Please note that **Azure hosting costs** are involved when DREAM Demos in a Box are implemented in customer or partner Azure subscriptions. **Microsoft will not cover** DDiB hosting costs for partners or customers.
  4. Since this is a DDiB, there are certain resources open to the public. **Please ensure proper security practices are followed before you add any sensitive data into the environment.** To strengthen the security posture of the environment, **leverage Azure Security Centre.** 
  5.  For any questions or comments please email **[dreamdemos@microsoft.com](mailto:dreamdemos@microsoft.com).**
  
   > **Note**: Set up your demo environment at least two hours before your scheduled demo to make sure everything is working.
   
# Copyright

© 2021 Microsoft Corporation. All rights reserved.   

By using this demo/lab, you agree to the following terms: 

The technology/functionality described in this demo/lab is provided by Microsoft Corporation for purposes of obtaining your feedback and to provide you with a learning experience. You may only use the demo/lab to evaluate such technology features and functionality and provide feedback to Microsoft.  You may not use it for any other purpose. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell this demo/lab or any portion thereof. 

COPYING OR REPRODUCTION OF THE DEMO/LAB (OR ANY PORTION OF IT) TO ANY OTHER SERVER OR LOCATION FOR FURTHER REPRODUCTION OR REDISTRIBUTION IS EXPRESSLY PROHIBITED. 

THIS DEMO/LAB PROVIDES CERTAIN SOFTWARE TECHNOLOGY/PRODUCT FEATURES AND FUNCTIONALITY, INCLUDING POTENTIAL NEW FEATURES AND CONCEPTS, IN A SIMULATED ENVIRONMENT WITHOUT COMPLEX SET-UP OR INSTALLATION FOR THE PURPOSE DESCRIBED ABOVE. THE TECHNOLOGY/CONCEPTS REPRESENTED IN THIS DEMO/LAB MAY NOT REPRESENT FULL FEATURE FUNCTIONALITY AND MAY NOT WORK THE WAY A FINAL VERSION MAY WORK. WE ALSO MAY NOT RELEASE A FINAL VERSION OF SUCH FEATURES OR CONCEPTS.  YOUR EXPERIENCE WITH USING SUCH FEATURES AND FUNCITONALITY IN A PHYSICAL ENVIRONMENT MAY ALSO BE DIFFERENT.

## Contents

<!-- TOC -->

- [Requirements](#requirements)
- [Before Starting](#before-starting)
  - [Task 1: Power BI Workspace creation](#task-1-power-bi-workspace-creation)
  - [Task 2: Run the Cloud Shell to provision the demo resources](#task-2-run-the-cloud-shell-to-provision-the-demo-resources)
  - [Task 3: Uploading required assets to the PowerBI Workspace](#task-3-uploading-required-assets-to-the-powerbi-workspace)

<!-- /TOC -->

## Requirements

* An Azure Account with the ability to create an Fabric Workspace.
* A Power BI Pro or Premium account to host Power BI reports.
* Make sure you are the Power BI administrator for your account and service principal access is enabled on your Power BI tenant.
* Make sure the following resource providers are registered with your Azure Subscription.
   - Microsoft.EventHub 
   - Microsoft.Databricks
* You can run only one deployment at any point in time and need to wait for its completion. You should not run multiple deployments in parallel as that will cause deployment failures.
* Select a region where the desired Azure Services are available. If certain services are not available, deployment may fail. See [Azure Services Global Availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=all) for understanding target service availability. (consider the region availability for Synapse workspace, Iot Central and cognitive services while choosing a location)
* Do not use any special characters or uppercase letters in the environment code. Also, do not re-use your environment code.
* In this Accelerator we have converted Real-time reports into static reports for the ease of users but have covered entire process to configure Realtime dataset. Using those Realtime dataset you can create Realtime reports.
* Please ensure that you select the correct resource group name. We have given a sample name which may need to be changed should any resource group with the same name already exist in your subscription.
* The audience for this document is CSAs and GBBs.
* Please log in to Azure and Power BI using the same credentials.
* Once the resources have been setup, please ensure that your AD user and synapse workspace have “Storage Blob Data Owner” role assigned on storage account name starting with “storage”. You need to contact AD admin to get this done.
* Please review the [License Agreement](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) before proceeding.

## Before starting

### Task 1: Power BI Workspace creation

1. **Open** Power BI in a new tab using the following link:  [https://app.powerbi.com/](https://app.powerbi.com/)

2. **Sign in**, to Power BI using your Power BI Pro account.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use the same credentials for Power BI which you will be using for the Azure account.

3. In Power BI service **Click** on 'Workspaces'.

4. Then **click** on the 'Create a workspace' tab.

	![Create Power BI Workspace.](media/power-bi-2.png)

	> **Note:** Please create a Workspace by the name "Contoso Sales".

5. **Copy** the Workspace GUID or ID. You can get this by browsing to [https://app.powerbi.com/](https://app.powerbi.com/), selecting the workspace, and then copying the GUID 	from the address URL.

6. **Paste** the GUID in a notepad for future reference.

	![Give the name and description for the new workspace.](media/power-bi-3.png)

	> **Note:** This workspace ID will be used during ARM template deployment.


### Task 2: Run the Cloud Shell to provision the demo resources

**Open** the Azure Portal.

1. In the Resource group section, **open** the Azure Cloud Shell by selecting its icon from the top toolbar.

	![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/cloud-shell.png)

2. **Click** on 'Show advanced settings'.

	![Mount a Storage for running the Cloud Shell.](media/cloud-shell-2.png)

	> **Note:** If you already have a storage mounted for Cloud Shell, you will not get this prompt. In that case, skip step 2 and 3.

3. **Select** your 'Resource Group' and **enter** the 'Storage account' and 'File share' name.

	![Mount a storage for running the Cloud Shell and Enter the Details.](media/cloud-shell-3.png)

	> **Note:** If you are creating a new storage account, give it a unique name with no special characters or uppercase letters.

4. In the Azure Cloud Shell window, ensure the PowerShell environment is selected and **enter** the following command to clone the repository files.
Command:
```
git clone -b fabric-ddib --depth 1 --single-branch https://daidemos@dev.azure.com/daidemos/Microsoft%20Data%20and%20AI%20DREAM%20Demos%20and%20DDiB/_git/DreamDemoInABox fabric
```

![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-4.png)
	
> **Note:** If you get File already exist error, please execute following command: rm fabric -r -f to delete existing clone.

> **Note**: When executing scripts, it is important to let them run to completion. Some tasks may take longer than others to run. When a script completes execution, you will be returned to a command prompt. 

5. **Execute** the Powershell script by executing the following command:
Command:
```
cd ./fabric/
```

6. Then **run** the PowerShell: 
```
./fabricSetup.ps1
```
    
![Commands to run the PowerShell Script.](media/cloud-shell-5.png)
      
7. From the Azure Cloud Shell, **copy** the authentication code

8. Click on the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

	![Authentication link and Device Code.](media/cloud-shell-6.png)
     
9. **Paste** the authentication code.

	![New Browser Window to provide the Authentication Code.](media/cloud-shell-7.png)

10. **Select** the same user that you used for signing in to the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.png)

11. **Close** the browser tab once you see the message window at right and **go back** to your Azure Cloud Shell execution window.

	![Authentication done.](media/cloud-shell-9.png)
	
12. **Navigate back** to the resource group tab.

13. You will get another code to authenticate an Azure PowerShell script for creating reports in Power BI. **Copy** the code.

14. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

	![Authentication link and Device code.](media/cloud-shell-10.png)

15. A new browser window will launch.

16. **Enter** the authentication code you copied from the shell above.

	![Enter the Resource Group name.](media/cloud-shell-11.png)

17. Again, **select** the same user to authenticate which you used for signing into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select Same User to Authenticate.](media/cloud-shell-12.png)
	
18. **Close** the browser tab once you see the message window at right, and then go back to your Azure Cloud Shell execution window.

	![Close the browser tab.](media/cloud-shell-13.png)

19. Now you will be prompted to select subscription if you have multiple subscription assigned to the user you used for device login.

    ![Close the browser tab.](media/select-sub.png)
	
	> **Notes:**
	> - The user with single subscription won't be prompted to select subscription.
	> - The subscription highlighted in yellow will be selected by default if you do not enter any disired subscription. Please select the subscription carefully, as it may break the execution further.
	> - While you are waiting for processes to get completed in the Azure Cloud Shell window, you'll be asked to enter the code three times. This is necessary for performing installation of various Azure Services and preloading content in the Azure Synapse Analytics SQL Pool tables.

20. You will now be prompted to **enter** the Region for deployment. Enter the region with necessary resources available preferably "eastus". (ex. eastus,westus,westus2 etc)

	![Enter Resource Group name.](media/cloudshell-region.png)

21. You will now be prompted to **enter** the Power BI workspace id.

	![Enter Resource Group name.](media/cloud-shell-14.png)

22. You will get another code to authenticate an Azure PowerShell script for creating reports in Power BI. **Copy** the code.
	> **Note:**
	> Note: You may see errors in script execution if you  do not have necessary permissions for cloudshell to manipulate your Power BI workspace. In such case follow this document [Power BI Embedding](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/fintax/fintaxdemo/Power%20BI%20Embedding.md) to get the necessary permissions assigned. You’ll have to manually upload the reports to your Power BI workspace by downloading them from this location [Reports](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/fintax/fintaxdemo/artifacts/reports). 

23. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

      ![Click the link.](media/cloud-shell-16.png)
      
24. A new browser window will launch. **Paste** the code that you copied from the shell in step 21.

	![Paste the code.](media/cloud-shell-17.png)

	> Note: Make sure to provide the device code before it expires and let the script run till completion.

25. **Select** the same user to authenticate which you used for signing into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure). 

	![Select the same user.](media/cloud-shell-18.png)

26. **Close** the browser tab once you see the message window at right and go back to your Azure Cloud Shell execution window.

	![Close the browser.](media/cloud-shell-19.png)

	> **Note:** The deployment will take approximately 50-55 minutes to complete. Keep checking the progress with messages printed in the console to avoid timeout.

27. After complete script has been executed, you get to see a messages "--Execution Complete--"
	
28. **Goto** the resource group which you created.

29. In the search pane **type** "app-realtime-kpi-analytics..." and **click** on the resource.

	![Close the browser.](media/demo-1.png)

30. **Click** on "Browse" and a new tab will open.

	![Close the browser.](media/demo-2.png)

31. **Wait** for the tab to load and you will see a screen shown below.

	![Close the browser.](media/demo-3.png)

### Task 3: Uploading required assets to the PowerBI Workspace


### Task 4: Copy data from Storage account to Lakehouse using data pipeline.

1. **Open** Power BI in a new tab using the following link:  [https://app.powerbi.com/](https://app.powerbi.com/)

2. **Sign in**, to Power BI using your Power BI Pro account.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use the same credentials for Power BI which you will be using for the Azure account.

3. In Power BI service **Click** on 'Workspaces'.

![Close the browser.](media/demo-4.png)

4. Select the appropriate **Workspace** for creating **Lakehouse** 

5. Click on **+ New** and the Click on **Show all**

![Close the browser.](media/demo-5.png)

6. It will open the dashboard with list of all resouces then Click on **Lakehouse(Preview)**

![Close the browser.](media/demo-6.png)

7. Enter the **Name** for the lakehouse and then click on **Create** button.

![Close the browser.](media/demo-7.png)

8. Once Lakehouse created it will open the **Explorer**.

![Close the browser.](media/demo-8.png)


## SAS Token
1. **Copy** the SAS token for Storage account container and keep it for future reference.

![Close the browser.](media/demo-13.png)

## Create a data pipeline

1. Switch to Data factory on the https://app.powerbi.com page.

![Close the browser.](media/demo-14.png)

2. Verify the Workspace name and then **Click** on **Data pipeline (preview)**.

![Close the browser.](media/demo-15.png)

3. Provide the name to the pipeline and **Click** on **Create** button.

![Close the browser.](media/demo-16.png)

4. Select **Copy data** on the canvas to open the copy assistant tool to get started.

![Close the browser.](media/demo-17.png)

5. **Configure your source** Select **Azure Blob Storage**, and then select **Next**.

![Close the browser.](media/demo-18.png)

6. Create a connection to your data source by selecting **Create New connection**.

After selecting **Create new connection**, you only need to fill in **Storage Account Container URL**, and **Authentication kind**. If you input **Account name or URL** using your Azure Blob Storage account name, the connection will be auto filled. In this demo, we will choose **Shared Access Signature** and paste the SAS Token which we have created earlier. After selecting Sign in, you only need to log in to one account that having this blob storage permission.

![Close the browser.](media/demo-19.png)

7. Once your connection is created successfully, you only need to select Next to Connect to **data source**.

**Note**: If you get error **Unable to list files** then provide a **Container Name** and Click on **Retry** button.

![Close the browser.](media/demo-20.png)

8. Choose the file **xyz.txt** in the source configuration to preview, and then select **Next**.

![Close the browser.](media/demo-21.png)

9. Configure your destination Select **Lakehouse** and then **Next**.

![Close the browser.](media/demo-22.png)

10. Create a new Lakehouse and input the Lakehouse name. Then select **Next**.

![Close the browser.](media/demo-23.png)

11. Configure and map your source data to your destination; then select **Next** to finish your destination configurations.

![Close the browser.](media/demo-24.png)

12. Review your copy activity settings in the previous steps and select OK to finish.

![Close the browser.](media/demo-25.png)

13. Once finished, the copy activity will then be added to your data pipeline canvas. All settings including advanced settings to this copy activity are available under the tabs below when it's selected.

![Close the browser.](media/demo-26.png)

14. **Run and schedule your data pipeline** Switch to **Home** tab and select **Run**. Then select **Save and Run**.

![Close the browser.](media/demo-27.png)
![Close the browser.](media/demo-28.png)

15. Select the Details button to monitor progress and check the results of the run.

![Close the browser.](media/demo-29.png)

16. The Copy data details dialog displays results of the run including status, volume of data read and written, start and stop times, and duration.

![Close the browser.](media/demo-30.png)

17. You can also schedule the pipeline to run with a specific frequency as required. Below is the sample to schedule the pipeline to run every 15 minutes.

![Close the browser.](media/demo-31.png)
![Close the browser.](media/demo-32.png)

## Creating KQL Database.

1. **Open** Power BI in a new tab using the following link:  [https://app.powerbi.com/](https://app.powerbi.com/)

2. **Sign in**, to Power BI using your Power BI Pro account.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use the same credentials for Power BI which you will be using for the Azure account.

3. In Power BI service **Click** on 'Workspaces'.

![Close the browser.](media/demo-4.png)

4. Select the appropriate **Workspace** for creating **KQL Database** 

5. Click on **+ New** and the Click on **Show all**

![Close the browser.](media/demo-5.png)

6. It will open the dashboard with list of all resouces in **Real-Time Analytics** section Click on **KQL Database (Preview)**

![Close the browser.](media/demo-33.png)

7. Provide the name to the KQL Database and **Click** on **Create** button.

![Close the browser.](media/demo-34.png)

8. Once database created in overview page go to **Get data** and click on **Event Hubs**.

![Close the browser.](media/demo-35.png)

9. On **Destination** tab select **New table** and provide the name as **thermostat**. Click on **Next:Source** button.

![Close the browser.](media/demo-36.png)

10. On **Source** tab provide the **Event Hub namespace**, **Event Hub**, **Authentication kind**, **Shared access key name** & **Shared access Key** and Click on **Save** button.

![Close the browser.](media/demo-37.png)

![Close the browser.](media/demo-38.png)

![Close the browser.](media/demo-39.png)

11. Once click on save it will enable below 2 disabled options **Data connection name** & **Consumer group**. Keep it default. and click on **Next:Schema** button.

![Close the browser.](media/demo-40.png)

12. On **Schema** tab select the **Data format** as **JSON** and Click on **Next:Summary** button.

![Close the browser.](media/demo-41.png)

13. Once click on Summary button it will show the message as **Continuous ingestion from Event Hubs established**.

![Close the browser.](media/demo-42.png)

14. To verify the data tree expand the thermostat table check the size and table details.

![Close the browser.](media/demo-43.png)

## QuerySet