CREATE OR ALTER PROCEDURE [dbo].[find_relevant_products]
@text NVARCHAR(MAX),
@top INT = 10,
@min_similarity DECIMAL(19,16) = 0.50,
@JsonResults NVARCHAR(MAX) OUTPUT
AS
BEGIN
    IF (@text IS NULL) RETURN;

    DECLARE @RefinedQuery NVARCHAR(MAX);
    DECLARE @LLMResponse NVARCHAR(MAX);
    DECLARE @LLMRetval INT;
    DECLARE @LLMPayload NVARCHAR(MAX);

    SET @LLMPayload = 
    N'{
        "model": "gpt-4",
        "messages": [
            {
                "role": "system",
                "content": "You are an assistant that extracts the core product keyword(s) from a user''s query."
            },
            {
                "role": "user",
                "content": "Extract the key product name or keywords from the following query: ' 
                + REPLACE(@text, '"', '\"') + '"
            }
        ],
        "temperature": 0.5,
        "max_tokens": 20
    }';

    EXEC @LLMRetval = sp_invoke_external_rest_endpoint
         @url = '+++@lab.Variable(endpointurl)+++/openai/deployments/gpt-4/chat/completions?api-version=2024-08-01-preview',
         @method = 'POST',
         @credential = [+++@lab.Variable(endpointurl)+++],
         @payload = @LLMPayload,
         @response = @LLMResponse OUTPUT;

    -- Extract the refined query from the LLM response JSON
    SET @RefinedQuery = JSON_VALUE(@LLMResponse, '$.result.choices[0].message.content');
					
								   
																		
		
								 
			
				
 

    IF (@RefinedQuery IS NULL OR LEN(@RefinedQuery) = 0)
        SET @RefinedQuery = @text;


    DECLARE @retval INT, @qv VECTOR(1536);

    EXEC @retval = dbo.get_embedding @RefinedQuery, @qv OUTPUT;

    IF (@retval != 0) RETURN;

    WITH cteSimilarEmbeddings AS (
        SELECT TOP(@top)
            pe.ProductName AS ProductName,
            pe.Description AS Description,
            vector_distance('euclidean', pe.[EmbeddedName], @qv) AS distance
        FROM dbo.Product_Embeddings pe
        ORDER BY distance
    )

    SELECT @JsonResults = (
        SELECT 
            -- p.id AS ProductId,
            p.ProductName AS ProductName
            -- p.description AS ProductDescription,
            -- p.price AS ProductPrice,
            -- 1 - distance AS CosineSimilarity
	
        FROM cteSimilarEmbeddings se
		  
        INNER JOIN dbo.dim_products p ON se.ProductName = p.ProductName
	 
        WHERE 1 - distance >= @min_similarity
		
        ORDER BY distance
        FOR JSON AUTO, ROOT('search_results')
    );
END;