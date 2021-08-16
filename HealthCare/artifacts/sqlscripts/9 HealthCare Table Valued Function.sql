/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */


/* Table-Valued function in Azure Synapse is a user-defined function that returns data of a table type.
The return type of a table-valued function is a table, therefore, you can use the table-valued function just like you would use a table
Let's see how we can implement this in Azure Synapse.*/

/*Step 1 udfPatientdetail is table-valued function that returns patient details whose age is between some range: */
DROP FUNCTION IF EXISTS udfPatientdetail
GO
CREATE FUNCTION udfPatientdetail (
    @patientAge1 nvarchar(200),
	@patientAge2 nvarchar(200)
)
RETURNS TABLE
AS
RETURN
    SELECT 
        *
    FROM
        dbo.[healthcare-tablevalued]
    WHERE patientAge
	BETWEEN @patientAge1 AND @patientAge2
       
GO

--Step 2 Number of patients aged between 30 and 70
SELECT 
   COUNT(*) 
FROM 
    udfPatientdetail(30,70)
GO

--Step 3 details of patients aged between 30 and 40
SELECT 
     *
FROM 
    udfPatientdetail(30,40)
	order by patientAge desc
GO
	
