/* ∗∗∗∗∗∗∗∗∗ Important – Do not use in production, for demonstration purposes only – please review the legal notices before continuing ∗∗∗∗∗ */
/*	Row level Security (RLS) in Microsoft Fabric enables us to use group membership to control access to rows in a table.
	Fabric applies the access restriction every time the data access is attempted from any user. 
	Let see how we can implement row level security in Fabric Data Warehouse & SQL Endpoint.*/

----------------------------------Row-Level Security (RLS), 1: Filter predicates------------------------------------------------------------------
-- Step:1 The FactSales table has two SalesRep values
SELECT  * FROM [dbo].[Sales] order by SalesRep ;

-- Step:2 
CREATE FUNCTION Security.fn_securitypredicate(@SalesRep AS Varchar(100))  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result
    WHERE @SalesRep = USER_NAME()
GO
-- Now we define security policy that allows users to filter rows based on thier login name.
CREATE SECURITY POLICY SalesFilter
ADD FILTER PREDICATE Security.fn_securitypredicate(SalesRep)
ON dbo.Sales
WITH (STATE = ON);

-- Step:3 Let us now test the filtering predicate, by selecting data from the FactSales table.
select * from dbo.Sales


--Step:4 To disable the security policy we just created above, we execute the following.
ALTER SECURITY POLICY SalesFilter  
WITH (STATE = OFF);
DROP SECURITY POLICY SalesFilter;
DROP FUNCTION Security.fn_securitypredicate;
