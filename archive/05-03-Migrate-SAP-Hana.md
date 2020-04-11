## Data Orchestration and Ingestion

### Orchestrate Hub and Data Pipelines

1. **Select** “Orchestrate”

![SAP HANA To ADLS Pipeline](../media/05-06.png)

2. **Select/Expand** “Pipelines” and then **Select** “SAP HANA TO ADLS” pipeline.

#### Migrate SAP Hana to Azure Synapse Analytics

![Ingesting finance data from SAP Hana](../media/2020-04-10_16-03-02.png)

3. From the editor window **Select** copy data activity. Then **select** ‘Source’ property of the copy data activity to see the Source Dataset and observe that the query is pulling data from SAP Hana

![Ingesting finance data from SAP Hana](../media/2020-04-10_16-03-54.png)

4. With copy data selected, **Select** the ‘Sink’ property of the copy data activity. Look at the Sink dataset, in this case; you are saving to ADLS Gen2 storage container.

![Data moves to Azure Data Lake Gen2](../media/2020-04-10_16-05-13.png)

5. **Select** Mapping Data Flow activity and then **select** Settings. Next **select** "Open" to go to Data Flow editor.

![Mapping Data Flow](../media/2020-04-10_16-06-30.png)

6. In Data Flow editor **observe** the flow. Look in detail into each activity using the following steps.

![Moving data from SAP to the Data Lake](../media/2020-04-10_16-07-29.png)

7.	In the **first activity**, we are selecting data from the Data Lake staging area.
8.	In the **second activity**, we are filtering data for the last 5 years.

![filtering data for the last 5 years](../media/2020-04-10_16-15-39.png)

9.	In the **third activity**, we are deriving columns from a Column Order Date.

![deriving columns from a Column Order Date](../media/2020-04-10_16-16-23.png)

10.	In the **fourth activity**, we are only selecting the required columns from the table.

![](../media/2020-04-10_16-16-52.png)

11. In the **fifth activity**, we are creating an aggregated Total Sales grouped by Year and Month.

![](../media/2020-04-10_16-17-46.png)

12. In the **sixth activity**, we load the aggregated table to Azure Synapse.

![Load the aggregated table to Azure Synapse](../media/2020-04-10_16-18-21.png)

20. In the **seventh activity**, we are taking a parallel route by selecting all the remaining rows and writing the full table to Azure Synapse.

![Writing the full table to Azure Synapse](../media/2020-04-10_16-18-47.png)

21. To view all the available transformations in the data flow editor, **select** the + (add action), which is to the right of the first activity.

![view all the available transformations](../media/2020-04-10_16-19-47.png)

22.	**Scroll down** to see the full list of transformations at different levels.

![Full list of transformations at different levels](../media/2020-04-10_16-20-21.png)