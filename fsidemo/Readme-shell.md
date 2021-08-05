# Fsi DREAM Demo in a Box Setup Guide
## Setup Instructions


## Requirements

* An Azure Account with the ability to create an Azure Synapse Workspace.
* A Power BI Pro or Premium account to host Power BI reports.
* Make sure you are the Power BI administrator for your account and service principal access is enabled on your Power BI tenant.
* Make sure the following resource providers are registered with your Azure Subscription.
   - Microsoft.Sql 
   - Microsoft.Synapse 
   - Microsoft.StreamAnalytics 
   - Microsoft.EventHub 
   - Microsoft.Media.MediaServices
* You can run only one deployment at any point in time and need to wait for its completion. You should not run multiple deployments in parallel as that will cause deployment failures.
* Select a region where the desired Azure Services are available. If certain services are not available, deployment may fail. See [Azure Services Global Availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=all) for understanding target service availability. (consider the region availability for Synapse workspace, Iot Central and cognitive services while choosing a location)
* Do not use any special characters or uppercase letters in the environment code. Also, do not re-use your environment code.
* In this Accelerator we have converted Real-time reports into static reports for the ease of users but have covered entire process to configure Realtime dataset. Using those Realtime dataset you can create Realtime reports.
* Please ensure that you select the correct resource group name. We have given a sample name which may need to be changed should any resource group with the same name already exist in your subscription.
* The audience for this document is CSAs and GBBs.
* Please log in to Azure and Power BI using the same credentials.
* Once the resources have been setup, please ensure that your AD user and synapse workspace have “Storage Blob Data Owner” role assigned on storage account name starting with “stfsi”. You need to contact AD admin to get this done.
* Please review the [Liscence Agreement](https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/fsi/fsidemo/Power%20BI%20Embedding.md) before proceeding.

## Setup Tasks:

<!-- TOC -->

  - [Task 1: Create a resource group in Azure](#task-1-create-a-resource-group-in-azure)
  - [Task 2: Create Power BI workspace](#task-2-create-power-bi-workspace)
  - [Task 3: Deploy the ARM Template](#task-3-deploy-the-arm-template)
  - [Task 4: Run the Cloud Shell](#task-4-run-the-cloud-shell)
  - [Task 5: Create Power BI reports and Dashboard](#task-5-create-power-bi-reports-and-dashboard)
  - [Task 6: AML notebook execution](#task-6-aml-notebook-execution)
  - [Task 7: Pause/Resume script](#task-7-pause-resume-resources)
  - [Task 8: Clean up environment](#task-8-clean-up-resources)

<!-- /TOC -->

### Task 1: Create a resource group in Azure

1. **Log into** the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, **select** the '+ Create a resource' tile.

	![A portion of the Azure Portal home screen is displayed with the + Create a resource tile highlighted.](media/create-a-resource.png)

3. In the Search the Marketplace text box, **type** "Resource Group" and **press** the Enter key.

	![On the new resource screen Resource group is entered as a search term.](media/resource-group.png)

4. **Select** the 'Create' button on the 'Resource Group' overview page.

	![A portion of the Azure Portal home screen is displayed with Create Resource Group tile](media/resource-group-2.png)
	
5. On the 'Create a resource group' screen, **select** your desired Subscription. For Resource group, **type** 'DDiB-FSI-Lab'. 

6. **Select** your desired region.

	> **Note:** Some services behave differently in different regions and may break some part of the setup. Choosing one of the following regions is preferable: 		westus2, eastus2, northcentralus, northeurope, southeastasia, australliaeast, centralindia, uksouth, japaneast.

7. **Click** the 'Review + Create' button.

	![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](media/resource-group-3.png)

8. **Click** the 'Create' button once all entries have been validated.

	![Create Resource Group with the final validation passed.](media/resource-group-4.png)

### Task 2: Power BI Workspace creation

1. **Open** Power BI in a new tab using the following link:  [https://app.powerbi.com/](https://app.powerbi.com/)

2. **Sign in**, to Power BI using your Power BI Pro account.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use the same credentials for Power BI which you will be using for the Azure account.

3. In Power BI service **Click** on 'Workspaces'.

4. Then **click** on the 'Create a workspace' tab.

	![Create Power BI Workspace.](media/power-bi-2.png)

	> **Note:** Please create a Workspace by the name "DDiB-FSI".

5. **Copy** the Workspace GUID or ID. You can get this by browsing to [https://app.powerbi.com/](https://app.powerbi.com/), selecting the workspace, and then copying the GUID 	from the address URL.

6. **Paste** the GUID in a notepad for future reference.

	![Give the name and description for the new workspace.](media/power-bi-3.png)

	> **Note:** This workspace ID will be used during ARM template deployment.

7. Go to your Power BI **workspace** and **click** on New button. 

8. Then **click** on **Streaming Dataset** option from the dropdown. 

	![Select new and then steaming dataset.](media/power-bi-4.png)

9. **Select API** from the list of options and **click** next. 

10. **Enable** the ‘Historic data analysis’ 

	![Select API then next.](media/power-bi-5.png)

	![Switch Historical data analysis on.](media/power-bi-6.png)

11. **Enter** ‘Before-scenario-cco-dataset’ as dataset name and **enter** the column names in “values from stream” option from list below  and **click** on create button: 
	- NPS 				:	number
	- TargetNPS  			:	number
	- CustomerChurn  		:	number
	- TargetCustomerChurn  		:	number
	- AccountOpeningTime  		:	number
	- TargetAccountOpeningTime  	:	number
	- RequestsWithinSLA  		:	number
	- TargetRequestsWithinSLA  	:	number
	- SocialSentiment  		:	text
	- NPSAfter  			:	number
	- TargetNPSAfter  		:	number
	- CustomerChurnAfter  		:	number
	- TargetCustomerChurnAfter  	:	number
	- AccountOpeningTimeAfter  	:	number
	- TargetAccountOpeningTimeAfter :	number
	- RequestsWithinSLAAfter  	:	number
	- TargetRequestsWithinSLAAfter  :	number
	- SocialSentimentAfter  	:	text
	
	![Create new streaming dataset.](media/power-bi-7.png)

12. **Copy** the push url of dataset ‘Before-scenario-cco-dataset’ and place it in a notepad for later use.

	![Provide the Push Url.](media/power-bi-8.png)

13. Similarly create another dataset and **Enter** ‘Before-scenario-financial-hcrr-dataset’ as dataset name and **enter** the column names in “values from stream” option from list below and **click** on create button: 
	- InvestigationResponseTime :number
	- TargetInvestigationResponseTime :number
	- PerfvsEfficiency :number
	- TargetPerfvsEfficiency :number
	- SanctionsAlertRate :number
	- TargetSanctionsAlertRate :number
	- OpenTransactionsAlertLevel1 :number
	- TargetOpenTransactionsAlertLevel1 :number
	- OpenTransactionsAlertLevel2 : number
	- TargetOpenTransactionsAlertLevel2 :number
	- AlertsClosedWithSLA :number
	- TargetAlertsClosedWithSLA :number
	- KYCAlertinSanctions :number
	- TargetKYCAlertinSanctions : number
	- KYCAlertinPEP:number
	- TargetKYCAlertinPEP: number
	- TargetKYCAlertinMedia : number
	- Vulnerabilities : number
	- KYCAlertinMedia:number
	- TargetVulnerabilities: number
	- InvestigationResponseTimeCyberSec : number
	- TargetInvestigationResponseTimeCyberSec: number
	- TerminatedEmployeesAccess: number
	- TargetTerminatedEmployeesAccess: number
	- UnauthorizedEmployees: number
	- TargetUnauthorizedEmployees: number
	- NoHardwareSecurity: number
	- TargetNoHardwareSecurity: number
	- CreditRiskExposure: number
	- TargetCreditRiskExposure: number
	- FinancialCrime: number
	- TargetFinancialCrime: number
	- TradingExposure: number
	- TargetTradingExposure: number
	- ESGAssets: number
	- TargetESGAssets: number
	- ClaimsProcessingCycleTime: number
	- TargetClaimsProcessingCycleTime: number
	- UnderwritingEfficiency: number
	- TargetUnderwritingEfficiency: number
	- OverallCreditRisk: number
	- TargetOverallCreditRisk: number
	- OverallOperationalRisk: number
	- TargetOverallOperationalRisk: number

	![Create new streaming dataset.](media/power-bi-9.png)

14. **Copy** the push url of dataset ‘Before-scenario-financial-hcrr-dataset’ and place it in a notepad for later use.

	![Provide the Push Url.](media/power-bi-8.png)

15. Similarly create another dataset and **Enter** ‘Before-after-scenario-group-ceo-dataset’ as dataset name and **enter** the column names in “values from stream” option from list below and **click** on create button:: 
	- CSAT :number
	- AverageAttrition :number
	- ComplianceScore :number
	- CustomerChurn :number
	- CustomerChurnAfter :number
	- EmployeeSatisfaction :number
	- EmployeeSatisfactionAfter :number
	- TargetCustomerChurn :number
	- TargetCustomerChurnAfter :datetime
	- TargetAverageAttrition :number
	- TargetEmployeeSatisfaction :number
	- TargetEmployeeSatisfactionAfter :number
	- TargetComplianceScore :number
	- RelativePerformancetoS&P500 :number
	- RelativePerformancetoS&P500After :number
	- TargetRelativePerformancetoS&P500 :number
	- TargetRelativePerformancetoS&P500After :number
	- QuarterlyClaimsProcessingEfficiency :number
	- QuarterlyClaimsProcessingEfficiencyAfter :number
	- TargetQuarterlyClaimsProcessingEfficiency :number
	- TargetQuarterlyClaimsProcessingEfficiencyAfter :number
	- CSRRating :number
	- CSRRatingAfter :number
	- TargetCSRRating :number
	- TargetCSRRatingAfter :number
	- ChannelEngagementRiskofChurn :number
	- ChannelEngagementRiskofChurnAfter :number
	- TargetChannelEngagementRiskofChurn :number

	![Create new streaming dataset.](media/power-bi-10.png)

16. **Copy** the push url of dataset ‘Before-after-scenario-group-ceo-dataset’ and place it in a notepad for later use.

	![Provide the Push Url.](media/power-bi-8.png)

17. Similarly create another dataset and **Enter** ‘After-scenario-financial-hcrr-dataset’ as dataset name and **enter** the column names in “values from stream” option from list below and **click** on create button:

	- InvestigationResponseTime :number
	- TargetInvestigationResponseTime :number
	- PerfvsEfficiency :number
	- TargetPerfvsEfficiency :number
	- SanctionsAlertRate :number
	- TargetSanctionsAlertRate :number
	- OpenTransactionsAlertLevel1 :number
	- TargetOpenTransactionsAlertLevel1 :number
	- OpenTransactionsAlertLevel2 : number
	- TargetOpenTransactionsAlertLevel2 :number
	- AlertsClosedWithSLA :number
	- TargetAlertsClosedWithSLA :number
	- KYCAlertinSanctions :number
	- TargetKYCAlertinSanctions : number
	- KYCAlertinPEP:number
	- TargetKYCAlertinPEP: number
	- TargetKYCAlertinMedia : number
	- Vulnerabilities : number
	- KYCAlertinMedia:number
	- TargetVulnerabilities: number
	- InvestigationResponseTimeCyberSec : number
	- TargetInvestigationResponseTimeCyberSec: number
	- TerminatedEmployeesAccess: number
	- TargetTerminatedEmployeesAccess: number
	- UnauthorizedEmployees: number
	- TargetUnauthorizedEmployees: number
	- NoHardwareSecurity: number
	- TargetNoHardwareSecurity: number
	- CreditRiskExposure: number
	- TargetCreditRiskExposure: number
	- FinancialCrime: number
	- TargetFinancialCrime: number
	- TradingExposure: number
	- TargetTradingExposure: number
	- ESGAssets: number
	- TargetESGAssets: number
	- TargetClaimsProcessingCycleTime: number
	- UnderwritingEfficiency: number
	- TargetUnderwritingEfficiency: number
	- OverallCreditRisk: number
	- TargetOverallCreditRisk: number
	- OverallOperationalRisk: number
	- TargetOverallOperationalRisk: number

	![Create new streaming dataset.](media/power-bi-11.png)

18. **Copy** the push url of dataset ‘After-scenario-financial-hcrr-dataset’ and place it in a notepad for later use.

	![Provide the Push Url.](media/power-bi-8.png)

### Task 3: Deploy the ARM Template

1. **Open** this link in a new tab of the same browser that you are currently in: 
	
	<a href='https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FAzure-Analytics-and-AI-Engagement%2Ffsi%2Ffsidemo%2FmainTemplate.json' target='_blank'><img src='http://azuredeploy.net/deploybutton.png' /></a>

2. On the Custom deployment form, **select** your desired Subscription.

3. **Select** the resource group name **DDiB-FSI-Lab** which you created in [Task 1](#task-1-create-a-resource-group-in-azure).

4. **Provide/Type** an environment code which is unique to your environment. This code is a suffix to your environment and should not have any special characters or uppercase letters and should not be more than 6 characters. 

5. **Provide** a strong SQL Administrator login password and set this aside for later use.

6. **Enter** the Power BI workspace ID created in [Task 2](#task-2-power-bi-workspace-creation).

7. **Enter** the power BI streaming dataset url for **Before-scenario-financial-hcrr-dataset** you copied in step 14 of task 2.

8. **Enter** the power BI streaming dataset url for **After-scenario-financial-hcrr-dataset** you copied in step 18 of task 2.

	![The Custom deployment form is displayed with example data populated.](media/powerbi-deployment-1.png)

9. **Enter** the power BI streaming dataset url for **Before-scenario-cco-dataset** you copied in step 12 of task 2.

10. **Enter** the power BI streaming dataset url for **Before-after-scenario-group-ceo-dataset** you copied in step 16 of task 2.

11. **Click** ‘Review + Create’ button.

	![The Custom deployment form is displayed with example data populated.](media/powerbi-deployment-2.png)

12. **Click** the **Create** button once the template has been validated.

	![Creating the template after validation.](media/powerbi-deployment-3.png)

	> **NOTE:** The provisioning of your deployment resources will take approximately 20 minutes.

13. **Stay** on the same page and wait for the deployment to complete.
    
	![A portion of the Azure Portal to confirm that the deployment is in progress.](media/microsoft-template.png)
    
14. **Select** the **Go to resource group** button once your deployment is complete.

	![A portion of the Azure Portal to confirm that the deployment is in progress.](media/microsoft-template-2.png)

### Task 4: Run the Cloud Shell to provision the demo resources

**Open** the Azure Portal.

1. In the Resource group section, **open** the Azure Cloud Shell by selecting its icon from the top toolbar.

	![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/cloud-shell.png)

2. **Click** on 'Show advanced settings'.

	![Mount a Storage for running the Cloud Shell.](media/cloud-shell-2.png)

	> **Note:** If you already have a storage mounted for Cloud Shell, you will not get this prompt. In that case, skip step 2 and 3.

3. **Select** your 'Resource Group' and **enter** the 'Storage account' and 'File share' name.

	![Mount a storage for running the Cloud Shell and Enter the Details.](media/cloud-shell-3.png)

	> **Note:** If you are creating a new storage account, give it a unique name with no special characters or uppercase letters.

4. In the Azure Cloud Shell window, ensure the PowerShell environment is selected and **enter** the following command to clone the repository files.
Command:
```
git clone -b fsi https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git fsi
```

![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-4.png)
	
> **Note:** If you get File already exist error, please execute following command: rm fsi -r -f to delete existing clone.

> **Note**: When executing scripts, it is important to let them run to completion. Some tasks may take longer than others to run. When a script completes execution, you will be returned to a command prompt. 

5. **Execute** the fsiSetup.ps1 script by executing the following command:
Command:
```
cd ./fsi/fsidemo
```

6. Then **run** the PowerShell: 
```
./fsiSetup.ps1
```
    
![Commands to run the PowerShell Script.](media/cloud-shell-5.png)
      
7. From the Azure Cloud Shell, **copy** the authentication code

8. Click on the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

	![Authentication link and Device Code.](media/cloud-shell-6.png)
     
9. **Paste** the authentication code.

	![New Browser Window to provide the Authentication Code.](media/cloud-shell-7.png)

10. **Select** the same user that you used for signing in to the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.png)

11. **Close** the browser tab once you see the message window at right and **go back** to your Azure Cloud Shell execution window.

	![Authentication done.](media/cloud-shell-9.png)
	
12. **Navigate back** to the resource group tab.

13. You will get another code to authenticate an Azure PowerShell script for creating reports in Power BI. **Copy** the code.

14. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

	![Authentication link and Device code.](media/cloud-shell-10.png)

15. A new browser window will launch.

16. **Enter** the authentication code you copied from the shell above.

	![Enter the Resource Group name.](media/cloud-shell-11.png)

17. Again, **select** the same user to authenticate which you used for signing into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select Same User to Authenticate.](media/cloud-shell-12.png)
	
18. **Close** the browser tab once you see the message window at right, and then go back to your Azure Cloud Shell execution window.

	![Close the browser tab.](media/cloud-shell-13.png)

	> **Notes:**
	> - While you are waiting for processes to get completed in the Azure Cloud Shell window, you'll be asked to enter the code three times. This is necessary for performing installation of various Azure Services and preloading content in the Azure Synapse Analytics SQL Pool tables.
	> - You may be prompted to choose a subscription after the above-mentioned step if you have multiple subscriptions associated with your account. Choose the **subscription** that you used to sign in to the Azure portal. 

19. You will now be prompted to **enter** the resource group name in the Azure Cloud Shell. Type the same resource group name that you created in [Task 1](#task-1-create-a-resource-group-in-azure). – 'DDiB-FSI-Lab'.

	![Enter Resource Group name.](media/cloud-shell-14.png)

20. You will get another code to authenticate an Azure PowerShell script for creating reports in Power BI. **Copy** the code.
	> **Note:**
	> Note: You may see errors in script execution if you  do not have necessary permissions for cloudshell to manipulate your Power BI workspace. In such case follow this document (https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/fsi/fsidemo/Power%20BI%20Embedding.md) to get the necessary permissions assigned. You’ll have to manually upload the reports to your Power BI workspace by downloading them from this location [https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/tree/fsi/fsidemo/artifacts/reports]. 

21. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

      ![Click the link.](media/cloud-shell-16.png)
      
22. A new browser window will launch. **Paste** the code that you copied from the shell in step 21.

	![Paste the code.](media/cloud-shell-17.png)

	> Note: Make sure to provide the device code before it expires and let the script run till completion.

23. **Select** the same user to authenticate which you used for signing into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure). 

	![Select the same user.](media/cloud-shell-18.png)

24. **Close** the browser tab once you see the message window at right and go back to your Azure Cloud Shell execution window.

	![Close the browser.](media/cloud-shell-19.png)

	> **Note:** The deployment will take approximately 40-45 minutes to complete. Keep checking the progress with messages printed in the console to avoid timeout.
      
### Task 5: Power BI reports and dashboard creation 

1. **Open** Power BI in a new tab using the following link
        [https://app.powerbi.com/](https://app.powerbi.com/).

2. **Sign into** Power BI. Use the same Azure account you have used throughout this setup process.

	![Sign in to Power BI Services.](media/power-bi-report.png)

3. **Select** the Workspace, which is created in [Task2](#task-2-create-power-bi-workspace).

	![Select the Workspace 'Engagement Accelerators – Manufacturing'.](media/power-bi-report-2.png)

Once [Task 4](#task-4-run-the-cloud-shell-to-provision-the-demo-resources) has been completed successfully and the template has been deployed, you will be able to see a set of reports in the Reports tab of Power BI, and real-time datasets in the Dataset tab. 

The image on the right shows the Reports tab in Power BI.  We can create a Power BI dashboard by pinning visuals from these reports. 

![Screenshot to view the reports tab.](media/power-bi-report-3.png)

To give permissions for the Power BI reports to access the data sources:

4. **Click** the ellipses or settings icon on top right-side corner.

5. **Click** the settings button.

6. **Click** on settings.

	![Authenticate Power BI Reports.](media/power-bi-report-4.png)

7. **Click** 'Datasets' tab.

	![Go to Datasets.](media/power-bi-report-5.png)

8. **Click** on the first Dataset.
9. **Expand** Data source credentials.
10. **Click** Edit credentials and a dialogue box will pop up.

	![Select Campaign.](media/power-bi-report-6.png)

11. **Enter** Username as ‘labsqladmin’.

12. **Enter** the same SQL Administrator login password that was created for [Task 3](#task-3-deploy-the-arm-template) Step #5

13. **Click** Sign in.

	![Configure Campaign.](media/power-bi-report-7.png)

Follow these steps to create the Power BI dashboard:

14. **Select** the workspace in [Task2](#task-2-create-power-bi-workspace).

	![Select the workspace.](media/power-bi-report-2.png)

15. **Click** on ‘+ New’ button on the top-left navigation bar.

16. **Click** the ‘Dashboard’ option from the drop-down menu.

	![Click the dashboard.](media/power-bi-dashboard-2.png)

17. **Name** the dashboard ‘Fsi Dashboard-Before’ and **click** “create”. 

18. This new dashboard will appear in the Dashboard section (of the Power BI workspace). 

	![Name and Click Create.](media/power-bi-dashboard-3.png)

Follow the below steps to change the dashboard theme:

19. **Open** the URL in a new browser tab to get JSON code for a custom theme:
https://raw.githubusercontent.com/microsoft/Azure-Analytics-and-AI-Engagement/fsi/fsidemo/CustomTheme.json

20. **Right click** anywhere in browser and **click** 'Save as...'.

21. **Save** the file to your desired location on your computer, leaving the name unchanged.

	![Save the File.](media/power-bi-dashboard-4.png)

22. **Go back** to the Power BI dashboard you just created.

23. **Click** on the “Edit” at the top right-side corner.

24. **Click** on “Dashboard theme”.

	![Click on Dashboard Theme.](media/power-bi-dashboard-5.png)

25. **Click** ‘Upload the JSON theme’.

26. **Navigate** to the location where you saved the JSON theme file in the steps above and **select** open.

27. **Click** Save.

	![Navigate Select and Click Save.](media/power-bi-dashboard-6.png)

Do the following to pin visuals to the dashboard you just created:
**Pillar 3: Market Perception**

28. **Select** the workspace [Task2](#task-2-create-power-bi-workspace).

	![Select the workspace.](media/power-bi-report-2.png)

29. **Click** on the “Content” section/tab.

	![Create Dashboard further steps.](media/power-bi-dashboard-7.png)

30. In the “Content” section, there will be a list of all the published reports.

31. **Click** on ‘FSI CCO Dashboard’ report.

	![Click on Video and Revenue Analytics.](media/power-bi-dashboard-8.png)

32. **Click** on ‘Market perception before’ page.

33. **Click** on pin visual button.

	![Click on Pin Visual button.](media/power-bi-dashboard-9.png)

34. **Select** ‘Existing dashboard’ radio button. 

35. From ‘select existing dashboard’ dropdown, **select** ‘Media Demo Dashboard-Before’.

36. **Click** ‘Pin’.

	![Click Pin.](media/power-bi-dashboard-10.png)

37. Similarly, **pin** the others tiles to the Dashboard.

	![Pin the others tiles.](media/power-bi-dashboard-11.png)

38. **Select** workpace created in task 2 in the left pane.

	![Select workspace.](media/power-bi-report-2.png)

39. **Open** 'FSI-Chicklets' report.

	![Open report.](media/power-bi-dashboard-12.png)

40. To pin an image into Dashboard you have to go to the report, **click** on edit and then you will see the pin icon.

	![Pin an image.](media/report-1.png)

41. **Select** the ‘Chief Customer Officer Before’ from existing dashboard list and **click** on pin.

42. Similarly pin rest of the images from chief customer officer tab of the Chicklets report.

	![Pin all image.](media/report-2.png)

43. **Go back** to the ‘Chief Customer Officer Before’ dashboard.
	
	![Go back.](media/report-3.png)

To hide title and subtitle for all the images that you have pined above. Please do the following:

44. **Click** on ellipsis ‘More Options’ of the image you selected.

45. **Click** ‘Edit details’.
	
	![Edit Details.](media/report-4.png)

46. **Uncheck** ‘Display title and subtitle’.

47. **Click** ‘Apply’.

48. **Repeat** Step 46 to 48 for all image tiles.

	![Repeat Steps.](media/report-5.png)

49. After disabling ‘Display title and subtitle’ for all images, **resize** and **rearrange** the top images tiles as shown in the screenshot. Resize the Contoso Healthcare logo to 1x1 size; resize other vertical tiles to 2x1 size.  

	![Resize and Rearrange.](media/report-6.png)

50. Similarly pin left image tiles from ‘page 1’ of chicklets report to the Chief Customer officer Before dashboard.

51. **Resize** and **rearrange** the left images tiles as shown in the screenshot. Resize the KPI tile to 1x2. Resize the Deep Dive to 1x4.

	![Pin and Repeat.](media/report-7.png)

	![Note.](media/report-8.png)

	> **Note:** The cards in each Dashboard should be created in the Dashboard like ‘Negative Card’ as you can see in orange.

52. To create a new tile like the car above **click** on edit button on dashboard.

53. **Click** on add a tile button.

	![Create a new tile.](media/report-9.png)
	
54. Then **go to** Text Box and there you can **add** the text and the text format it.
	
	![Add text.](media/report-10.png)

55. **Refer** to the screenshot of the sample dashboard and pin the visuals to replicate its look and feel. 

56. **Latest** pillar ‘Chief Customer Officer Before’ is completed.

	![Pin the visuals.](media/report-11.png)

57. You will see some KPIs or charts like this KPI with title and subtitle. 1. Title, 2. Subtitle.

	![KPIs.](media/report-12.png)

58. **Go** to the cards more options.

59. **Click** on Edit Details.

	![Cards more options.](media/report-13.png)

60. You will see something like this picture where you can add subtitle.
	
	![Add subtitle.](media/report-14.png)

61. The Dashboard “Chief Customer Officer Before” should finally look like this.
Table in following row indicates which Kpi’s need to be pinned from which report to achieve this final look.
	
![Final look.](media/report-15.png)
	
62. **Refer** to this table while pinning rest of the tiles to the dashboard.
	
	![Refer the table.](media/report-16.png)

63. Here is the list of Dashboards you have to create for FSI. You will see the necessary details for the same below.

	![List of Dashboards.](media/report-17.png)

64. Chief Customer Officer After Dashboard should look like this. Following are the details of tiles for the same.

	![Chief Customer Officer.](media/report-18.png)

65. Chief Customer Officer After KPIs.

	![Chief Customer Officer After KPIs.](media/report-19.png)

66. ESG Dashboard Dashboard should look like this. Following are the details of tiles for the same.

	![ESG Dashboard Dashboard.](media/report-20.png)

67. ESG Dashboard KPIs

	![ESG Dashboard KPIs.](media/report-21.png)

68. Finance Dashboard should look like this. Following are the details of tiles for the same.

	![Finance Dashboard.](media/report-22.png)

69. Finance Dashboard KPIs

	![Finance Dashboard KPIs.](media/report-23.png)

70. Group Chief Risk Officer After Dashboard

	![Group Chief Risk Officer.](media/report-24.png)

71. Group Chief Risk Officer After Dashboard KPIs

	![Group Chief Risk Officer After Dashboard KPIs.](media/report-25.png)

72. Group Chief Risk Officer Before Dashboard

	![Group Chief Risk Officer.](media/report-26.png)

73. Group Chief Risk Officer Before KPIs

	![Group Chief Risk Officer Before KPIs.](media/report-27.png)

74. Head of Financial Intelligence After Dashboard

	![Head of Financial Intelligence.](media/report-28.png)

75. Head of Financial Intelligence After KPI

	![Head of Financial Intelligence After KPI.](media/report-29.png)

76. Head of Financial Intelligence Before Dashboard

	![Head of Financial Intelligence.](media/report-30.png)

77. Head of Financial Intelligence Before KPIs

	![Head of Financial Intelligence Before KPIs.](media/report-31.png)

78. Woodgrove Executive Dashboard Dec

	![Woodgrove Executive Dashboard Dec.](media/report-32.png)

79. Woodgrove Executive Dashboard Dec KPIs

	![Woodgrove Executive Dashboard Dec KPIs.](media/report-33.png)

80. Woodgrove Executive Dashboard June

	![Woodgrove Executive Dashboard June.](media/report-34.png)

81. Woodgrove Executive Dashboard June KPIs

	![Woodgrove Executive Dashboard June KPIs.](media/report-35.png)

82. Woodgrove Executive Dashboard March KPIs

	![Woodgrove Executive Dashboard March KPIs.](media/report-36.png)

83. Woodgrove Executive Dashboard September

	![Woodgrove Executive Dashboard September.](media/report-37.png)

84. Woodgrove Executive Dashboard September KPIs

	![Woodgrove Executive Dashboard September KPIs.](media/report-38.png)

85. Woodgrove Executive Dashboard September 2

	![Woodgrove Executive Dashboard September 2.](media/report-39.png)

86. Dashboard KPI’s.

	![Dashboard KPI’s.](media/report-40.png)

**Steps to create Real time report (Optional)**
This task is optional since we have provided static versions of the reports in the package already.

1. **Open** Power BI in a new tab using the following link:
	[https://app.powerbi.com/](https://app.powerbi.com/).

2. **Sign into** Power BI using your Power BI Pro account.

	![Sign_in_powerbi.](media/realtime-report.png)

> **Note:** Use the same credentials for Power BI which you will be using for the Azure account.

3. After signing in, **click** the workspaces button from the hamburger menu and **select** the “DDiB-FSI” workspace.

	![Click Workspace.](media/realtime-report-2.png)

4. **Click** New to expand menu and then **click** Report.

	![Click New and Report.](media/realtime-report-3.png)

5. **Click** Pick a published dataset.
	
	![Click Pick a Public Dashboard.](media/realtime-report-4.png)

6. **Click** on the desired streaming dataset from the given list, here we are selecting “FSI CCO Realtime Before” and **click** Create.

	![Click desired streaming dataset.](media/realtime-report-5.png)

7. **Select** the KPI visual or any other required visual from Visualization pane.

8. **Drag** or **select** the required fields from Fields pane to Visualization pane’s Field tab.

	![Select the KPI, Drag or select required fields.](media/realtime-report-6.png)

9. Similarly, **create** other visuals and **save** the Power BI Report. You can also pin the visuals to the dashboard as mentioned in step 33

	![Create other visuals and save the Power BI Report.](media/realtime-report-7.png)

10. Similarly you can create real time reports for rest of the streaming datasets if needed.

	![Create real time reports for rest.](media/realtime-report-8.png)

**Updating Dashboard and Report Id’s in Web app:**
By default, the web app will be provisioned with Gif placeholders for web app screens with dashboards. Once you have completed the steps listed above in this section, you can update the dashboard id’s generated in to the main web app if you choose. Here are the steps for it.

1. **Navigate** to your Power BI workspace.

2. **Click** on one of the dashboards you created. Eg. Woodgrove Executive dashboard June.

	![Navigate and Click.](media/updating-powerbi.png)

3. **Copy** the dashboard id from the url bar at the top.
	
	![Copy the dashboard id.](media/updating-powerbi-2.png)

4. **Navigate** to azure portal.

5. **Open** the Azure Cloud Shell by selecting its icon from the top toolbar.

	![Navigate and Open.](media/updating-powerbi-3.png)

6. **Click** on upload/download button.

7. **Click** download.

8. **Enter** the following path:  
	
	```
	fsi/fsidemo/app_fsidemo/wwwroot/config.js
	```

9. **Click** Download button.

	![Enter path and Click download button.](media/updating-powerbi-4.png)

10. **Edit** the downloaded file in notepad.

11. **Paste** the dashboard id you copied earlier between the double quotes of key ‘ceo_dashboard_march’.

12. **Save** the changes to the file.

	![Edit paste and save.](media/updating-powerbi-5.png)

13. **Navigate** to azure portal.

14. **Open** the Azure Cloud Shell by selecting its icon from the top toolbar.

	![Navigate and Open.](media/updating-powerbi-6.png)

15. **Click** upload/download button.

16. **Click** upload.

17. **Select** the config.js file you just updated.

18. **Click** open.

	![Select and Click open.](media/updating-powerbi-7.png)

19. **Execute** following command in cloudshell:  
	
	```
	cp config.js ./fsi/fsidemo/app_fsidemo/wwwroot
	```
	
	![Execute the command.](media/updating-powerbi-8.png)

20.	Execute  following command in cloudshell: 
	
	```
	cd fsi/fsidemo/subscripts 
	./updateWebAppSubScript.ps1
	```
	
	![Execute the command.](media/updating-powerbi-9.png)

21. From the Azure Cloud Shell, **copy** the authentication code. 

22. **Click** on the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

	![Copy and Click on Link.](media/updating-powerbi-10.png)

23. **Paste** the authentication code.

24. **Select** appropriate username when prompted.

25. Wait for script execution to complete.

	![Paste select and wait.](media/updating-powerbi-11.png)

> **Note:** You may be prompted to select your subscription if you have multiple subscriptions.

### Task 6: AML notebook execution

1. **Open** the azure portal and go to resource group **‘DDib-FSI’.**

	![Open resource.](media/open-rg.png)

2. **Type** in filter “amlws-” and open the resource.

	![Open resource.](media/aml-1.png)

3. **Click** “Launch studio”

	![Launch studio.](media/aml-2.png)

4. **Login** with the same user that you used for signing into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

5. **Open** Compute section and enter compute name, **select** “ STANDARD_DS2_V2” as compute quota and **click** on create.

	![Compute section and enter compute name.](media/aml-3.png)

> **Note:**  It will take few minutes to create a compute instance.

6. **Open** Notebooks.

7. **Click** on “ 8. Understanding and Removing Biases from Machine Learning Models using Azure Fairlearn” notebook.

	![Open Notebooks.](media/aml-4.png)

8. **Select** Compute created in step 5 and kernel as shown in image.

9. **Click** run all.
	
	![Select Compute created.](media/aml-5.png)

10. **Scroll** through the notebook cells, at cell 16 execution it will ask to do device login. Follow the steps with same user.

	![Scroll through the notebook.](media/aml-6.png)


11. **Scroll** down till the end and wait for the green tick.

12. **Open** Experiments and see if experiments are created.

	![Scroll and Open.](media/aml-7.png)

### Task 7: Pause/Resume resources

> **Note:** Please perform these steps after your demo is done and you do not need the environment anymore. Also ensure you Resume the environment before demo if you paused it once. 
 
1. **Open** the Azure Portal 

2. **Click** on the Azure Cloud Shell icon from the top toolbar. 

	![Open and Click on Azure Cloud Shell.](media/fsi-poc-26.png)

**Execute** the Pause_Resume_script.ps1 script by executing the following command: 
1. **Run** Command: 
	```
	cd "fsi\fsidemo"
	```

2. Then **run** the PowerShell script: 
	```
	./pause_resume_script.ps1 
	```
	
	![Run the Powershell Script.](media/powershell.png)
	
3. From the Azure Cloud Shell, **copy** the authentication code
	
	![Copy the Authentication Code.](media/powershell-2.png)
	
4. Click on the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.
	
5. **Paste** the authentication code.
	
	![Paste the authentication code.](media/authentication.png)
	
6. **Select** the same user that you used for signing into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure). 

7. **Close** this window after it displays successful authentication message.

	![Select the same user and Close.](media/authentication-2.png)

8. When prompted, **enter** the resource group name to be paused/resumed in the Azure Cloud Shell. Type the same resource group name that you created. 
	
	![Enter the Resource Group Name.](media/authentication-3.png)

9. **Enter** your choice when prompted. Enter ‘P’ for **pausing** the environment or ‘R’ for **resuming** a paused environment. 

10. Wait for script to finish execution. 

	![Enter your choice.](media/authentication-4.png)

### Task 8 : Clean up resources.

> **Note: Perform these steps after your demo is done and you do not need the resources anymore**

**Open** the Azure Portal.

1. Open the Azure Cloud Shell by **clicking** its icon from the top toolbar.

	![Open the Azure Portal.](media/authentication-5.png)

**Execute** the resourceCleanup.ps1 script by executing the following:

2. **Run** Command: 
	```
	cd "fsi\fsidemo"
	```

3. Then **run** the PowerShell script: 
	```
	./resource_cleanup.ps1
	```

	![Run the Powershell Script.](media/authentication-6.png)

4. You will now be prompted to **enter** the resource group name to be deleted in the Azure Cloud Shell. Type the same resource group name that you created in [Task 1](#task-1-create-a-resource-group-in-azure) - 'DDib-FSI'.

5. You may be prompted to select a subscription in case your account has multiple subscriptions.

	![Enter the Resource Group Name.](media/authentication-7.png)
	
Your Accelerator environment is now set up.
