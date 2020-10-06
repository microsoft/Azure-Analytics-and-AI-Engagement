# Frequently Asked Questions

- [What if any resource shows failure during ARM deployment?](#what-if-any-resource-shows-failure-during-arm-deployment)
- [What if my cloud-shell session times out?](#what-if-my-cloud-shell-session-times-out)
- [Cloning repository gives error on cloudshell](#cloning-repository-gives-error)
- [Unable to authenticate a Power BI report](#unable-to-authenticate-power-bi-report)


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
- If there is a data source mismatch, download the report and edit the datasource of it to point to the correct SQL pool and republish the report.Make sure the report id does not change during the republish.
