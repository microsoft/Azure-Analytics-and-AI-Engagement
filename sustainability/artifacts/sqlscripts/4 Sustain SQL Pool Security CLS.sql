
SELECT  Top 100 * FROM [Vehicle_Analytics];


SELECT Name as [User] FROM sys.sysusers 
WHERE name IN (N'ChiefDataOfficer',N'DataAnalystSurdatum')


GRANT SELECT ON Vehicle_Analytics  
(VehicleID,Fueltype,Mileage,Year,Months,Distance,FuelConsumption,[CO2Emission(kg)],
Date,FuelCost,VehicleType) TO DataAnalystSurdatum;


EXECUTE AS USER ='DataAnalystSurdatum'
select * from Vehicle_Analytics


EXECUTE AS USER ='DataAnalystSurdatum'
select VehicleID,Fueltype,Mileage,Year,Months,Distance,FuelConsumption,[CO2Emission(kg)],Date,FuelCost,VehicleType 
from Vehicle_Analytics
Revert;


Revert;
GRANT SELECT ON [Vehicle_Analytics] TO ChiefDataOfficer;


EXECUTE AS USER ='ChiefDataOfficer'
select * from Vehicle_Analytics


Revert;