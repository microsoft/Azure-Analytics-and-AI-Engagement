# Questions and Answers

**Q:** My deployment is failing with **BadRequest** status during ARM deployment. 

![Deployment progress shown with Synapse workspace lineitem highlighted.](media/template-deployment-bad-request.png)

**A:** Navigate to the operation details for the failing operation and see the status message. If the message mentions "`Location '' is not accepting creation of new Windows Azure SQL Database servers at this time.`" try another data center for your deployment.

![Synapse Workspace](media/template-deployment-location-not-allowed.png)



