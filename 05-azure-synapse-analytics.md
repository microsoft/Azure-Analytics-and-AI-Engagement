# Azure Synapse Analytics

## Pitch the awesomeness of Synapse

![Dream Demo Synapse](media/05-01.png)

## Data Orchestration and Ingestion

### Data Ingestion

1. On the Synapse Overview page **Select** Ingest and then observe already created linked services.

![Dream Demo Synapse](media/05-02.png)

2. In the Copy data dialog **Select** next.

![Properties](media/05-03.png)

3. **Select** ‘Create new connection’

![Create new connection](media/05-04.png)

4. **Show/highlight** available data providers.

![Create new connection](media/05-05.png)

### Orchestrate Hub and Data Pipelines

1. **Select** “Orchestrate”

![SAP HANA To ADLS Pipeline](media/05-06.png)

2. **Select/Expand** “Pipelines” and then **Select** “SAP HANA TO ADLS” pipeline.

#### Migrate SAP Hana to Azure Synapse Analytics

![Ingesting finance data from SAP Hana](media/05-07.png)

3. From the editor window **Select** copy data activity. Then **select** ‘Source’ property of the copy data activity to see the Source Dataset and observe that the query is pulling data from SAP Hana

![Ingesting finance data from SAP Hana](media/05-08.png)

4. With copy data selected, **Select** the ‘Sink’ property of the copy data activity. Look at the Sink dataset, in this case; you are saving to ADLS Gen2 storage container.

![Data moves to Azure Data Lake Gen2](media/05-09.png)

5. **Select** Mapping Data Flow activity and then **select** Settings. Next **select** "Open" to go to Data Flow editor.

![Mapping Data Flow](media/05-10.png)

6. In Data Flow editor **observe** the flow. Look in detail into each activity using the following steps.

![Moving data from SAP to the Data Lake](media/05-11.png)

7.	In the **first activity**, we are selecting data from the Data Lake staging area.
8.	In the **second activity**, we are filtering data for the last 5 years.

![filtering data for the last 5 years](media/05-12.png)

9.	In the **third activity**, we are deriving columns from a Column Order Date.

![deriving columns from a Column Order Date](media/05-13.png)

10.	In the **fourth activity**, we are only selecting the required columns from the table.
11. In the **fifth activity**, we are creating an aggregated Total Sales grouped by Year and Month.
12. In the **sixth activity**, we load the aggregated table to Azure Synapse.

![Load the aggregated table to Azure Synapse](media/05-14.png)

20. In the **seventh activity**, we are taking a parallel route by selecting all the remaining rows and writing the full table to Azure Synapse.

![Writing the full table to Azure Synapse](media/05-15.png)

21. To view all the available transformations in the data flow editor, **select** the + (add action), which is to the right of the first activity.

![view all the available transformations](media/05-16.png)

22.	**Scroll down** to see the full list of transformations at different levels.

![Full list of transformations at different levels](media/05-17.png)

#### Code First Experience: Migrate Teradata to Azure Synapse Analytics

1. In the Orchestrate hub, **select** ‘MarketingDBMigration’ from the list of pipelines.

![Full list of transformations at different levels](media/05-18.png)

**Note:** This pipeline is for demonstration purposes only. __Do NOT execute__ the pipeline.

2. **Select** lookup activity, then **select** Settings to observe the Source dataset property (Teradata).

![](media/05-19.png)

3. **Select** "Copy data" activity and observe Source and Sink properties.

![](media/05-20.png)

4. **Select** "Prep data in Azure Synapse" Notebook, then **select** "Settings". Once you are in the settings tab, **select** "Open" to open the notebook

![](media/05-21.png)

5.	**Show** the Python code. This is the code first experience in Synapse analytics.

![](media/05-22.png)

#### Migrate last five years of sales transactional data from Oracle to Azure Synapse Analytics

1. **Select** “SalesDBMigration” from the Orchestrate hub.

![](media/05-23.png)

2. **Select** “Lookup”
3. **Point** out “OracleSalesDB” field in Source Dataset field
4. **Select** Copy data

![](media/05-24.png)

5. Hover over various pipelines in the orchestrate tab.

![](media/05-25.png)

#### Moving semi-structured data to Azure Synapse Analytics

1. **Select** "TwitterDataMigration" from the list of pipelines.

![](media/05-26.png)

2. Look at the “Copy data”, “Archive Tweets data in ADLS Gen2” and “Clean up the archived Twitter Data” activities. 

![](media/05-27.png)

### On Demand Query: Azure Data Lake Gen2

1. **Select** "Data" Hub from the left navigation in the Synapse Analytics workspace. From the Data blade, under Storage accounts, **Select/expand** "dreamdemostorageforgen2". **Observe** various data sources (including CI) that are now in ADL Gen2 and then **Select** ‘twitterdata’ storage container.

![](media/05-28.png)

2. **See** all the parquet files and other folders in the twitterdata container. **Select** the first two parquet files and **right Click**, from the context menu, Select ‘New SQL Script’

![](media/05-29.png)

3. **Select** run.

![](media/05-30.png)

4. **Select** Chart

![](media/05-31.png)

5. **Minimize** the storage accounts on the left side, then **expand** the "Databases" tree, expand "AzureSynapseDW (SQL pool)", and finally expand "Tables" folder.

![](media/05-32.png)

#### COPY INTO Command

1. **Select** Develop, then **expand** SQL Scripts to list all available scripts. **Select** “8 External Data to Synapse Via Copy Into” and **highlight** the query presented below titled "Step:1".

![](media/05-33.png)

2. **Select** Run and observe the “No results found” message.

![](media/05-34.png)

3.	**Scroll** to the bottom and **select** "COPY INTO" query below "Step:2" as shown in the screenshot. Finally, **select** "Run"

![](media/05-35.png)

## Develop Hub

1. **Select** Develop in the various tabs available in the Develop hub workspace and discover the environment. 

![](media/05-36.png)

2. **Select** “Develop” and then **select** “1 SQL Query with Synapse”

![](media/05-37.png)

3. **Select** "AzureSynapseDW" SQL Pool from the "Connect to" drop down menu. Once the "Use database" drop dows is populated **Select** "AzureSynapseDW" database from the "Use Database" drop down. Finally, **Select** the below query (#3 in the screenshot)

![](media/05-38.png)

`SELECT COUNT_BIG(1) as TotalCount  FROM wwi.Sales(nolock)`

4. **Select** "Run" and observe the results (30 Billion). **Scroll down** a few lines to the second query, **select** the query as shown in the screenshot, and then **Select** "Run".  **Observe** time the query takes – query time is listed at the bottom of the screenshot.

![](media/05-39.png)

5. **Select** the "chart" button, and then **select** chart type dropdown to **see** various chart types 

![](media/05-40.png)

### JSON Extractor Differentiator and other optional differentiator “snackable” pocket demos

1. **Select** "Develop", and then **Select** "2 JSON Extractor". Next, from the "Connect to" dropdown **Connect** To "AzureSynapseDW" SQL Pool. **Select** the query as shown in the screenshot and **Select** "Run".

![](media/05-41.png)


2. **Observe** the results of query 

### Using Notebooks to Run Machine Learning Experiments

1. Select the develop hub from the Synapse workspace. Next, **Select** and expand the "Notebooks" option.

![](media/05-42.png)

2. **Select** the "1. Product Recommendations" notebook, which will open the notebook.

![](media/05-43.png)

3. Once the notebook is open, **select** “CDP DreamPool” from the "Attach to" dropdown. CDP DreamPool is a Spark Pool. **Select** PySpark from the “Language” dropdown list.

![](media/05-44.png)

4. **Expand** “Language” and see supported languages.

![](media/05-45.png)

5. **Observe** the import statements in the Notebook 

![](media/05-46.png)

6. **Observe** the results in the notebook under "Map Products".

![](media/05-47.png)

**See** code in cell 26, but **DO NOT** execute any code.

![](media/05-48.png)

#### AutoML in Azure Synapse Analytics 

1. **Select** "Develop" from the Synapse workspace

![](media/05-49.png)

2. **Expand** Notebooks section and **Select** "2 AutoML Customer Forecasting" Notebook.

![](media/05-50.png)

3. **Scroll down** to see the content in the screenshot.

![](media/05-51.png)

4. **Scroll down** to observe the content in the screenshot.

![](media/05-52.png)

5. **Scroll down** to see the code in cell 35.

![](media/05-53.png)

6. Scroll down to see cell 42.

![](media/05-54.png)

### Power BI reporting within the Synapse Analytics workspace

1. **Select** "Develop" from the Synapse workspace and **Expand** the Power BI section. Next, **expand** "Data & AI Demo" (which is a Power BI workspace) and **expand** Power BI reports. Finally, **select** "1. CDP Vision Demo" Power BI report. This will open the decomposition tree.

![](media/05-55.png)

2. Once the report is open, in the "Decomposition Tree Analysis" tab **see** Store Visits by Campaign then by Region. **Select** "+" next to North & Central America 

![](media/05-56.png)

3. **Select** QnA tab 

![](media/05-57.png)

4.	In the Q&A box, **type** "profit by country by product category as treemap"

![](media/05-58.png)

### Ad Hoc Reporting in Azure Synapse Analytics (Optional)

1. From the "Develop" hub, "Power BI" section **Select** "2. Billion Rows Demo" Power BI report.

![](media/05-59.png)

2. **Select** the empty area in the report canvas. Next, from the Fields list **Select** or **Drag and Drop** "CustomerId" from "wwi AllSales" table to the report canvas.

![](media/05-60.png)

3. From the Visualizations pane **select** the card visual. **Resize and move** the card visual to see what is shown in screenshot.

![](media/05-61.png)

4. **Select** the empty area in the report canvas. From the Fields list **Select** or **Drag and Drop** "CustomerId" from "wwi AllSales" table to the report canvas. [Pointer 1 from the screenshot]. Then **Select** "Name" field from the "Products" table [Pointer 2 from the screenshot]. Then **Select** "Campaign" field from the "ProdChamp" table [Pointer 3 from the screenshot]. From the Visualizations pane select the Treemap icon [Pointer 4 from the screenshot].

![](media/05-62.png)

5.	**Resize and move** the card visual as shown in the screenshot.

![](media/05-63.png)

6.	**Select** an empty area in the report canvas.Then **Select** the "Campaign" field from the "ProdChamp" table [Pointer 1 from the screenshot]. Then **Select** "Profit" field from the "wwi AllSales" table [Pointer 2 from the screenshot]. Finally, from the Visualizations pane select the Bar Chart icon [Pointer 3 from the screenshot].

![](media/05-64.png)

7.	**Resize and move** the card visual as shown in the screenshot. 

![](media/05-65.png)

8.	**Hover** over save button, but **do NOT** save.
