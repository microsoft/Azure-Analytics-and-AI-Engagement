-- VM2-SQL: SQL Server 2019 Developer
-- Run as: sqlcmd -S VM2-SQL -E -v APP_LOGIN_PASSWORD="$(APP_LOGIN_PASSWORD)" -i 01_CreateDatabase.sql
-- Supply APP_LOGIN_PASSWORD at runtime (min 12 chars). Never commit a real value to source control.

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PharmacyDB')
BEGIN
    CREATE DATABASE PharmacyDB
    ON PRIMARY
    (
        NAME = 'PharmacyDB_Data',
        FILENAME = 'C:\SQLData\PharmacyDB.mdf',
        SIZE = 256MB,
        MAXSIZE = 4096MB,
        FILEGROWTH = 64MB
    )
    LOG ON
    (
        NAME = 'PharmacyDB_Log',
        FILENAME = 'C:\SQLData\PharmacyDB_log.ldf',
        SIZE = 64MB,
        MAXSIZE = 1024MB,
        FILEGROWTH = 32MB
    );
    PRINT 'Database PharmacyDB created.';
END
ELSE
    PRINT 'Database PharmacyDB already exists.';
GO

USE PharmacyDB;
GO

DECLARE @AppLoginPassword NVARCHAR(128) = N'$(APP_LOGIN_PASSWORD)';

IF @AppLoginPassword IS NULL
   OR LEN(@AppLoginPassword) < 12
   OR @AppLoginPassword IN (N'', N'CHANGEME', N'REPLACE_ME_AT_RUNTIME')
BEGIN
    THROW 50001, 'APP_LOGIN_PASSWORD is missing or weak. Supply a strong password using sqlcmd -v APP_LOGIN_PASSWORD="...".', 1;
END
GO

-- Application login for VM1-App connection string
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'pharmacyapp')
BEGIN
    DECLARE @EscapedPassword NVARCHAR(256) = REPLACE(@AppLoginPassword, '''', '''''');
    DECLARE @CreateLoginSql NVARCHAR(MAX) =
        N'CREATE LOGIN pharmacyapp WITH PASSWORD = ''' + @EscapedPassword + N''', CHECK_POLICY = ON, CHECK_EXPIRATION = ON;';

    EXEC(@CreateLoginSql);
    PRINT 'Login pharmacyapp created.';
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'pharmacyapp')
BEGIN
    CREATE USER pharmacyapp FOR LOGIN pharmacyapp;
    ALTER ROLE db_datareader ADD MEMBER pharmacyapp;
    ALTER ROLE db_datawriter ADD MEMBER pharmacyapp;
    PRINT 'User pharmacyapp created and roles assigned.';
END
GO
