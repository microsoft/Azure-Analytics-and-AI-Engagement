SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[All_Data]
( 
	[ID] [float]  NULL,
	[TypeIdentifier] [nvarchar](255)  NULL,
	[Name] [nvarchar](255)  NULL,
	[NTaxpayers] [nvarchar](255)  NULL,
	[NReturn] [nvarchar](255)  NULL,
	[NIssues] [nvarchar](255)  NULL,
	[NReturnsProcessed] [nvarchar](255)  NULL,
	[NReturnsAccepted] [nvarchar](255)  NULL,
	[NMonthlyDelayedPayments] [nvarchar](255)  NULL,
	[Penaltycollected] [nvarchar](255)  NULL,
	[PenaltyTarget] [nvarchar](255)  NULL,
	[InterestCollected] [nvarchar](255)  NULL,
	[InterestTarget] [nvarchar](255)  NULL,
	[NTaxpayersReportedtoLawEnforcement] [nvarchar](255)  NULL,
	[NPotentialAnomalies] [nvarchar](255)  NULL,
	[TaxIssues] [nvarchar](255)  NULL,
	[UnderaymentrDelayedPayments] [nvarchar](255)  NULL,
	[Penalties_YTD] [nvarchar](255)  NULL,
	[InterestCollected_YTD] [nvarchar](255)  NULL,
	[NReturnsScrutiny] [nvarchar](255)  NULL,
	[NAuditedReportsClosedWithPenaltyLessThan$1000] [nvarchar](255)  NULL,
	[NTaxpayersUnderScrutiny] [nvarchar](255)  NULL,
	[InternalRiskandCompliance] [nvarchar](255)  NULL,
	[NTaxpayersReportedtoLawEnforcement1] [nvarchar](255)  NULL,
	[# of cases with potential fraudâ€‹] [nvarchar](255)  NULL,
	[# of cases still under scrutinyÂ â€‹] [nvarchar](255)  NULL,
	[Potential fraud detectedâ€‹] [nvarchar](255)  NULL,
	[# of employees reported to LEâ€‹] [nvarchar](255)  NULL,
	[Dues collectedâ€‹] [nvarchar](255)  NULL,
	[Penalties collectedâ€‹] [nvarchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Color]
( 
	[ColorId] [int]  NULL,
	[ColorName] [varchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Corruption_Data]
( 
	[State] [nvarchar](255)  NULL,
	[Sector1] [nvarchar](255)  NULL,
	[Month Year] [datetime]  NULL,
	[TaxpayerID] [nvarchar](255)  NULL,
	[VAT] [money]  NULL,
	[VAT Target] [money]  NULL,
	[VAT Gap] [money]  NULL,
	[Anomaly Index] [float]  NULL,
	[Fraud Risk Score​] [float]  NULL,
	[Auditor​] [nvarchar](255)  NULL,
	[Auditor action​] [nvarchar](255)  NULL,
	[Auditor Supervisor​] [nvarchar](255)  NULL,
	[Penalty charged​] [nvarchar](255)  NULL,
	[Time to close​] [nvarchar](255)  NULL,
	[Closing approved by​] [nvarchar](255)  NULL,
	[Additional Penalty / Action] [nvarchar](255)  NULL,
	[Remarks/Findings] [nvarchar](255)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Customer]
( 
	[customer_id] [nvarchar](max)  NULL,
	[customer_firstname] [nvarchar](max)  NULL,
	[customer_lastname] [nvarchar](max)  NULL,
	[customer_middlename] [nvarchar](max)  NULL,
	[customer_date_of_birth] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Fact-dailytaxdetails]
( 
	[ID] [int]  NULL,
	[UpdatedOn] [datetime]  NULL,
	[IncomeTax] [money]  NULL,
	[TargetIncomeTax] [money]  NULL,
	[ValueAddedTax] [money]  NULL,
	[TargetValueAddedTax] [money]  NULL,
	[CorporationTax] [money]  NULL,
	[TargetCorporationTax] [money]  NULL,
	[Locations] [nvarchar](50)  NULL,
	[Industries] [nvarchar](50)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Fact-Invoices]
( 
	[Designation] [varchar](50)  NULL,
	[TaxpayerID] [varchar](50)  NULL,
	[Address] [varchar](100)  NULL,
	[Region] [varchar](30)  NULL,
	[State] [varchar](30)  NULL,
	[Industry] [varchar](30)  NULL,
	[TaxableAmount] [money]  NULL,
	[TaxAmount] [money]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[fact-pbiMonthlyTaxDetails]
( 
	[ID] [int]  NULL,
	[ReportingPeriod] [varchar](30)  NULL,
	[IncomeTax] [money]  NULL,
	[IncomeTaxTarget] [money]  NULL,
	[ValueAddedTax] [money]  NULL,
	[ValueAddedTaxTarget] [money]  NULL,
	[CorporationTax] [money]  NULL,
	[CorporationTaxTarget] [money]  NULL,
	[PctTaxPayerCsatDigital] [float]  NULL,
	[PctTaxPayerCsatDigitalPredicted] [float]  NULL,
	[PctTaxPayerCsatDigitalTarget] [float]  NULL,
	[PctTaxPayerCsatPhysical] [float]  NULL,
	[PctTaxPayerCsatPredicted] [float]  NULL,
	[PctTaxPayerCsatPhysicalTarget] [float]  NULL,
	[CntTaxPayerComplaints] [int]  NULL,
	[CntTaxPayerComplaintsTarget] [int]  NULL,
	[PctTaxPayerCsatOverall] [float]  NULL,
	[PctTaxPayerCsatOverallTarget] [float]  NULL,
	[PctTaxPayerCsatOverallPredicted] [float]  NULL,
	[CntTaxReturnMail] [int]  NULL,
	[CntTaxReturnMailTarget] [int]  NULL,
	[PctPhysicalTaxReturnResponse15Days] [float]  NULL,
	[PctPhysicalTaxReturnResponse15DaysTarget] [float]  NULL,
	[CntTaxReturnInOffice] [int]  NULL,
	[CntTaxReturnInOfficeTarget] [int]  NULL,
	[CntTaxPayerCalls] [int]  NULL,
	[TaxPayerCallAnswerTime] [float]  NULL,
	[CntTaxPayerCallWaiting10MinOrMore] [float]  NULL,
	[CntTier1Complaints] [int]  NULL,
	[CntTier2Complaints] [int]  NULL,
	[CntTaxReturnDigital] [int]  NULL,
	[PctDigialTaxReturnOutOfOverall] [float]  NULL,
	[PctDigialTaxReturnOutOfOverallTarget] [float]  NULL,
	[PctDigitalTaxReturnResponse7Days] [float]  NULL,
	[PctDigitalTaxReturnResponse7DaysTarget] [float]  NULL,
	[PctTaxReturnAmended] [float]  NULL,
	[PctTaxReturnAmendedTarget] [float]  NULL,
	[PctTaxReturnAudited] [float]  NULL,
	[PctTaxReturnAuditedTarget] [float]  NULL,
	[PctTaxPayerCsatChangeNextMonth] [float]  NULL,
	[PctTaxPayerCsatChangeNextMonthTarget] [float]  NULL,
	[PctTaxPayerComplaintsChangeNextMonth] [float]  NULL,
	[PctTaxPayerComplaintsChangeNextMonthTarget] [float]  NULL,
	[PctTaxPayerTrafficInOfficesChangeNextMonth] [float]  NULL,
	[PctTaxPayerTrafficInOfficesChangeNextMonthTarget] [float]  NULL,
	[PctTaxPayerTrafficDigitalChangeNextMonth] [float]  NULL,
	[PctTaxPayerTrafficDigitalChangeNextMonthTarget] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Fact-Taxpayersatisfactiondetail]
( 
	[ID] [nvarchar](max)  NULL,
	[UpdatedOn] [nvarchar](max)  NULL,
	[TaxpayerID] [nvarchar](max)  NULL,
	[Gender] [nvarchar](max)  NULL,
	[Age] [nvarchar](max)  NULL,
	[Rating] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactInvoicedetailsfinal]
( 
	[Reporting Month] [datetime]  NULL,
	[Invoice Number] [nvarchar](30)  NULL,
	[Invoice Date] [nvarchar](30)  NULL,
	[TaxpayerID] [nvarchar](30)  NULL,
	[Sold-To State] [nvarchar](30)  NULL,
	[TaxableAmount] [money]  NULL,
	[TaxAmount] [money]  NULL,
	[SKU Number] [nvarchar](30)  NULL,
	[Sector] [nvarchar](50)  NULL,
	[FlaggedproductCategory] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactInvoicedetailsfinals]
( 
	[Reporting Month] [datetime]  NULL,
	[Invoice Number] [nvarchar](30)  NULL,
	[Invoice Date] [datetime]  NULL,
	[TaxpayerID] [nvarchar](30)  NULL,
	[Sold-To State] [nvarchar](30)  NULL,
	[TaxableAmount] [money]  NULL,
	[TaxAmount] [money]  NULL,
	[SKU Number] [nvarchar](30)  NULL,
	[Sector] [nvarchar](50)  NULL,
	[FlaggedproductCategory] [int]  NULL,
	[TaxAnomaliesTypes] [varchar](50)  NULL,
	[VATTarget] [numeric](23,6)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactInvoicedetailsIDpTA]
( 
	[Reporting Month] [datetime]  NULL,
	[Invoice Number] [nvarchar](30)  NULL,
	[Invoice Date] [nvarchar](30)  NULL,
	[TaxpayerID] [nvarchar](30)  NULL,
	[Sold-To State] [nvarchar](30)  NULL,
	[TaxableAmount] [money]  NULL,
	[TaxAmount] [money]  NULL,
	[SKU Number] [nvarchar](30)  NULL,
	[Sector] [nvarchar](50)  NULL,
	[FlaggedproductCategory] [int]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactInvoices]
( 
	[Designation] [varchar](50)  NULL,
	[TaxpayerID] [varchar](50)  NULL,
	[Address] [varchar](100)  NULL,
	[Region] [varchar](30)  NULL,
	[State] [varchar](30)  NULL,
	[Industry] [varchar](30)  NULL,
	[TaxableAmount] [money]  NULL,
	[TaxAmount] [money]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[FactInvoicesData]
( 
	[Designation] [varchar](50)  NULL,
	[TaxpayerID] [varchar](50)  NULL,
	[Address] [varchar](100)  NULL,
	[Region] [varchar](30)  NULL,
	[State] [varchar](30)  NULL,
	[Industry] [varchar](30)  NULL,
	[TaxableAmount] [money]  NULL,
	[TaxAmount] [money]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Fintaxtransaction]
( 
	[TranID] [bigint]  NOT NULL,
	[Invoice Date] [datetime]  NULL,
	[Invoice No ] [varchar](30)  NULL,
	[Invoice Name] [varchar](30)  NULL,
	[TaxpayerID] [varchar](30)  NULL,
	[location] [varchar](30)  NULL,
	[Industry] [varchar](30)  NULL,
	[Item Price] [float]  NULL,
	[Item Qty] [float]  NULL,
	[Item Discount] [float]  NULL,
	[Item VAT %] [float]  NULL,
	[Item VAT] [float]  NULL,
	[Item Net Price] [float]  NULL
)
WITH
(
	DISTRIBUTION = HASH ( [TaxpayerID] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Industry]
( 
	[id] [int]  NULL,
	[Sector] [varchar](30)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[iot-foottraffic-data]
( 
	[RecordedOn] [nvarchar](max)  NULL,
	[before-foottraffic] [bigint]  NULL,
	[after-foottraffic] [bigint]  NULL,
	[EventProcessedUtcTime] [datetime2](7)  NULL,
	[PartitionId] [bigint]  NULL,
	[EventEnqueuedUtcTime] [datetime2](7)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Location]
( 
	[id] [int]  NULL,
	[Sold-To State] [varchar](20)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiTaxCustSatMonthly]
( 
	[year] [int]  NULL,
	[month] [int]  NULL,
	[latitude] [decimal](11,8)  NULL,
	[longitude] [decimal](11,9)  NULL,
	[admin_name] [nvarchar](max)  NULL,
	[excellent_sentiment] [decimal](4,2)  NULL,
	[good_sentiment] [decimal](4,2)  NULL,
	[negative_sentiment] [decimal](4,2)  NULL,
	[neutral_sentiment] [decimal](4,2)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[pbiTaxDetailMonthly]
( 
	[ID] [nvarchar](max)  NULL,
	[MonthUpdatedOn] [nvarchar](max)  NULL,
	[YearUpdatedOn] [nvarchar](max)  NULL,
	[IncomeTax] [nvarchar](max)  NULL,
	[TargetIncomeTax] [nvarchar](max)  NULL,
	[ValueAddedTax] [nvarchar](max)  NULL,
	[TargetValueAddedTax] [nvarchar](max)  NULL,
	[CorporationTax] [nvarchar](max)  NULL,
	[TargetCorporationTax] [nvarchar](max)  NULL,
	[DigitalCsat] [nvarchar](max)  NULL,
	[DigitalCsatTarget] [nvarchar](max)  NULL,
	[DigitalCsatPredicted] [nvarchar](max)  NULL,
	[PhysicalCsat] [nvarchar](max)  NULL,
	[PhysicalCsatTarget] [nvarchar](max)  NULL,
	[PhysicalCsatPredicted] [nvarchar](max)  NULL,
	[CustomerComplaints] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Source]
( 
	[id] [int]  NULL,
	[Name] [varchar](10)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[StagingFintaxtransaction]
( 
	[Invoice Date] [datetime]  NULL,
	[Invoice No ] [varchar](30)  NULL,
	[Invoice Name] [varchar](30)  NULL,
	[TaxpayerID] [varchar](30)  NULL,
	[location] [varchar](30)  NULL,
	[Industry] [varchar](30)  NULL,
	[Item Price] [float]  NULL,
	[Item Qty] [float]  NULL,
	[Item Discount] [float]  NULL,
	[Item VAT %] [float]  NULL,
	[Item VAT] [float]  NULL,
	[Item Net Price] [float]  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TaxpayerSatisfactionMetrics]
( 
	[Month] [nvarchar](max)  NULL,
	[Taxpayer Satisfaction] [nvarchar](max)  NULL,
	[Taxpayer Satisfaction Prior Month] [nvarchar](max)  NULL,
	[Predicted Taxpayer Satisfaction] [nvarchar](max)  NULL,
	[Time to Comply VAT (Hrs)] [nvarchar](max)  NULL,
	[Taxpayer Satisfaction Target (Hrs)] [nvarchar](max)  NULL,
	[Annual Taxpayer Satisfaction Target] [nvarchar](max)  NULL,
	[Time to Comply VAT Target] [nvarchar](max)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[temp]
( 
	[Reporting Month] [datetime]  NULL,
	[Invoice Number] [nvarchar](30)  NULL,
	[Invoice Date] [nvarchar](30)  NULL,
	[TaxpayerID] [nvarchar](30)  NULL,
	[Sold-To State] [nvarchar](30)  NULL,
	[TaxableAmount] [money]  NULL,
	[TaxAmount] [money]  NULL,
	[SKU Number] [nvarchar](30)  NULL,
	[Sector] [nvarchar](50)  NULL,
	[FlaggedproductCategory] [int]  NULL,
	[TaxAnomaliesTypes] [varchar](50)  NULL,
	[VATTarget] [numeric](23,6)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TRF-Social-Data]
( 
	[TwitterData] [nvarchar](4000)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[VAT_Daily]
( 
	[ID] [int]  NULL,
	[ReportingPeriod] [varchar](30)  NULL,
	[IncomeTax] [money]  NULL,
	[IncomeTaxTarget] [money]  NULL,
	[ValueAddedTax] [money]  NULL,
	[ValueAddedTaxTarget] [money]  NULL,
	[CorporationTax] [money]  NULL,
	[CorporationTaxTarget] [money]  NULL,
	[location] [varchar](30)  NULL,
	[Industries] [varchar](30)  NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO