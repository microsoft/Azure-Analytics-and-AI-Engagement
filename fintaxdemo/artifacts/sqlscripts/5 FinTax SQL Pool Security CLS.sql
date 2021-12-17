select  Top 100 * from FactInvoicesData;


SELECT Name as [User] FROM sys.sysusers WHERE name IN (N'AntiCorruptionUnitHead', N'TaxAuditor')

EXEC [sp_GrantLimitedSelectFactInvoicesData];

EXECUTE AS USER ='TaxAuditor'
select * from FactInvoicesData

EXECUTE AS USER ='TaxAuditor'
select [TaxpayerID], [Region], [State], [Industry], [TaxableAmount], [TaxAmount] from FactInvoicesData

EXEC sp_GrantFullSelectFactInvoicesData;

EXECUTE AS USER ='AntiCorruptionUnitHead'
select * from FactInvoicesData

Revert;