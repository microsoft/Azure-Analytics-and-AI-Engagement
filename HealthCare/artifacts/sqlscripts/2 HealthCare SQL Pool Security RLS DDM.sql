/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

/* Row level Security (RLS) in Azure Synapse enables us to use group membership to control access to rows in a table.
	Azure Synapse applies the access restriction every time the data access is attempted from any user. 
	Let see how we can implement row level security and Dynamic Data Masking in Azure Synapse.*/

--Step 1
SELECT count(*) as 'TotalEmp' FROM dbo.HospitalEmpPIIData ; 
SELECT * FROM dbo.HospitalEmpPIIData ;

-- Step 2 Let now test the filtering predicate (for state), by selecting data from the HospitalEmpPIIData table as Your Alias
-- ChiefOperatingManager 'Spencer' should be able to see all rows in the table.
-- Spencer is logged in as demo-healthcare-user.
EXECUTE AS USER ='demo-healthcare-user@cloudlabsai.ms'
SELECT count(*) as 'TotalEmp' FROM dbo.HospitalEmpPIIData ;
SELECT * FROM dbo.HospitalEmpPIIData;
revert

-- Step 3 Let us test the same for other user.
-- CareManager 'Jim' should be able to see only Miami State and BillingStaff Data in the table.
-- Jim is logged in as demo-healthcare-user-02.
EXECUTE AS USER ='demo-healthcare-user-02@cloudlabsai.ms'
SELECT count(*) as 'TotalEmp' FROM dbo.HospitalEmpPIIData ;
SELECT 
    *
FROM 
    dbo.HospitalEmpPIIData ;
revert






