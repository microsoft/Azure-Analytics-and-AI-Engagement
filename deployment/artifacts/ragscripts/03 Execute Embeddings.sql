-- Step 1: Create a temporary table to store the results
CREATE TABLE dbo.Product_Embeddings (
    ProductName NVARCHAR(MAX),
	Description NVARCHAR (MAX),
    EmbeddedName VECTOR(1536)
);

CREATE TABLE dbo.ChatMessages (
    MessageID INT IDENTITY(1,1) PRIMARY KEY,
    UserSessionID UNIQUEIDENTIFIER,
    MessageType NVARCHAR(10),  -- 'User' or 'AI'
    MessageText NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- Step 2: Declare variables for the procedure output
DECLARE @ProductName NVARCHAR(MAX);
DECLARE @Description NVARCHAR(MAX);
DECLARE @Embedding VECTOR(1536);

-- Step 3: Loop through the dimproduct table
DECLARE ProductCursor CURSOR FOR
SELECT ProductName, Description
FROM dbo.dim_products;

OPEN ProductCursor;

FETCH NEXT FROM ProductCursor INTO @ProductName, @Description;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Execute the procedure for each row
    EXEC [dbo].[get_embedding]
        @inputText = @ProductName,
        @embedding = @Embedding OUTPUT;

    -- Insert the result into the ProductEmbeddings table
    INSERT INTO dbo.Product_Embeddings (ProductName, Description, EmbeddedName)
    VALUES (@ProductName, @Description, @Embedding);

    -- Fetch the next row
    FETCH NEXT FROM ProductCursor INTO @ProductName, @Description;
END;

CLOSE ProductCursor;
DEALLOCATE ProductCursor;