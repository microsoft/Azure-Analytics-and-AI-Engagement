## Develop Hub

1. **Select** Develop in the various tabs available in the Develop hub workspace and discover the environment. 

![](media/2020-04-10_17-09-25.png)

2. **Select** “SQL Scripts” and then **select** “1 SQL Query with Synapse”

![](media/05-37.png)

3. **Select** "AzureSynapseDW" SQL Pool from the "Connect to" drop down menu. Once the "Use database" drop dows is populated **Select** "AzureSynapseDW" database from the "Use Database" drop down. Finally, **Select** the below query (#3 in the screenshot)

![](media/05-38.png)

`SELECT COUNT_BIG(1) as TotalCount  FROM wwi.Sales(nolock)`

4. **Select** "Run" and observe the results (30 Billion).

![](media/2020-04-10_17-11-19.png)

5. **Scroll down** a few lines to the second query, **select** the query as shown in the screenshot, and then **Select** "Run".  **Observe** time the query takes – query time is listed at the bottom of the screenshot.

![](media/05-39.png)

5. **Select** the "chart" button, and then **select** chart type dropdown to **see** various chart types 

![](media/05-40.png)