# Frequently Asked Questions

- [What if any resource shows failure during ARM deployment?](#what-if-any-resource-shows-failure-during-arm-deployment)
- [What if my cloud-shell session times out?](#what-if-my-cloud-shell-session-times-out)


## What if any resource shows failure during ARM deployment?

Sometimes resources may fail to deploy when there is too much traffic on azure servers ,the azure service is down for maintenance or the particular service is not available in your region.

- Check the azure services status here: https://status.azure.com/en-us/status and check the availability of the service that is failing for you.
- Retry the deployment in another region/location.

## What if my cloud-shell session times out?

It is important to keep the cloud shell session live during execution else the script will fail to complete. In this case you may try to re-run the script but it may throw errors for the conflicting tasks. As a last resort you will have t delete the resources and re-deploy the templates.

## What if my cloning fails with "File already exist message?"

Please run following command to remove\delete already clone file and then run the clone command again.  

## Command 
rm MfgAI -f --recursive
