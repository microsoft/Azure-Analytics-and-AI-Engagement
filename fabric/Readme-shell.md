![Showcase Image](media/showcase.png)

## What is DPoC?
DREAM PoC Accelerators (DPoC) are packaged DREAM Demos using ARM templates and automation scripts (with a demo web application, Power BI reports, Fabric resources, ML Notebooks, etc.) that can be deployed in a customer’s environment.

## Objective & Intent
Partners can deploy DREAM Demos in their own Azure subscriptions and demonstrate them live to their customers. 
Partnering with Microsoft sellers, partners can deploy the Industry scenario DREAM demos into customer subscriptions. 
Customers can play, get hands-on experience navigating through the demo environment in their own subscription, and show it to their own stakeholders.

**Here are some important guidelines before you begin** 

1. **Read the [license agreement](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) and [disclaimer](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/disclaimer.md) before proceeding, as your access to and use of the code made available hereunder is subject to the terms and conditions made available therein.**
2. Without limiting the terms of the [license](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) , any Partner distribution of the Software (whether directly or indirectly) must be conducted through Microsoft’s Customer Acceleration Portal for Engagements (“CAPE”). CAPE is accessible to Microsoft employees. For more information regarding the CAPE process, contact your local Data & AI specialist or CSA/GBB.
3. It is important to note that **Azure hosting costs** are involved when DREAM PoC Accelerator is implemented in customer or partner Azure subscriptions. DPoC hosting costs are not covered by Microsoft for partners or customers.
4. Since this is a DPoC, there are certain resources available to the public. **Please ensure that proper security practices are followed before adding any sensitive data to the environment.** To strengthen the environment's security posture, **leverage Azure Security Centre.** 
5.  In case of questions or comments; please email **[dreamdemos@microsoft.com](mailto:dreamdemos@microsoft.com).**


## Contents

<!-- TOC -->

- [Requirements](#requirements)
- [Before Starting](#before-starting)
  - [Task 1: Power BI Workspace creation](#task-1-power-bi-workspace-creation)
  - [Task 2: Run the Cloud Shell to provision the demo resources](#task-2-run-the-cloud-shell-to-provision-the-demo-resources)
  - [Task 3: Creating a Shortcut in Lakehouse](#task-3-creating-a-shortcut-in-lakehouse)
  - [Task 4: Setting up the Warehouse](#task-4-setting-up-the-warehouse)
  - [Task 5: Excecuting Notebooks](#task-5-excecuting-notebooks) 
    - [Creating a new Runtime](#creating-a-new-runtime)
	- [Running Notebooks](#running-notebooks)
  - [Task 6: Creating Internal Shortcut](#task-6-creating-internal-shortcut)
  - [Task 7: KQL DB and QuerySet creation](#task-7-kql-db-and-queryset-creation)
  - [Task 8: Enabling Data Activator](#task-8-enabling-data-activator)
  - [Task 9: Creating Semantic Model for PowerBI Copilot](#task-9-creating-semantic-model-for-powerbi-copilot)

- [Appendix](#appendix)
  - [Setting up the Lakehouse](#setting-up-the-lakehouse)
  - [Creating Pipelines and Dataflows](#creating-pipelines-and-dataflows)
  - [Creating a Resource Group](#creating-a-resource-group)
  - [Deleting the assets](#deleting-the-assets)

<!-- /TOC -->

## Requirements

* An Azure Account with the ability to create Fabric Workspace.
* A Power BI with Fabric License to host Power BI reports.
* Make sure the user deploying the script has atleast a 'Contributor' level of access on the 'Subscription' on which it is being deployed.
* Make sure your Power BI administrator can provide service principal access on your Power BI tenant.
* Make sure to register the following resource providers with your Azure Subscription:
   - Microsoft.Fabric
   - Microsoft.EventHub
   - Microsoft.SQLSever
   - Microsoft.StorageAccount
   - Microsoft.AppService
* You must only execute one deployment at a time and wait for its completion. Running multiple deployments simultaneously is highly discouraged, as it can lead to deployment failures.
* Select a region where the desired Azure Services are available. If certain services are not available, deployment may fail. See [Azure Services Global Availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=all) for understanding target service availability (Consider the region availability for Synapse workspace, Iot Central and cognitive services while choosing a location).
* In this Accelerator, we have converted real-time reports into static reports for the user's ease, but have covered the entire process to configure real-time datasets. Using those real-time datasets, you can create real-time reports.
* Make sure you use the same valid credentials to log into Azure and Power BI.
* Once the resources have been set up, ensure that your AD user and synapse workspace have the “Storage Blob Data Owner” role assigned on the storage account name starting with “storage”.
* Review the [License Agreement](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) before proceeding.

>**Note:** This demo contains PowerBI Copilot, pre-requisites of which can be found [HERE](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/microsoftfabric/fabric/PowerBI%20Copilot/PowerBI%20Copilot%20Pre-requisites.md)

### Task 1: Power BI Workspace creation

1. **Open** Power BI in a new tab by clicking [HERE](https://app.powerbi.com/)

2. **Sign in** to Power BI.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use your Azure Active Directory credentials to login to Power BI.

3. In Power BI service, **click** on **Workspaces**.

4. **Click** the **+ New workspace** button.

	![Create Power BI Workspace.](media/power-bi-2.png)

5. **Enter** the name **contosoSales** and **click** on the **Apply** button.

>**Note:** The name of the workspace should be in camel case, i.e. the first word starting with a small letter and then the second word staring with a capital letter with no spaces in between.

>If name 'contosoSales' is already taken, add a suffix to the end of the name. For example: **contosoSalesTest**.

>Workspace name cannot contain any spaces.

   ![Create Power BI Workspace.](media/power-bi-4.png)

6. **Copy** the Workspace GUID or ID from the address URL.

7. **Save** the GUID in a notepad for future reference.

	![Give the name and description for the new workspace.](media/power-bi-3.png)

	> **Note:** This workspace ID will be used during powershell script execution.

8. In the workspace, **click** the **three dots (Ellipsis)** and **select** the **Workspace settings**.

	![Give the name and description for the new workspace.](media/power-bi-6.png)

9. In the left pane of the side bar, **click** on **Premium**, **scroll down** and **check** the **Trial** radio box.

	![Give the name and description for the new workspace.](media/power-bi-7.png)

>**Note:** All workspaces used in this demo use 'Trial' License type. 

10. **Scroll down** and **click** on **Apply**.

	![Give the name and description for the new workspace.](media/power-bi-8.png)

11. **Repeat** step 3 to 5 to **create** a new workspace with the name **contosoFinance**.

>**Note:** Make sure to add this workspace as a Fabric Trial License as well and note the names of the workspaces and lakehouses. These will be used during script execution (Task 2).

### Task 1.1 (Optional): Create Streaming Datasets

1. Navigate to the **contosoSales** Workspace

2. Using the **+ New** Dropdown, create a new **Streaming Dataset**

	![Create a new Streaming Dataset.](media/streamingds-new.jpg)

3. Pick the **API** option and click next

	![Configure the Streaming Method.](media/streamingds-api.jpg)

4. Name the Dataset **ThermostatData** and make sure to switch **Historical Data Analysis** on

	![Configure the Values.](media/streamingds-thermostat.jpg)

5. Add following values and click **Create**

|NAME	|TYPE|
|-----|-----|
|DeviceId	|Text|
|City		|Text|
|StoreID	|Text|
|EnqueuedTimeUTC	|DateTime|
|BatteryLevel	|Number|
|Temp	|Number|
|Temp_UoM	|Text|
| | |

6. Once created, copy the **Push Url** from the confirmation screen and keep it for later.

	![Copy Push Url.](media/streamingds-thermostat-url.png)

7. Repeat Steps 1-6 for a new Streaming Dataset called **OccupancyData** with following values

|NAME	|TYPE|
|-----|-----|
|DeviceId	|Text|
|City		|Text|
|StoreID	|Text|
|EnqueuedTimeUTC	|DateTime|
|BatteryLevel	|Number|
|visitors_cnt	|Number|
|visitors_in	|Number|
|visitors_out	|Number|
|avg_aisle_time_spent	|Number|
|avg_dwell_time	|Number|
| | |

![Configure the Values.](media/streamingds-occupancy.png)

### Task 2: Run the Cloud Shell to provision the demo resources

>**Note:** For this Demo we have assets in an Azure resource group as well as Fabric Workspaces

>**Note:** In this task we will execute a powershell script on Cloudshell to create those assets

>**Note:** List of the resources are as follows:

**Azure resources:**
|NAME	|TYPE|
|-----|-----|
|adx-thermostat-occupancy-{suffix}	|Event Hubs Namespace	|
|app-fabric-{suffix}	|App Service	|
|app-realtime-kpi-analytics-{suffix}	|App Service	|
|asp-fabric-{suffix}	|App Service plan	|
|asp-realtime-kpi-analytics-{suffix}	|App Service plan	|
|mssql{suffix}	|SQL server	|
|SalesDb (mssql{suffix}/SalesDb)	|SQL database	|
|storage{suffix}	|Storage account	|
| | |


**Fabric resources:**
| displayName | type |
|-----------|------|
|lakehouseBronze_{suffix}                                                |Lakehouse|
|lakehouseBronze_{suffix}                                                | SemanticModel|
|lakehouseBronze_{suffix}                                            |     SQLEndpoint|
|lakehouseSilver_{suffix}                            |                     Lakehouse|
|lakehouseSilver_{suffix}                                              |   SemanticModel|
|lakehouseSilver_{suffix}                                             |    SQLEndpoint|
|lakehouseGold_{suffix}                               |                    Lakehouse|
|lakehouseGold_{suffix}                                                 |  SemanticModel|
|lakehouseGold_{suffix}                                                |   SQLEndpoint|
|Sales_Lakehouse1                                     |                   Lakehouse|
|Sales_Lakehouse1                                                        |SemanticModel|
|Sales_Lakehouse1                                                      |  SQLEndpoint|
|01 Campaign Analytics Report with Lakehouse               |              Report|
|02 Sales Analytics Report with Warehouse                    |            Report|
|03 Contoso Finance Report                                       |           Report|
|04 Group CEO KPI Fabric+AML                                      |          Report|
|05 HR Analytics Report Lakehouse                                  |         Report|
|06 IT Report                                                       |        Report|
|07 Marketing Report                                                 |       Report|
|08 Operations Report                                                 |      Report|
|09 Score Cards Report                                                 |     Report|
|10 World Map (Trident)                                                 |    Report|
|01 Campaign Analytics Report with Lakehouse             |                SemanticModel|
|02 Sales Analytics Report with Warehouse                  |              SemanticModel|
|03 Contoso Finance Report                                     |             SemanticModel|
|04 Group CEO KPI Fabric+AML                                    |            SemanticModel|
|05 HR Analytics Report Lakehouse                                |           SemanticModel|
|06 IT Report                                                     |          SemanticModel|
|07 Marketing Report                                               |         SemanticModel|
|08 Operations Report                                               |        SemanticModel|
|09 Score Cards Report                                               |       SemanticModel|
|10 World Map (Trident)                                               |      SemanticModel|
|01 Marketing Data to Lakehouse (Bronze) - Code-First Experience.ipynb|   Notebook|
|02 Bronze to Silver layer_ Medallion Architecture.ipynb     |            Notebook|
|03 Silver to Gold layer_ Medallion Architecture.ipynb        |           Notebook|
|04 Churn Prediction Using MLFlow From Silver To Gold Layer.ipynb|        Notebook|
|05 Sales Forecasting for Store items in Gold Layer.ipynb         |       Notebook|
|salesDW_{suffix}                                                        | Warehouse|
|salesDW_{suffix}                                        |                 SemanticModel|
|Contoso-KQL-DB                                        |                  KQLDatabase|
|  |  |

1. **Open** the Azure Portal by clicking on the button below.

<a href='https://portal.azure.com/' target='_blank'><img src='http://azuredeploy.net/deploybutton.png' /></a>

2. In the Azure portal, select the **Terminal icon** to open Azure Cloud Shell.

	![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/cloud-shell.png)

3. **Click** on the **PowerShell**.

4. **Click** on **Show advanced settings**.

	![Mount a Storage for running the Cloud Shell.](media/cloud-shell-2.png)

	> **Note:** If you already have a storage mounted for Cloud Shell, you will not get this prompt. In that case, skip step 5 and 6.

5. **Select** your **Subscription**, **Cloud Shell region** and **Resource Group**.

>**Note:** If you do not have an existing resource group please follow the steps [HERE](#creating-a-resource-group) to create one. Complete the task and then continue with the steps below.

>Cloud Shell region need not be specific, you may select any region that works best for your experience.

6. **Enter** the **Storage account**, **File share** name and then click on **Create storage**.

	![Mount a storage for running the Cloud Shell and Enter the Details.](media/cloud-shell-3.png)

	> **Note:** If you are creating a new storage account, give it a unique name with no special characters or uppercase letters. The entire name should be all lowercase with no more than 24 characters.

	> It is not mandatory for storage account and file share name to be same.

7. In the Azure Cloud Shell window, ensure that the **PowerShell** environment is selected.

	![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-3.1.png)

	>**Note:** All the cmdlets used in the script work best in Powershell.	

	>**Note:** Please use 'Ctrl+C' to copy is and 'Shift+Insert' to paste, as 'Ctrl+V' is NOT supported by Cloudshell.

8. Enter the following command to clone the repository files in cloudshell.

Command:
```
git clone -b microsoftfabric2.0 --depth 1 --single-branch https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git fabric
```

   ![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-4.5.png)
	
   > **Note:** If you get File already exist error, please execute the following command to delete existing clone and then reclone:
```
 rm fabric -r -f 
```
   > **Note**: When executing scripts, it is important to let them run to completion. Some tasks may take longer than others to run. When a script completes execution, you will be returned to a command prompt. 

9. **Execute** the Powershell script with the following command:
```
cd ./fabric/fabric
```

```
./fabricSetup.ps1
```
    
   ![Commands to run the PowerShell Script.](media/cloud-shell-5.1.png)
      
10. From the Azure Cloud Shell, **copy** the authentication code. You will need to enter this code in next step.

11. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

	![Authentication link and Device Code.](media/cloud-shell-6.png)
     
12. **Paste** the authentication code.

	<img src="media/cloud-shell-7.png" alt="drawing" width="400"/>

13. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	<img src="media/cloud-shell-8.png" alt="drawing" width="400"/>

14. **Click** on **Continue** button.

	<img src="media/cloud-shell-8.1.png" alt="drawing" width="400"/>

15. **Close** the browser tab when you see the message box.

	![box](media/cloud-shell-9.png)   

16. **Navigate back** to your **Azure Cloud Shell** execution window.

17. **Copy** the code on screen to authenticate the Azure PowerShell script for creating reports in Power BI.

18. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

	![Authentication link and Device code.](media/cloud-shell-10.png)

19. A new browser window will launch.

20. **Paste** the authentication code you copied from the shell above.

	<img src="media/cloud-shell-11.png" alt="drawing" width="400"/>

21. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select Same User to Authenticate.](media/cloud-shell-12.png)

22. **Click** on 'Continue'.

	<img src="media/cloud-shell-12.1.png" alt="drawing" width="400"/>

23. **Close** the browser tab once you see the message box.

	<img src="media/cloud-shell-13.png" alt="drawing" width="400"/>

24. **Go back** to Azure Cloud Shell execution window.

25. **Copy** your subscription name from the screen and **paste** it in the prompt.

    ![Close the browser tab.](media/select-sub.png)
	
	> **Notes:**
	> - Users with a single subscription won't be prompted to select a subscription.
	> - The subscription highlighted in yellow will be selected by default, if you do not enter a disired subscription. Please select the subscription carefully as it may break the execution further.
	> - While you are waiting for the processes to complete in the Azure Cloud Shell window, you'll be asked to enter the code three times. This is necessary for performing the installation of various Azure Services and preloading the data.

26. **Enter** the Region for deployment with the necessary resources available, preferably "eastus" (Ex.: eastus, eastus2, westus, westus2, etc).

	![Enter Resource Group name.](media/cloudshell-region.png)

27. **Enter** your desired SQL Password.

	![Enter Resource Group name.](media/cloud-shell-14.png)

>**Note:** Copy the password in Notepad for further reference.

28. **Enter** both the Workspace IDs which you copied in [Task 1](#task-1-power-bi-workspace-and-lakehouse-creation) consecutively.

	![Enter Resource Group name.](media/cloud-shell-14.1.png)

29. You will get another code to authenticate the Azure PowerShell script for creating reports in Power BI. **Copy** the code.

	> **Note:** You may see errors in script execution if you  do not have necessary permissions for cloudshell to manipulate your Power BI workspace. In that case, follow this document [Power BI Embedding](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/fintax/fintaxdemo/Power%20BI%20Embedding.md) to get the necessary permissions assigned. You’ll have to manually upload the reports to your Power BI workspace by downloading them from this location [Reports](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/fintax/fintaxdemo/artifacts/reports). 

30. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

    ![Click the link.](media/cloud-shell-16.png)
      
31. In the new browser tab, **paste** the code you copied from the shell in step 30 and **click** on **Next**.

	<img src="media/cloud-shell-17.png" alt="drawing" width="400"/>

	> **Note:** Be sure to provide the device code before it expires and let the script run until completion.

32. **Select** the user account you used to log into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure). 

	![Select the same user.](media/cloud-shell-18.png)

33. **Click** on **Continue**.

	<img src="media/cloud-shell-18.1.png" alt="drawing" width="400"/>

34. **Close** the browser tab when you see the message box.

	![box](media/cloud-shell-9.png)

	>**Note:** During script execution you need to note the resource group which gets created, since a resource group with unique suffix is created each time the script is executed.

35. **Navigate back** to your Azure Cloud Shell execution window.

	> **Note:** Deployment will take approximately 20-30 minutes to complete. Keep checking the progress with messages printed in the console to avoid timeout.

36. After  script execution is complete, the "--Execution Complete--" prompt appears.
	
37. **Go to** Azure Portal and **search** for 'fabric-dpoc' and **click** on the resource group name created by the script.

	![Close the browser.](media/demo-1.1.png)

	>**Note:** The resource group name starts with 'fabric-dpoc-' with a random unique suffix in the end.

38. In the search pane of the resource group, **type** "app-realtime-kpi-analytics..." and **select** the resource.

	![Close the browser.](media/demo-1.png)

39. **Click** on **Browse** and a new tab will open.

	![Close the browser.](media/demo-2.png)

40. **Wait** for the tab to load the following screen.

	![Close the browser.](media/demo-3.png)

### Task 3: Creating a Shortcut in Lakehouse

1. **Open** [Power BI](app.powerbi.com).

2. In PowerBI, **click** on **Workspaces** and **select** the **contosoSales** workspace. 

    ![Lakehouse.](media/demo-4.png)

3. In 'contosoSales' workspace, **click** on the **lakehouseBronze** lakehouse.

    ![Lakehouse.](media/lakehouse-1a.png)

>**Note:** Lakehouses will have a concatenated random suffix, resulting in names like 'lakehousesbronze_SUFFIX' for example. 

4. In the lakehouse window, **click** on the collapse icon in front of Files, if it is expanded.

>**Note:** When the collapse icon is expanded, the three dots icon is note visible.

5. **Click** on the three dots in front of Files.

6. **Click** on **New shortcut**.

	![Lakehouse.](media/lakehouse-2.png)

7. In the pop-up window, under External sources, **select** the **Azure Data Lake Storage Gen2** option. 

	![Lakehouse.](media/demo-9.png)

8. In a new tab, **open** the resource group created in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources) with name 'fabric-dpoc-...'.

9. **Search** for "storage account" and **click** the storage account resource.

	![Lakehouse.](media/demo-10.png)

10. In the resource window, **go to** the left pane and **scroll down**.

11. In the **Security + networking** section, **click** on **Access keys**.

12. **Click** on the **Show** button under key1.

	![Lakehouse.](media/demo-11.png)

13. **Click** 'Copy to clickboard' button.

14. **Save** it in a notepad for further use.

	![Lakehouse.](media/demo-12.png)

15. **Scroll down** in the left pane.

16. **Select** 'Endpoints' from the 'Settings' section.

17. **Scroll down** and **copy** the 'Data Lake Storage' endpoint under the 'Data Lake Storage' section.

18. **Save** it in a notepad for further use.

	![Lakehouse.](media/demo-12.1.png)

>**Note:** You may see different endpoints as well in the above screen. Make sure to select only the Data Lake Storage endpoint.

19. **Navigate back** to the Power BI workspace (the powerbi tab which we working in earlier).

20. **Paste** the endpoint copied under the 'URL' field.

21. In the 'Authentiation kind' dropdown, **select** the **Account Key**.

22. **Paste** the account key copied in step number 13.

23. **Click** on **Next**.

	![Lakehouse.](media/demo-12.2.png)

24. Under Shortcut Name, **type** "sales-transaction-litware."

25. **Verify** the URL is same as the one you copied in step 17.

26. Under Sub Path, **type** "/bronzeshortcutdata".

27. **Click** on the **Create** button.

	![Lakehouse.](media/lakehouse-3.png)


### Task 4: Setting up the Warehouse

1. In PowerBI, **click** on **Workspaces** and **select** the **contosoSales** workspace. 

    ![Lakehouse.](media/demo-4.png)

2. **Filter** and **Select** '"Data Warehouse." 

	![Datawarehouse.](media/warehouse-1a.png)

3. **Open** 'salesDW'.

>**Note:** warehouses will have a concatenated suffix, resulting in names like 'salesDW_SUFFIX'

4. **Click** on 'Get data'.

5. **Select** 'New data pipeline'.

	![Datawarehouse.](media/warehouse-4.png)

>**Note:** It will take some time for the page to load, please wait.

6. In the pop-up window, **enter** the name "02 Sales data from Azure SQL DB to Data Warehouse - Low Code Experience."

7. **Click** on Create.

8. **Wait** for a new pop-up.

	![Datawarehouse.](media/warehouse-5.png)

9. **Scroll down** in the pop-up.

10. **Select** 'Azure SQL Database'.

11. **Click** on the 'Next' button.

	![Datawarehouse.](media/warehouse-6.png)

12. In a new tab, **open** the resource group created in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources).

13. **Search** for 'sql server'.

14. **Click** on the SQL server resource.

	![Datawarehouse.](media/warehouse-7.png)

15. In the resource window, **copy** the 'Server admin'.

16. **Save** it in a notepad for further use.

17. **Copy** the 'Server name'.

18. **Save** it in a notepad for further use.

19. **Click** 'SQL databases' under the Settings in the left pane.

	![Datawarehouse.](media/warehouse-8.png)

20. **Copy** the name of the database and **paste** it in a notepad for further use.

	![Datawarehouse.](media/warehouse-9.png)

21. **Go back** to the PowerBI tab.

22. **Select** the 'Create new connection' radio button, in the 'Server;' and 'Database' field **paste** the value copied in step number 17 and 19.

	![Datawarehouse.](media/warehouse-10.png)

23. **Select** 'Basic' for the Authentication kind, **enter** the Username 'labsqladmin' and **patse** the Password you copied in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources)
step 28, and **click** on the 'Next' button.

![Datawarehouse.](media/warehouse-11.png)

24. In 'Connect to data source,' **select** 'tables' then **select** 'Select all' and **click** on the 'Next' button.

	![Datawarehouse.](media/warehouse-12.png)

25. In 'Choose data destination,' **select** the Data Warehouse and **click** on the 'Next' button.

	![Datawarehouse.](media/warehouse-13.png)

26. In 'Choose data destination,' **select** 'Load to new table' and **click** on 'Source' checkbox, then **click** on the 'Next' button.

	![Datawarehouse.](media/warehouse-14.png)

27. In 'Settings' section keep it default and **click** on the 'Next' button.

	![Datawarehouse.](media/warehouse-15.png)

28. In the 'Review + save' section, **review** the copy summary and **scrolldown** tick mark the option of 'Start data transfer immediately' then **click** on the 'Save + Run' button.

	![Datawarehouse.](media/warehouse-16.png)	

>**Note:** As you click on 'Save + Run' click 'OK' on the pop-up to automatically trigger the pipeline.

![Datawarehouse.](media/warehouse-16a.png)

29. **Check** the notification or pipeline output screen for the progress of copy database.

	![Datawarehouse.](media/warehouse-17.png)

30. In Output section of pipeline **check** the status of running pipeline.

	![Datawarehouse.](media/warehouse-18.png)

>**Note:** Please wait for the resultant data to load.

31. **Wait** for the status of pipeline to display 'Succeeded' and **go back** the the Data Warehouse from the workspace.

32. **Open** the Data Warehouse and **click** 'New SQL query'.

	![Datawarehouse.](media/warehouse-18.1.png)

33. **Click** on [Warehouse Scripts](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/microsoftfabric2.0/fabric/artifacts/warehousescripts) link to open the scripts.

34. **Click** on the first script to open it.

	![Datawarehouse.](media/warehouse-19.png)

35. In a new tab **open** the resource group created in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources).

36. **Search** for the 'Storage account' **copy** the 'Storage account' name and **paste** it in a notepad for further use.

	![Datawarehouse.](media/warehouse-22.png)

37. **Click** on searched 'Storage account', **scrolldown** left pane and **click** to select 'Shared access signature'.

	![Datawarehouse.](media/warehouse-23.png)

38. **Select** 'Container' in 'Allowed resource type'. **select** 'Read','Write', 'List' in 'Allowed permissions' keep  rest all uncheck. In 'Start and expiry date/time' **select** date & time and then **scrolldown** to **click** 'Generate SAS and connection string' button.

	![Datawarehouse.](media/warehouse-24.png)

	![Datawarehouse.](media/warehouse-25.png)

39. Below the 'Generate SAS and connection string' button, we can see the generated SAS token. **Copy** and paste it into notepad for further use.

	![Datawarehouse.](media/warehouse-26.png)

40. **Click** '00 Ingest Data In DW Using COPY INTO Command.sql' file and **copy** the script and **replace** '#STORAGE_ACCOUNT_NAME#' and '#STORAGE_ACCOUNT_SAS_TOKEN#' with the appropriate values copied in earlier steps.

41. **Copy** the script.

	![Datawarehouse.](media/warehouse-19.1.png)

42. **Navigate back** to 'salesDW' warehouse explorer to execute SQL scripts and **click** 'New SQL query'. In dropdown, **click** 'New SQL query' again.

	![Datawarehouse.](media/warehouse-21.png)

43. Once the SQL editor opens, **paste** the script which we have modified in step 41. **Right click** on 'SQL query 1' and **click** 'Rename'.

	![Datawarehouse.](media/warehouse-27.png)

44. **Enter** the name as '00 Ingest Data In DW Using COPY INTO Command.sql' and **click** 'Rename' button.

	![Datawarehouse.](media/warehouse-28.png)

45. **Click** the 'three dots (Ellipsis)' in front of the name of the scripts and **select** 'Move to Shared queries'.

	![Datawarehouse.](media/warehouse-29.png)

>**Note:** We are going to create 6 more scripts following the above steps for querying the Warehouse data.

46. **Repeat** the steps (33-45) for the other six scripts in the repository. Get the scripts [HERE](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/microsoftfabric2.0/fabric/artifacts/warehousescripts)

>**Note:** If there are no replacements necessary in the scripts, you can skip the steps in between.

47. **Click** 'New visual query'.

	![Datawarehouse.](media/warehouse-30.png)

48. **Click** and **drag** the table 'DimProduct' to the canvas.

	![Datawarehouse.](media/warehouse-31.png)

49. **Click** and **drag** the table 'FactSales' to the canvas.

	![Datawarehouse.](media/warehouse-40.png)

50. **Click** 'Combine' and **select** 'Merge queries as new'.

	![Datawarehouse.](media/warehouse-32.png)

51. In the 'Left table for merge' **select** 'DimProduct' from the dropdown and **click** on column 'ProductKey' of the table.

	![Datawarehouse.](media/warehouse-33.png)

52. **Scroll down** in the 'Right table for merge' **select** 'FactSales' from the dropdown and **click** on column 'ProductKey' of the table.

	![Datawarehouse.](media/warehouse-34.png)

53. **Scroll down** to Join kind section and **click** on 'Inner' radio button and click on 'OK' button.

	![Datawarehouse.](media/warehouse-35.png)

54. You would see the following result.

	![Datawarehouse.](media/warehouse-36.png)

55. **Right click** on 'Visual query 1' and **select** 'Rename'.

	![Datawarehouse.](media/warehouse-37.png)

56. **Enter** the name as "Visual query- Total Sales By Product" and **click** on 'Rename' button.

	![Datawarehouse.](media/warehouse-38.png)

57. **Click** on the 'three dots' infront of the visual query name and **click** one 'Moved to Shared queries'

	![Datawarehouse.](media/warehouse-39.png)

### Task 5: Excecuting Notebooks

### Creating a new Runtime

1. In the workspace **click** on the "02 Bronze to Silver layer_ Medallion Architecture" notebook.

	![Datawarehouse.](media/notebook-6.png)

2. **click** on the 'Environment' and **select** 'New'

    ![Datawarehouse.](media/env.png)

3. **Enter** name for environment as 'salesEnvironment'
    
	![Datawarehouse.](media/envname.png)

### Running Notebooks

1. In the workspace **click** on the "02 Bronze to Silver layer_ Medallion Architecture" notebook.

	![Datawarehouse.](media/notebook-6.png)

2. In the left pane **click** on 'Missing Lakehouse' button and **select** 'Remove all Lakehouses'.

	![Datawarehouse.](media/notebook-11.png)

>**Note:** In case you do not see Missing lakehouse, you would see 'lakehouse{Name}', click on the same to get the 'Remove all Lakehosues' option.

3. **Click** on 'Continue' in the pop-up window.

	![Datawarehouse.](media/notebook-12.png)

4. In the left pane **click** on the 'Add' button.

	![Datawarehouse.](media/notebook-13.png)

5. In the pop-up **select** 'Existing Lakehouse' radio button and then **click** on 'Add' button.

	![Datawarehouse.](media/notebook-14.png)

6. **Click** on 'lakehouseSilver' checkbox and **click** on 'Add'.

	![Datawarehouse.](media/notebook-15.png)

7. Similarly **perform** step number 1 to step number 6 for the other notebooks as well.

>**Note:** To perform the above steps you need to attach the notebooks to respective lakehouses before running the notebooks. Follow the below instruction for the same.

8. Refer the below table to attach notebooks with the respective lakehouses

	|	Notebook	|	Lakehouse	|
	| -----------	| ------------- |
	|	01 Marketing Data to Lakehouse (Bronze) - Code-First Experience.ipynb	|	lakehouseBronze	|
	|	02 Bronze to Silver layer_ Medallion Architecture.ipynb	|	lakehouseSilver	|
	|	03 Silver to Gold layer_ Medallion Architecture.ipynb	|	lakehouseGold	|
	|	04 Churn Prediction Using MLFlow From Silver To Gold Layer	|	lakehouseSilver	|
	|	05 Sales Forecasting for Store items in Gold Layer	|	lakehouseSilver	|
	|||

>**Note:** Please complete Task 6 and then execute notebook '05 Sales Forecasting for Store items in Gold Layer'.

> Please comeback to continue with the below given steps after completing Task 6

9. In PowerBI workspace **click** on 'Workspaces' and **select** 'contosoSales'.

	![Close the browser.](media/demo-4.png)

10. **Filter** 'Notebook' and then **click** on the notebook '03 Silver to Gold layer_ Medallion Architecture'

	![Close the browser.](media/notebook-16.png)

11. **Click** on the 'Run all' button.

	![Close the browser.](media/notebook-17.png)

### Task 6: Creating Internal Shortcut

>**Note:** In this task we are creating Internal Shortcut in lakehouse 'Silver To Gold'

1. In Power BI workspace **click** on 'Workspaces' and **select** 'contosoSales'.

	![Close the browser.](media/demo-4.png)

2. **Filter** 'Lakehouse' and then **select** 'lakehouseGold'.
    
	![Close the browser.](media/FilterLakehouseGold.png)
	
3. **Click** on the 'three dots' infont of Tables and then **select** 'New Shortcut'.

	![Close the browser.](media/LakehouseGoldShortcutupdated.png)

4. In the 'Internal Sources' section **select** 'Microsoft OneLake'.

	![Close the browser.](media/LakehouseGoldShortcut2.png)

5. **Search** for 'lakehouseSilver' in the search box, **click** on 'lakehouseSilver' and then **click** on 'Next'.

	![Close the browser.](media/LakehouseGoldShortcut3.png)

6. **Select** the radio buttons for all the tables listed below and then **click** on 'Next'.

	|	Table Name	|	Create Shortcut From Lakehouse	|
	| -----------	| ------------- |
	|	dimension_date|	lakehouseSilver	|
	|	dimension_product|	lakehouseSilver	|
	|	dimension_customer|	lakehouseSilver	|
	|	fact_sales|	lakehouseSilver	|
	|	fact_campaigndata|	lakehouseSilver	|
	|||

	![Close the browser.](media/LakehouseGoldShortcut4.png)

7. Finally, **click** on the 'Create' button.

	![Close the browser.](media/LakehouseGoldShortcut5.png)


>**Note:** Once you are done with Task 6 please go back to Task 5 and follow the steps from the point where you had stopped.


### Task 7: KQL DB and QuerySet creation

1. In Power BI service click 'Workspaces' and **click** current working workspace. 

	![Close the browser.](media/power-bi-5.png)

2. **Filter** for the **KQL Database** and Open 'Contoso-KQL-DB'.

	![Close the browser.](media/demo-34a.png)

3. **click** on 'Get data' and then **click** 'Event Hubs'.

    ![Close the browser.](media/demo-35.png)

4. In Destination tab **select** 'New table' and provide the name as 'Thermostat'and then **click** 'Next:Source' button.

    ![Close the browser.](media/demo-36.png)

5. In the Source tab **select** the source type as 'Event Hub' and **select** 'create new connection'

	![Close the browser.](media/demo-36.1.png)

	>**Note:** For the rest of the details we will get the data from the resource group.

6. In a new tab **open** the resource group created in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources).

7. **Search** for 'Event Hub namespace' and **copy** the name of Event Hub namespace and **paste** it in a notepad for further use.

	  ![Close the browser.](media/demo-52.png)

8. **Click** the 'Event Hubs Namespace' under overview **scrolldown** at bottom and **copy** the name of Event Hub and **paste** it in a notepad for further use.

	 ![Close the browser.](media/demo-53.png)	

9. To get the shared access key & shared access key name,**click** Event Hubs Instance 'thermostat'. Then **click** 'Shared access policies' in the left pane. **Click** on shared access key name 'thermostat' to open the shared access key tab in right pane. 
**Copy** the primary key and **paste** it in a notepad for further use. 

   ![Close the browser.](media/demo-54.png)

10. **Navigate back** to the PowerBI tab.

11. Make sure you are in the 'Create new connection' section. **Select** 'Authentication kind' as 'Shared Access Key' and then in the connection setting **paste** the value copied in step 9,10,11 and **click** 'Save' button.

    ![Close the browser.](media/demo-37.png)
    ![Close the browser.](media/demo-38.png)
    ![Close the browser.](media/demo-39.png)

12. Upon clicking on 'Save', the below disabled fields 'Data connection name' & 'Consumer group' will be enabled. Keeping its value as default, **click** 'Next: Schema' button.

    ![Close the browser.](media/demo-40.png)

13. On Schema tab, **select** the Data format as JSON and **click** Next:Summary button.

    ![Close the browser.](media/demo-41.png)

14. Once **click** Summary button, it will show the message as 'Continuous ingestion from Event Hubs established'. **Click** 'Close' button.

    ![Close the browser.](media/demo-42.png)

15. To verify the data tree **expand** the Thermostat table, check the size and the table details.

    ![Close the browser.](media/demo-43.png)

16. **Click** 'Contoso-KQL-DB' and  **wait** for sometime to load the data. **Check** the table size.

	![Close the browser.](media/demo-44.png)

17. Once you see the table size is increased then, **click** 'Explore your data' button. 

	![Close the browser.](media/demo-45.png)

18. It will open the KQL queryset editor. **Click** link [KQL Queryset Scripts](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/microsoftfabric2.0/fabric/artifacts/kqlscripts). **Copy** and **paste** the script in the editor and **click** 'Run' button.

	![Close the browser.](media/demo-46.png)

19. To create a Query Set **go to** current Workspace, **click** '+ New' and **click** 'More options' button.

	![Close the browser.](media/demo-5.png)

20. In the new window, **scroll down** to 'Real-Time Analytics' section and **click** 'KQL Queryset'.

	![Close the browser.](media/demo-47.png)

21. **Enter** the name as "01 Query Thermostat Data in Near 'Real-Time' using KQL Script", **click** 'Create' button and **wait** for the Queryset to get created.

	![Close the browser.](media/demo-48.png)

22. **Select** the database 'Contoso-KQL-DB' and **click** 'Select' button.

	![Close the browser.](media/demo-49.png)

23. Now this will open the Queryset editor. **Copy** the queries from step 20 and **paste** it to queryset editor. **Select** the query and **click** 'Run' button.

	![Close the browser.](media/demo-50.png)

24. Navigate back to the KQL Database.
    
	![kqldb](media/demo-34a.png)

25. **click** on 'Get data' and then **click** 'Azure Storage'.

    ![kqldb](media/azstg.png)

26. **Navigate back** to the Azure portal and **open** the resource group and **Search** for 'storage account', **click** the storage account resource.

	![kqldb](media/demo-10.png)

27. **Click** on 'Containers' in the left navigation pane and then **click** on the 'kqldata' container.

    ![Kql](media/select-cont.png)

28. **Navigate** to the 'OnlineShoppingData' folder and **click** on 'Behaviour.csv'
     
	 ![kqldb](media/kqlcsv.png)

29. **Click** on 'Copy to clickboard' icon and
    **copy** it in a notepad for further use.
    
	![kqldb](media/csvurl.png)

30. **Navigate back** to Power BI workspace i.e. the powerbi tab which we working earlier.

31. **Enter** table name as 'Behaviour' and **Paste** the URL that you've copied earlier in 'URI' field. **click** on Next.

    ![kqldb](media/uripaste1.png)

32. On Inspect tab, ensure that the data format is selected as 'CSV' and **click** Next:Summary button.
    
	![kqldb](media/inspect.png)

33.  Once **click** Summary button, it will show the message as '1 blob succeeded'. **Click** 'Close' button.

   ![kqldb](media/blobinges.png)

34. **Repeat** the steps (25-32) for other 'CSVs' under 'OnlineShoppingData' folder to ingest data into KQL-DB. Use 'CSVs' name as table name in KQL-DB.

35. In the KQL-DB **click** on 'Get data' and then **click** 'Azure Storage'.

    ![kqldb](media/azstg.png)

36. Navigate back to the Azure portal and **open** the resource group and **Search** for 'storage account', **click** the storage account resource.

   ![kqldb](media/demo-10.png)

37. **open** 'kqldata' container and navigate to 'kqldata' 

  ![Kql](media/select-cont.png)

38. **Select** properties from left-handside of the menu and **copy** the URL.

   ![Kql](media/kql-db-1.png)

39. **Navigate back** to Power BI workspace i.e. the powerbi tab which we working earlier. **Enter** table name as 'OccupancyHistoricalData' and **Paste** the URL that you've copied earlier in 'URI' field.
   
   ![Kql](media/kql-db-2.png)

40. In the 'File filters' dropdown **Enter** Folder path as 'OccupancyHistoricalData' and File extension as 'csv'. **Click** on Next.

   ![Kql](media/kql-db-3.png)

41. On Inspect tab, ensure that the data format is selected as 'CSV' and **click** Next:Summary button.

   ![Kql](media/kql-db-4.png)

42. **click** on Summary button, it will show the message as '7 blob succeeded'. **Click** 'Close' button.

   ![Kql](media/kql-db-5.png)

>**Note:** **repeat** the steps (35-42) for Ingesting data from 'ThermostatHistoricalData'.

43. To create a Query Set **go to** current Workspace, **click** '+ New' and **click** 'More options' button.

	![Close the browser.](media/demo-5.png)

44. In the new window, **scroll down** to 'Real-Time Analytics' section and **click** 'KQL Queryset'.

	![Close the browser.](media/demo-47.png)

45. **Enter** the name as "Analyze_Consumers_E-commerce_Website_Purchasing_Behaviour", **click** 'Create' button and **wait** for the Queryset to get created.

	![Close the browser.](media/demo_48.png)

46. **Select** the database 'Contoso-KQL-DB' and **click** 'Select' button.

	![Close the browser.](media/demo-49.png)

47. **Click** link [KQL Queryset Scripts](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/microsoftfabric2.0/fabric/artifacts/kqlscripts). **Copy** kql script '02_Analyze_Consumers_E-commerce_Website_Purchasing_Behaviour' and **paste** the script in the editor and **click** 'Run' button.

     ![Close the browser.](media/kql-db-6.png)


### Task 8: Enabling Data Activator

1. **Click** on workspace and **select** contosoSales.

	![Close the browser.](media/data-activator-1.png)

2. **Filter** out 'KQL Database' and **select** 'Contoso-KQL-DB'.

	![Close the browser.](media/data-activator-2.png)

3. In the KQL Database screen **click** on the three dots in front of the Thermostat table and **select** 'Build PowerBI report'.

	![Close the browser.](media/data-activator-3.png)

4. **Select** 'Area chart', **expand** 'Kusto Query Result', **select** 'ExnquedTimeUTC' and 'Sum of Temp' in the 'X-axis' and 'Y-axis' respectively and you would notice a chart as shown in the screenshot.

	![Close the browser.](media/data-activator-4.png)

5. **Click** on the 'expand' icon of the Sum of Temp and **select** 'Average'.

	![Close the browser.](media/data-activator-4.1.png)

6. **Expand** 'File' and **select** 'Save'.

	![Close the browser.](media/data-activator-5.png)

7. **Select** the 'Use existing PowerBI credentials' radio button and then **click** on the 'Continue' button.

	![Close the browser.](media/data-activator-6.png)

8. **Enter** the Name of the file as 'kqlRealtimeReport', **select** the workspace name as 'contosoSales' and then **click** on 'Continue'.

	![Close the browser.](media/data-activator-7.png)

9. **Click** on 'Open file' option.

	![Close the browser.](media/data-activator-8.png)

10. **Click** on the three dots at right corner of the KPI and **select** 'Set Alert'.

	![Close the browser.](media/data-activator-9.png)

11. **Enter** a 'Threshold' value to the nearest whole number of the default value.

	![Close the browser.](media/data-activator-10.png)

12. **Scroll down**, **select** the 'Teams' radio button, **select** the current workspace, and then **expand** the 'Item' field and finally **click** on '+ Create a new reflex item'.

	![Close the browser.](media/data-activator-11.png)

13. **Enter** the 'Item name' as 'Store Analytics' and **click** on the 'Create alert' button.

	![Close the browser.](media/data-activator-12.png)




### Task 9 : Creating Semantic Model for PowerBI Copilot

1.	**Click** on the 'Workspace' icon and **select** the 'contosoSales' workspace.

    ![01](media/data-activator-4.png)

2.	**Filter** 'Lakehouse'.
    
    ![02](media/02.png)

3. **Click** on 'lakehouseBronze...'.

    ![03](media/03.png)

5. **Click** on the 'New semantic model' button.

    ![04](media/04.png)

6.	**Type** 'campaign_churn_semanticmodel' for the New semantic Model name, **select** the **Select all** checkbox and then **click** on the **Confirm** button.

    ![05](media/05.png)
  


### Appendix

This section is optional and created to showcase other data ingestion options. Use it as a refrence if you have your own Dataverse and Snowflake connections.

### Setting up the Lakehouse

1. **Open** Power BI in a new tab by clicking [HERE](https://app.powerbi.com/).

2. **Sign in** to Power BI using your Power BI with Fabric License account.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use the same credentials for Power BI that you will be using for the Azure account.

3. In Power BI service, **click** on 'Workspaces' and **select** the 'contosoSales' workspace. 

    ![Close the browser.](media/demo-4.png)

4. **Click** on '+ New' and **select** 'More options'.

    ![Close the browser.](media/demo-5.png)

5. In the new window, **click** on 'Lakehouse'.

    ![Close the browser.](media/demo-6.png)

6. **Enter** the name 'lakehouseBronze' and **click** on the 'Create' button.

    ![Close the browser.](media/demo-7.png)

7. **Wait** for the lakehouse to be created. **Click** on the three dots (Ellipsis) in front of the 'Files' and **select** 'New shortcut'

    ![Close the browser.](media/demo-8.png)

8. In the pop-up window, under External sources **select** 'Azure Data Lake Storage Gen2'

	![Close the browser.](media/demo-9.png)

>**Note:** To fill in the required fields in the pop-up screen, you'll need to fetch it from the storage account resource. Follow the steps below to get the data.

9. In a new tab, **open** the resource group created in Task 2 (you noted this in the script execution with name starting with 'fabric-dpoc-').

10. **Search** for 'storage account', **click** the storage account resource.

	![Close the browser.](media/demo-10.png)

11. In the Storage account window, **scroll down** in the left pane. In the 'Security + networking' section, **click** 'Access keys' and **click** the 'Show' button under key1.

	![Close the browser.](media/demo-11.png)

12. **Click** the 'Copy to clickboard' button and **paste** it in notepad for further use.

	![Close the browser.](media/demo-12.png)

13. **Scroll down** in the left pane, **select** 'Endpoints' from the Settings section. **Copy** the 'Primary endpoint' under 'Data Lake Storage' section, and **paste** it in notepad for further use.

	![Close the browser.](media/demo-12.1.png)

14. **Go back** the Power BI workspace, under 'URL' **paste** the endpoint copied in step number 13.

15. In the 'Authentiation kind' dropdown, **select** 'Account Key'.

16. **Paste** the account key copied in step number 12.

17. **Click** on the 'Next' button.

	![Close the browser.](media/demo-12.2.png)

18. Under Shortcut Name, **type** 'BlobToLakehouse'.

19. Verify the URL.

20. Under Sub Path **type** '/bronzelakehousefiles'.

21. **Click** on the 'Create' button.

	![Close the browser.](media/demo-12.3.png)

### Creating Pipelines and Dataflows

1. While you are in the 'contosoSales' workspace **click** the '+ New' button and **select** 'More options'.

	![Pipeline.](media/demo-5.png)

2. Under Data Factory section, **select** 'Dataflow Gen2'.

	![Pipeline.](media/pipeline-2.png)

3. In the dataflow window, **click** the default dataflow name 'Dataflow 1' and in the Name field **type** '04 Customer Insights Data from Dataverse' then **click** somewhere outside of the rename box to update the dataflow name.

	![Pipeline.](media/pipeline-3.png)

4. **Click** 'Get data' and **click** 'More...'.

	![Pipeline.](media/pipeline-4.png)

5. **Click** 'Dataverse'.

	![Pipeline.](media/pipeline-5.png)

6. **Enter** the Dynamics 365 credentials if available and then **click** the 'Next' button.

	![Pipeline.](media/pipeline-6.png)

7. **Go back** to the workspace, **click** '+ New' and **click** 'More options'.

	![Pipeline.](media/demo-5.png)

8. Under the Data Factory section, **select** 'Data pipeline'.

	![Pipeline.](media/pipeline-7.png)

9. **Type** the name '03 Customer Insights Dataflow trigger from Data' and **click** 'Create'.

	![Pipeline.](media/pipeline-8.png)

10. Wait for the pipeline to create, **click** 'Add pipeline activity' and **click** on 'Dataflow'.

	![Pipeline.](media/pipeline-9.png)

11. **Click** the new dataflow activity. In the General tab, **type** the name 'Customer Insights Data to Lakehouse'.

	![Pipeline.](media/pipeline-10.png)

12. In the Settings tab, **attach** it to the dataflow you created before.

	![Pipeline.](media/pipeline-11.png)

13. **Create** another pipeline with the name "01 Campaigns data from Snowflake to Lakehouse - Low Code Experience".

14. When the pipeline has been created, **click** on 'Lookup'. 

	![Pipeline.](media/pipeline-12.png)

15. In the 'General' tab of the Lookup activity, **enter** "Check if Snowflake Campaign Data exist" as the name' and "GetMetadata activity is used to ensure the source dataset is ready for downstream consumption, before triggering the copy and analytics job." for the 'Description.' 

	![Pipeline.](media/pipeline-13.png)

16. In the 'Settings' tab, **select** the External radio button and **click** 'New'.

	![Pipeline.](media/pipeline-14.png)

17. In the 'New connection' pop-up window, **scroll down** to **select** 'Snowflake' and **click** 'Continue'.

	![Pipeline.](media/pipeline-15.png)

18. **Enter** your Server, Warehouse, Username, and Password for Snowflake if available.

	![Pipeline.](media/pipeline-16.png)	

	![Pipeline.](media/pipeline-17.png)	

19. Once your connection setup is done, **enter** the details as shown.

	![Pipeline.](media/pipeline-18.png)	

20. **Click** 'Copy data activity' and **select** 'Add to canvas'.

	![Pipeline.](media/pipeline-19.png)	

21. In the 'General' tab **enter** 'SnowflakeDB To Lakehouse' as the Name.

	![Pipeline.](media/pipeline-20.png)	

22. **Enter** the values in the 'Source' tab.

	![Pipeline.](media/pipeline-21.png)	

23. **Enter** the values in the 'Destination' tab.

	![Pipeline.](media/pipeline-22.png)	

24. **Click** the 'green tick' on the Lookup and drag it to Copy data as shown in the screenshot.

	![Pipeline.](media/pipeline-23.png)

### Creating a Resource Group

1. **Login** to the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, **select** the '+ Create a resource' tile.

	![A portion of the Azure Portal home screen is displayed with the + Create a resource tile highlighted.](media/create-a-resource.png)

3. In the Search the Marketplace text box, **type** "Resource Group" and **press** the Enter key.

	![On the new resource screen Resource group is entered as a search term.](media/resource-group.png)

4. **Select** the 'Create' button on the 'Resource Group' overview page.

	![A portion of the Azure Portal home screen is displayed with Create Resource Group tile](media/resource-group-2.png)
	
5. On the 'Create a resource group' screen, **select** your desired Subscription. For Resource group, **type** 'cloudshell-dpoc'. 

6. **Select** your desired region.

	> **Note:** Some services behave differently in different regions and may break some part of the setup. Choosing one of the following regions is preferable: 		westus2, eastus2, northcentralus, northeurope, southeastasia, australliaeast, centralindia, uksouth, japaneast.

7. **Click** on the 'Review + Create' button.

	![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](media/resource-group-3.png)

8. **Click** on the 'Create' button when all entries have been validated.

	![Create Resource Group with the final validation passed.](media/resource-group-4.png)


### Deleting the assets

1. **Open** the Azure Portal by clicking [HERE](https://portal.azure.com/).

2. In the Resource group section, select the **Terminal icon** to open Azure Cloud Shell.

	![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/cloud-shell.png)

3. In the Azure Cloud Shell window, ensure that the **PowerShell** environment is selected.

	![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-3.1.png)

	>**Note:** All the cmdlets used in the script work best in Powershell.	

	>**Note:** Please use 'Ctrl+C' to copy is and 'Shift+Insert' to paste, as 'Ctrl+V' is NOT supported by CLoudshell.

4. **Execute** the Powershell script with the following command:
```
cd ./fabric/
```

```
./cleanup.ps1
```
    
   ![Commands to run the PowerShell Script.](media/cloud-shell-5.1.2.png)
      
5. From the Azure Cloud Shell, **copy** the authentication code. You will need to enter this code in next step.

6. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

	![Authentication link and Device Code.](media/cloud-shell-6.1.png)
    
7. **Paste** the authentication code.

	![New Browser Window to provide the Authentication Code.](media/cloud-shell-7.png)

8. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.png)

9. **Click** on **Continue** button.

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.1.png)

10. **Close** the browser tab when you see the message box.

	![box](media/cloud-shell-9.png)   

11. **Navigate back** to your **Azure Cloud Shell** execution window.

12. **Copy** your subscription name from the screen and **paste** it in the prompt.

    ![Close the browser tab.](media/select-sub.png)
	
	> **Notes:**
	> - Users with a single subscription won't be prompted to select a subscription.
	> - The subscription highlighted in yellow will be selected by default, if you do not enter a disired subscription. Please select the subscription carefully as it may break the execution further.
	> - While you are waiting for the processes to complete in the Azure Cloud Shell window, you'll be asked to enter the code three times. This is necessary for performing the installation of various Azure Services and preloading the data.

13. **Enter** your resource group name and **press** 'Enter' key.

	![Enter Resource Group name.](media/cloud-shell-14.3.png)

	> **Note:** Let the script run until completion.

14. After  script execution is complete, the "----CLEAN-UP OPERATION DONE----" prompt appears.


# Copyright

© 2023 Microsoft Corporation. All rights reserved.   

By using this demo/lab, you agree to the following terms: 

The technology/functionality described in this demo/lab is provided by Microsoft Corporation for purposes of obtaining your feedback and to provide you with a learning experience. You may only use the demo/lab to evaluate such technology features and functionality and provide feedback to Microsoft.  You may not use it for any other purpose. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell this demo/lab or any portion thereof. 

COPYING OR REPRODUCTION OF THE DEMO/LAB (OR ANY PORTION OF IT) TO ANY OTHER SERVER OR LOCATION FOR FURTHER REPRODUCTION OR REDISTRIBUTION IS EXPRESSLY PROHIBITED. 

THIS DEMO/LAB PROVIDES CERTAIN SOFTWARE TECHNOLOGY/PRODUCT FEATURES AND FUNCTIONALITY, INCLUDING POTENTIAL NEW FEATURES AND CONCEPTS, IN A SIMULATED ENVIRONMENT WITHOUT COMPLEX SET-UP OR INSTALLATION FOR THE PURPOSE DESCRIBED ABOVE. THE TECHNOLOGY/CONCEPTS REPRESENTED IN THIS DEMO/LAB MAY NOT REPRESENT FULL FEATURE FUNCTIONALITY AND MAY NOT WORK THE WAY A FINAL VERSION MAY WORK. WE ALSO MAY NOT RELEASE A FINAL VERSION OF SUCH FEATURES OR CONCEPTS.  YOUR EXPERIENCE WITH USING SUCH FEATURES AND FUNCITONALITY IN A PHYSICAL ENVIRONMENT MAY ALSO BE DIFFERENT.

