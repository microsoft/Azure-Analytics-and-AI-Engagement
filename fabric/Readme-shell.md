![Showcase Image](media/showcase.png)

## What is a DPoC?
DREAM PoC Accelerators (DPoC) are packaged DREAM Demos using ARM templates and automation scripts (with a demo web application, Power BI reports, Fabric resources, ML Notebooks, etc.) that can be deployed in a customer’s environment.

## Objective & Intent
Partners can deploy DREAM Demos in their own Azure subscriptions and demonstrate them live to their customers. 
By Partnering with Microsoft sellers, partners can deploy Industry Scenario DREAM Demos into customer subscriptions. 
Customers can play, get hands-on experience navigating through the demo environment in their own subscription, and show it to their own stakeholders.

**Here are some important guidelines before you begin** 

1. **Read the [license agreement](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) and [disclaimer](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/disclaimer.md) before proceeding, as your access to and use of the code made available hereunder is subject to the terms and conditions made available therein.**
2. Without limiting the terms of the [license](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) , any Partner distribution of the Software (whether directly or indirectly) must be conducted through Microsoft’s Customer Acceleration Portal for Engagements (“CAPE”). CAPE is accessible to Microsoft employees. For more information regarding the CAPE process, contact your local Data & AI specialist or CSA/GBB.
3. It is important to note that **Azure hosting costs** are involved when a DREAM PoC Accelerator is implemented in customer or partner Azure subscriptions. DPoC hosting costs are not covered by Microsoft for partners or customers.
4. Since this is a DPoC, there are certain resources available to the public. **Please ensure that proper security practices are followed before adding any sensitive data to the environment.** To strengthen the environment's security posture, **leverage Azure Security Center.** 
5.  In case of questions or comments, email **[dreamdemos@microsoft.com](mailto:dreamdemos@microsoft.com).**


## Contents

<!-- TOC -->

- [Requirements](#requirements)
- [Before Starting](#before-starting)
  - [Task 1: Power BI Workspace creation](#task-1-power-bi-workspace-creation)
  - [Task 2: Run the Cloud Shell to provision the demo resources](#task-2-run-the-cloud-shell-to-provision-the-demo-resources)
  - [Task 3: Unified Multi-Source Querying](#task-3-unified-multi-source-querying)  
  - [Task 4: Setting up Eventstream](#task-4-setting-up-eventstream)
  - [Task 5: Get data into QuerySet](#task-5-get-data-into-querySet)
  - [Task 6: Create Genie](#task-6-create-genie)
  - [Task 7: Creating a data agent](#task-7-creating-a-data-agent)
  - [Task 8: Creating a Semantic Model for Power BI](#task-8-creating-a-semantic-model-for-Power-bi)
  - [Task 9: Updating Semantic Models with Cloud connection](#task-9-updating-semantic-Models-with-cloud-connection)
  - [Task 10: Creating a Dashboard and enabling Data Activator](#task-10-creating-a-dashboard-and-enabling-data-activator)
  - [Task 11: Create Digital Twin Builder](#task-11-digital-twin-builder)
  - [Task 12: Creating a Cosmos DB Mirror](#task-12-creating-a-cosmos-db-mirror)
  - [Task 13: Setting up and Running Data Pipelines](#task-13-setting-up-and-running-the-data-pipelines)
  - [Task 14 : Azure Purview set up](#task-14-azure-purview-set-up)

- [Appendix](#appendix)
  - [Setting up the Mirrored Snowflake](#setting-up-the-mirrored-snowflake)


<!-- /TOC -->

## Requirements

* An Azure Account with the ability to create a Fabric Workspace.
* A Power BI with Fabric License to host Power BI reports.
* Make sure the user deploying the script has at least a 'Contributor' level of access on the 'Subscription' on which it is being deployed.
* Make sure your Power BI administrator can provide service principal access on your Power BI tenant.
* Make sure to register the following resource providers with your Azure Subscription:
   - Microsoft.Fabric
   - Microsoft.EventHub
   - Microsoft.SQLSever
   - Microsoft.StorageAccount
   - Microsoft.AppService
* You must only execute one deployment at a time and wait for its completion. Running multiple deployments simultaneously is highly discouraged, as it can lead to deployment failures.
* Select a region where the desired Azure Services are available. If certain services are not available, deployment may fail. See [Azure Services Global Availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=all) for understanding target service availability (consider the region availability for Synapse workspace, IoT Central and cognitive services while choosing a location).
* In this Accelerator, we have converted real-time reports into static reports for the user's ease but have covered the entire process to configure real-time datasets. Using those real-time datasets, you can create real-time reports.
* Make sure you use the same valid credentials to log into Azure and Power BI.
* Once the resources have been set up, ensure that your AD user and synapse workspace have the “Storage Blob Data Owner” role assigned on the storage account name starting with “storage”.
* Review the [License Agreement](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/CDP-Retail/license.md) before proceeding.

>**Note:** This demo contains Power BI Copilot, pre-requisites of which can be found [HERE](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/microsoftfabric/fabric/PowerBI%20Copilot/PowerBI%20Copilot%20Pre-requisites.md).

### Task 1: Power BI Workspace creation

1. **Open** Power BI in a new tab by clicking [HERE](https://app.powerbi.com/).

2. **Sign in** to Power BI.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use your Azure Active Directory credentials to login to Power BI.

3. In Power BI service, **click** on **Workspaces**.

4. **Click** the **+ New workspace** button.

	![Create Power BI Workspace.](media/power-bi-2.png)

5. **Enter** the name **Zava** and **click** on the **Apply** button.

>**Note:** The name of the workspace should be in camel case, i.e. the first word starts with a small letter and then the second word starts with a capital letter with no spaces in between.

>If the name 'Zava' is already taken, add a suffix to the end of the name. For example: **ZavaTest**.

>The Workspace name cannot contain any spaces.

   ![Create Power BI Workspace.](media/power-bi-4.png)

6. **Copy** the Workspace GUID or ID from the address URL.

7. **Save** the GUID in a notepad for future reference.

	![Give the name and description for the new workspace.](media/power-bi-3.png)

	> **Note:** This workspace ID will be used during PowerShell script execution.

8. In the workspace, click on **Workspace settings**.

   ![Give the name and description for the new workspace.](media/powerbi1.png)

9. In the left side bar, click on **License info** and then click on **Edit**.

   ![Give the name and description for the new workspace.](media/workspacesettings.png)

10. Click on **Primary** in the Workspace settings pane and check the **Trial** radio box.

![](media/power-bi-7.png)

> **Note:** If your workspace has **Fabric capacity**, select it. Otherwise, use the **Trial** License type.
> **Note:** Use of the Fabric Capacity is recommended for a better experience.

11. **Scroll down** and click on **Select license**.

    ![Give the name and description for the new workspace.](media/workspacesettings2.png)

> **Note:** Make sure to add this workspace as a Fabric Trial/Fabric capacity License and note down the names of the **Workspace** and **Lakehouses**. These will be used during script execution (Task 2).


### Task 2: Run the Cloud Shell to provision the demo resources

>**Note:** For this Demo, we have assets in an Azure resource group as well as Fabric Workspaces.

>**Note:** In this task, we will execute a PowerShell script on Cloud Shell to create those assets.

>**Note:** The list of resources are as follows:

**Azure resources:**
|NAME	|TYPE|
|-----|-----|
|app-fabric-{suffix}	|App Service	|
|asp-fabric-{suffix}	|App Service plan	|
|asp-realtime-kpi-analytics-{suffix}	|App Service plan	|
|mssql{suffix}	|SQL server	|
|SalesDb (mssql{suffix}/SalesDb)	|SQL database	|
|stfabricadb{suffix} | Microsoft.Storage/storageAccounts |
|adb-fabric-{suffix} | Microsoft.Databricks/workspaces |
|ami-databricks-{suffix} | Microsoft.ManagedIdentity/userAssignedIdentities |
|access-adb-connector-{suffix} | Microsoft.Databricks/connectors |
|kv-adb-{suffix} | Microsoft.KeyVault/vaults |
|cosmosdb-herodemo-{suffix} | Microsoft.Azure Cosmos DB account |
|cosmosdb-mongo-herodemo-{suffix} | Microsoft.Azure Cosmos DB for MongoDB account (RU) |
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
|LakehouseAI                                     |                   Lakehouse|
|LakehouseAI                                                        |SemanticModel|
|LakehouseAI                                                      |  SQLEndpoint|
|Website_Bounce_Rate                                               |       SemanticModel|
|Sales_Report                                               |      SemanticModel|
|01 Copilot Notebook for Data Science.ipynb|   Notebook|
|01 Data Wrangler Notebook.ipynb     |            Notebook|
|02 Churn Prediction using MLFlow.ipynb        |           Notebook|
|03 Silver to Gold layer Medallion Architecture.ipynb|        Notebook|
|CreateSchema.ipynb         |       Notebook|
|FootTraffic_RealtimeData.ipynb|   Notebook|
|Generate realtime thermostat data.ipynb     |            Notebook|
|real-time paint accessory inventory data.ipynb        |           Notebook|
|Segment customer and Incorporate discount.ipynb|        Notebook|
|salesDW_{suffix}                                                        | Warehouse|
|salesDW_{suffix}                                        |                 SemanticModel|
|ZAVA-KQL-DB                                        |                  KQLDatabase|
|  |  |

1. **Open** the Azure Portal by clicking on the button below.

<a href='https://portal.azure.com/' target='_blank'><img src='http://azuredeploy.net/deploybutton.png' /></a>

2. In the Azure portal, select the **Terminal icon** to open Azure Cloud Shell.

	![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/cloud-shell.png)

3. **Click** on **PowerShell**.

    ![](media/cloud-shell.1.png)

4. Select the **Subscription** and click on **Apply**.

	![Mount a Storage for running the Cloud Shell.](media/cloud-shell-2.1.png)

	> **Note:** If you already have a storage mounted for Cloud Shell, you will not get this prompt. In that case, skip step 5 and 6.


5. In the Azure Cloud Shell window, ensure that the **PowerShell** environment is selected.

	![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-3.1.png)

	>**Note:** All the cmdlets used in the script work best in PowerShell .	

	>**Note:** Use 'Ctrl+C' to copy and 'Shift+Insert' to paste, as 'Ctrl+V' is NOT supported by Cloud Shell.

6. Enter the following command to clone the repository files in Cloud Shell.

Command:

```
git clone -b azureherodemo --depth 1 --single-branch https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git fabric
```

<!-- ```
git clone --branch herodemosdpoc --single-branch https://daidemos@dev.azure.com/daidemos/DREAMDemos/_git/DREAMPoC
``` -->

   ![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-4.5.png)
	
   > **Note:** If you get File already exist error, please execute the following command to delete existing clone and then re-clone:
```
 rm fabric -r -f 
```
   > **Note**: When executing scripts, it is important to let them run to completion. Some tasks may take longer than others to run. When a script completes execution, you will be returned to a command prompt. 

7. **Execute** the PowerShell script with the following command:
```
cd ./fabric/fabric
```

```
./herodemo.ps1
```
    
   ![Commands to run the PowerShell Script.](media/cloud-shell-5.1.png)

8. **Press** **Y** and click on the **Enter** button.
      
![Yes.](media/yes.png)

9. From the Azure Cloud Shell, **copy** the authentication code. You will need to enter the code in the next step.

10. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

![Authentication link and Device Code.](media/cloud-shell-10.png)
     
11. **Paste** the authentication code.

	![box](media/cloud-shell-7.png) 

12. **Select** the user account you used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

![box](media/cloud-shell-8.png) 

13. **Click** on the **Continue** button.

![box](media/cloud-shell-8.1.png) 

14. **Close** the browser tab when you see the message box.

	![box](media/cloud-shell-9.png)   

15. **Navigate back** to your **Azure Cloud Shell** execution window.

16. **Copy** your subscription name from the screen and **paste** it in the prompt.

    ![Close the browser tab.](media/select-sub1.png)
	
	> **Notes:**
	> - Users with a single subscription won't be prompted to select a subscription.
	> - The subscription highlighted in Light blue will be selected by default, if you do not enter a desired subscription. Please select the subscription carefully as it may break the execution further.
	> - While you are waiting for the processes to complete in the Azure Cloud Shell window, you'll be asked to enter the code three times. This is necessary for performing the installation of various Azure Services and preloading the data.

17. **Copy** the code on the screen to authenticate the Azure PowerShell script for creating reports in Power BI. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

	![Authentication link and Device code.](media/cloud-shell-10.png)

18. A new browser window will launch. **Paste** the authentication code you copied from the shell above.

	![box](media/cloud-shell-11.png) 

19. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select Same User to Authenticate.](media/cloud-shell-12.png)

20. **Click** on 'Continue'.

	![box](media/cloud-shell-12.1.png) 

21. **Close** the browser tab when you see the message box.

	![box](media/cloud-shell-13.png) 

22. **Go back** to the Azure Cloud Shell execution window.

23. **Enter** the Region for deployment with the necessary resources available, preferably "eastus". 
    (Ex.: eastus, eastus2, westus, westus2, etc).

	![box](media/cloudshell-region.png) 

24. **Enter** your desired SQL Password.

	![Enter Resource Group name.](media/cloud-shell-14.png)

>**Note:** Copy the password in Notepad for further reference.

25. **Enter** the Workspace IDs that you copied in [Task 1](#task-1-power-bi-workspace-and-lakehouse-creation) consecutively.

	![Enter Resource Group name.](media/cloud-shell-14.1.png)

26. You will get another code to authenticate the Azure PowerShell script for creating reports in Power BI. **Copy** the code.

	> **Note:** You may see errors in script execution if you  do not have necessary permissions for Cloud Shell to manipulate your Power BI workspace. In that case, follow this document [Power BI Embedding](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/fsi/fsidemo/Power%20BI%20Embedding.md) to get the necessary permissions assigned. You’ll have to manually upload the reports to your Power BI workspace by downloading them from this location [Reports](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/fintax/fintaxdemo/artifacts/reports). 

27. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

    ![Click the link.](media/cloud-shell-10.png)
      
28. In the new browser tab, **paste** the code you copied from the shell in step 30 and **click** on **Next**.

![box](media/cloud-shell-11.png) 

**Note:** Be sure to provide the device code before it expires and let the script run until completion.

29. **Select** the user account you used to log into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure). 

	![Select the same user.](media/cloud-shell-12.png)

30. **Click** on **Continue**.

	![box](media/cloud-shell-12.1.png) 

31. **Close** the browser tab when you see the message box.

	![box](media/cloud-shell-9.png)

	>**Note:** During script execution you need to note the resource group that gets created, since a resource group with a unique suffix is created each time the script is executed.

32. **Navigate back** to your Azure Cloud Shell execution window.

33. When it asks **Are you sure?** press **Y** and click on the **Enter** button.

![](media/internalshortcut1.png)

34. Repeat **step 33** two times whenever it asks. If the same prompt repeats more than two times, continue to **step 33** until you move forward.

![](media/internalshortcut2.png)

35. When it asks **Are you sure?** press **Y** and click on the **Enter** button.

![](media/externalshortcut.png)

> **Note:** Deployment will take approximately 40-50 minutes to complete. Keep checking the progress with messages printed in the console to avoid timeout.

36. After  script execution is complete, the "--Execution Complete--" prompt appears.


### Task 3: Unified Multi-Source Querying

1. In Power BI service, click on **Workspaces** and **click** on the current working workspace. 

	![Close the browser.](media/power-bi-5.png)

2. **Filter** for the **Lakehouse** and click on **LakehouseBronze_...**.

	![Close the browser.](media/unifiedquery1.png)

3. Click on **Lakehouse** in the top right corner and then click on **SQL analytics endpoint**.

![](media/unifiedquery2.png)

4. Click on **New SQL Query** and paste the query below in the editor.

```
SELECT 
    sqldb.[CampaignName],
    sqldb.[ProductID] as sqldb_ProductID,
    sqldb.[CampaignType],
    sqldb.[Location],
    sqldb.[No_Subcampaigns],
    sqldb.[Conducted_Via],
    sqldb.[How_It_Went],
    sqldb.[Total_Attendees],
    aggr.*
FROM azuresql.CampaignData sqldb
JOIN (
    SELECT 
        AWS.ProductID AS AWS_ProductID,
        AWS.[ProductName],
        AWS.[ProductCategory],
        AWS.[StoreLocation],
        AWS.[InventorySKU],
        AWS.[StockAvailabilityStatus],
        AWS.[LastRestockDateTime],
        AWS.[EventProcessedUtcTime],
        AWS.[PartitionId],
        AWS.[EventEnqueuedUtcTime],
        csdb.[ProductID],
        csdb.[CustomerSentiment],
        csdb.[Website_Bounce_Rate],
        csdb.[Total_No_Of_Searches],
        csdb.[CustomerSatisfactionRate]
    FROM cosmosDb.Inventory_Customersentiment csdb
    JOIN AWS.products AWS
        ON AWS.ProductID = csdb.ProductID
) aggr
ON aggr.AWS_ProductID = sqldb.[ProductID];


```

![](media/unifiedquery3.png)


5. Right click on **SQL query1**, click on **Rename** and paste **Integrated_sqlquery** in the **Name** field.

![](media/unifiedquery4.png)


### Task 4: Setting up Eventstream

1. In Power BI service, click on **Workspaces** and **click** on the current working workspace. 

	![Close the browser.](media/power-bi-5.png)

2. **Filter** for the **Eventstream** and click on **ThermostatEventStream_...**.

	![Close the browser.](media/thermostat1.png)

3. Click on **Use custom endpoint**.

	![](media/thermostat2.png)

4. Paste **Thermostat** in the Source name and click on **Add**.

	![](media/thermostat3.png)

5. Click on **Transform events or add destination** and then click on **Eventhouse**.

	![](media/thermostat4.png)

6. For **Data ingestion mode**, 
    - Select **Event processing before ingestion**, 
    - Paste **Eventhouse** for the **Destination name** field, 
    - Select the current workspace from the drop down for **Workspace** field, 
    - Select the **ZAVA-Eventhouse** from the drop down for **Eventhouse** field, 
    - Select the **ZAVA-Eventhouse** from the drop down for **KQL Database** field, 
    - For **KQL Destination table** field, click on **Create new**, 
    - paste **thermostat** in the **Table name** field and then click on **Done**.

	![](media/thermostat5.png)

7. Click on **Save**.

	![](media/thermostat6.png)

8. Click on **Publish**.

	![](media/thermostat7.png)

9.  Click on the three lines in the bottom right corner of the **Thermostat** endpoint,
    - Click on **SAS KeyAuthentication**.
    - Copy the values of **Event hub name**.
    - Click on eye icon of  **Connection string-primary key**, copy the value and then store them in Notepad for the next steps.

	![](media/thermostat8.png)

10. In Power BI service, click on **Workspaces** and **click** on the current working workspace. 

	![Close the browser.](media/power-bi-5.png)

11. **Filter** for the **Notebook** and click on **Generate realtime thermostat data**.

	![Close the browser.](media/thermostat9.png)

12. Go to the last cell and replace the **#Connection string-primary key#** and **#Event hub name#** with the values copied in step 9.

	![](media/thermostat10.png)

13. Click on **Run all**.

	![](media/thermostat11.png)

>**📝 Note:** The above Notebook will generate only 100 records per run, if you want more data, schedule the notebook accordingly.

![](media/thermostat14.png)

![](media/thermostat13.png)



14. Repeat steps 1 to 13:
    - In Step 2, click on **Eventstream_foottraffic_..**.
    - In Step 4, enter **foottraffic**.
    - In Step 6, after clicking on "New Table," enter the table name as **foottraffic**.
    - In Step 9, click on the three ellipses of the **foottraffic** endpoint.
    - In Step 11, click on **FootTraffic_RealtimeData.ipynb**.

15. Repeat steps 1 to 13:
    - In Step 2, click on **Eventstream_Inventory_..**.
    - In Step 4, enter **Inventory**.
    - In Step 6, after clicking on "New Table," enter the table name as **Inventory**.
    - In Step 9, click on the three ellipses of the **Inventory** endpoint.
    - In Step 11, click on **real-time paint accessory inventory data.ipynb**.

**Appendix:** After Step 8, if want we can add **Manage fields** in between Eventsream and eventhouse, **Filters** in between Eventsream and stream.

![](media/thermostat15.png)

![](media/thermostat16.png)

![](media/thermostat17.png)

### Task 5: Get data into QuerySet

1. Navigate to the **Microsoft Fabric** tab on your browser (https://app.fabric.microsoft.com).

2. Click on **Filter** to select **KQL Queryset**.

![queryset](media/queryset1.png)

3. Click on **thermostat**.

![queryset](media/queryset3.png)

<!-- 4. Click on **select database** and then Slect **OneLake data hub**.

![queryset](media/queryset3.png) -->

4. Click on **+ Add data source** and then select **Eventhouse/KQL Database**.
 
![queryset](media/eventhousegetdata4.1.png)

5. Select the **ZAVA-Eventhouse** and then click on **Connect**.

![queryset](media/queryset4.png)


### Task 6: Create Genie 

1. Navigate to the Azure Portal, 
    - In the **rg-herodemos-dpoc-...** resource group, search for **Databricks** and click on the Databricks resource with the name **adb-fabric....**

![databricks](media/databricks1.png)

2. Click on the **Launch Workspace** button.

![databricks](media/databricks2.png)

3. Sign in with the user ID used to create the rg.

4. In the left menu bar, click on **Genie**.

![databricks](media/databricks3.png)

5. Click on **+ New**.

![databricks](media/databricks4.png)

6. Click on **All** and then click on **herodemo_unity_catalog**.

![databricks](media/databricks5.png)

7. Click on **herodemo**.

![databricks](media/databricks6.png)

8. Select **bronze_campaign_data** and **gold_top_loss_making_campaign**, then click on **Create**.

![databricks](media/databricks7.png)

9. Click on **New Space** in the top left to edit the name and replace it with **Hero_Genie**.

![databricks](media/databricks9.png)



### Task 7: Creating a data agent

> This task only works if you selected the Fabric Capacity License in Task 1.

1. Open the **Microsoft Fabric** tab in your browser.

2. Click on **Workspaces** in the left navigation pane and select **Zava**.

![task-1.3.02.png](media/power-bi-5.png)

3. Click on **+ New item**, search for `Data agent` and click on **Data agent**.

![task-1.3.02.png](media/Dataagent1.png)

4. Paste `DataAgent` in the name field and click on **Create**.

![task-1.3.02.png](media/Dataagent2.png)

5. Click on **+ Data source**.

![task-1.3.02.png](media/Dataagent3.png)

6. Click on the **lakehouseSilver..** checkbox and click on **Connect**.

![task-1.3.02.png](media/Dataagent4.png)

7. Expand **LakehouseSilver..**, expand **dbo** and then select all the tables.

![task-1.3.02.png](media/Dataagent5.png)

8. Click on **AI instructions** and then paste following instructions in it.

```
You have access to multiple connected data sources including:
Customer Sentiment Data from Lakehouse DB, which includes customer satisfaction and sentiment analysis.
Marketing Campaign Data from a Data Warehouse, providing information about active and past campaigns.
Inventory and Store Temperature Data from KQL DB, containing real-time inventory and store environmental data.
Use this data to answer business questions about:
Customer preferences and satisfaction trends
Real-time inventory status across locations
The impact of marketing campaigns
Issues affecting sales performance, especially for locations like Miami and San Francisco
Provide concise, insightful answers without requiring SQL or code.
Combine campaign effectiveness, post-campaign sales uplift, and customer sentiment insights into one unified view. Use the following sources:
DataWarehouse: Get campaign revenue, cost, ROI, product category, and customer segment details from Campaigndata.
Eventhouse: Add store-level foot traffic and inventory data from foottraffic and Inventory to measure physical impact of campaigns.
Lakehouse_Silver: Include average customer satisfaction and churn metrics during campaign periods from customersatisfactiondata.
Combine all relevant metrics into a single table where each row represents a campaign, and include columns such as:
Campaign_Name, Region, ProductCategory, Revenue, ROI, Customer_Segment
AvgCustomerSatisfaction, AvgChurn, PostCampaignSales, FootTrafficChange, InventoryLevelChange
Fill in metrics per campaign across time, territory, and product category.
```

![task-1.3.02.png](media/Dataagent6.png)

9. Click on **Example queries** and then click on the **pencil icon** beside Example SQL queries.

![task-1.3.02.png](media/Dataagent7.png)

10. Click on **+ Add example**, add the examples below and then **close** the example tab.

``` What is the monthly average customer satisfaction score?```

``` 
SELECT FORMAT(CAST([Date] AS DATE), 'yyyy-MM') AS Month, AVG([CustomerSatisfaction]) AS AvgSatisfaction FROM dbo.[customersatisfactiondata]
GROUP BY FORMAT(CAST([Date] AS DATE), 'yyyy-MM')
ORDER BY Month;
```
```What is the trend of actual churn over time? ```
```
SELECT Date, ActualChurn
FROM dbo.customersatisfactiondata
ORDER BY Date;
``` 

```Which months showed a decline in satisfaction but rise in churn?```
```
SELECT FORMAT(CAST([Date] AS DATE), 'yyyy-MM') AS Month,
       AVG(CustomerSatisfaction) AS AvgSatisfaction,
       AVG(ActualChurn) AS AvgChurn
FROM dbo.customersatisfactiondata
GROUP BY FORMAT(CAST([Date] AS DATE), 'yyyy-MM')
HAVING AVG(CustomerSatisfaction) < 0.5 
   AND AVG(ActualChurn) > 0.3
ORDER BY Month;

```





![task-1.3.02.png](media/Dataagent8.png)

11. Click on **Publish**.

![task-1.3.02.png](media/Dataagent9.png)



### Task 8: Creating a Semantic Model for Power BI

1. Open the **Microsoft Fabric** tab on your browser.

2. Click on **Workspaces** in the left navigation pane and select **Zava**.

![task-1.3.02.png](media/power-bi-5.png)

3. Click on **Filter** and select **Lakehouse**.

![task-1.3-ext-shortcut1.png](media/sellakehouse.png)

4. Click on **Lakehouse_Silver**.

> **Note:** There are 3 lakehouse options, namely Lakehouse, Semantic model (Default) and SQL endpoint. Make sure you select the **Lakehouse Type** option.

![task-wb11.png](media/lakehousesilver.png)

5. Click on the **New semantic model** button.

![task-new4.png](media/lakehousesilver1.png)

6. In the **Name** field, enter **Website_Bounce_Rate**.

7. Select **Zava** as the workspace, click on the expand icon next to the **dbo** checkbox and then click on the expand icon next to the **Tables** checkbox.

![task-new5.png](media/semantic1.png)

8. Scroll down if you see a scrollbar and select the **product_inventory** and **website_bounce_rate** tables, then click on the **Confirm** button.

![task-new6.png](media/semantic2.png)

>**Note:** Wait for the semantic model creation.

<!-- 10. To create the second semantic model,
- Follow the same steps from 1 to 5.
- In **step 6**, enter **Sales_Report** in the **Name** field.
- Follow steps 7 and 8.
- In **step 9**, select **dim_products** and **fact_sales**.

11. After creating the **Sales_Report** Semantic Model, click on New Table. In the formula tab, paste ```[Dim_Measures] = Row(""Column"", BLANK())``` and then click on the **Enter** button.

![task-new6.png](media/semantic3.png)

12. **Right click** on the **Dim_Measures** table and select **New Measure**.

![task-new6.png](media/semantic4.png)

13. In the formula tab, paste ```Number of Rows = COUNTROWS(fact_sales)``` and then click on the **Enter** button.

![task-new6.png](media/semantic3.1.png)

14. Repeat **step 12 and 13** four times to add four new measures.

    - ```Orders = sum(fact_sales[Quantity])/10000```
    - ```Price = sum(fact_sales[Price])/10000```
    - ```Profit = sum(fact_sales[ProfitAmount])/10000```
    - ```Revenue = sum(fact_sales[TotalAmount])/10000```

![task-new6.png](media/semantic5.png) -->


### Task 9: Updating Semantic Models with Cloud connection

1. Open the **Microsoft Fabric** tab in your browser.

2. Click on **Workspaces** in the left navigation pane and select **Zava**.

![task-1.3.02.png](media/power-bi-5.png)

3. Click on **Filter** and select **Semantic model**.

![task-1.3-ext-shortcut1.png](media/selsemantic1.png)

4. Click on the three dots (ellipsis) next to the **Column Level Security in Warehouse** Semantic model and click on **Settings**.

![](media/settingssel.png)

5. Expand **Gateway and cloud connections**. In the Cloud connections, click on the dropdown and then select **Create a connection**.

![](media/semanticauthentication.png)

6. Paste `Datawarehousecon` in the **Connection name** field, select **OAuth 2.0** in the **Authentication method** and then click on **Edit credentials**.

![](media/semanticeditcred.png)

7. Select the **user account** that was used for logging into the **Azure Portal** in [Task 1](#task-1-create-a-resource-group-in-azure).

   ![Cloud Shell](media/cloud-shell-8.png)

8. Click on the **Create** button.

![](media/updatesemantic2.png)

10. Click on the dropdown under **Cloud connections**, select **Datawarehousecon** and then click on the **Apply** button.

![](media/lakehousereports1.png)

11. Click on **Object Level Security in Warehouse** semantic model from the list.
    - Expand **Gateway and Cloud connections**.
    - In the **Cloud connections**, click on dropdown and select **Datawarehousecon**.
    - Click on the **Apply** button.

![](media/lakehousereports.png)

12. Repeat **Step 11** for the **Row-Level Security in Warehouse** and **Dynamic Data Masking in Warehouse** semantic models.

13. Click on  **Sales_Report** semantic model from the list.

14. Expand **Gateway and cloud connections**. In the Cloud connections, click on the dropdown and then select **Create a connection**.

![](media/semanticauthentication1.1.png)

15. Paste `Lakehouseconn` in the **Connection name** field, select **OAuth 2.0** in the **Authentication method** and then click on **Edit credentials**.

![](media/semanticeditcred1.png)

16. Select the **user account** that was used for logging into the **Azure Portal** in [Task 1](#task-1-create-a-resource-group-in-azure).

   ![Cloud Shell](media/cloud-shell-8.png)

17. Click on the **Create** button.

![](media/updatesemantic2.1.png)

18. Click on the dropdown under **Cloud connections**, select **Lakehouseconn** and then click on the **Apply** button.

![](media/lakehousereports1.png)

### Task 10: Creating a Dashboard and enabling Data Activator

1. Click on the **Workspaces** in the left navigation pane and select **Zava**.

	![Close the browser.](media/power-bi-5.png)

2. Filter for **KQL Database** and select **Zava-Eventhouse**.

	![](media/activator02.png)

3. Click on **Real-Time Dashboard**, paste **Impactful Zava RTI Dashboard** in the **New dashboard** field and then click on **Create**.

![](media/dashboard1.png)

4. Click on **Viewing** in the top right and then click on **Editing**.

**Note: If it is already in Editing mode, continue with next steps**.

![](media/dashboard2.png)

5. Click on **New tile**.

![](media/dashboard3.png)

6. Paste the Query below, 

```
thermostat| summarize round(avg(toint(Temp)),0)
```

7. Click on the **Run icon**.
8. Click on **+ Add Visual**.
9. In Visual formating tab, paste **Tempertaure** in the Tile name field.
10. Select **Stat** in visual type field.
11. Click on **Apply chnages**.



![](media/dashboard4.png)

12. Click on **New tile**.
13. Paste the Query below,

```
['foottraffic']| summarize  round(avg(['before_traffic']),0)
```
14. Click on **Run icon**.
15. Click on **+ Add visual**.
16. In Visual formating tab, paste **Foot traffic** in the Tile name field.
17. Select **Stat** in the visual type field.
18. Click on **Apply chnages**.

![](media/dashboard5.png)

19. Click on **New tile**.
20. Paste the Query below, click on **Run icon**.
```
thermostat | summarize round(avg(BatteryLevel),0)
```
21. Click on **+ Add visual** in Visual formatting  tab.
22. Paste **Battery Level (%)** in the Tile name field.
23. Select **Stat** type in the visual type field.
24. In the **Conditional formatting ** tab click on **Add rule** and then click on the **pencil icon**.

![](media/dashboard6.png)

25. In the Conditional formatting tab,
26. For the **Color style** click on drop down and select **Light**.
27. For **Conditions** field, paste **0** in the **Value** field.
28. For **Formatting**, select the **Yellow** color from the drop down.
29. For **Icon** field, select the **globe** icon from the list and then click on the **Save** button.

![](media/dashboard7.1.png)

30. Click on **Apply changes**.

![](media/dashboard12.png)

31. Click on **New tile**.
32. Paste the Query below.
```
thermostat
| where  City in ("San Francisco","New York", "Miami","Tokyo")
| summarize ['Battery(%)'] = toint(avg(BatteryLevel)), ['Date Time'] = format_datetime(todatetime(max(EnqueuedTimeUTC)), '[HH:mm]')
    by City, bin(todatetime(EnqueuedTimeUTC),1h)
| project ['Date Time'], City, ['Battery(%)']
|sort by ['Date Time']asc 

```
33. Click on **Run icon**.
34. Click **+ Add visual**.
35. In Visual formating tab, paste **Battery Levels by City and Time** in the Tile name field.   - Select **Line chart** in visual type field.

![](media/dashboard8.png)

36. Scroll down and expand **Y Axis**.
37. In the Label field paste **Battery Level %**.
38. In the **Maximum value** field paste **52**.
39. In the **Minimum value** field paste **45**.
40. Click on the **Apply changes** button.

![](media/dashboard9.png)

41. Click on **New tile**.
42. Paste the Query below.
```
Inventory
| where StockAvailabilityStatus  <> 'Medium Stock'
| project Category = ProductCategory,Product = ProductName,Store = StoreLocation,Inventory = InventorySKU,Status = StockAvailabilityStatus,['Last Restocked Date']= LastRestockDateTime
```
43. Click on **Run icon**.
44. Click **+ Add visual**.
45. In Visual formating tab, paste **Inventory Details** in the Tile name field.
46. Select **Table** in visual type field.
47. In the **Conditional formating** tab, click on the **Toggle** button beside **Show**.
48. Click on **+ Add rule** and then click on **pencil icon**.

![](media/dashboard10.png)

49. For Rule type, select **Color by value** in the dropdown menu. 
50. In the Column field, select **Inventory (long)** from the dropdown menu. 
51. In the Theme field, select **Yellow** from the dropdown menu. 
52. For Apply options, under Formatting, select **Apply to rows**. 
53. Click on the **Save** button. 

![](media/dashboard11.png)

54. Click on **Apply changes**.

![](media/dashboard12.png)

55. Click on **Set alert**, click on **Temperature** and then click on the **Select** button.

![](media/activator1.png)

56. Under Field, select **avg_Temp**. 
57. For Condition, select **Is greater than or equal**. 
58. Set the Value to **69**. 

![](media/activator2.png)

59. Scroll down and click on the **Message me in Teams** radio button.
60. In the Workspace field, select the **Zava** workspace.
61. For the **Item** field, click on the dropdown and select **Create a new item**.
62. Paste **Zava-Activator** in the New item name field.
63. Click on the **Create** button.

![](media/activator3.png)

64. Click on **Save**.

![](media/dashboard13.png)





<!-- 3. In the KQL Database screen **click** on the three dots in front of the Thermostat table and select **PowerBI**.

	![Close the browser.](media/data-activator-3.1.png)

4. **Select** 'Area chart', **expand** 'Kusto Query Result', **select** 'ExnquedTimeUTC' and 'Sum of Temp' in the 'X-axis' and 'Y-axis' respectively and you would notice a chart as shown in the screenshot.

	![Close the browser.](media/data-activator-4.1.1.png)

5. **Click** on the 'expand' icon of the Sum of Temp and **select** 'Average'.

	![Close the browser.](media/data-activator-4.1.png)

6. **Expand** 'File' and **select** 'Save'.

	![Close the browser.](media/data-activator-5.png)

7. **Enter** the Name of the file as 'kqlRealtimeReport', **select** the workspace name as 'Zaca' and then **click** on 'Continue'.

	![Close the browser.](media/data-activator-7.png)

9. **Click** on 'Open file' option.

	![Close the browser.](media/data-activator-8.png)

10. **Click** on the **Set alert**.

	![Close the browser.](media/data-activator-9.1.png)

11. Click on **Average of Temp Alert**.

	![Close the browser.](media/act1.png)

12. Select the radio button for **Becomes**.  
    In the **Condition** field drop-down, select **Greater than**.  
    In the **Value** field, paste **68.00**.  
    Select **Teams** in **Send Notification**, and then click on **Apply**.

	![Close the browser.](media/act2.png)

13. Click on **My Power BI Activator Alerts**.  
    Select the appropriate **Workspace**.  
    In the **Item** field, select **Create a new activator item**.  
    Enter the **Item Name** as **Store Analytics**.  
    Click on the **Confirm** button.

	![Close the browser.](media/act3.png) -->


### Task 11: Create Digital Twin Builder

1. Open the **Microsoft Fabric** tab on your browser.

2. Click on **Workspaces** in the left navigation pane and select **Zava**.

![task-1.3.02.png](media/power-bi-5.png)

3. Click on **+ New item**, search for **Digital Twin Builder** and then click on **Digital Twin Builder (preview)**.

![DTB](media/dtb1.png)

4. Paste **HeroDemo_DTB** in the Name field and then click on **Create**.

![DTB](media/dtb2.png)


### Task 12: Creating a Cosmos DB Mirror

Mirroring in Fabric provides an easy experience to avoid complex ETL (Extract Transform Load) processes and integrate your existing Azure Cosmos Database estate with the rest of your data in Microsoft Fabric.

1. Navigate to the **Microsoft Fabric** tab on your browser (https://app.fabric.microsoft.com).

2. Click on your **workspace** in the left navigation pane and select **New item** from the menu bar.

![Task-1.1_1.png](media/Task-6.1_1.png)

3. In the **New item** window, search for **Cosmos** in the search bar, then select **Mirrored Azure Cosmos DB...**.

![Task-1.1_2.png.png](media/Task-1.1_2.png)

4. When prompted to **Choose a database connection to get started**, look for **New sources** and select **Azure Cosmos DB v2**.

![Task-1.1_3.png.png](media/Task-1.1_3.png)

> **Note:** To fill in the details for required fields, we need to fetch the data from the Cosmosdb resource deployed in the Azure Portal.

5. Navigate to the **Azure Portal**.
   - In the resource group **herodemos-dpoc-...**, click on the **cosmosdb** resource.

![Pipeline.](media/selcosmosdb.png)

6. Copy the **Server name** value.

![Pipeline.](media/task-1.3.13.png)

<!-- 7. In the left search bar, search for **Keys**, click on **keys** and then Click on **show primary key** icon,

![cosmosdb](media/cosmosdb1.png)

8. Copy the **primary key**

![cosmosdb](media/cosmosdb2.png) -->

9. Navigate back to the **Fabric** tab on your browser.

10. In the **Cosmos DB Endpoint** field, paste the URI you copied in **step 6**. This will automatically fetch the pre-created connection.

11. Click on **Create**.

![cosmosdb](media/cosmosdb3.png)

<!-- 11. Select **Account key** for Authentication kind, paste the primary key copied in step 8 as key value, and click on the **Connect** button.

![Task-1.1_4.png.png](media/Task-1.1_4.png) -->

12. Click on the dropdown for Database, then select **CustomerSentimentdata** and click on the **Connect** button.

![Task-1.1_5.png.png](media/cosmosdb4.png)

13. Click on the **Connect** button.

![Task-1.1_6.png.png](media/cosmosdb5.png)

14. In the Name field, paste `Mirror_cosmosdb_CustomerSentimentdata`.
   -  Click on the **Create mirrored database** button.

![Task-1.1_7.png.png](media/cosmosdb6.png)

15. Show **Monitor replication** Status to track the replication status.

![Task-1.1_8.png.png](media/cosmosdb7.png)

>**Note:**Wait until the Rows replicated statistics are displayed. If not displayed, refresh the **Monitor replication** tab as shown in the screen below. Now, Azure Cosmos DB has been successfully mirrored.


### Task 13: Setting up and Running Data Pipelines

1. Navigate to the **Microsoft Fabric** tab on your browser (https://app.fabric.microsoft.com).

2. Click on your workspace and filter for **Data Pipeline**.

![](media/datapipeline1.png)

3. Click on **Ingest AzureSQLDB data using Pipeline**.

![](media/datapipeline2.png)

4. Click on **Destination**, click on the **X** next to **Existing Connection** and click on **Drop down**.

![](media/datapipeline3.png)


5. Click on **Browse all**.

![](media/datapipeline4.png)


6. Click on **OneLake Catalog** in the left navigation pane, search for **SQL_DB** and the click on **SQL_DB**.

![](media/datapipeline5.png)


7. Make sure new connection is created.
  - Click on the **Auto create tale** radio button.
  - Paste **@item().destination.schema** in the Schema field.
  - Paste **@item().destination.table** in the Table field.

![](media/datapipeline6.png)

8. Click on the **Save icon**.
   - Click on **Run** and then click on **Ok**.

![](media/datapipeline7.png)

<!-- 9. Click on your workspace, and filter for **Data Pipeline**.

![](media/datapipeline1.png)

10. Click on **Ingest Datawarehouse data using pipeline**.

![](media/datapipeline8.png)

11. Click on **Get Metadata1** and then click on **Settings**, click on **Select** for Connection field.

![](media/datapipeline9.png)

12. Search for **Azure Data Lake** and click on **Azure Data lake Storage Gen2**. 

![](media/datapipeline10.png)

13. In a new tab, open the **resource group** created in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources) with name 'rg-herodemos-dpoc..'.

14. Click the **storage account resource**.

   ![Lakehouse.](media/demo-10.png)

15. In the resource window, go to the **left pane** and scroll down.

16. In the **Security + networking** section, click on **Access keys**.

17. click on the **Show** button under **key1**.

    ![Lakehouse.](media/demo-11.png)

18. click on **Copy** icon next to **Key**.

19. **Save** it in a notepad for further use.

    ![Lakehouse.](media/demo-12.png)

20. **Scroll down** in the left pane.

21. Select **Endpoints** from the **Settings** section.

22. **Scroll down** and copy the **'Data Lake Storage'** endpoint under the 'Data Lake Storage' section.(Save it in a **notepad** for further use)

    ![Lakehouse.](media/demo-12.1.png)

> **Note:** You may see different endpoints as well in the above screen. Make sure to select only the Data Lake Storage endpoint.

23. Navigate back to the **Power BI workspace** (the power bi tab which we working in earlier).

24. Paste the endpoint copied under the URL field.In the Authentiation kind dropdown, select the Account Key.Paste the account key copied in step number. Click on **Connect** button.

![](media/datapipeline11.png)

25. Paste **datawarehouse** in File path container filed. and then click on **+ New** for fieldlist, from the drop down click on **Child items**.

![](media/datapipeline13.png)


25. Double click on **copy data1**, click on **Source** and then click on **drop down**.

![](media/datapipeline12.png)

26. Click on **Browse all**

![](media/datapipeline4.png)

27. Search for **Azure Data Lake** and click on **Azure Data lake Storage Gen2**. 

![](media/datapipeline10.png)

28. Paste the endpoint copied in step 22 under the URL field. Click on **Connect** button..

29. Paste **datawarehouse** in File path container filed.

![](media/datapipeline14.png)

30. Click on **Save icon** and then click on **Run**.

![](media/datapipeline15.png) -->


### Task 14: Azure Purview set up

1. From the **Azure Portal**, search for **purview** in the resource group and click on the resource.

   ![](./media/purview-1.png)

2. The Azure Purview resource window will open. **Click** on **Open Azure Purview Studio** and the Azure Purview Studio will open in a new window.
  
   ![](./media/purview-2.png)

>**Note:** The steps below are visible to the user only when using the new Classic Purview portal, which is available as a single instance per tenant. If a new Purview account already exists in the tenant, any subsequent Purview accounts deployed will not include the new Classic portal.

3. In the Azure Purview Portal, Click on **Solutions** and go to **Data Map** 

   ![](./media/p1.png)

4. Click on **Data Sources** and then click **Register** to add a new data source.

   ![](./media/gd20.png)

5. Select **Azure SQL Database** and then click **Continue**.

   ![](./media/image2.png)

6. On the **Register data source** page, provide the **data source name**.

7. Select the required **Azure subscription**. 

8. Choose the **SQL Server** you want to connect to. 

9. Accept the default **Endpoint** and then click **Register**.

   ![](./media/image3.png)

10. Click on **Data Sources** and then click **Register** to add a new data source.

   ![](./media/gd20.png)

11. Select **Fabric**, and then choose **Continue**.

   ![](./media/image5.png)

12. On the Register data source page, enter the **Data source name**, **Tenant ID** and click **Register**.

   ![](./media/image6.png)

>**Note:** You can follow the same steps to add any other data sources you need.

   ![](./media/image7.png)

## Adding the Governance domains

1. From the left navigation menu, go to **Solutions** and then select **Unity Catalog**.

    ![](./media/gd1.png)

2. Expand **Catalog Management**, select **Governance Domains**, and then click **+ New Governance Domain**.

    ![](./media/gd2.png)

3. Enter the required **Name** and **Description**, select the **Type**, and then click **Next**.

    ![](./media/gd3.png)

    >**Note:** You can choose the name of your domain based on the type of data it will contain.

4.  On the Custom Attributes page, accept the default settings and click **Create** to finish creating the governance domain.

    ![](./media/gd4.png)

5. To assign permissions for a governance domain, select the **domain** you created previously, go to **Roles**, click the **Add** icon in front of Governance Domain Owner, and add people.

    ![](./media/gd5.png)

## Creating the Sensitivity label

1. From the left navigation menu, click on **Solutions** and then select **Information Protection**.

    ![](./media/gd6.png)

2. From the left navigation, select **Sensitivity Labels** and click **+ Create a label**.

    ![](./media/gd7.png)

3. On the Label Details page, enter the required information such as **Name**, **Display Name**, and **Description**, then click **Next**.

    ![](./media/gd8.png)

    >**Note:** You can provide the details based on the type of sensitivity label you are creating.

4. In the **Scope** section, select the required scope where the sensitivity label should be enabled

    ![](./media/gd9.png)

5. In the **Items** section, select the checkbox next to **Control access** and click **Next**.

    ![](./media/gd10.png)

6. In the Access control section, select the radio button next to **Configure access control**, **Assign permissions** to the sensitivity label by choosing the required users, and then click **Next**.

    ![](./media/purview2.png)

7. Review the settings, then click **Create label** to finalize.

    ![](./media/gd12.png)

8. After creating a sensitivity label, you need to create a policy label on top of it. Select the sensitivity label you created and click **Publish Label**.

    ![](./media/gd13.png)

9. On the Create Policy page, select the sensitivity label you created earlier, then click **Next**.

    ![](./media/gd14.png)

10. Navigate to the **Users and Groups** page. Click on **Edit**, then select the user who should be granted access to the sensitivity label. Once the appropriate user is selected, click **Next** to proceed.

    ![](./media/gd15.png)

11. On the Policy Settings page, enable the checkbox labeled **Require users to apply a label to their Fabric and Power BI content.** This setting grants the previously selected user access to manage sensitivity labels for content within Microsoft Fabric and Power BI and click on **Next**.

    ![](./media/gd16.png)

12. Go to the **Apply a default label to Fabric and Power BI content** setting and choose the sensitivity label you created earlier. 

    ![](./media/gd17.png)

13. Enter a name for the policy, then click **Next** to continue.

    ![](./media/gd18.png)

14. On the Review and Finish page, review your selections and then click **Submit**.

    ![](./media/gd19.png)

    

### Appendix

>**Note:** Follow these steps to create a **Mirrored Snowflake** database only if you have an existing **Snowflake** resource.

### Setting up the Mirrored Snowflake

1. Navigate to the **Microsoft Fabric** tab on your browser (https://app.fabric.microsoft.com).

2. Click on **+ New item**, search for `snowflake` and click on **Mirrored Snowflake**.

![task-1.3.02.png](media/snowflake1.png)

3. Search for **snowflake** and click on **Snowflake**.

![](media/snowflake2.png)

4. Go to the Snowflake resource and copy **Server, Warehouse, Username, password**.
5. Return to the fabric page and paste all the values copied from Snowfalke resource and then click on **Connect**.

![](media/snowflake3.png)

6. Paste the name as **Mirrored_Snowflake_DB** and click on **Connect**

7. Check the **Monitor replication**.

![](media/snowflake4.png)


