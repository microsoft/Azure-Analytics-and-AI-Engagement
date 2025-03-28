## Exercise 1: Loading Data into SQL Database

This module covers the basics of getting started with **SQL Database in Microsoft Fabric**. You will learn how to **create workspaces**, create a **SQL Database in Microsoft Fabric**, and **seed the database** with initial data that will be used in later modules. You will see how simple it is to create the databases by providing a name. And even more exciting, loading the initial data into SQL Database can be achieved without any code! This reduces maintenance effort while delighting developers!

---
>**!Note:** Follow the steps provided in the task below. The Click-by-Click is available as a **backup option** in case of any technical issues preventing you from performing the lab in the actual environment.
Before starting this exercise, open a backup Click-by-Click using the following hyperlink in a new tab, then return to the browser.
[Click-by-Click](https://regale.cloud/Microsoft/play/4463/01-loading-data-into-sql-database#/0/0)
---




### Task 1.1: Load Data from Azure SQL Database

In this task, you will use **Dataflow Gen2** to ingest data and efficiently copy it from **Azure SQL Database** to **SQL Database in Microsoft Fabric**.

#### Activity: Create a new Microsoft Fabric workspace

1. Open a new tab and paste ``app.powerbi.com`` into the browser then press **Enter**.

2. Enter your **Username** in the **Email** field, then click on the **Submit** button.

![alt text](../media/image.png)

3. Enter your **password** and click on the **Sign in** button.

![alt text](../media/image-1.png)

4. Enter your **current password**, then enter and confirm your **new password**, and click **Sign in** to proceed.

![alt text](../media/h12.png)

5. If you see a message stating, "More information required," click **Next** to proceed.

![alt text](../media/h13.png)

6. The system will prompt you to set up Microsoft Authenticator, click **Skip setup** skip this step.

![alt text](../media/h14.png)

7. If prompted to stay signed in, click on **Yes**.

![alt text](../media/image-2.png)

> **Note:** Close any pop-up screen that appears on the screen.

![alt text](../media/image-3.png)

> **Note:** If you see the following screen, continue with the following steps or directly move to step number **8**.

8. Click on the **Continue** button.

![alt text](../media/image-4.png)

9. Click on the **Business phone number** textbox and type a 10-digit number ```1230000849```. Click on the **Get Started** button.

![alt text](../media/image-5.png)

10. Again, click on the **Get Started** button.

![alt text](../media/image-6.png)

> **Note:** Wait for the Power BI workspace to load and close the top bar for a better view.

11. From the left navigation pane, click on **Workspaces** and then the **+ New workspace** button.

![alt text](../media/image-7.png)

12. In the **Name** field, enter ``Fabcon``,followed by a unique suffix (e.g., FabconJD23 using your initials). Validate the availability of the name, then expand **Advanced Settings**.

> **Note:** It is very Important to use the workspace name provided above in the lab for a seamless experience.

> **Note:** If the name is already taken, refresh the page and check again. A workspace with that name may already be created. If so, add a different suffix until the name is available.

![](../media/h15.png)

13. Enable **Fabric capacity**, select the **Capacity** from the dropdown, and click **Apply** to proceed.

![](../media/h16.png)

> **Note:** Wait for the Power BI Workspace to load.
<!--
![alt text](../media/image-9.png)
-->

#### Activity: Create a new SQL Database in Microsoft Fabric

1. Click on **+ New item** and type **SQL** in the search bar, then select **SQL Database (preview)**.

<img src="../media/database1.png" width="600" height="300">

2. In the **Name** field, enter ```Fabcon_database``` and click on the **Create** button. Database creation should take less than a minute.

![](../media/03.png)

3. When the new database is provisioned, on the **Home page** notice that the Explorer pane is showing database objects.

<img src="../media/f54.png" width="600" height="300">

4. Under **Build your database**, three useful tiles can help you get your newly created database up and running.

<img src="../media/06.png" width="600" height="300">

- **Sample data** - Lets you import sample data into your Empty database.
- **T-SQL** - Gives you a web-editor that can be used to write T-SQL to create database objects like schema, tables, views, and more. For users who are looking for code snippets to create objects, they can look for available samples in the **Templates** drop down list at the top of the menu.
- **Connection strings** - Shows the SQL Database connection string that is required when you want to connect using **SQL Server Management Studio**, the mssql extension with **Visual Studio Code**, or other external tools.


#### Activity: Use Dataflow Gen2 to move data from Azure SQL DB to the SQL Database in Microsoft Fabric.

1. Click on the **New Dataflow Gen2**.

<img src="../media/h4.png" width="650" height="300">

3. If prompted, click the **Create** button otherwise, proceed to the next step.

![](../media/dfgen2.2.png)

3. Click on the **Get data** icon (**not on the dropdown arrow at the bottom of the icon**).

![](../media/f47.png)

4. On the **Choose data source** pane, search for **Azure SQL** and click on **Azure SQL Database**.

<img src="../media/dfgen2.4.png" width="650" height="300">


>**Note:** Note: To fill in the details for required fileds, we need to fetch the details from the SQL Database resource deployed in the Azure Portal.

<img src="../media/g10.png" width="650" height="500">

5. Navigate to the URL: [https://stfabcon.blob.core.windows.net/injectkeys/injectkeys.txt](https://stfabcon.blob.core.windows.net/injectkeys/injectkeys.txt), copy the **SQL Server Endpoint** value, and copy it to your notepad.

![](../media/h7.png)

6. On the **Connection settings** pane, in the **Server** field, paste the value you copied in step number **5**, and in the **Database** field, paste ```SalesDb```.

<img src="../media/dfgen2.5.png" width="650" height="350">

7. Navigate to the URL: [https://stfabcon.blob.core.windows.net/injectkeys/injectkeys.txt](https://stfabcon.blob.core.windows.net/injectkeys/injectkeys.txt), copy the **SQL Server password** value, and copy it to your notepad.

![](../media/h8.png)

8.  Scroll down and select **Basic** in the **Authentication kind** dropdown. Enter ``labsqladmin`` as the **Username**, paste the value you copied in step number **7** in the **Password** field, then click on the **Next** button.

<img src="../media/dfgen2.6.png" width="650" height="350">

9. Select ``Suppliers``, ``Website_Bounce_rate`` and ``inventory`` tables, then click on the **Create** button.

<img src="../media/dim_products1u.png" width="700" height="300">

<!--
10. Click on the ``Suppliers`` table, select the **Add data destination** option from the ribbon, then select **SQL Database** from the list.

<img src="../media/dim_products2u.png" width="700" height="300">

11. Click on the **Next** button.

<img src="../media/dfgen2.9.png" width="600" height="350">


12. Expand the **Fabcon** folder, select the **Fabcon_database** and then click on the **Next** button.

<img src="../media/g13.png" width="600" height="300">

13. Click on the **Save settings** button.

<img src="../media/dfgen2.11.png" width="600" height="300">

14. For ``Website_Bounce_rate`` and ``inventory`` tables perform steps **8-11** to select the destination.

>**Note:** Please ensure to select the destination for all the tables before publishing the dataflow.
-->

10. Click on the **Publish** button.

![alt text](../media/f21.png)

>**Note:** Wait for the Dataflow to complete, it will take 2-3 minutes.

11. Click on the **Bell** icon at the top right of the screen to verify the status of the Dataflow Gen2.

![alt text](../media/h1.png)

#### Activity: Verify the data transfer by querying tables in the SQL Database

1. Click on **Workspaces** and select the **Fabcon** workspace.

<img src="../media/datapipeline1.png" width="400" height="400">

**Note:** You'll have a suffix concatenated with your workspace name.

2. Search for **database** and select the **Fabcon_database**.

<img src="../media/database2.png" width="600" height="350">

3. Click on the **New Query** icon.

![](../media/database3.png)

4. Paste the query ```SELECT * FROM inventory```, click on the **Run** icon and then check the output.

<img src="../media/dim3u.png" width="700" height="300">


### Task 1.2: Load Data from On-Premises Database


Data Factory for Microsoft Fabric is a powerful cloud-based data integration service that allows you to create, schedule, and manage workflows for various data sources. In scenarios where your data sources are located on-premises, Microsoft provides the On-Premises Data Gateway to securely bridge the gap between your on-premises environment and the cloud. 

For this workshop, the **On-Premises Data Gateway** is already provisioned for you and no setup is required by the workshop user, the **gateway connection** can be accessed in your Microsoft Fabric workspace while setting up the data pipeline. The connection is displayed automatically when database credentials passed on in the pipeline.



#### Activity: Use a Microsoft Fabric Pipeline to load data from the On-premises database to the SQL Database

1. Click on **Workspaces** and select the **Fabcon** workspace.

<img src="../media/datapipeline1.png" alt="Alt Text" width = "500">



2. Click on **+ New item** and select the **Data pipeline** option.

![](../media/datapipeline2.png)

3. In the name field, enter ``Ingest on-premises data using pipeline``and click on the **Create** button.

![](../media/24.png)

4. From the **Home** tab of the pipeline editor, click on the **Copy data** dropdown and select **Use copy assistant** option.

![](../media/25.png)

5. On the **Home** pane, select the **SQL Server database** option.

![](../media/datapipeline3.png)

6. In the **Connection settings** pane, in the **Server** field paste **FabconVM358akxs** , and paste **FabconDatabase** in the **Database** field. It automatically selects the **Connection**. Click on the **Next** button.
 

>**Note:** For this workshop, the **On-Premises Data Gateway** is already provisioned for you and no setup is required by the workshop user, the **gateway connection** can be accessed in your Microsoft Fabric workspace while setting up the data pipeline. The connection is displayed automatically when database credentials passed on in the pipeline.

![](../media/f51.png)

7. Now, under the **FabconDatabase** database, click **Select all** and then click on the **Next** button.

![](../media/f52.png)

8. Click on **OneLake** and select existing **SQL Database**.

![](../media/f53.png)


#### Activity: Validate the data transfer and ensure schema compatibility

1. Select the **Load to new table** radio button and and wait for the **column mapping** to appear.
2. Click on the **Next** button.

![](../media/h18.png)

3. Under Options, ensure that **Start data transfer immediately** remains **enabled** (default setting).

4. Click on **Save + Run** to proceed.

<img src="../media/saverun.png" alt="Alt Text" width = "500">

5. Click on the **Ok** button in the **Pipeline run** window..

<img src="../media/datapipeline12.png" alt="Alt Text" width = "500">
 
6. Click on the **Bell** icon at the top right of the screen to verify the Running status of the pipeline.

<img src="../media/datapipeline14.png" alt="Alt Text" width="500">



There you go! Your data has been transferred from the on-premises SQL Database to the Microsoft Fabric SQL Database.

Congratulations! You have successfully created your database in a new Microsoft Fabric workspace and ingested data from both **Azure SQL Database** and an **on-premises SQL Server**. You are ready to move on to the next exercise: [Introduction to Copilot for SQL Database](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/Fabric-SQL-Workshop/Workshop_Exercises/02%20-%20Introduction%20to%20Copilot%20for%20SQL%20Database.md)
