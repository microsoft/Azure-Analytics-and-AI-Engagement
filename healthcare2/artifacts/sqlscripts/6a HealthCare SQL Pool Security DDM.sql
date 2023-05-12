/******Important - Do not use in production, for demonstration purposes only - please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer

-- Step:1(View the existing table 'PatientInformation' Data) 
select top 100 * from PatientInformation

-- Step:2 Let's confirm that there are no Dynamic Data Masking (DDM) applied on columns
Exec [Confirm DDM]
-- No results returned verify that no data masking has been done yet.

-- Step:3 Now lets mask 'Medical Insurance Card' and 'Email' Column of 'PatientInformation' table.
ALTER TABLE PatientInformation  
ALTER COLUMN [Medical Insurance Card] ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-XXXX-",4)')
GO
ALTER TABLE PatientInformation 
Alter Column Email ADD MASKED WITH (FUNCTION = 'email()')
GO
-- The columns are sucessfully masked.

-- Step:4 Let's see Dynamic Data Masking (DDM) applied on the two columns.
Exec [Confirm DDM]

-- Step:5 Now, let us grant SELECT permission to 'CareManager'sysusers on the 'PatientInformation' table.
SELECT Name as [User] FROM sys.sysusers WHERE name = N'CareManager'
GRANT SELECT ON PatientInformation TO CareManager;  

-- Step:6 Logged in as  'CareManager' let us execute the select query and view the result.
EXECUTE AS USER =N'CareManager';  
SELECT  * FROM PatientInformation; 

-- Step:7 Let us Remove the data masking using UNMASK permission
GRANT UNMASK TO CareManager
EXECUTE AS USER = 'CareManager';  
SELECT top 10 * FROM PatientInformation; 
revert; 
REVOKE UNMASK TO CareManager;  

----step:8 Reverting all the changes back to as it was.
ALTER TABLE PatientInformation
ALTER COLUMN [Medical Insurance Card] DROP MASKED;
GO
ALTER TABLE PatientInformation
ALTER COLUMN Email DROP MASKED;
GO