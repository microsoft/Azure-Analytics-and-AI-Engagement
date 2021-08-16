/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

 --JSON Extractor 
    --First, Azure Synapse enables you to store JSON in standard textual format, use standard SQL language for querying JSON data
        SELECT top (100) * from  dbo.[TwitterRawData] 


 -- Second, let's take JSON data and extract specific structured columns.

 SELECT   
       JSON_VALUE( TwitterData,'$.Time') AS Time, 
       JSON_VALUE( TwitterData,'$.Hashtag') AS Hashtag, 
       JSON_VALUE( TwitterData,'$.Tweet') AS Tweet, 
       JSON_VALUE( TwitterData,'$.City') AS City , 
       JSON_VALUE( TwitterData,'$.Sentiment') AS Sentiment , 
       JSON_VALUE( TwitterData,'$.Language') AS Language  
FROM dbo.[TwitterRawData] WHERE    ISJSON(TwitterData) > 0 

--## Third, let's filter for #sunglasses.
    --The query below fetches JSON data and filters it by hashtag.<br>
    --Please note, this extracts specific columns in a structured format

SELECT   
       JSON_VALUE( TwitterData,'$.Time') AS Time, 
       JSON_VALUE( TwitterData,'$.Hashtag') AS Hashtag, 
       JSON_VALUE( TwitterData,'$.Tweet') AS Tweet, 
       JSON_VALUE( TwitterData,'$.City') AS City , 
       JSON_VALUE( TwitterData,'$.Sentiment') AS Sentiment , 
       JSON_VALUE( TwitterData,'$.Language') AS Language  
FROM dbo.[TwitterRawData]  
WHERE    ISJSON(TwitterData) > 0 And JSON_VALUE( TwitterData,'$.Hashtag')='#sunglasses'


-- petsa
select * from (
SELECT   
       JSON_VALUE( TwitterData,'$.Time') AS Time, 
       JSON_VALUE( TwitterData,'$.Hashtag') AS Hashtag, 
       JSON_VALUE( TwitterData,'$.Tweet') AS Tweet, 
       JSON_VALUE( TwitterData,'$.City') AS City , 
       JSON_VALUE( TwitterData,'$.Sentiment') AS Sentiment , 
       JSON_VALUE( TwitterData,'$.Language') AS Language  
FROM dbo.[TwitterRawData]  
WHERE    ISJSON(TwitterData) > 0) as sub
where sub.Hashtag = '#sunglasses'


