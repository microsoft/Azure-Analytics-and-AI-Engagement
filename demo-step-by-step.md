**Contents**

<!-- TOC -->

- [Azure Synapse hands-on lab step-by-step](#)
  - [Accessing Synapse Workspace](#Accessing-Synapse-Workspace)
  - [Exercise 1: Data Orchestration and Ingestion](#Exercise-1-Data-Orchestration-and-Ingestion)
    - [Task 1: Data Ingestion](#Task-1-Data-Ingestion)
    - [Task 2: Migrate SAP Hana to Azure Synapse Analytics](#Task-2-Migrate-SAP-Hana-to-Azure-Synapse-Analytics)
    - [Task 3: Code First Experience: Migrate Teradata to Azure Synapse Analytics](#Task-3-Code-First-Experience-Migrate-Teradata-to-Azure-Synapse-Analytics)
    - [Task 4: Migrate last five years of sales transactional data from Oracle to Azure Synapse Analytics](#Task-4-Migrate-last-five-years-of-sales-transactional-data-from-Oracle-to-Azure-Synapse-Analytics)
    - [Task 5: Moving semi-structured data to Azure Synapse Analytics](#Task-5-Moving-semi-structured-data-to-Azure-Synapse-Analytics)
    - [Task 6: On Demand Query: Azure Data Lake Gen2](#Task-6-On-Demand-Query-Azure-Data-Lake-Gen2)
    - [Task 7: COPY INTO Command](#Task-7-COPY-INTO-Command)
  - [Exercise 2: Develop Hub](#Exercise-2-Develop-Hub)
    - [Task 1: Running Queries against 30 Billion records](#Task-1-Running-Queries-against-30-Billion-records)
    - [Task 2: JSON Extractor Differentiator and other optional differentiator](#Task-2-JSON-Extractor-Differentiator-and-other-optional-differentiator)
    - [Task 3: Using Notebooks to Run Machine Learning Experiments](#Task-3-Using-Notebooks-to-Run-Machine-Learning-Experiments)
    - [Task 4: AutoML in Azure Synapse Analytics](#Task-4-AutoML-in-Azure-Synapse-Analytics)
  - [Exercise 3: Power BI reporting within the Synapse Analytics workspace](#Exercise-3-Power-BI-reporting-within-the-Synapse-Analytics-workspace)
    - [Task 1: Accessing PowerBI reports in Synapse Analytics workspace](#Task-1-Accessing-PowerBI-reports-in-Synapse-Analytics-workspace)
    - [Task 2: Ad Hoc Reporting in Azure Synapse Analytics](#Task-2-Ad-Hoc-Reporting-in-Azure-Synapse-Analytics)

<!-- /TOC -->

# Accessing Synapse Workspace

Select the Synapse Workspace web URL to access your Synapse Workspace.

![Synapse Workspace](media/synapse-workspace-access.jpg) 

Once you access your workspace select the arrow on the top of the left menu to open the slider and access various sections of the workspace.

![Synapse Workspace](media/2020-04-10_15-51-29.png)

## Exercise 1: Data Orchestration and Ingestion

### Task 1: Data Ingestion

1. On the Synapse Home page select **Ingest**.

![Dream Demo Synapse](media/2020-04-10_15-53-52.png)

2. In the Copy data dialog select **Next**.

![Properties](media/2020-04-11_11-09-46.png)

3. Select **Create new connection**

![Create new connection](media/2020-04-11_11-11-00.png)

4. See all available data providers.

![Create new connection](media/05-05.png)

**TODO** What is the purpose of seeing these options? Maybe we can include a demo to show how it is done?

### Task 2: Migrate SAP Hana to Azure Synapse Analytics

1. Select **Orchestrate**

![SAP HANA To ADLS Pipeline](media/2020-04-11_11-12-13.png)

2. Select/Expand **Pipelines** and then select **SAP HANA TO ADLS** pipeline.

![Ingesting finance data from SAP Hana](media/2020-04-10_16-03-02.png)

3. From the editor window select **Copy data** activity. Then select **Source** property of the **Copy data** activity to see the **Source Dataset** and observe that the query is pulling data from SAP Hana

![Ingesting finance data from SAP Hana](media/2020-04-10_16-03-54.png)

4. With copy data selected, select the **Sink** property of the **Copy data** activity. Look at the **Sink** dataset, in this case; you are saving to ADLS Gen2 storage container.

![Data moves to Azure Data Lake Gen2](media/2020-04-10_16-05-13.png)

5. Select **Mapping Data Flow** activity and then select **Settings**. Next select **Open** to go to **Data Flow** editor.

![Mapping Data Flow](media/2020-04-10_16-06-30.png)

6. In Data Flow editor observe the flow. Look in detail into each activity using the following steps.

![Moving data from SAP to the Data Lake](media/2020-04-10_16-07-29.png)

7.	In the **first activity**, we are selecting data from the Data Lake staging area.
8.	In the **second activity**, we are filtering data for the last 5 years.

![filtering data for the last 5 years](media/2020-04-10_16-15-39.png)

9.	In the **third activity**, we are deriving columns from a **Column Order Date**.

![deriving columns from a Column Order Date](media/2020-04-10_16-16-23.png)

10.	In the **fourth activity**, we are only selecting the required columns from the table.

![](media/2020-04-10_16-16-52.png)

11. In the **fifth activity**, we are creating an aggregated **Total Sales** grouped by **Year** and **Month**.

![](media/2020-04-10_16-17-46.png)

12. In the **sixth activity**, we load the aggregated table to Azure Synapse.

![Load the aggregated table to Azure Synapse](media/2020-04-10_16-18-21.png)

20. In the **seventh activity**, we are taking a parallel route by selecting all the remaining rows and writing the full table to Azure Synapse.

![Writing the full table to Azure Synapse](media/2020-04-10_16-18-47.png)

21. To view all the available transformations in the data flow editor, select the **+ (add action)**, which is to the right of the first activity.

![view all the available transformations](media/2020-04-10_16-19-47.png)

22.	Scroll down to see the full list of transformations at different levels.

![Full list of transformations at different levels](media/2020-04-10_16-20-21.png)

### Task 3: Code First Experience: Migrate Teradata to Azure Synapse Analytics

1. In the Orchestrate hub, select **MarketingDBMigration** from the list of pipelines.

![Full list of transformations at different levels](media/2020-04-10_16-24-54.png)

**Note:** This pipeline is for demonstration purposes only. __Do NOT execute__ the pipeline.

2. Select **Lookup** activity, then select **Settings** to observe the **Source dataset** property (Teradata).

![](media/2020-04-11_11-21-42.png)

3. Select **Copy data** activity and observe **Source** and **Sink** properties.

![](media/2020-04-11_11-24-23.png)

4. Select **Prep data in Azure Synapse** Notebook, then select **Settings**. Once you are in the settings tab, select **Open** to open the notebook

![](media/2020-04-10_16-27-51.png)

5.	Show the Python code. This is the code first experience in Synapse analytics.

![](media/2020-04-10_16-29-16.png)

### Task 4: Migrate last five years of sales transactional data from Oracle to Azure Synapse Analytics

1. Select **SalesDBMigration** from the **Orchestrate** hub.

![](media/2020-04-10_16-42-55.png)

2. Select **Lookup** activity and then **Settings** to see **OracleSalesDB** field in **Source Dataset** field

![](media/2020-04-10_16-50-57.png)

3. Select **Copy data** and see Synapse as the **sink**.

![](media/2020-04-10_16-54-39.png)

### Task 5: Moving semi-structured data to Azure Synapse Analytics

1. Select **TwitterDataMigration** from the list of pipelines.

![](media/2020-04-10_16-56-21.png)

2. Look at the **Copy data**, **Archive Tweets data in ADLS Gen2** and **Clean up the archived Twitter Data** activities. 

![](media/2020-04-10_16-57-19.png)

### Task 6: On Demand Query: Azure Data Lake Gen2

1. Select **Data** Hub from the left navigation in the Synapse Analytics workspace. From the **Data** blade, under **Storage accounts**, Select/expand **daidemosynapsestorageforgen2**. Observe various data sources (including CI) that are now in ADL Gen2 and then select **twitterdata** storage container.

![](media/2020-04-10_17-00-38.png)

2. See all the parquet files and other folders in the **twitterdata** container. Select the first two parquet files and right click, from the context menu, Select **New SQL Script**

![](media/2020-04-10_17-01-49.png)

3. Select **Run**.

**TODO** Currently not working.

![](media/2020-04-11_11-26-50.png)

4. Select **Chart**

![](media/05-31.png)

5. Minimize the **storage accounts** on the left side, then expand the **Databases** tree, expand **AzureSynapseDW (SQL pool)**, and finally expand **Tables** folder.

![](media/2020-04-11_11-29-17.png)

**TODO** Why did we do this?

### Task 7: COPY INTO Command

1. Select **Develop**, then expand **SQL Scripts** to list all available scripts. Select **8 External Data to Synapse Via Copy Into** and highlight the query presented below titled **Step:1**.

![](media/2020-04-10_17-06-50.png)

2. Select **Run** and observe the **No results found** message.

![](media/2020-04-11_11-31-19.png)

3.	Scroll to the bottom and select **COPY INTO** query below **Step:2** as shown in the screenshot. Finally, select **Run**

![](media/2020-04-11_11-32-39.png)

## Exercise 2: Develop Hub

### Task 1: Running Queries against 30 Billion records

1. Select **Develop** in the various tabs available in the **Develop** hub workspace and discover the environment. 

![](media/2020-04-10_17-09-25.png)

2. Select **SQL Scripts** and then select **1 SQL Query with Synapse**

![](media/2020-04-11_11-33-42.png)

3. Select **AzureSynapseDW** SQL Pool from the **Connect to** drop down menu. Once the **Use database** drop dows is populated select **AzureSynapseDW** database from the **Use Database** drop down. Finally, select the below query (#3 in the screenshot)

![](media/2020-04-11_11-35-09.png)

`SELECT COUNT_BIG(1) as TotalCount  FROM wwi.Sales(nolock)`

4. Select **Run** and observe the results (30 Billion).

![](media/2020-04-10_17-11-19.png)

5. Scroll down a few lines to the second query, select the query as shown in the screenshot, and then select **Run**. Observe time the query takes – query time is listed at the bottom of the screenshot.

![](media/2020-04-11_11-39-28.png)

5. Select the **chart** button, and then select **chart type** dropdown to see various chart types 

![](media/2020-04-11_11-40-23.png)

### Task 2: JSON Extractor Differentiator and other optional differentiator

1. Select **Develop**, and then select **2 JSON Extractor**. 
![](media/2020-04-10_17-13-47.png)

2. From the **Connect to** dropdown connect to **AzureSynapseDW** SQL Pool. Select the query as shown in the screenshot and select **Run**.

![](media/2020-04-10_17-14-55.png)

3. Observe the results of query 

![](media/2020-04-10_17-16-30.png)

### Task 3: Using Notebooks to Run Machine Learning Experiments

1. Select the **Develop** hub from the Synapse workspace. Next, select and expand the **Notebooks** option.

![](media/2020-04-10_17-17-52.png)

2. Select the **1. Product Recommendations** notebook, which will open the notebook.

![](media/2020-04-10_17-18-41.png)

3. Once the notebook is open, select **CDP DreamPool** from the **Attach to** dropdown. CDP DreamPool is a Spark Pool. Select **PySpark** from the **Language** dropdown list.

![](media/2020-04-10_17-19-32.png)

4. Expand **Language** and see supported languages.

![](media/05-45.png)

5. Observe the import statements in the Notebook 

**TODO** Not available in the environment

![](media/05-46.png)

6. Observe the results in the notebook under **Map Products**.

![](media/05-47.png)

See code in **cell 26**, but **DO NOT** execute any code.

![](media/05-48.png)

### Task 4: AutoML in Azure Synapse Analytics 

1. Select **Develop** from the Synapse workspace

![](media/2020-04-10_17-17-52.png)

2. Expand **Notebooks** section and select **2 AutoML Customer Forecasting** Notebook.

![](media/2020-04-10_17-23-41.png)

3. Scroll down to see the content in the screenshot.

![](media/05-51.png)

4. Scroll down to observe the content in the screenshot.

![](media/05-52.png)

**TODO** This content isn't really scrollable. 

5. Scroll down to see the code in **cell 35**.

![](media/05-53.png)

**TODO** This is not how **Cell 35** looks like

6. Scroll down to see **cell 42**.

![](media/05-54.png)

**TODO** This is not how **Cell 42** looks like

## Exercise 3: Power BI reporting within the Synapse Analytics workspace 

### Task 1: Accessing PowerBI reports in Synapse Analytics workspace 

1. Select **Develop** from the Synapse workspace and expand the **Power BI** section. Next, expand **Data & AI Demo** (which is a Power BI workspace) and expand **Power BI** reports. Finally, select **1. CDP Vision Demo** Power BI report. This will open the decomposition tree.

![](media/2020-04-10_17-27-03.png)

2. Once the report is open, in the **Decomposition Tree Analysis** tab see **Store Visits by Campaign** then by **Region**. Select **+** next to **North & Central America** 

![](media/2020-04-11_11-42-23.png)

3. Select **QnA** tab 

![](media/2020-04-11_11-43-15.png)

4. In the **Q&A** box, type **profit by country by product category as treemap**

![](media/2020-04-11_11-44-04.png)

### Task 2: Ad Hoc Reporting in Azure Synapse Analytics

1. From the **Develop** hub, **Power BI** section select **2. Billion Rows Demo** Power BI report.

![](media/2020-04-10_17-29-53.png)

2. Select the empty area in the report canvas. Next, from the **Fields** list select or drag and drop **CustomerId** from **wwi AllSales** table to the report canvas.

![](media/2020-04-11_11-45-25.png)

3. From the Visualizations pane select the **card visual**. Resize and move the **card visual** to see what is shown in screenshot.

![](media/2020-04-11_11-46-44.png)

4. Select the empty area in the report canvas. From the **Fields** list select or drag and Drop **CustomerId** from **wwi AllSales** table to the report canvas. [Pointer 1 from the screenshot]. Then select **Name** field from the **Products** table [Pointer 2 from the screenshot]. Then select **Campaign** field from the **ProdChamp** table [Pointer 3 from the screenshot]. From the **Visualizations** pane select the **Treemap** icon [Pointer 4 from the screenshot].

![](media/2020-04-11_11-48-18.png)

5.	Resize and move the **card visual** as shown in the screenshot.

![](media/05-63.png)

6. Select an empty area in the report canvas.Then select the **Campaign** field from the **ProdChamp** table [Pointer 1 from the screenshot]. Then select **Profit** field from the **wwi AllSales** table [Pointer 2 from the screenshot]. Finally, from the **Visualizations** pane select the **Bar Chart** icon [Pointer 3 from the screenshot].

![](media/2020-04-11_11-50-10.png)

7. Resize and move the **card visual** as shown in the screenshot. 

![](media/05-65.png)

8. Hover over **Save** button, but **do NOT** save.

**TODO** Report was already prepared when launched for the first time.