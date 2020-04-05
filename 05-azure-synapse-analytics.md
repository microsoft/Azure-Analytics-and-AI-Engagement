# Azure Synapse Analytics

## Pitch the awesomeness of Synapse

![Dream Demo Synapse](media/05-01.png)

## Data Orchestration and Ingestion

### Data Ingestion

1. On the Synapse Overview page **Click** Ingest
2. **Show/highlight** already created linked services.

![Dream Demo Synapse](media/05-02.png)

3. In the Copy data dialog **Click** next.

![Properties](media/05-03.png)

4. **Click** ‘Create new connection’

![Create new connection](media/05-04.png)

5. **Show/highlight** available data providers.

![Create new connection](media/05-05.png)

### Orchestrate Hub and Data Pipelines

1. **Click** on “Orchestrate”

![SAP HANA To ADLS Pipeline](media/05-06.png)

2. **Click/Expand** “Pipelines”
3. **Click** on “SAP HANA TO ADLS” pipeline.

#### Migrate SAP Hana to Azure Synapse Analytics

![Ingesting finance data from SAP Hana](media/05-07.png)

4. From the editor window **Select** copy data activity.
5. **Click** ‘Source’ property of the copy data activity.
6. **Point** to the Source Dataset 
7. **Show** that our query is pulling from SAP Hana

![Ingesting finance data from SAP Hana](media/05-08.png)

8. With copy data selected, **click** the ‘Sink’ property of the copy data activity.
9. **Point** to the Sink dataset, in this case we are saving to ADLS Gen2 storage container

![Data moves to Azure Data Lake Gen2](media/05-09.png)

10. **Select** Mapping Data Flow activity.
11.	**Click** Settings
12.	**Click** Open, this will take you to Data Flow editor.

![Mapping Data Flow](media/05-10.png)

13.	In Data Flow editor **show/point** the flow, and you can elaborate on each activity using the information below.

![Moving data from SAP to the Data Lake](media/05-11.png)

14.	In the **first activity**, we are selecting data from the Data Lake staging area.
15.	In the **second activity**, we are filtering data for the last 5 years.

![filtering data for the last 5 years](media/05-12.png)

16.	In the **third activity**, we are deriving columns from a Column Order Date.

![deriving columns from a Column Order Date](media/05-13.png)

17.	In the **fourth activity**, we are simply selecting the required columns from the table.
18. In the **fifth activity**, we are creating an aggregated Total Sales grouped by Year and Month.
19. In the **sixth activity**, we load the aggregated table to Azure Synapse.

![Load the aggregated table to Azure Synapse](media/05-14.png)

20. In the **seventh activity**, we are taking a parallel route by selecting all the remaining rows and writing the full table to Azure Synapse.

![Writing the full table to Azure Synapse](media/05-15.png)

21. To view all the available transformations in the data flow editor, **click** on the + (add action) which is to the right of the first activity.

![view all the available transformations](media/05-16.png)

22.	**Scroll down** to see full list of transformations at different levels.

![Full list of transformations at different levels](media/05-17.png)

#### Code First Experience: Migrate Teradata to Azure Synapse Analytics

1. In the Orchestrate hub, **select** ‘MarketingDBMigration’ from the list of pipelines.

![Full list of transformations at different levels](media/05-18.png)

**Note:** This pipeline is for demonstration purposes only. __Do NOT execute__ the pipeline.

2.	**Click** lookup activity.
3.	**Click** Settings
4.	**Point** to the Source dataset property (Teradata).

![](media/05-19.png)

5. **Select** ‘Copy data’ activity.
6. **Point/show** Source and Sink properties.

![](media/05-20.png)

7.	**Click** on “Prep data in Azure Synapse” Notebook.
8.	**Click** Settings
9.	From the settings tab, **Click** on “Open” to open the notebook

![](media/05-21.png)

10.	**Show** the Python code. This is the code first experience in Synapse analytics.

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

1. **Select** “TwitterDataMigration” from the list of pipelines.

![](media/05-26.png)

2.	Point out “Copy data” activity.
3.	Point out “Archive Tweets data in ADLS Gen2”
4.	Point out “Clean up the archived Twitter Data”

![](media/05-27.png)

### On Demand Query: Azure Data Lake Gen2

1. **Select** ‘Data’ Hub from the left navigation in Synapse Analytics workspace.

![](media/05-28.png)

2. From the Data blade, under Storage accounts, **click/expand** ‘dreamdemostorageforgen2’ 
3. **Point out** the various data sources (including CI) that are now in ADL Gen2 and then **Click** ‘twitterdata’ storage container.
4. **Point out** all the parquet files and other folders in the twitterdata container.
5. **Select** the first two parquet files
6. **Right Click**, from the context menu Select ‘New SQL Script’

![](media/05-29.png)

7. **Click** run.

![](media/05-30.png)

8. **Click** Chart

![](media/05-31.png)

9. **Minimize** the storage accounts on the left side
10.	**Expand** the Databases
11.	**Expand** AzureSynapseDW (SQL pool) 
12.	**Expand** Tables

![](media/05-32.png)

#### COPY INTO Command

1. **Click** on Develop

![](media/05-33.png)

2. **Click** on SQL Scripts
3. **Click** on “8 External Data to Synapse Via Copy Into”
4. **Select** the query below “Step:1” as shown
5. **Click** Run

![](media/05-34.png)

6.	**Show** “No results found”
7.	**Scroll** to the bottom 
8.	**Select** “COPY INTO” query below “Step:2” as shown
9.	**Click** ‘Run’

![](media/05-35.png)

## Develop Hub

1. **Select** Develop in the various tabs available in the Develop hub workspace and walk through 

![](media/05-36.png)

1. **Click** on “Develop”
2. **Click** on “1 SQL Query with Synapse”

![](media/05-37.png)

1.	**Select** ‘AzureSynapseDW’ SQL Pool from the Connect to drop down menu.

![](media/05-38.png)

2.	**Select** ‘AzureSynapseDW’ database from the Use Database drop down. 
3.	**Select** the below query (#3 in the screenshot]

`SELECT COUNT_BIG(1) as TotalCount  FROM wwi.Sales(nolock)`

4.	**Click** on “Run”
5.	**Show** results (30 Billion)
6.	**Scroll down** a few lines to the second query
7.	**Select** the query as shown on right
8.	**Click** on Run
9.	**Highlight** time the query takes – query time is listed at bottom of screenshot.

![](media/05-39.png)

10.	**Select** the “chart” button
11.	**Select** chart type drop down
12.	**Show** various chart types 

![](media/05-40.png)

### JSON Extractor Differentiator and other optional differentiator “snackable” pocket demos

1. **Click** on “Develop”

![](media/05-41.png)

2. **Click** on “2 JSON Extractor”
3. **Connect** To ‘AzureSynapseDW’ SQL Pool
4. **Select** the Query we need to run.
5. **Click** on “Run”
6. **Show** Results of query 

### Using Notebooks to Run Machine Learning Experiments

1. Select the develop hub from the Synapse workspace.

![](media/05-42.png)

2. **Click** to expand the “Notebooks” option 
3. **Select** the “1. Product Recommendations” notebook, which will open the notebook.

![](media/05-43.png)

4. Once the notebook is open, **point to** “Attach to CDP DreamPool”, which is a Spark Pool
5. **Point to** “Language” in this case it is PySpark

![](media/05-44.png)

6. **Expand** “Language” and show supported languages.

![](media/05-45.png)

7. **Point** to the import statements in the Notebook 

![](media/05-46.png)

8. **Point** to the results in the notebook under “Map Products”.

![](media/05-47.png)

**Show** code in cell 26, but **DO NOT** execute any code.

![](media/05-48.png)

#### AutoML in Azure Synapse Analytics 

1. **Select** Develop from the Synapse workspace

![](media/05-49.png)

2. **Expand** Notebooks section
3. **Select** ‘2 AutoML Customer Forecasting’ Notebook.

![](media/05-50.png)

**Scroll down** to show content in screenshot.

![](media/05-51.png)

**Scroll down** to show content in screenshot.

![](media/05-52.png)

**Scroll down** to show the code in cell 35.

![](media/05-53.png)

Scroll down to show cell 42.

![](media/05-54.png)

### Power BI reporting within the Synapse Analytics workspace

1. **Select** Develop from the Synapse workspace.

![](media/05-55.png)

2. **Expand** the Power BI section.
3. **Expand** ‘Data & AI Demo’ (which is a Power BI workspace).
4. **Expand** Power BI reports.
5. **Select** ‘1. CDP Vision Demo’ Power BI report. This will open the decomposition tree.
6. Once the report is open, in the ‘Decomposition Tree Analysis’ tab 
7. **Show** Store Visits by Campaign then by Region.
8. **Click** on “+” next to North & Central America 

![](media/05-56.png)

9. **Select** QnA tab 

![](media/05-57.png)

10.	In the Q&A box, **type** ‘profit by country by product category as treemap’

![](media/05-58.png)

### Ad Hoc Reporting in Azure Synapse Analytics (Optional)

1. From the Develop hub, Power BI section **Select** ‘2. Billion Rows Demo’ Power BI report

![](media/05-59.png)

2. **Click** on the empty area in the report canvas.
3. From the Fields list **Select** or **Drag and Drop** CustomerId from ‘wwi AllSales’ table to the report canvas.

![](media/05-60.png)

4. From the Visualizations pane **select** the card visual.
5. **Resize and move** the card visual wo what is shown in screenshot.

![](media/05-61.png)

6. **Click** on the empty area in the report canvas.

![](media/05-62.png)

7. From the Fields list **Select** or **‘Drag and Drop’** CustomerId from ‘wwi AllSales’ table to the report canvas. [Pointer 1 from the screenshot]
8. Then **Select** ‘Name’ field from the Products table [Pointer 2 from the screenshot].
9. Then **Select** ‘Campaign’ field from the ProdChamp table [Pointer 3 from the screenshot].
10. From the Visualizations pane click on the Treemap icon [Pointer 4 from the screenshot].
11.	**Resize and move** the card visual as shown in screenshot.

![](media/05-63.png)

12.	**Click** on an empty area in the report canvas.

![](media/05-64.png)

13.	Then **Select** the ‘Campaign’ field from the ProdChamp table [Pointer 1 from the screenshot].
14.	Then **Select** ‘Profit’ field from the wwi AllSales table [Pointer 2 from the screenshot].
15.	From the Visualizations pane select the Bar Chart icon [Pointer 3 from the screenshot].
16.	**Resize and move** the card visual as shown in screenshot. 

![](media/05-65.png)

17.	**Hover** over save button, but **do NOT** save.
