# Frequently Asked Questions

- [What if any resource shows failure during ARM deployment?](#what-if-any-resource-shows-failure-during-arm-deployment)
- [What if my cloud-shell session times out?](#what-if-my-cloud-shell-session-times-out)
- [Cloning repository gives error on cloudshell](#cloning-repository-gives-error)
- [Unable to authenticate a Power BI report](#unable-to-authenticate-a-power-bi-report)
- [What if pipeline execution fails in synapse](#what-if-pipeline-execution-fails-in-synapse)
- [What if embedded reports dont show up in web app](#what-if-embedded-reports-dont-show-up-in-web-app)


## What if any resource shows failure during ARM deployment?

Sometimes resources may fail to deploy when there is too much traffic on azure servers ,the azure service is down for maintenance or the particular service is not available in your region.

- Check the azure services status here: https://status.azure.com/en-us/status and check the availability of the service that is failing for you.
- Retry the deployment in another region/location.
- Make sure the following resource providers are registered for your Azure Subscription.  
  - Microsoft.Sql 
  - Microsoft.Synapse 
  - Microsoft.StreamAnalytics  
  - Microsoft.EventHub  

## What if my cloud-shell session times out?

It is important to keep the cloud shell session live during execution else the script will fail to complete. In this case you may try to re-run the script but it may throw errors for the conflicting tasks. As a last resort you will have t delete the resources and re-deploy the templates.

## Cloning repository gives error
- Check if you already have a folder named MfgAI in your cloudshell using PowerShell ```ls```
- If so, delete the folder by running the following command ```rm MfgAI -r -f```
- If you are getting insufficient space error, delete any other folders that are present on the cloud shell.
- You can choose to recreate the storage mount for your cloudshell by deleting the existin storage account that you configured for it or executing the command ```clouddrive unmount```

## Unable to authenticate a Power BI report

- Check the datasource server of the report if it got updated with server name of your SQL pool.
- If there is a data source mismatch, download the report and edit the datasource of it to point to the correct SQL pool and republish the report. Make sure the report id does not change during the republish. 

Follow the steps below to update the datasource:

### Updating Power BI report parameters through Power BI Service

1.	In the Power BI service, **click** on 'Settings' icon on top-right corner. **Click** on 'Settings' from the expanded list.

![Click on settings.](media/click-settings.png)

2.	**Select** the tab for 'Datasets' and **highlight** a dataset in the list.

![Highlight a dataset.](media/select-datasets.png)

3.	**Expand** 'Parameters'.

4.	If the selected dataset has no parameters, you see a message with a link to 'Learn more about query parameters', in which case you should follow the steps mentioned in the next section. If the dataset has parameters, expand the 'Parameters' heading to reveal those parameters.

5.	**Review** the parameter settings and make changes if needed. 

> **Note:** Grayed-out parameter fields are not editable.

![Expand and edit parameters.](media/expand-parameters.png)

6. **Click** on 'Apply'.

![Click Apply.](media/click-apply.png)


### Modifying the Power BI report’s dataset through Power BI Desktop

1. **Open** Power BI Desktop application. If you don’t have Power BI Desktop pre-installed on your system, please **install** it from here:  https://www.microsoft.com/en-us/download/details.aspx?id=58494

2. Download the pbix file by going to your report in the Power BI service and clicking download button from the file dropdown. **Open** the pbix file once downloaded.

![Download pbix.](media/download-pbix.png)

3. In the 'Home' tab, under the 'Queries' section, **click** on the 'Transform Data' dropdown icon.

4. **Click** on 'Data Source Settings' from the dropdown. This opens the 'Data Source Setting' window.

![Click Transform Data.](media/transform-data.png)

5. In the 'Data Source Setting' window, **select** the 'Data sources in current file' radio button.

6. **Click** on the data source that you want to modify.

7. **Click** on 'Change Source'.

![Edit the data source.](media/data-source-setting.png)

8.	In the database window that appears, **enter** the Synapse workspace name in the 'Server' name field and 'ManufacturingDW' in the 'Database' name field.

9. **Verify** the SQL statement that you are using to query your SQL data source.

10. **Click** on 'OK'.

> **Note:** The SQL statement verification is an optional step, you can connect to the data source even if the SQL statement is blank.

![Edit the SQL server details.](media/sql-server-details.png)

11. **Click** on 'Close' in the 'Data Source Setting' window.

![Edit the data source.](media/data-source-setting1.png)

12.	On the prompt that appears next to the 'Report' pane, **click** on 'Apply Changes'.

![Apply Changes.](media/apply-changes.png)

13.	This starts updating the data sources as per the modification. Once this is done, the report reflects the data source changes.

![Monitor progress.](media/monitor-progress.png)

14.	Click the publish button to publish the report back to Power BI service.

![Publish Changes.](media/publish-changes.png)


## What if pipeline execution fails in synapse
1. **Open** Monitor Hub in synapse.
2. **Click** the pipeline run that failed.
3. **Check** the error message from the table listed.
4. If the error message shows "spark pool core limit reached", wait for sometime and then re-run the pipeline.

## What if embedded reports dont show up in web app
1. Ensure that admin consent is granted for your app service principal.
2. Ensure the client secret and client id are replaced in the appsettings.json of the web app starting with "manufacturing-poc".
