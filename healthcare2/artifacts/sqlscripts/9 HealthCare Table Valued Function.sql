/******Important - Do not use in production, for demonstration purposes only - please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer

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
   COUNT(*) as [Number of patients]
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
	
