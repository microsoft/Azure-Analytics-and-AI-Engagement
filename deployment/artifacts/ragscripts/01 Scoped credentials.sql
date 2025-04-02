CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Smoothie@123';

CREATE DATABASE SCOPED CREDENTIAL [+++@lab.Variable(endpointurl)+++] 
WITH IDENTITY = 'HTTPEndpointHeaders',
 SECRET = '{"api-key": "+++@lab.Variable(endpointkey)+++"}';

SELECT * 
FROM sys.database_scoped_credentials
WHERE name = '+++@lab.Variable(endpointurl)+++';