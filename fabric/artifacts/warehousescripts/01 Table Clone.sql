/* Table clones allow developers and testers to experiment, validate, and refine the tables without impacting the tables in production environment.
 The clone provides a safe and isolated space to conduct development and testing activities of new features, ensuring the integrity and stability
  of the production environment.***/

--Step 1 Let's view existing table
Select * from [dbo].[DimChannel]

--Step 2
--Clone creation within the same schema
CREATE TABLE [dbo].[DimChannelClone] AS CLONE OF [dbo].[DimChannel];

--Step 3 Let's select table to see whether the data is reflected or Not
Select * from [dbo].[DimChannelClone]

-----------------------Across Schemas-------------------------------------
--Step 1 Clone creation across schemas
--Create schema abc

CREATE TABLE [abc].[DimCustomer1]  AS CLONE OF [dbo].[DimCustomer] ;

--Step 2 Let's select table to see whether the data is reflected or Not
Select top 100 * from [abc].[DimCustomer1]
