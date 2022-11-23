/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/*
-- Step:1(View the existing table 'TweeterUserInfo' Data) 
select top 100 * from TweeterUserInfo

-- Step:2 Let's confirm that there are no Dynamic Data Masking (DDM) applied on columns
Exec [Confirm DDM]
-- No results returned verify that no data masking has been done yet.

-- Step:3 Now lets mask 'Phone number' and 'Email' Column of 'TweeterUserInfo' table.
ALTER TABLE TweeterUserInfo  
ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-XXXX-",4)')
GO
ALTER TABLE TweeterUserInfo 
Alter Column Email ADD MASKED WITH (FUNCTION = 'email()')
GO
-- The columns are sucessfully masked.

-- Step:4 Let's see Dynamic Data Masking (DDM) applied on the two columns.
Exec [Confirm DDM]

-- Step:5 Now, let us grant SELECT permission to 'FacilityManager'sysusers on the 'TweeterUserInfo' table.
SELECT Name as [User] FROM sys.sysusers WHERE name = N'FacilityManager'
GRANT SELECT ON TweeterUserInfo TO [FacilityManager];  

-- Step:6 Logged in as  'FacilityManager' let us execute the select query and view the result.
EXECUTE AS USER =N'FacilityManager';  
SELECT  * FROM TweeterUserInfo; 

-- Step:7 Let us Remove the data masking using UNMASK permission
GRANT UNMASK TO FacilityManager
EXECUTE AS USER = 'FacilityManager';  
SELECT top 10 * FROM TweeterUserInfo; 
revert; 
REVOKE UNMASK TO FacilityManager;  

----step:8 Reverting all the changes back to as it was.
ALTER TABLE TweeterUserInfo
ALTER COLUMN Phone DROP MASKED;
GO
ALTER TABLE TweeterUserInfo
ALTER COLUMN Email DROP MASKED;
GO