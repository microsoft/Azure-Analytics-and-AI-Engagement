--?????????? Important - Do not use in production, for demonstration purposes only - please review the legal notices before continuing ?????--
-- Description: This script is used to apply appropriate permissions to the database for the Retail 2.0 Demo User Group account
-- 
-- ********************** APPLY PERSMISSIONS ***********************

-- DROP USER FOR TESTING PURPOSES

DROP USER [Retail 2.0 Demo User Group];

-- CREATE USERS
CREATE USER [Retail 2.0 Demo User Group] FROM EXTERNAL PROVIDER; 
CREATE USER [MarketingOwner] WITHOUT LOGIN
CREATE USER [TaxAuditor] WITHOUT LOGIN
CREATE USER [TaxAuditSupervisor] WITHOUT LOGIN
CREATE USER [TaxAuditorSurDatum] WITHOUT LOGIN
CREATE USER [TaxAuditorStatiso] WITHOUT LOGIN 
CREATE USER [AntiCorruptionUnitHead] WITHOUT LOGIN
GRANT IMPERSONATE ON USER::MarketingOwner TO [Retail 2.0 Demo User Group];

-- ADD DB_DATAREADER PERMISSIONS
EXEC sp_addrolemember 'db_datareader', [Retail 2.0 Demo User Group];
EXEC sp_addrolemember 'db_datareader', [AntiCorruptionUnitHead];
EXEC sp_addrolemember 'db_datareader', [TaxAuditorStatiso];
EXEC sp_addrolemember 'db_datareader', [TaxAuditorSurDatum];
EXEC sp_addrolemember 'db_datareader', [TaxAuditSupervisor];
EXEC sp_addrolemember 'db_datareader', [TaxAuditor];
EXEC sp_addrolemember 'db_owner', [MarketingOwner];

-- CREATE STORED PROCEDURES FOR TEST USER TO GRANT SELECT -> Demo 1 Step 5
GO
CREATE PROCEDURE dbo.sp_GrantSelectTaxAuditor
    AS
    EXECUTE AS USER =N'MarketingOwner';
    GRANT SELECT ON [Fact-Invoices] TO TaxAuditor;  
    REVERT;

-- CREATE STORED PROCEDURES FOR TEST USER TO GRANT UNMASK -> Demo 1 Step 7

Go

CREATE PROCEDURE dbo.sp_GrantUnmaskTaxAuditor
    AS
    EXECUTE AS USER = 'MarketingOwner'
    GRANT UNMASK TO TaxAuditor
    REVERT;

-- CREATE STORED PROCEDURES FOR TEST USER TO GRANT UNMASK -> Demo 1 Step 7
GO

CREATE PROCEDURE dbo.sp_RevokeUnmaskTaxAuditor
    AS
    EXECUTE AS USER = 'MarketingOwner'
    REVOKE UNMASK TO TaxAuditor
    REVERT;

-- CREATE STORED PROCEDURES FOR TEST USER TO CREATE Schema and Function -> Demo 2 Step 2
GO
CREATE PROCEDURE dbo.sp_CreateSecuritySchema
    AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql nvarchar(4000) = 'create schema Security'
    EXEC sp_executesql @sql
    END
    REVERT;

-- CREATE STORED PROCEDURES FOR TEST USER TO CREATE Security Function -> Demo 2 Step 2
GO
CREATE PROCEDURE dbo.sp_CreateSecurityFunction
    AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql nvarchar(4000) = 'CREATE FUNCTION Security.fn_securitypredicate(@Analyst AS sysname)  
        RETURNS TABLE  
        WITH SCHEMABINDING  
        AS  
        RETURN SELECT 1 AS fn_securitypredicate_result
        WHERE USER_NAME() = ''TaxAuditSupervisor'' OR @Analyst = USER_NAME()'
    EXEC sp_executesql @sql
    END
    REVERT;


-- CREATE STORED PROCEDURES FOR TEST USER TO CREATE Schema and Function -> Demo 2 Step 2
GO
CREATE PROCEDURE dbo.sp_CreateSecurityPolicy
    AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql nvarchar(4000) = 'CREATE SECURITY POLICY SalesFilter  
        ADD FILTER PREDICATE Security.fn_securitypredicate(Designation)
        ON dbo.[FactInvoices]
        WITH (STATE = ON);'
    EXEC sp_executesql @sql
    END
    REVERT;

-- CREATE STORED PROCEDURES FOR TEST USER TO GRANT SELECT ON SECURITY PREDICATE -> Demo 2 Step 2
GO
CREATE PROCEDURE dbo.sp_GrantSelectSecurityPredicate
    AS
    EXECUTE AS USER = 'MarketingOwner'
    GRANT SELECT ON security.fn_securitypredicate TO TaxAuditSupervisor, TaxAuditorStatiso, TaxAuditorSurDatum;
    REVERT;

-- CREATE STORED PROCEDURES FOR TEST USER TO GRANT SELECT ON SECURITY PREDICATE -> Demo 2 Step 6
GO
CREATE PROCEDURE dbo.sp_CleanUpRLS
    AS
    EXECUTE AS USER = 'MarketingOwner';
    BEGIN
    DECLARE @sql1 nvarchar(4000) = 'ALTER SECURITY POLICY SalesFilter  
        WITH (STATE = OFF);'
    DECLARE @sql2 nvarchar(4000) = 'DROP SECURITY POLICY SalesFilter;'
    DECLARE @sql3 nvarchar(4000) = 'DROP FUNCTION Security.fn_securitypredicate;'
    DECLARE @sql4 nvarchar(4000) = 'DROP SCHEMA Security;'
    EXEC sp_executesql @sql1
    EXEC sp_executesql @sql2
    EXEC sp_executesql @sql3
    EXEC sp_executesql @sql4
    END
    REVERT;

-- CREATE STORED PROCEDURE FOR TEST USER TO GRANT LIMITED SELECT FOR CLS -> Demo 3

GO
CREATE PROC [dbo].[sp_GrantLimitedSelectFactInvoicesData] AS
    EXECUTE AS USER = 'MarketingOwner'
    DENY SELECT ON FactInvoicesData TO TaxAuditor;
    GRANT SELECT ON FactInvoicesData ([TaxpayerID], [Region], [State], [Industry], [TaxableAmount], [TaxAmount]) TO TaxAuditor;
    REVERT;

-- CREATE STORED PROCEDURE FOR TEST USER TO GRANT FULL SELECT FOR CLS -> Demo 3

GO  
CREATE PROC [dbo].[sp_GrantFullSelectFactInvoicesData] AS
    EXECUTE AS USER = 'MarketingOwner'
    GRANT SELECT ON FactInvoicesData TO AntiCorruptionUnitHead; 
    REVERT;

-- GRANT PERMISSIONS FOR THE DEMO - 1 Finance SQL Pool Security DDM
GO
GRANT EXECUTE ON [Confirm DDM] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_GrantSelectTaxAuditor] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_GrantUnmaskTaxAuditor] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_RevokeUnmaskTaxAuditor] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_CreateSecuritySchema] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_CreateSecurityFunction] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_CreateSecurityPolicy] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_GrantSelectSecurityPredicate] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_CleanUpRLS] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_CreateExternalTable] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_DropDatabase] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_GrantLimitedSelectFactInvoicesData] TO [Retail 2.0 Demo User Group];
GRANT EXECUTE ON [sp_GrantFullSelectFactInvoicesData] TO [Retail 2.0 Demo User Group];
GRANT ALTER ON [Fact-Invoices] TO [Retail 2.0 Demo User Group];
GRANT ALTER ANY MASK TO [Retail 2.0 Demo User Group]; 
GRANT VIEW DEFINITION TO [Retail 2.0 Demo User Group]; --Allows to query sys.sysusers
GRANT IMPERSONATE ON USER::TaxAuditor TO [Retail 2.0 Demo User Group];
GRANT IMPERSONATE ON USER::TaxAuditSupervisor TO [Retail 2.0 Demo User Group];
GRANT IMPERSONATE ON USER::TaxAuditorSurDatum TO [Retail 2.0 Demo User Group];
GRANT IMPERSONATE ON USER::TaxAuditorStatiso TO [Retail 2.0 Demo User Group];
GRANT IMPERSONATE ON USER::TaxAuditSupervisor TO [Retail 2.0 Demo User Group];
GRANT IMPERSONATE ON USER::AntiCorruptionUnitHead TO [Retail 2.0 Demo User Group];
-- GRANT PERMISSIONS FOR THE DEMO - 1 Finance SQL Pool Security DDM
GO
GRANT EXECUTE ON [Sp_FinTaxRLS] TO [Retail 2.0 Demo User Group]

-- ********************** QUERIES TO VALIDATE PERMISSIONS ***********************

-- Query to view permissions applied to the database
GO  
SELECT r.name role_principal_name, m.name AS member_principal_name
FROM sys.database_role_members rm 
JOIN sys.database_principals r 
    ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m 
    ON rm.member_principal_id = m.principal_id


-- Check Mask Permissions
GO
SELECT  
    princ.name,
    princ.type_desc,
    perm.permission_name,
    perm.state_desc,
    perm.class_desc,
    object_name(perm.major_id)
FROM sys.database_principals princ
LEFT JOIN
    sys.database_permissions perm ON perm.grantee_principal_id = princ.principal_id
WHERE  name = 'BusinessAnalyst'
ORDER BY name asc;

GRANT UNMASK TO BusinessAnalyst


-- Check User Permissions
GO
SELECT  
    [UserName] = CASE princ.[type] 
                    WHEN 'S' THEN princ.[name]
                 END,
    [UserType] = CASE princ.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
                 END,  
    [DatabaseUserName] = princ.[name],       
    [Role] = null,      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],       
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    --database user
    sys.database_principals princ  
LEFT JOIN        
    --Permissions
    sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
LEFT JOIN
    --Table columns
    sys.columns col ON col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
WHERE 
    princ.[type] in ('S','U')
UNION
--List all access provisioned to a sql user or windows user/group through a database or application role
SELECT  
    [UserName] = CASE memberprinc.[type] 
                    WHEN 'S' THEN memberprinc.[name]
                 END,
    [UserType] = CASE memberprinc.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
                 END, 
    [DatabaseUserName] = memberprinc.[name],   
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],   
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    --Role/member associations
    sys.database_role_members members
JOIN
    --Roles
    sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
JOIN
    --Role members (database users)
    sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
LEFT JOIN        
    --Permissions
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    --Table columns
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
UNION
--List all access provisioned to the public role, which everyone gets by default
SELECT  
    [UserName] = '{All Users}',
    [UserType] = '{All Users}', 
    [DatabaseUserName] = '{All Users}',       
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],  
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    --Roles
    sys.database_principals roleprinc
LEFT JOIN        
    --Role permissions
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    --Table columns
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]                   
JOIN 
    --All objects   
    sys.objects obj ON obj.[object_id] = perm.[major_id]
WHERE
    --Only roles
    roleprinc.[type] = 'R' AND
    --Only public role
    roleprinc.[name] = 'public' AND
    --Only objects of ours, not the MS objects
    obj.is_ms_shipped = 0
ORDER BY
    princ.[Name],
    OBJECT_NAME(perm.major_id),
    col.[name],
    perm.[permission_name],
    perm.[state_desc],
    obj.type_desc--perm.[class_desc] 
