# Azure Databricks in Action: Unified Al & Analytics Across Microsoft
 
**The estimated time to complete this lab is 50-60 minutes.**
 
**DISCLAIMER**
 
This presentation, demonstration, and demonstration model are for informational purposes only and (1) are not subject to SOC 1 and SOC 2 compliance audits, and (2) are not designed, intended or made available as a medical device(s) or as a substitute for professional medical advice, diagnosis, treatment or judgment. Microsoft makes no warranties, express or implied, in this presentation, demonstration, and demonstration model. Nothing in this presentation, demonstration, or demonstration model modifies any of the terms and conditions of Microsoft's written and signed agreements. This is not an offer and applicable terms and the information provided are subject to revision and may be changed at any time by Microsoft.
 
This presentation, demonstration, and demonstration model do not give you or your organization any license to any patents, trademarks, copyrights, or other intellectual property covering the subject matter in this presentation, demonstration, and demonstration model.
 
The information contained in this presentation, demonstration and demonstration model represents the current view of Microsoft on the issues discussed as of the date of presentation and/or demonstration, for the duration of your access to the demonstration model. Because Microsoft must respond to changing market conditions, it should not be interpreted to be a commitment on the part of Microsoft, and Microsoft cannot guarantee the accuracy of any information presented after the date of presentation and/or demonstration and for the duration of your access to the demonstration model.
 
No Microsoft technology, nor any of its component technologies, including the demonstration model, is intended or made available as a substitute for the professional advice, opinion, or judgment of (1) a certified financial services professional, or (2) a certified medical professional. Partners or customers are responsible for ensuring the regulatory compliance of any solution they build using Microsoft technologies.
 
**Copyright**
 
© 2025 Microsoft Corporation. All rights reserved. 
 
By using this demo/lab, you agree to the following terms:
 
The technology/functionality described in this demo/lab is provided by Microsoft Corporation for purposes of obtaining your feedback and to provide you with a learning experience. You may only use the demo/lab to evaluate such technology features and functionality and provide feedback to Microsoft. You may not use it for any other purpose. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell this demo/lab or any portion thereof.
 
COPYING OR REPRODUCTION OF THE DEMO/LAB (OR ANY PORTION OF IT) TO ANY OTHER SERVER OR LOCATION FOR FURTHER REPRODUCTION OR REDISTRIBUTION IS EXPRESSLY PROHIBITED.
 
THIS DEMO/LAB PROVIDES CERTAIN SOFTWARE TECHNOLOGY/PRODUCT FEATURES AND FUNCTIONALITY, INCLUDING POTENTIAL NEW FEATURES AND CONCEPTS, IN A SIMULATED ENVIRONMENT WITHOUT COMPLEX SET-UP OR INSTALLATION FOR THE PURPOSE DESCRIBED ABOVE. THE TECHNOLOGY/CONCEPTS REPRESENTED IN THIS DEMO/LAB MAY NOT REPRESENT FULL FEATURE FUNCTIONALITY AND MAY NOT WORK THE WAY A FINAL VERSION MAY WORK. WE ALSO MAY NOT RELEASE A FINAL VERSION OF SUCH FEATURES OR CONCEPTS. YOUR EXPERIENCE WITH USING SUCH FEATURES AND FUNCITONALITY IN A PHYSICAL ENVIRONMENT MAY ALSO BE DIFFERENT.
 
 
## Overview

![Lab535 Archi.png](./media/Lab535Archi.png)
 
This lab showcases how **Azure Databricks**, **Microsoft Fabric**, **Copilot Studio**, and **Azure AI Foundry** work together to deliver a cost-effective, performance-optimized, cloud-native analytics solution pattern. the architecture unifies the enterprise data estate, enabling organizations to accelerate data value creation and unlock actionable insights with Microsoft's latest innovations: Azure Databricks, Microsoft Fabric, Azure AI Foundry, and Copilot Studio.
 
 
In today's data-driven world, organizations need solutions that seamlessly integrate analytics and AI to deliver actionable insights at scale. This hands-on lab will guide you through building a modern, cloud-native analytics and AI architecture using Microsoft's latest innovations: Azure Databricks, Microsoft Fabric, Azure AI Foundry, and Copilot Studio.
You'll work through a real-world scenario featuring Zava, a global retailer acquiring Litware Inc., which introduces a rich set of curated marketing and sales data. This data is processed in Azure Databricks and stored in the gold layer of ADLS, forming the foundation for advanced analytics and AI-driven decision-making.
Throughout the lab, you will:
 
* Set up a **Lakehouse** architecture with Azure Databricks and orchestrate data pipelines using **Lakeflow** declarative pipelines.
* Transform and enrich data with **ETL** processes, explore data lineage, and leverage AI-powered column-level insights.
* Build AI-driven experiences using **Genie** and Azure AI **Foundry**, enabling conversational analytics and business Q&A.
* **Mirror Unity Catalog** tables into Microsoft Fabric's OneLake, create semantic models in Direct Lake mode, and visualize insights in Power BI.
* Develop low-code automation with **Copilot Studio**, creating conversational agents that integrate with Teams and respond to business queries like "What's the top-selling product this week?"
 
By the end of this immersive session, you'll have implemented a scalable, cost-effective, and performance-optimized solution that demonstrates how AI-powered analytics can reshape business outcomes-from data ingestion to intelligent insights and automation.
 
 
 
 
## Table of Contents
 
## Exercise 1: Lakehouse Setup & Data Orchestration with Azure Databricks and Lakeflow declarative pipelines
 
- [Task 1.1: Set Up Azure Databricks Environment and load data into Unity Catalog](#task-11-set-up-azure-databricks-environment-and-load-data-into-unity-catalog)
- [Task 1.2: Create ETL pipeline for Data Transformation](#task-12-create-etl-pipeline-for-data-transformation)
- [Task 1.3: Generate column-level insights with AI Suggested Descriptions, then explore data lineage, table update history, and profiling in Azure Databricks](#task-13-generate-column-level-insights-with-ai-suggested-descriptions-then-explore-data-lineage-table-update-history-and-profiling-in-azure-databricks)
 
---
 
## Exercise 2: AI-Driven Insights with Azure AI Foundry & Genie
 
- [Task 2.1: Create a Databricks Assistant AI/BI Genie](#task-21-create-a-databricks-assistant-aibi-genie)
- [Task 2.2: Connect AI/BI Genie inside AI Foundry](#task-22-connect-aibi-genie-inside-ai-foundry)
- [Task 2.3: Use Agent Created Inside AI Foundry with Custom Web App](#task-23-use-agent-created-inside-ai-foundry-with-custom-web-app)
 
---
 
## Exercise 3: Azure Databricks Mirrored Catalog in Microsoft Fabric
 
- [Task 3.1: Mirror Unity Catalog Table into Fabric's OneLake](#task-31-mirror-unity-catalog-table-into-fabrics-onelake)
- [Task 3.2: Create a semantic model in Direct Lake mode and use Power BI to visualize and generate insights](#task-32-create-a-semantic-model-in-direct-lake-mode-and-use-power-bi-to-visualize-and-generate-insights)
 
---
 
## Exercise 4: Copilot Studio for Low-Code Automation
 
- [Task 4.1: Create an agent and connect Azure Databricks as its knowledge source to support Business Q&A](#task-41-create-an-agent-and-connect-azure-databricks-as-its-knowledge-source-to-support-business-qa)
- [Task 4.2: Publish the agent in Microsoft Teams channels and make it accessible to users](#task-42-publish-the-agent-in-microsoft-teams-channels-and-make-it-accessible-to-users)
 
---
 
<!-- ## Exercise 5: Advanced Reporting in Power BI
 
- Task 5.1: Build a Power BI Report Using Direct Lake Mode
    - Connect to the Lakehouse using Direct Lake for real-time performance
    - Design visuals for sales, trends, and KPIs
- Task 5.2: Add AI Visuals to Explain Key Drivers
    - Use Key Influencers to identify factors impacting sales
    - Add Smart Narrative to auto-generate insights and summaries -->
    
<!-- > **Note 1:** After logging into the VM, if you see the screen below, please click on **Opt Out of backup**.
 
> **Note 2:** On the next screen, if you encounter the 'backup is recommended' message shown below, please select **Skip for now**.
 
![bcp2.png](./media/bcp2.png) -->
 
## Exercise 1: Lakehouse Setup & Data Orchestration with Azure Databricks and Lakeflow declarative pipelines
 
### Task 1.1: Set Up Azure Databricks Environment and load data into Unity Catalog
 
1. After running the script to create the required resources, navigate to the resource group you created.

![Task-2.3_1.png](./media/ex1t1i1.png)

2. Select the Databricks workspace you created and launch it.

![Task-2.3_1.png](./media/ex1t1i2.png)

![Task-2.3_1.png](./media/adblaunch.png)
 
3. Click on the **Continue with Microsoft Entra ID**.
 
![adb19.png](./media/adb19.png)

4. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

    ![Select Same User to Authenticate.](./media/cloud-shell-12.png)

<!--  
3. Enter the following email by clicking on username ```@lab.CloudPortalCredential(User1).Username``` and click on **Next**.
 
![adb20.png](./media/adb20.png)
 
4. Enter the **Temporary Access Pass** by clicking on ```@lab.CloudPortalCredential(User1).TAP``` and click on Sign in.
 
![adb21.png](./media/adb21.png) -->
 
5. If prompted to **stay signed in**, select **Yes**.
 
![adb22.png](./media/adb22.png)
 
6. On the Databricks workspace page, select the **Catalog** and click on **zava_unity_catalog**.
 
> **Note**: If you are unable to see the catalog on your screen, please reduce your screen resolution or zoom level to **80%** or below.
 
![adb1.png](./media/adb1.png)
 
 
 
<!--
7. Expand **schema-56466348** schema, then expand **Volumes**, and select **fraud_raw_data** to view the uploaded files.
 
![adb23.png](./media/adb23.png)
 
Using these raw files, the ETL pipeline was executed, and tables were created in the Unity Catalog. Let's look at the pre-executed pipeline.
 
8. In the Databricks workspace, click **Jobs & Pipelines** from the left navigation pane and select the **ETL pipeline** listed under the Pipelines section.
 
![adb24.png](./media/adb24.png)
 
> **Note:** Refresh the page if you are unable to view the pipeline.
 
9. Look at a graphical representation of an ETL pipeline, with distinct streaming tables and a materialized view as part of the data flow.
 
![adb25.png](./media/adb25.png)
 
Here is a link of [click-by-click lab](https://click-by-click.azurewebsites.net/#preview/mhuep2jp0ddz5ecfz69g) showcasing how the pipeline was created and executed. Once you've completed the click-by-click walkthrough, please return to the lab and continue with the next step.
 
10. Click on **Catalog** in the left menu, expand the **zava_unity_catalog** catalog and expand the **schema-56466348** schema under the catalog.
 
11. Expand the **Tables** section to view table created by ETL pipeline.
 
![adb26.png](./media/adb26.png)
-->
 
7. On the right-hand side, click **Create Schema**.
 
![adb2.png](./media/adb2.png)
 
8. Enter ```schema-lab535``` in Schema name field and click on **Create**.
 
![ex1t1i4.png](./media/ex1t1i4.png)
 
9. After creating the schema, search for the schema (```schema-lab535```) you just created and select it.
 
![adb63.png](./media/adb63.png)
 
10. Click the **Create** button and choose **Volume** to create a new volume.
 
![adb64.png](./media/adb64.png)
 
11. Enter a volume name as ```fraud_raw_data``` and click on **Create**.
 
![Task-2.3_1.png](./media/ex1t1i61.png)
 
12. On the newly created volume, click **Upload to this Volume** to upload the required files.
 
![Task-2.3_1.png](./media/ex1t1i71.png)

13. Download the csv's by opening this url in a new tab and upload the csv's to the volume: ` https://stignite25.blob.core.windows.net/volume/csvs.zip ` *
 
14. Extract the downlaoded csv's
 
15. Navigate back to Databricks workspace, In the Upload Files to Volume window, select the **Browse** option.
 
![Task-2.3_1.png](./media/ex1t1i8.png)

16. select all the files and then click **Open**.
 
![adb4.png](./media/adb4.png)
 
16. Choose **Upload** to complete the process.
 
![adb5.png](./media/adb5.png)
 
>**Note:** Wait for the upload to complete before proceeding to the next step.
 
<!-- 16. From the left navigation, select **Workspace**, expand **Shared**, choose **Analytics with ADB** folder, and open **01.1-DLT-fraud-detection-SQL**.
 
![adb6.png](./media/adb6.png)
 
>**Note:** If you are not able to see content in the notebook, please download the notebook by opening this url in a new tab and import the notebook to your workspace: ` https://stignite25.blob.core.windows.net/notebook/01.1-DLT-fraud-detection-SQL.ipynb ` *
 
17. Press **Ctrl + F** to open the search bar, ensure its the notebook's search bar, then click the **down arrow** to the left of the search box to expand the **Replace options**. Type ```#schemaName#``` in the first field, enter ```schema-lab535``` in the second field, and then click **Replace All** to update all occurrences in the notebook.
 
![adb7.png](./media/adb7.png)
 
*Note: You may see a compressed view in case of a smaller window resolution. Please split the instructions screen or zoom out to view all menus correctly* -->
 
### Task 1.2: Create ETL pipeline for Data Transformation
 
1. From the left navigation pane, select **Jobs & Pipelines**, then choose **ETL Pipeline**.
 
![adb8.png](./media/adb8.png)
 
2. From the dropdown list, select **zava_unity_catalog**.
 
![Task-2.3_1.png](./media/ex1t1i19.png)
 
3. From the Schema dropdown list, search and select ```schema-lab535``` schema which you have created in the previous steps.
 
> **Note:** If you encounter the error "Couldn't load schemas", click the **Try again** button, this will reload and display the schemas.
 
![adb9.png](./media/adb9.png)
 
4. On the New Pipeline page, select **Add Existing Assets**.
 
![Task-2.3_1.png](./media/ex1t1i13.png)
 
5. In the **Pipeline root folder**, click on notebook icon.
 
![adb10.png](./media/adb10.png)
 
6. Search for ```Analytics with ADB``` folder and click **Select**.
 
![adb11.png](./media/adb11.png)
 
7. In the **Source Code Path**, select the **01.1-DLT-fraud-detection-SQL** notebook from the **Analytics with ADB** folder, and then click **Select**.
 
![Task-2.3_1.png](./media/ex1t1i15.png)
 
8. After adding the **pipeline root folder** and **source code path**, review the details and click **Add**.
 
![Task-2.3_1.png](./media/ex1t1i18.png)
 
9. After adding, click **Run Pipeline** from the top-right corner to execute the pipeline.
 
![Task-2.3_1.png](./media/ex1t1i211.png)
 
> **Note:** Wait for the pipeline to complete. A pop-up will confirm that the pipeline executed successfully, and the graph will appear afterward.
 
![adb12.png](./media/adb12.png)

10. The ETL pipeline created above generates streaming data, which cannot be mirrored in Fabric for Task 3.1: Mirror Unity Catalog Table into Fabric's OneLake. Follow the steps below to create static tables instead.

11. On the Databricks workspace page, select the **Catalog** and click on **zava_unity_catalog**.
  
![adb1.png](./media/adb1.png)

12. Expand the pre-created **cdata** schema, click on the pre-created **fraud_raw_data** volume, and then select datastore.
 
 ![adb1.png](./media/staticdata1.png)

13. Click on **Serverless Starter Warehouse**, then click on **Start and Close**.

 ![adb1.png](./media/staticdata3.png)

14. Click the three dots (ellipsis) next to the **gold_transactions** table, then select **Create table**.

 ![adb1.png](./media/staticdata2.png)

15. Click the three dots (ellipsis) next to the silver_transactions table, then select **Create table**.



 
### Task 1.3: Generate column-level insights with AI Suggested Descriptions, then explore data lineage, table update history, and profiling in Azure Databricks.
 
1. Click on Catalog and search for the schema ```schema-lab535``` select it.
 
![adb66.png](./media/adb66.png)
 
2. Expand **Tables** and click on the **bronze_transactions** table.
 
![adb67.png](./media/adb67.png)
 
3. On the right-hand side, scroll down and click **AI generate**.
 
![adb14.png](./media/adb14.png)
 
> **Note:** If a pop-up appears with the message "Saving comments in bulk could be slow", click **Continue**.
 
![adb69.png](./media/adb69.png)
 
4. Review the AI-generated comments for the columns, then click **Save all**.
 
![adb65.png](./media/adb65.png)
 
<!--
5. Click on **Discard changes**.
 
![adb29.png](./media/adb29.png)
-->
 
5. To view the lineage, select the **Lineage** tab and review the details in that section. Additionally, click on **See Lineage Graph** to view a visual representation of the data flow.
 
![adb30.png](./media/adb30.png)
 
6. Click the **X (Close)** button to exit the lineage view.
 
![adb31.png](./media/adb31.png)
 
 
===
 
## Exercise 2: AI-Driven Insights with Azure AI Foundry & Genie
 
### Task 2.1: Create a Databricks Assistant AI/BI Genie
 
In this task, we will create Genie workspace in Databricks.
 
1. In the left menu bar, click on **Genie**.
 
![databricks](./media/databricks3.png)
 
2. Click on **+ New**.
 
![databricks](./media/databricks4.png)
 
3. Search for ```schema-lab535``` schema in the search bar.
 
4. Select **gold_transactions** table.
 
5. Click on **Create**.
 
![adb16.png](./media/adb16.png)
 
6. Click on **New Space** in the top left to edit the name and replace it with ```Zava_Genie```.
 
![databricks](./media/databricks9.png)
 
7. Paste the following question in chat box and click on **send**.
 
 
```what is the percentage of fraudulent transactions in my dataset?```
 
![Gini.png](./media/Gini.png)
 
8. Observe the response from Genie, then click **Show code** to view the code Genie used to formulate the answer.
 
> **Note:** The responses from Genie may not match the ones in the screenshot but will provide a similar response.
 
![Gini1.png](./media/Gini1.png)
 
 
 
### Task 2.2: Connect AI/BI Genie inside AI Foundry.
 
In this task, we will set up a connection between Azure Databricks Genie and Azure AI Foundry and then create an agent.
 
1. Navigate back to the resource group page and click on **AIhub-....**.

![databricks](./media/aifoundary1.png)

2. Click on **Go to Azure AI Foundary portal**.

![databricks](./media/aifoundary2.png)
 
2. Scroll down all the way to bottom and then click on **Management center**.
 
> **Note**: Due to screen resolution, a scrollbar may appear on the **far right side**. Scroll all the way down to access and click on **Management Center**.
 
![databricks](./media/aifoundary3.png)
 
3. Click on **Connected resources**, then click on **+ New connection**.
 
![databricks](./media/aifoundary4.png)
 
4. Scroll down and click on **Azure Databricks**.
 
![databricks](./media/aifoundary5.png)
 
5. Click the dropdown for **Connection Type**, then Select **Genie**.

>**Note**: Please make sure you select the **Resource group** you opened in **step 1**.

![databricks](./media/aifoundary6.png)
 
6. Click the drop down for **Select Genie space**, choose **Zava_genie**, and then click on **Add connection**.
 
![databricks](./media/aifoundary7.png)
 
7. Once it's **connected**, the status will confirm the connection.
 
![adb48.png](./media/adb48.png)
 
Due to time constraints in the lab, we will not create an agent in AI Foundry. It has already been created and orchestrated within a custom web app. In the next task, we will interact with it.
 
### Task 2.3: Use Agent Created Inside AI Foundry with Custom Web App
 
In this Task, You'll use the AI agent within a custom web application to deliver interactive, data-powered intelligence.
 
1. In a new tab of your browser enter the URL ```https://app-aifoundry-genieintegration.azurewebsites.net/#/landing-page``` and press Enter key.
 
> **Note:** If a permissions request **pop-up** appears, click the **Accept** button.
 
2. Select the **terms and conditions** checkbox, then click **Login**.
 
![Webapp Login.png](./media/WebappLogin.png)
 
3. Click on the **robot** icon located at the bottom-right corner of the page.
 
![](./media/customwebapp1.png)
 
4. Click on the first pre-populated question.
 
![](./media/customwebapp2.png)
 
5. Observe the response.
 
![](./media/customwebapp3.png)
 
6. Click on the second pre-populated question and observe the response.
 
![](./media/customwebapp4.png)
<!--
6. Click on the third pre-populated question and observe the response.
 
![](./media/customwebapp5.png)
 
7. Click on the next pre-populated question and observe the response.
 
![](./media/customwebapp6.png)
-->
 
===
## Exercise 3: Azure Databricks Mirrored Catalog in Microsoft Fabric
 
### Task 3.1: Mirror Unity Catalog Table into Fabric's OneLake
 
Mirroring the Azure Databricks Catalog structure in Fabric allows seamless access to the underlying catalog data through shortcuts. This means that any changes made to the data are instantly reflected in Fabric, without the need for data movement or replication. Let's step into Data Engineer's shoes to create a Mirrored Azure Databricks Catalog.
 
1. In a new tab of your browser enter the URL ```https://app.fabric.microsoft.com``` and press **Enter** key.
 
> **Note:** Close any pop-up that appears on the screen throughout the lab.
 
![adb49.png](./media/adb49.png)
 
2. From the left navigation pane, click on **Workspaces** and then the **+ New workspace** button.
 
![adb33.png](./media/adb33.png)
 
3. Type the name ```fabric-lab535``` **validate** the available name and click **Apply**.
 
![adb34.png](./media/adb34.png)
 
> **Note:** Close any pop-up that appears on the screen.
 
![adb50.png](./media/adb50.png)
 
4. In the workspace, click on **Workspace settings**.

   ![Give the name and description for the new workspace.](./media/powerbi1.png)

5. In the left side bar, click on **License info** and then click on **Edit**.

   ![Give the name and description for the new workspace.](./media/workspacesettings.png)
6. Click on **Fabric Capacity** radio button.

> **Note:** If your workspace doesn't has **Fabric capacity**, use the **Trial** License type.
> **Note:** Use of the Fabric Capacity is recommended for a better experience.

7. **Scroll down** and click on **Select license**.

    ![Give the name and description for the new workspace.](media/workspacesettings2.png)

8. Select **New item** from menu bar.
 
![adb36.png](./media/adb36.png)
 
9. In the **New item** window, search ```Mirrored Azure Databricks catalog``` and select it.
 
![adb51.png](./media/adb51.png)

10. Navigate to the resource group you created.

![Task-2.3_1.png](./media/ex1t1i1.png)

11. Select the Databricks workspace you created and copy the **URL**.

![Task-2.3_1.png](./media/ex1t1i2.png)

![Task-2.3_1.png](./media/copyadburl.png)

12. Naviagate bck to Fabric page.

13. When the **New source** window pops up, click on the **New connection**, click on **Sign in**.
 
<!-- ![ADBC1.png](./media/mirroreddbsp.png) -->

 ![ADBC1.png](./media/signinadb.png)

14. **Select** the user account you used for logging into the Azure Portal.
 
15. click on the **Connect** button.
 
![Task-2.3_7.png](./media/Task-2.3_7.2.png)
 
> **Note:** Close any pop-up that appears on the screen.
 
16. Click on **Next** button.
 
![Task-2.3_7.1.png](./media/Task-2.3_7.1.png)
 
17. In the **Choose data** screen, select the Catalog name as **zava_unity_catalog** from the dropdown box, and select the **cdata** schema if not selected, scroll down then select the checkbox **Automatically sync future catalog changes for the selected schema** (to mirror future tables) if not ticked and click on **Next** button.
 
![Task-2.3_8.png](./media/Task-2.3_8.png)
 
18. Click on the **Create** button.
 
![adb54.png](./media/adb54.png)
 
> **Note**: Wait for the notification confirming that the mirroring is complete (as shown in the "Shortcuts created" message).
 
![adb52.png](./media/adb52.png)
 
19. Click on the **Monitor catalog** button to track the mirroring status and then close it.
 
![Task-2.3_10.1.png](./media/Task-2.3_10.1.png)
 
20. Click on the **View SQL endpoint** button. You can also select the tables to preview data.
 
![Task-2.3_10.png](./media/Task-2.3_10.png)
 
### Task 3.2: Create a semantic model in Direct Lake mode and use Power BI to visualize and generate insights
 
1. Click on **New semantic model**.
 
![](./media/semantic.png)
 
2. Paste the semantic model name as ```fraud_detection```, search ```gold_transactions```, select it and then click on **Confirm**.
 
![adb60.png](./media/adb60.png)
 
3. Wait for the semantic model to be created, then select the **workspace** from the left menu.
 
![adb55.png](./media/adb55.png)
 
4. Click on the Ellipses (3 dots) next to **fraud_detection** Semantic Model to load the dropdown menu. Select **Create report** from the dropdown.
 
![](./media/semantic2.png)
 
5. Click on the **Copilot** button and click on **Get started**.
 
![adb57.png](./media/adb57.png)
 
6. select the ‘Inspire’ button (The Glitter icon at the bottom left of the chat window). Select the option **What’s in my data?** under the Inspire pane.

![](./media/semantic3.1.5.png)

7. Paste the following question into the Copilot chat and click on send icon.
 
```Create a report to analyse in detail only fraudulent transactions.```
 
> **Note**: Wait for the report to load.
 
![semantic6.png](./media/semantic6.png)
 
8. Look at the **response**.
 
> **Note**: The responses from Copilot may not match the ones in the screenshot.
 
![adb59.png](./media/adb59.png)
 
9. Paste the following question into the Copilot chat and take a look at the response.
 
```Based on the data of this report, what can be done to reduce the fraudulent transactions, and should I focus on.```
 
![adb68.png](./media/adb68.png)
 
 
===
 
 
## Exercise 4: Copilot Studio for Low-Code Automation
### Task 4.1: Create an agent and connect Azure Databricks as its knowledge source to support Business Q&A.
 
1. In a new tab of your browser enter the URL ```https://copilotstudio.microsoft.com/``` and press **Enter** key.
 
2. On the **welcome** screen for Microsoft Copilot Studio, Click on the **Get Started** button to proceed.
 
![adb37.png](./media/adb37.png)
 
3. Select **Agents** from the left menu, and click **+ New agent**.
 
![](./media/ex4t1i1.png)
 
> **Note:** Close any pop-up that appears on the screen.
 
![adb38.png](./media/adb38.png)
 
4. On the **Start building your agent** page, click **Configure**, enter the agent name as ```Databricks Agent``` and add the description ```Responds to queries using data from your Databricks workspace```.
 
![adb61.png](./media/adb61.png)
 
5. On the right menu, click **Create**.
 
![adb40.png](./media/adb40.png)
 
> Note: Wait for the agent to load.
 
6. On the **knowledge** page, click **+ Add knowledge** to include a knowledge source.
 
![adb41.png](./media/adb41.png)
 
7. On the **Add knowledge** page, click **Advanced**, then select **Azure Databricks**.
 
> **Note**: Ensure that you select **Azure Databricks** only, as Databricks is also available as a separate connection option.
 
![adb62.png](./media/adb62.png)
 
8. On the **Select Azure Databricks connection** pane, click on **Not connected** dropdown and select **Create new connection**.
 
![adb42.png](./media/adb42.png)
 
9. Navigate back to your Databricks workspace, click **SQL Warehouses** from the left menu, select **SQL Warehouses** at the top, and then click **Serverless Starter Warehouse.**
 
![](./media/ex4t1i5.png)
 
10. On the **Serverless Starter Warehouse** page, click **Connection Details**, and copy the **Server Hostname** and **HTTP Path**.
 
![](./media/ex4t1i6.png)
 
11. In Copilot Studio, on the **Azure Databricks Connection** page, paste the **Server Hostname** and **HTTP Path** you copied earlier and click on **Create**.
 
![](./media/ex4t1i7.png)
 
12. In the pop-up window, select your account and click **Sign in**.
 
![](./media/ex4t1i8.png)
 
13. Select **zava_unity_catalog** and click **Select**.
 
![](./media/ex4t1i9.png)
 
14. Search for ```schema-lab535.gold```, select the ```gold_transactions``` tables within it, and click **Add to Agent**.
 
![](./media/ex4t1i10.png)
 
> **Note:** Wait for the agent to load.
 
15. Paste the following question to **Test your agent**.
 
```what is the percentage of fraudulent transactions in my dataset?```
 
![gini.png](./media/gini.png)
 
16. The Agent will respond with:
**Let's get you connected first, and then I can find that info for you. Open connection manager to verify your credentials.**
Click on **Open connection manager**.
 
![](./media/ex4t1i13.png)
 
>**Note**:  If prompted to sign in, use your user ID to complete the sign-in process.
 
![](./media/ex4t1i14.png)
 
17. Click on **Connect**.
 
![](./media/ex4t1i15.png)
 
18. Click on **Submit**.
 
![](./media/ex4t1i16.png)
 
19. Navigate back to the **Agent** page and Paste the same question again into **Test your agent**.
 
```what is the percentage of fraudulent transactions in my dataset?```
 
![gini1.png](./media/gini.png)
 
<!--
16. Paste the following questions one by one into the Agent and review the responses.
 
```
Show me the top 10 most frequent fraud types in gold_transactions.
```
```
What is the average transaction amount for fraudulent vs non-fraudulent transactions?
```
```
Which countries have the highest number of flagged transactions?
```
 
17. Click on **Publish**.
 
![](./media/ex4t1i11.png)
-->
 
### Task 4.2: Publish the agent in Microsoft Teams channels and make it accessible to users.
 
1. Click on **+7** at the top, then select **Channels** from the dropdown menu to view channel options.
 
![adb43.png](./media/adb43.png)
 
> **Note**: The number displayed (such as +7) may vary depending on your screen's resolution or window size, as it indicates the count of additional menu options not visible in the main navigation bar.
 
3. The **Microsoft Teams** channel should appear in the list, for this lab the agent has already been published and added to **Teams.**
 
![adb44.png](./media/adb44.png)
 
<!--
>**Note:** If you don't see **Channels**, click on **+4** or **+5** in the Agent menu blade.
 
![](./media/teams2.png)
 
2. Click on **Add channel**.
 
![](./media/teams3.png)
 
3. Click on **See agent in Teams**.
 
![](./media/teams4.png)
 
 
4. Click on **Use the web app instead**.
 
![](./media/teams5.png)
 
5. Click on **Add**.
 
![](./media/teams6.png)
 
 
 
4. In a new tab of your browser enter the URL ```https://teams.microsoft.com/v2/``` and press **Enter** key.
 
> **Note:** Close any pop-up that appears on the screen.
 
![adb45.png](./media/adb45.png)
-->
5. In a new tab of your browser enter the URL ```https://click-by-click.azurewebsites.net/#preview/mhw2w6exgz21zno97ch``` and press **Enter** key.
6. Follow click by click url, then navigate to Microsoft Teams to see the agent in action.
 
![C2CTeams.png](./media/ADBC1.png)
 
Congratulations!
As Data Engineers and Data Analysts, you have empowered Zava to transform its disparate data sources into actionable insights-driving growth, enhancing customer satisfaction, and securing a competitive edge.