
/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part.  */

-- select TOP 10 publishDate
-- from openrowset(
--     bulk 'https://#STORAGE_ACCOUNT#.blob.core.windows.net/esg-migrate/gdelt.parquet/*.parquet',
--     format = 'parquet') as rows

    -- EXEC sp_describe_first_result_set N'
	-- SELECT
    --     *
	-- FROM 
	-- 	OPENROWSET(
    --     	BULK ''https://#STORAGE_ACCOUNT#.blob.core.windows.net/esg-migrate/gdelt.parquet/*.parquet'',
	--         FORMAT=''PARQUET''
    -- 	) AS gdelt';


--   CREATE TABLE FSIRiskDW .gdelt
--   (
--        gkgRecordId    varchar(8000),
--        publishDate    datetime2(7), 
--        sourceCollectionIdentifier varchar(8000),
--        documentIdentifier varchar(8000),
--        counts varchar(8000),
--        enhancedCounts varchar(8000),
--        themes varchar(8000),
--        enhancedThemes varchar(8000),
--        locations varchar(8000),
--        enhancedLocations varchar(8000),
--        persons varchar(8000),
--        enhancedPersons varchar(8000),
--        organisations varchar(8000),
--        enhancedOrganisations varchar(8000),
--        tone varchar(8000),
--        enhancedDates varchar(8000),
--        gcams varchar(8000),
--        sharingImage varchar(8000),
--        relatedImages varchar(8000),
--        socialImageEmbeds varchar(8000),
--        socialVideoEmbeds varchar(8000),
--        quotations varchar(8000),
--        allNames varchar(8000),
--        amounts varchar(8000),
--        translationInfo varchar(8000),
--        extrasXML varchar(8000)
--   )

