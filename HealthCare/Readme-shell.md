# Azure Synapse HealthCare Setup Guide


**Contents**

<!-- TOC -->

- [Azure Synapse Analytics HealthCare setup guide](#azure-synapse-analytics-wwi-setup-guide)
  - [Requirements](#requirements)
  - [Before Starting](#before-starting)
    - [Task 1: Create a resource group in Azure](#task-1-create-a-resource-group-in-azure)
    - [Task 2: Create Power BI workspace](#task-2-create-power-bi-workspace)
    - [Task 3: Deploy the ARM Template](#task-3-deploy-the-arm-template)
    - [Task 4: Provision IoT central devices](#task-4-provision-iot-central-devices)
    - [Task 5: Run the Cloud Shell](#task-5-run-the-cloud-shell)
    - [Task 6: Starting high speed data generators and function apps](#task-6-starting-high-speed-data-generators-and-function-apps)
    - [Task 7: Create Power BI reports and Dashboard](#task-7-create-power-bi-reports-and-dashboard)
    - [Task 8: Creating Synapse Views](#task-8-creating-synapse-views)
    - [Task 9: Publishing the Custom Vision model](#task-9-publishing-the-custom-vision-model)
    - [Task 10: Pause-Resume resources](#task-10-pause-resume-resources)
    - [Task 11: Clean up resources](#task-11-clean-up-resources)
    
<!-- /TOC -->

## Requirements

* An Azure Account with the ability to create an Azure Synapse Workspace.
* A Power BI Pro or Premium account to host Power BI reports.
* Make sure the following resource providers are registered with your Azure Subscription.
   
   - Microsoft.Sql 
   - Microsoft.Synapse 
   - Microsoft.StreamAnalytics 
   - Microsoft.EventHub 
* Please note that you can run only one deployment at a given point of time and need to wait for the completion. You should not run multiple deployments in parallel as that will cause deployment failures.
* Please ensure selection of correct region where desired Azure Services are available. In case certain services are not available, deployment may fail. [Azure Services Global Availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=all) for understanding target services availablity.
* Do not use any special characters or uppercase letters in the environment code.
* Please ensure that you select the correct resource group name. We have given a sample name which  may need to be changed should any resource group with the same name already exist in your subscription.

> **Note:** Please log in to Azure and Power BI using the same credentials.

## Before starting

### Task 1: Create a resource group in Azure

1. **Log into** the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, **select** the '+ Create a resource' tile.

    ![A portion of the Azure Portal home screen is displayed with the + Create a resource tile highlighted.](media/create-a-resource.png)

3. In the **Search the Marketplace** text box, type 'Resource Group' and **press** the Enter key.

    ![On the new resource screen Resource group is entered as a search term.](media/bhol_searchmarketplaceresourcegroup.png)

4. **Select** the 'create' button on the 'Resource Group' overview page.

	![A portion of the Azure Portal home screen is displayed with Create Resource Group tile](media/create-resource-group.png)
	
5. On the 'Create a resource group' screen, **select** your desired Subscription. For Resource group, **type** 'Synapse-WWI-Lab'. 

6. **Select** your desired Region. 

7. **Click** the 'Review + Create' button.

    ![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](media/resourcegroup-form.png)

8. **Click** the 'Create' button once all entries have been validated.

    ![Create Resource Group with the final validation passed.](media/create-rg-validated.png)

### Task 2: Create Power BI workspace

1. **Open** Power BI Services in a new tab using the following link:  https://app.powerbi.com/

2. **Sign in**, to your Power BI account using Power BI Pro account.

> **Note:** Please use the same credentials for Power BI which you will be using for Azure Account.

   ![Sign in to Power BI.](media/PowerBI-Services-SignIn.png)

3. In Power BI service **click** on 'Workspaces'.

4. Then **click** on the 'Create a workspace' tab.

   ![Create Power BI Workspace.](media/Create-Workspace.png)

5. **Enter** the 'Workspace name' and 'Description' and **click** 'Save'.

   ![Give the name and description for the new workspace.](media/name-the-workspace.png)

> **Note:** Please create a Workspace by the name 'Engagement Accelerators – HealthCare'.

6. **Copy** the Workspace GUID or ID. You can get this by browsing to https://app.powerbi.com/, selecting the workspace, and then copying the GUID from the address URL and paste it in a notepad for future reference.
> **Note:** This workspace ID will be used during ARM template deployment.

   ![Copy the workspace id.](media/Workspace-ID.png)

7.  Go to your Power BI workspace and **click** on create button. 
8.	Then **click** on Streaming Dataset option from the dropdown. 

   ![Create Streaming Dataset.](media/create-dataset.png)

9.	**Select** API from the list of options and click next. 
	
   ![Select API.](media/select-api.png)

10.	**Enter** ‘healthcare-operation-analytics’ as dataset name and **enter** the column names in “values from stream” option from list below: 

| Field Name                        | Type     |
|-----------------------------------|----------|	
| recordedOn                        | Datetime |
| staffToPatientRatio               | number   |
| currentERWaitingTime              | number   |
| currentICUBedOccupancyRate        | number   |
| currentBedOccupancyRate           | number   |
| ratingNeutralPercentage           | number   |
| ratingNegativePercentage          | number   |
| averageERWaitingTime              | number   |
| staffToPatientRatioTarget         | number   |
| bedOccupanyRateMin                | number   |
| bedOccupanyRateMax                | number   |
| bedOccupanyRateTarget             | number   |
| scheduledAppointments             | number   |
| averageLOS                        | number   |
| targetLOS                         | text     |
| otUtilizationPercentage           | number   |
| otTargetPercentage                | number   |
| inPersonAppointment               | number   |
| virtualAppointment                | number   |
| missedAppointment                 | number   |
| roomTurnOver                      | number   |
| medicalEquipmentUtilization       | number   |
| inpatientSurgery                  | number   |
| outpatientSurgery                 | number   |
| onlinePrescription                | number   |
| inPersonPrescription              | number   |
| appointmentStats                  | text     |
| waittimeStats                     | text     |
| surgeriesStats                    | text     |
| prescriptionStats                 | text     |
| roomTurnOverTarget                | number   |
| medicalEquipmentUtilizationTarget | number   |
| currentICUBedOccupancyRate        | number   |
| currentRegularBedOccupancyRate    | number   |
| currentbedOccupancyRateStats      | text     |
| activeSensors                     | number   |

![Values for stream.](media/value-for-stream.png)

11.	Copy the push url of dataset and place it in a notepad for later use.
     ![Push Url.](media/push-url.png)


### Task 3: Deploy the ARM Template

1. **Right-click** on the 'Deploy to Azure' button given below and open the link in a new tab to **deploy** the Azure resources that you created in [Task 1](#task-1-create-a-resource-group-in-azure) with an Azure ARM Template.

     <a href='https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmicrosoft%2FAzure-Analytics-and-AI-Engagement%2Fmain%2FHealthCare%2FmainTemplate.json' target='_blank'><img src='http://azuredeploy.net/deploybutton.png' /></a>

2. On the Custom deployment form, **select** your desired Subscription.
3. **Type** the resource group name 'Synapse-WWI-Lab' created in [Task 1](#task-1-create-a-resource-group-in-azure).
4. **Select** Region where you want to deploy.
> **Note:** Ensure the resource availability for synapse, cognitive services and aml in the region you select.
5. **Provide** environment code which is a unique suffix to your environment without any special characters. e.g. 'demo'.
> **Note:** Please enter the values in compliance with tooltip instructions
6. **Provide** a strong SQL Administrator Login Password and set this aside for later use.
7. **Enter** the Power BI Workspace ID, created in [Task 2](#task-2-power-bi-workspace-creation), in the 'Pbi_workspace_id' field.
8. **Enter** the power BI streaming dataset url you copied in step 11 of task 2.
9. **Enter** the password for virtual machine. Please enter password based on tooltip recommendation. 
9. **Click** 'Review + Create' button.

   ![The Custom deployment form is displayed with example data populated.](media/Custom-Template-Deployment-Screen1.png)

10. **Click** the 'Create' button once the template has been validated.

   ![Creating the template after validation.](media/template-validated-create.png)

> **NOTE:** The provisioning of your deployment resources will take approximately 20 minutes.

11. **Stay** on the same page and wait for the deployment to complete.
    
    ![A portion of the Azure Portal to confirm that the deployment is in progress.](media/template-deployment-progress.png)
    
12. **Click** 'Go to resource group' button once your deployment is complete.

    ![A portion of the Azure Portal to confirm that the deployment is in progress.](media/Template-Deployment-Done-Screen6.png)

### Task 4: Provision IoT central devices

1. **Search** for iot in resource list.
2. **Click** on iot central in the resource list.

    ![Resource list iot.](media/resource-list-iot.png)
	
3. **Click** on application url on overview screen.

    ![Application URL.](media/application-url.png)
	
4. **Click** on devices.
5. **Click** IoMT device.
6. **Click** New.

    ![Create iomt.](media/create-iomt.png)
	
7. **Click** create.

> **Note:** You may choose to change the device name displayed for your scenario.

   ![Create device.](media/create-device.png)
	
8. **Click** on created device.

    ![Created device.](media/created-device.png)

9. **Click** on Connect.

    ![connect device.](media/connect-device.png)
	
10. **Copy** the values of ID scope, Device ID and primary key in a notepad.We will need these values during script execution.

    ![copy device.](media/copy-device.png)
	
11.	**Close** the device popup and click on data export(legacy) tab.
12.	**Click** New.
13.	**Click** Azure Event Hubs.

    ![data export.](media/data-export.png)
	
14.	**Select** Event hub namespace named ‘evh-namespace…’ from the dropdown.
15.	**Select** Event hub name from the dropdown.
16.	**Turn off** Devices and Device template features.
17.	**Click** Save.

    ![data export2.](media/data-export2.png)
	
18.	**Click** Dashboard.
19.	**Click** Edit.

    ![device dashboard.](media/device-dashboard.png)

20.	**Click** on configure button of Blood Pressure chart.
21.	**Select** Device group from the dropdown.
22.	**Select** Device Name from the dropdown.
23.	**Click** “+ Capability” button.
24.	**Select** systolicPressure kpi.
25.	**Click** “+ Capability” button again.
26.	**Select** distolicPressure kpi.
27.	**Click** update.

     ![device dashboard2.](media/device-dashboard2.png)

28.	**Click** save.
29.	Repeat above steps for remaining dashboard tiles and their respective kpi’s.

     ![device dashboard3.](media/device-dashboard3.png)


### Task 5: Run the Cloud Shell 

**Open** the Azure Portal.

1. In the 'Resource group' section, **open** the 'Azure Cloud Shell' by selecting its icon from the top toolbar.

    ![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/azure-cloudshell-menu-screen4.png)

2. **Click** on 'Show advanced settings'. 

    ![Mount a storage for running the cloud shell.](media/no-storage-mounted.png)
	
> **Note:** If you already have a storage mounted for Cloud Shell, you will not get this prompt. In that case, skip step 2 and 3.

3. **Select** your 'Resource Group' and **enter** the 'Storage account' and 'File share' name.

    ![Mount a storage for running the cloud shell and enter the details.](media/no-storage-mounted1.png)

> **Note:** If you are creating a new storage account, give it a unique name with no special characters or uppercase letters and it should not be more 10 characters.

4. In the Azure Cloud Shell window, **enter** the following command to clone the repository files.

    ```PowerShell
    git clone https://Username@dev.azure.com/daidemos/HealthCare/_git/HealthCare HealthCare
    ```
    > Here username will be your github username. You will be prompted for the password of the same username.
    ![Git clone command to pull down the demo repository](media/Git-Clone-Command-Screen11.png)
    
    > **Note:** If you get File “Healthcare” already exist error, please execute following command: rm Healthcare -r -f to delete existing clone.
    
    > **Note**: When executing the script below, it is important to let the scripts run to completion. Some tasks may take longer than others to run. When a script completes     execution, you will be returned to PowerShell prompt. The total runtime of all steps in this task will take approximately 1 hour.

5. Execute the `healthcareSetup.ps1` script by executing the following commands:

    ```PowerShell
    cd 'Healthcare/GitHubRepo/Healthcare'
    ```

6. Then **run** the PowerShell: 

    ```PowerShell
    ./healthcareSetup.ps1
    ```
    
     ![Commands to run the PowerShell script](media/executing-shell-script.png)
      
7. From the Azure Cloud Shell window, **copy** the Authentication Code.

8. Click on the link https://microsoft.com/devicelogin) and a new browser window will launch.

     ![Authentication link and device code](media/Device-Authentication-Screen7.png)
     
9. **Paste** the authentication code.

     ![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

10. **Select** the same user that you used for signing in to the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

     ![Select the user account which you want to authenticate.](media/pick-account-to-login.png)

11. **Close** the browser tab once you see the below message window and **go back** to your 'Azure Cloud Shell' execution window.

     ![Authentication done.](media/authentication-done.png)

12. **Navigate** back to the resource group tab.
13. You will get another code to authenticate Azure PowerShell script for creating reports in Power BI. **Copy** the code.

14. **Click** the link (https://microsoft.com/devicelogin).

     ![Authentication link and device code](media/Device-Authentication-Screen7a.png)

15. Follow the same steps as in [Task 4](#task-4-run-the-cloud-shell) steps 7 to 11.
 
     ![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

> **Note:** While you are waiting for processes to get completed in the Azure Cloud Shell window, you'll be asked to enter the code three times. This is necessary for performing installation of various Azure Services and preloading content in the Azure Synapse Analytics SQL Pool tables.

16. You will now be prompted to enter the resource group name in the Azure Cloud Shell window. Enter the name of the resource group that you created in [Task 1](#task-1-create-a-resource-group-in-azure) - 'Synapse-WWI-Lab'.

     ![Enter the resource group name](media/RG-Name-Screen10.png)

17. You will get another code to authenticate Power BI gateway. **Copy** the code.
18. **Click** the link (https://microsoft.com/devicelogin).

     ![Copy the authentication code.](media/task4-step18.png)

19. A new browser window will launch. **Follow** the same steps as in [Task 4](#task-4-run-the-cloud-shell) steps 9, 10 and 11.

**Open** the Azure Portal.

20. **Go** to the resource group you have created in [Task 1](#task-1-create-a-resource-group-in-azure).
21. **Search** the storage account name starts with 'sth'.
22. **Go** to the storage account by clicking on its link.

      ![Select Storage Account.](media/select-storage.png)
      
23. **Click** on 'Access Keys' from the left navigation pane for storage account.
24. **Copy** the 'key1' to the clipboard and **paste** the key in a notepad for future reference.

      ![Copy Storage Account Access Keys.](media/copy-access-keys.png)
            
### Task 6: Starting high speed data generators and function apps 
  
1.	**Search** for ‘data-gen’ in azure resource group.
2.	**Click** on the virtual machine.

	![Search for data-gen.](media/high-speed-data-gen1.png)
  
3.	**Copy** the public ip of the virtual machine.

	![Copy the public ip.](media/high-speed-data-gen2.png)
	
4.	**Open** Remote Desktop application on your machine. (use Wondows+r shortcut on windows machine)
5.	**Enter** the ip address in computer field.
6.	**Enter** the username as ‘data-generator’.
7.	**Click** on connect.
8.	You will be prompted to enter the password. Enter the password you chose during template deployment in task 2.
	
	![Remote Desktop.](media/high-speed-data-gen3.png)
	
9.	Once connected to the remote machine, open file explorer.
10.	**Navigate** to ‘C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.9\Downloads\0\highspeed-datagen’.
11.	**Right-click** on InvokeSenders file.
12.	**Click** on Run with PowerShell.
13.	**Close** the virtual machine window.

	![Run with PowerShell.](media/high-speed-data-gen4.png)
	
> **Note:** Ensure the data generation exe’s are running on this vm before you demo the high speed data ingestion part in synapse. If not, follow the task above to restart the generation.
	
14.	Navigate to azure portal.
15.	Search for ‘func-app-mongo’ in your rg.
16.	Click on the function app.

	![Run with PowerShell.](media/high-speed-data-gen5.png)
	
17.	Click on Functions.
18.	Click on JsonProcessor.

	![Run with PowerShell.](media/high-speed-data-gen6.png)

19.	Click ‘Get Function Url’.
20.	Copy the url and open it in new browser tab.

	![Run with PowerShell.](media/high-speed-data-gen7.png)

### Task 7: Create Power BI reports and Dashboard

1. **Open** Power BI Services in a new tab using following link https://app.powerbi.com/

2. **Sign into** Power BI. Use the same Azure account you have used throughout this setup process.

	![Sign in to Power BI Services.](media/PowerBI-Services-SignIn.png)

3. **Select** the Workspace, which is created in task2.

	![Select the Workspace 'Healthcare'.](media/select-workspace.png)

Once Task 4 has been completed successfully and the template has been deployed, you will be able to see a set of reports in the Reports tab of Power BI, and real-time datasets in the Dataset tab. 
The image on the right shows the Reports tab in Power BI.  We can create a Power BI dashboard by pinning visuals from these reports. 
	
   ![Screenshot to view the reports tab.](media/Reports-Tab.png)

To give permissions for the Power BI reports to access the datasources:

4. **Click** the ellipses on top right-side corner.

5. **Click** the 'Settings' icon.

6. **Click** 'Settings' from the expanded list.

	![Authenticate Power BI Reports.](media/Authenticate-PowerBI.png)

7. **Click** 'Datasets' tab.

	![Go to Datasets.](media/Goto-DataSets.png)

8.	**Click** on the first Report.
9.	**Expand** Data source credentials.
10.	**Click** Edit credentials and a dialogue box will pop up.

	![Data source credentials.](media/healthcare-report1.png)

11.	**Enter** Username as ‘labsqladmin’.
12.	**Enter** the same SQL Administrator login password that was created for Task 3 Step #6
13.	**Click** Sign in.

	![Configure Data source credentials.](media/healthcare-report2.png)

14.	**Click** on ‘3 Healthcare Dynamic Data Masking’ Report.
15.	**Expand** Data source credentials.
16.	**Click** Edit credentials and a dialogue box will pop up.

	![Edit data set credentials.](media/edit-credentials.png)

17.	**Enter** the username as labsqladmin.
18.	**Enter** the SQL pool password.
19.	**Click** sign in.

	![Edit SQL credentials.](media/edit-credentials1.png)

20.	**Click** on healthcare term index.
21.	**Click** on datasource credentials.
22.	**Click** edit credentials.

	![Edit data set credentials.](media/edit-credentials2.png)

23.	**Enter** the account key copied in task 5 step 24.
24.	**Click** sign in. 

	![Select authentication method.](media/select-key.png)

25.	**Select** the same user to authenticate which you used for signing into the Azure Portal in task1.

**Follow** these steps to create the Power BI dashboard:

26.	Select the workspace in task2.

	![Select the Workspace 'Healthcare'.](media/select-workspace.png)

27.	**Click** on ‘+ New’ button on the top-right navigation bar.
28.	**Click** the ‘Dashboard’ option from the drop-down menu.

	![create dashboard.](media/Create-Dashboard.png)

29.	**Name** the dashboard ‘Healthcare and click “create”.
30.	This new dashboard will appear in the Dashboard section (of the Power BI workspace). 

	![create dashboard](media/Create-Dashboard1.png)

Follow the below steps to change the dashboard theme:

31.	**Open** the URL in a new browser tab to get JSON code for a custom theme:
https://raw.githubusercontent.com/microsoft/Azure-Analytics-and-AI-Engagement/real-time/Manufacturing/automation/artifacts/theme/CustomTheme.json

32.	**Right click** anywhere in browser and **click** 'Save as...'.
33.	**Save** the file to your desired location on your computer, leaving the name unchanged.

	![Dashboard theme.](media/custom-theme.png)

34.	**Go back** to the Power BI dashboard you just created.
35.	**Click** on the “Edit” at the top right-side corner.
36.	**Click** on “Dashboard theme”.

	![Dashboard theme.](media/dashboard-theme-save.png)

37.	**Click** ‘Upload the JSON theme’.
38.	**Navigate** to the location where you saved the JSON theme file in the steps above and select open.
39.	**Click** Save.

	![Change portal theme.](media/change-theme-portal.png)

Do the following to pin visuals to the dashboard you just created:

**Pillar 1: Healthcare Financial Analytics**

40.	**Select** the workspace task2.

	![Select workspace.](media/select-workspace.png)

**Do the following to pin visuals to the dashboard you just created:**

41. **Select** on the “Content” section/tab.

	![Select Content section.](media/content-section.png)

42.	In the “Content” section, there will be a list of all the published reports.
43.	**Click** on ‘Consolidated Report’. 

	![Select Consolidated Report.](media/consolidated-report.png)

44.	On the Consolidated report page, **click** the ‘Response by campaign tactic and status’ visual and **click** the pin icon.

	![Consolidated report page.](media/consolidated-report1.png)

45.	**Select** ‘Existing dashboard’ radio button. 
46.	From ‘select existing dashboard’ dropdown, **select** ‘Healthcare’.
47.	**Click** ‘Pin’.
	
	![Further steps to pin visualization on the dashboard.](media/Pin-To-Dashboard.png)	
	
48.	Similarly, **pin** ‘Total Campaigns’ and ‘Margins’, ‘Response by campaign tactic and status’ from the report.

	![Pin visuals to the dashboard.](media/Pin-To-Dashboard1.png)

49.	Select the ‘**Financial Report**’ page
50.	Similarly, **pin** ‘Revenue(YTD)’ and ‘ Outpatients/Inpatients(YTD)’ from the report
	
	![Financial Report Page.](media/financial-report-page.png)

51.	**Select** the Workspace in task2.

	![select workspace.](media/select-workspace.png)

52.	**Open** ‘Healthcare Dashboard Images - Final’ report.
53.	**Pin** all the images from report to the ‘Healthcare’.

**Note:** Please refer to steps 44-47 of Task 7 for the complete procedure of pinning a desired visual to a dashboard.

54.	Go back to the ‘Healthcare’ dashboard.

	![Select dashboard.](media/go-back-to-dashboard.png)

To hide title and subtitle for all the images that you have pined above. Please do the following:

55.	**Click** on ellipsis ‘More Options’ of the image you selected.
56.	**Click** ‘Edit details’.

	![Edit details.](media/edit-details.png)
	
57.	**Uncheck** ‘Display title and subtitle’.
58.	**Click** ‘Apply’.
59.	**Repeat** Step 46 to 48 for all image tiles.

	![Display title and subtitle.](media/display-title-subtitle.png)

60.	After disabling ‘Display title and subtitle’ for all images, resize and rearrange the top images tiles as shown in the screenshot. Resize the Contoso Healthcare logo to 1x1 size; resize other vertical tiles to 2x1 size.
	
	![All images.](media/all-images.png)

61.	Resize and rearrange the left images tiles as shown in the screenshot. Resize the KPI tile to 1x2. Resize the Deep Dive to 1x4.

	![Resize and rearrange.](media/resize-rearrange.png)
	
62.	**Refer** to the screenshot of the sample dashboard and pin the visuals to replicate its look and feel. 
63.	**First** pillar ‘Healthcare Financial Analytics’ is completed.

	![Resize and rearrange.](media/healthcare-financial-analytics.png)	

**Pillar 2: Realtime Operational Analytics**

64.	**Let’s** start Pinning the second pillar ‘Realtime Operational Analytics’
65.	**Select** the Workspace in task2

	![select workspace.](media/select-workspace.png)	

66.	**Open** ‘healthcare-operational-analytics’ report.

	![Realtime Operational Analytics.](media/realtime-operational-analytics-report.png)

67.	Similarly, **pin** ‘Current Regular Bed Occupancy % Vs  Current ICU bed occupancy %’, ‘ InPerson Appointment/ Virtual Appointment/ Missed Appointment’ ,’ Ventilator Utilization %’ and ‘ Active Sensors’ from the report  to the ‘Healthcare’ dashboard.

	![Realtime Operational Analytics.](media/healthcare-operational-analytics-report1.png)

68.	**Select** the ‘ER Wait Time’ page
69.	Similarly, **pin** the visual from the report to the ‘Healthcare’.

	!['Realtime Operational Analystics'.](media/realtime-operational-analytics-report2.png)

70.	**Select** the Workspace in task2.

	![select workspace.](media/select-workspace.png)
	
71.	**Open** ‘Bed Occupancy Report’ report.
	
	![Select Bed Occupancy Report.](media/bed-occupancy-report.png)

72.	Similarly, **pin** all visuals from the report to the ‘Healthcare’.

	![Bed Occupancy Report.](media/bed-occupancy-report1.png.png)

73.	**Refer** to the screenshot of the sample dashboard and pin the visuals to replicate its look and feel. 
74.	**Second** pillar ‘Realtime Operational Analytics’ is completed.

	!['Realtime Operational Analystics'.](media/realtime-operational-analytics-report3.png)

**Pillar 3:  Realtime Quality of Care Analytics**

75.	**Let’s** start Pinning the third pillar ‘Realtime Quality of Care Analytics’
76.	**Select** the Workspace in task2
	
	![Realtime Operational Analystics.](media/realtime-operational-analytics-report3.png)

77.	**Open** ‘healthcare-operational-analytics’ report.

	![Realtime Operational Analytics.](media/realtime-operational-analytics-report.png)
	
78.	Similarly, **pin** ‘Staff to patient ratio’ an ‘ER Waiting Time’ from the report to the ‘Healthcare’ dashboard.

	![Staff to patient ratio.](media/staff-to-patient-ratio.png)
	
79.	**Select** the workspace task2.
	
	![select workspace.](media/select-workspace.png)
	
80.	In the “Reports” section, there will be a list of all the published reports.
81.	**Click** on ‘Consolidated Report’.

	![Consolidated report page.](media/consolidated-report1.png)
	
82.	**Select** the ‘Financial Report’ page.
83.	Similarly, **pin** ’Total Employees’ and ‘Total Patients’ from the report.
	
	![Financial Report.](media/financial-report-page1.png)
	
84.	**Select** the workspace task2.
	
	![select workspace.](media/select-workspace.png)
	
85.	In the “Reports” section, there will be a list of all the published reports.
86.	**Click** on ‘Operational_Analytics_Healthcare_v1’.

	![Operational_Analytics_Healthcare_v1.](media/operational_analytics_healthcare_v1.png)
	
87.	Similarly, **pin** ‘Admissions and readmission percentage- Before’ from the report.

	![Operational_Analytics_Healthcare_v1.](media/operational_analytics_healthcare_v1_1.png)
	
88.	**Select** the workspace task2.
	
	![select workspace.](media/select-workspace.png)
	
89.	In the “Reports” section, there will be a list of all the published reports.
90.	**Click** on ‘Consolidated Report’.
	
	![Consolidated report page.](media/consolidated-report.png)

91.	Similarly, **pin** ‘Patient experience score by dept’ from the report.

	![patient-experience-score-by-dept.](media/patient-experience-score-by-dept.png)

92.	**Refer** to the screenshot of the sample dashboard and pin the visuals to replicate its look and feel. 
93.	**Third** pillar ‘Realtime Quality of Care Analytics’ is completed.
	
	![realtime-quality-care-analytics.](media/realtime-quality-care-analytics.png)
	
**Pillar 4:   Predictive Analytics**

94.	**Let’s** start Pinning the fourth pillar ‘Predictive Analytics’.
95.	**Select** the Workspace in task2.
	
	![select workspace.](media/select-workspace.png)

96.	In the “Reports” section, there will be a list of all the published reports.
97.	**Click** on ‘HealthCare Predctive Analytics_V1’.

	![healthCare-predctive-analytics_v1](media/healthCare-predctive-analytics_v1.png)
		
98.	Similarly, **pin**  ‘Readmission rate’, ’Avg bed occupancy rate’ and ‘Patient CT scan report’ from the report.
	
	![healthCare-predctive-analytics_v1](media/healthCare-predctive-analytics_v1_1.png)
	
99.	Select the Workspace in task2.

	![select workspace.](media/select-workspace.png)
	
100. In the “Reports” section, there will be a list of all the published reports.
101. **Click** on ‘healthcare term index’.
	
   ![healthcare-term-index.](media/healthcare-term-index.png)

102.Similarly, **pin**  ‘Injury Type by Source’ from the report.

   ![healthcare-term-index.](media/healthcare-term-index1.png)
	
103. **Refer** to the screenshot of the sample dashboard and pin the visuals to replicate its look and feel.
104. **Fourth** pillar ‘Predictive Analytics’ is completed.
	
   ![healthcare-term-index.](media/predictive-analytics.png)
	
105. After pinning all the pillars and Dashboard images the final dashboard will look like this

   ![dashboard-final.](media/dashboard-final.png)
	

### Task 8: Creating Synapse Views

1.	**Open** Azure Synapse in a new tab using the following link: https://web.azuresynapse.net/.
2.	**Log in** with your Azure credentials.
3.	**Select** the ‘Subscription’ and Synapse ‘Workspace name’ that got created in Task 3. 
4.	**Click** Continue.

> **Note:** Before executing next step, please get “Storage Blob Data Owner” role assigned to your AD account as well as synapse workspace from your account admin.

   ![Select workspace.](media/select-workspace0.png)

5.	**Click** the 'Develop' hub from the left navigation in the Synapse Analytics workspace.
6.	**Click** on SQL scripts.
7.	**Click** vwCovidDataParquet.
8.	**Click** Run.

    ![Select vwCovidDataParquet.](media/select-workspace1.png)


### Task 9: Publishing the Custom Vision model

1.	**Go to**  https://customvision.ai/ and **click** on Sign In. 
2.	**Select** ‘I agree’ checkbox and **click** on 'I Agree’ button. 
 
> **Note:** If you get any sensitive information related warning then click on ‘OK’. 

   ![cv-login](media/cv-agree.png)

3.	**Select** your cognitive service resource from the resource dropdown starting with name ‘cog-healthcare’. 

   ![Select cv-projects](media/cv-agree.png)
	
4.	**Select** project ‘Safety_Mask_Detection’. 
	
   ![Select cv-saftey-mask-detection](media/cv-saftey-mask-detection.png)

5.	**Select** ‘iteration 1’ from the iteration dropdown. 

   ![iteration1](media/iteration1.png)
	
6.	**Click** on the Performance tab. 

   ![Performance](media/performance.png)
	
7.	**Click** on publish button. 

   ![publish-cv](media/publish-cv.png)
	
8.	**Select** Model Name and Prediction resource on publish model popup and Click on Publish button. 
	
   ![publish-cv](media/publish-cv1.png)

9.	**Navigate** back to project list page and repeat steps 4 to 8 for all the projects. 


### Task 10: Pause-Resume resources

> **Note:** Please perform these steps after your demo is done and you do not need the environment anymore. Also ensure you Resume the environment before demo if you paused it once. 

1. **Open** the Azure Portal. 

2. **Click** on the Azure Cloud Shell icon from the top toolbar.

   ![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/azure-cloudshell-menu-screen4.png)

Execute the ```Pause_Resume_script.ps1``` script by executing the following command:

1. **Run** Command: ```cd 'HealthCare/GitHubRepo/Healthcare'```

2. Then **run** the PowerShell script: ```./Pause_Resume_script.ps1```

   ![Run the script.](media/pause-resume-script.png)

3. From the Azure Cloud Shell, **copy** the authentication code. 

4. **Click** on the link https://microsoft.com/devicelogin and a new browser window will launch.

   ![Copy the code.](media/copy-code-new.png)

5. **Paste** the authentication code.  

   ![New browser window to provide the authentication code](media/Enter-Device-Code-Screen7.png)

6. **Select** the same user that you used for signing into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

7. **Close** this window after it displays successful authentication message.

   ![Select the user account which you want to authenticate.](media/pick-account-to-login.png)

8. When prompted, **enter** the resource group name to be deleted in the Azure Cloud Shell. **Type** the same resource group name that you created.

   ![Enter the resource group name](media/RG-Name-Screen10.png)

9. **Enter** your choice when prompted. **Enter** 'P' for **pausing** the environment or 'R' for **resuming** a paused environment.

10. Wait for script to finish execution.

   ![Enter the choice.](media/p-r.png)


### Task 11: Clean up resources

> **Note:** Perform these steps after your demo is done and you do not need the resources anymore.

**Open** the Azure Portal.

1. **Open** the Azure Cloud Shell by clicking its icon from the top toolbar.

   ![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/azure-cloudshell-menu-screen4.png)

**Execute** the 'resourceCleanup.ps1' script by executing the following commands:
**Run** Command:

   ```PowerShell
   cd 'HealthCare/GitHubRepo/Healthcare’
   ```
	
2. Then **run** the PowerShell script: 
	
   ```PowerShell
   ./resourceCleanup.ps1
   ```
	
   ![Cleaning the resources](media/resource-cleanup.png)

3. You will now be prompted to **enter** the resource group name to be deleted in the Azure Cloud Shell. **Type** the same resource group name that you created in [Task 1](#task-1-create-a-resource-group-in-azure) - 'Synapse-WWI-Lab'.

   ![Enter the resource group name](media/RG-Name-Screen10.png)

4.	You may be prompted to select a subscription in case your account has multiple subscriptions.

Your Accelerator environment is now set up.
