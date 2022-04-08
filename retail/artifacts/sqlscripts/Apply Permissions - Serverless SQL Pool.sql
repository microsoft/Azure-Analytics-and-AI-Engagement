--/*****For Demonstration purpose only, Please customize as per your enterprise security needs and compliances*****/*--
--------------- SET UP DATABASE ---------------
GO

ALTER DATABASE RetailSqlOnDemand
COLLATE LATIN1_GENERAL_100_CI_AS_SC_UTF8
GO
USE RetailSqlOnDemand;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD ='DreamDemo1*';
GO


--------------- CREATE USERS ---------------
USE RetailSqlOnDemand;
CREATE LOGIN [Retail 2.0 Demo User Group] FROM EXTERNAL PROVIDER;
CREATE LOGIN [RetailOwner] WITH PASSWORD = 'DreamDemo1';

CREATE USER testUser FROM LOGIN [Retail 2.0 Demo User Group];
CREATE USER RetailOwner FROM LOGIN [RetailOwner];

USE RetailSqlOnDemand
CREATE LOGIN [Retail 2.0 Demo User Group] FROM EXTERNAL PROVIDER;
CREATE LOGIN [RetailOwner] WITH PASSWORD = 'DreamDemo1';

CREATE USER testUser FROM LOGIN [Retail 2.0 Demo User Group];
CREATE USER RetailOwner FROM LOGIN [RetailOwner];

GRANT ALTER ON [vwSynapseLinkDBWorkload] TO [testUser];
GRANT ALTER ON [Connections] TO [testUser];

USE RetailSqlOnDemand;
ALTER ROLE db_owner
ADD MEMBER testUser

ALTER ROLE db_owner
ADD MEMBER RetailOwner

USE RetailSqlOnDemand;
ALTER ROLE db_owner
ADD MEMBER testUser

ALTER ROLE db_owner
ADD MEMBER RetailOwner

USE RetailSqlOnDemand;
ALTER ROLE db_datareader
ADD MEMBER testUser

-------- Demo 7 Set Up ---------  TODO 7/20/21 - NEED TO UPDATE SAS FOR PROD
CREATE CREDENTIAL [cosmosdb-retail2-prod]
    WITH IDENTITY = 'SHARED ACCESS SIGNATURE', SECRET = 'MYvjatcCeIu4FKtiSK2sDN00MmuMMQq1MyXOwjrwedLmVlk3k6ppHknFPcRNljNPdgnN5F2RnnHSXLkmHYeo1A=='
GRANT CONTROL ON CREDENTIAL::[cosmosdb-retail2-prod] TO [Retail 2.0 Demo User Group];




