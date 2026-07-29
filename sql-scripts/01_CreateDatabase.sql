-- VM2-SQL: SQL Server 2019 Developer
-- Run as: sqlcmd -S VM2-SQL -E -i 01_CreateDatabase.sql
:setvar PharmacyAppPassword "CHANGE_ME_STRONG_PASSWORD"

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

-- Application login for VM1-App connection string
IF '$(PharmacyAppPassword)' = 'CHANGE_ME_STRONG_PASSWORD'
BEGIN
    THROW 51000, 'Set PharmacyAppPassword via sqlcmd -v PharmacyAppPassword="<strong password>" before running this script.', 1;
END
GO

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'pharmacyapp')
BEGIN
    CREATE LOGIN pharmacyapp WITH PASSWORD = '$(PharmacyAppPassword)', CHECK_POLICY = ON;
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
