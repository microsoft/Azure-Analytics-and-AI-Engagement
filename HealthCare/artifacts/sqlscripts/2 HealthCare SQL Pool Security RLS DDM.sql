/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md
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






