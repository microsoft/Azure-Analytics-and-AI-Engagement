/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md
select  * from [dbo].[HospitalEmpPIIData] 

/*****************************************************************************************************************/
/*****************************************************************************************************************/

-- 2. Setting up Row Level Security on State
--Create User and Grant Select Permissions

If Not Exists (SELECT Name as [User] FROM sys.sysusers WHERE name='demo-healthcare-user@cloudlabsai.ms') 
CREATE USER [demo-healthcare-user@cloudlabsai.ms] FROM EXTERNAL PROVIDER
GRANT SELECT ON dbo.HospitalEmpPIIData TO [demo-healthcare-user@cloudlabsai.ms] 
EXEC sp_addrolemember 'db_datareader', 'demo-healthcare-user@cloudlabsai.ms'

If Not Exists (SELECT Name as [User] FROM sys.sysusers WHERE name='demo-healthcare-user-02@cloudlabsai.ms') 
CREATE USER [demo-healthcare-user-02@cloudlabsai.ms] FROM EXTERNAL PROVIDER
GRANT SELECT ON dbo.HospitalEmpPIIData TO [demo-healthcare-user-02@cloudlabsai.ms] 
EXEC sp_addrolemember 'db_datareader', 'demo-healthcare-user-02@cloudlabsai.ms'


--Grant Impersonate permissions for AAD login 
GRANT IMPERSONATE ON USER::[demo-healthcare-user-02@cloudlabsai.ms] TO [demo-healthcare-user@cloudlabsai.ms];
GRANT IMPERSONATE ON USER::[demo-healthcare-user@cloudlabsai.ms] TO [demo-healthcare-user-02@cloudlabsai.ms];

--REVOKE CONTROL ON USER::[demo-healthcare-user@cloudlabsai.ms] FROM HospitalEmpPIIData;
--Create roles as values present in column 
--CREATE ROLE [DE]; --This role already exists for SQL login

If Not EXISTS (
SELECT DP1.name AS DatabaseRoleName FROM sys.database_role_members AS DRM  
RIGHT OUTER JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id  
LEFT OUTER JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R' and DP1.Name in ('Miami','NY','PA') )
 CREATE ROLE [CA];

If Not EXISTS (
SELECT DP1.name AS DatabaseRoleName FROM sys.database_role_members AS DRM  
RIGHT OUTER JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id  
LEFT OUTER JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R' and DP1.Name in ('CA','NY','PA') ) 
CREATE ROLE [PA];

If Not EXISTS (
SELECT DP1.name AS DatabaseRoleName FROM sys.database_role_members AS DRM  
RIGHT OUTER JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id  
LEFT OUTER JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R' and DP1.Name in ('CA','NY','PA') )
CREATE ROLE [NY];
    

-- Add AAD users to roles      
EXEC sp_addrolemember 'NY', 'demo-healthcare-user@cloudlabsai.ms';
EXEC sp_addrolemember 'PA', 'demo-healthcare-user@cloudlabsai.ms';
EXEC sp_addrolemember 'CA', 'demo-healthcare-user@cloudlabsai.ms';
EXEC sp_addrolemember 'CA', 'demo-healthcare-user-02@cloudlabsai.ms';

CREATE FUNCTION dbo.fn_securitypredicate_rolemember(@State AS sysname)  
RETURNS TABLE  WITH SCHEMABINDING  
AS  
RETURN SELECT 1 AS fn_securitypredicate_result   
WHERE 
    (@State = 'NY' and IS_ROLEMEMBER('NY') = 1) 
    or (@State = 'CA' and IS_ROLEMEMBER('CA') = 1) 
    or (@State = 'PA' and IS_ROLEMEMBER('PA') = 1)
    or IS_ROLEMEMBER('dbo') = 1; 

--Create Security Policy to filter rows based on column values 
CREATE SECURITY POLICY StateFilter_rolemember 
ADD FILTER PREDICATE dbo.fn_securitypredicate_rolemember([state])   
ON  dbo.HospitalEmpPIIData WITH (STATE = ON);        


ALTER SECURITY POLICY StateFilter_rolemember  
WITH (STATE = OFF);
DROP SECURITY POLICY StateFilter_rolemember; 
DROP FUNCTION Security.fn_securitypredicate_rolemember
DROP SCHEMA Security;

/*****************************************************************************************************************/
-- 3. Setting up Dynamic Data Masking on EmailId column of dbo.HospitalEmpPIIData

        ALTER TABLE dbo.HospitalEmpPIIData  
        ALTER COLUMN Email varchar(100) MASKED WITH (FUNCTION = 'Email()'); 

        ALTER TABLE dbo.HospitalEmpPIIData  
        ALTER COLUMN SSN varchar(100) MASKED WITH (FUNCTION = 'partial(0,"XXX-XX",2)'); 

/********************  Column Level Encryption Set Up ******************/
	--Note:
	--Once CLE is enabled on SQL Pool, login with AAD login and execute all commands as provided below.
	--When executing with Synapse Studio, open symmetric key and select statement should be executed as a single query by selecting it.

/*************************************************************************************************/


--If your database does not already have a database master key, create one by executing the following statement providing your password else alter key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'eT!ePieU*RV@' --master key password
--ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'eT!ePieU*RV@' --alter master key password

--Verify Master Key is created
SELECT * FROM sys.symmetric_keys

--Grant control permisisons on database and create certificate permissions to user
grant control on database::HealthCareDW to [demo-healthcare-user@cloudlabsai.ms]
grant create certificate to [demo-healthcare-user@cloudlabsai.ms]

--Create a new certificate with date options
CREATE CERTIFICATE Cert1 
	encryption by password = 'm9p!T!zJN9#N' --cert password
	WITH SUBJECT = 'CLE Cert',--cert subject
	START_DATE = '20200512', 
	EXPIRY_DATE = '20400512'
--Verify cert creation
SELECT * FROM sys.certificates

--Create a new asymmetric key
CREATE ASYMMETRIC KEY Akey1
	WITH ALGORITHM = RSA_3072
	ENCRYPTION BY PASSWORD = '$T62uDCKP$iq' --asymmetric key password
--Verify asymmetric key creation
SELECT * FROM sys.asymmetric_keys

--Create symmetric key with encryption by certificate, password, and asymmetric key
CREATE SYMMETRIC KEY Key1
	WITH 
	KEY_SOURCE = 'key source',
	IDENTITY_VALUE = 'identity value',
	ALGORITHM = AES_192
	ENCRYPTION BY certificate Cert1, asymmetric key Akey1, password = 'Vhqiv4SyW$j7' --symmetric key password



/************* for wwi.HospitalEmpPIIData *******************/


---Create a new table with or alter a table to add a column for the encrypted data

ALTER TABLE [dbo].[HospitalEmpPIIData] ADD SSN_encrypted varbinary(128)

--Open the symmetric key as a first step to encrypting the column
OPEN SYMMETRIC KEY Key1 DECRYPTION by CERTIFICATE Cert1 WITH password = 'm9p!T!zJN9#N' --cert password

--Verify the key is open
--Select * from sys.openkeys

--Encrypt the column data with the symmetric key
UPDATE [dbo].[HospitalEmpPIIData] SET SSN_encrypted = convert(varbinary(128), ENCRYPTBYKEY(Key_Guid('Key1'), SSN)) 
--Verify the column data is encrypted
Select * from [dbo].[HospitalEmpPIIData] where Id<50


-- To validate encryption and decryption
OPEN SYMMETRIC KEY Key1 DECRYPTION by CERTIFICATE Cert1 WITH password = 'm9p!T!zJN9#N' --cert password
--Decrypt the column data
SELECT SSN_encrypted, CONVERT(NVARCHAR, DECRYPTBYKEY(SSN_Encrypted)) AS [SSN_decrypted] FROM [wwi].[HospitalEmpPIIData]
--Close the symmetric key
CLOSE SYMMETRIC KEY Key1


--drop original ssn column
ALTER TABLE [wwi].[HospitalEmpPIIData] drop column SSN;

