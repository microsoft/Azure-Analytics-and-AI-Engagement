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


