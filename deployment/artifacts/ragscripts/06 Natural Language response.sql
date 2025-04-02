CREATE OR ALTER PROCEDURE dbo.get_ai_response
@UserSessionID UNIQUEIDENTIFIER,
@UserQuery NVARCHAR(MAX),
@AIResponse NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @SearchResults NVARCHAR(MAX);

    -- Step 1: Fetch relevant products
    EXEC dbo.find_relevant_products @UserQuery, 10, 0.50, @SearchResults OUTPUT;

    -- Step 2: Ensure @SearchResults is not NULL or empty
    IF @SearchResults IS NULL OR LEN(@SearchResults) = 0
        SET @SearchResults = '{"search_results":[]}';  -- Prevent NULL errors

    DECLARE @CleanSearchResults NVARCHAR(MAX);
    SET @CleanSearchResults = REPLACE(@SearchResults, '"', '\"');

    -- Debugging: Display the search results before making API call
    -- SELECT @SearchResults AS DebugSearchResults;

    -- Step 3: Construct JSON payload correctly
    DECLARE @Payload NVARCHAR(MAX);
    SET @Payload = 
    N'{
        "model": "gpt-4",
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful assistant providing structured product summaries in a clean, readable format. Use bullet points, avoid excessive markdown (like ### or ***), and remove redundant blank lines. Make responses interactive by encouraging the user to choose."
            },
            {
                "role": "user",
                "content": "Based on the following product search results, generate a structured yet conversational summary with emojis, bullet points, and minimal empty lines:\n\n' + @CleanSearchResults + '"
            }
        ],
        "temperature": 0.7,
        "max_tokens": 300
    }';

    -- Debugging: Display the payload before calling OpenAI API
    -- SELECT @Payload AS DebugPayload;

    -- Step 4: Call Azure OpenAI API
    DECLARE @retval INT, @response NVARCHAR(MAX);
    
    EXEC @retval = sp_invoke_external_rest_endpoint
        @url = '+++@lab.Variable(endpointurl)+++/openai/deployments/gpt-4/chat/completions?api-version=2024-08-01-preview',
        @method = 'POST',
        @credential = [+++@lab.Variable(endpointurl)+++],
        @payload = @Payload,
        @response = @AIResponse OUTPUT;

    DECLARE @NaturalLanguageResponse NVARCHAR(MAX);
    SET @NaturalLanguageResponse = JSON_VALUE(@AIResponse, '$.result.choices[0].message.content');

    -- Step 5: Split AI response into separate messages and store in ChatMessages
    DECLARE @Pos INT = 1, @Line NVARCHAR(MAX), @Delimiter NVARCHAR(2) = CHAR(10);
    
    -- Step 6: Store the structured response in the database
    INSERT INTO dbo.ChatMessages (UserSessionID, MessageType, MessageText)
    VALUES (@UserSessionID, 'User', @UserQuery);

    -- Loop through AI response, splitting it into rows
    WHILE CHARINDEX(@Delimiter, @NaturalLanguageResponse, @Pos) > 0
    BEGIN
        SET @Line = LEFT(@NaturalLanguageResponse, CHARINDEX(@Delimiter, @NaturalLanguageResponse, @Pos) - 1);
        SET @NaturalLanguageResponse = STUFF(@NaturalLanguageResponse, 1, CHARINDEX(@Delimiter, @NaturalLanguageResponse, @Pos), '');

        -- Store each line separately
        INSERT INTO dbo.ChatMessages (UserSessionID, MessageType, MessageText)
        VALUES (@UserSessionID, 'AI', @Line);
    END;

    -- Store any remaining text
    IF LEN(@NaturalLanguageResponse) > 0
    BEGIN
        INSERT INTO dbo.ChatMessages (UserSessionID, MessageType, MessageText)
        VALUES (@UserSessionID, 'AI', @NaturalLanguageResponse);
    END;

    -- Step 6: Return AI response as multiple rows
    SELECT 
        CASE 
            WHEN MessageType = 'User' THEN 'User: ' + MessageText
            WHEN MessageType = 'AI' THEN 'AI: ' + MessageText
        END AS ChatMessage
    FROM dbo.ChatMessages
    WHERE UserSessionID = @UserSessionID
    ORDER BY CreatedAt ASC;
END;