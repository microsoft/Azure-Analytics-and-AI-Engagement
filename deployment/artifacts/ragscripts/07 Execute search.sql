DECLARE @UserSessionID UNIQUEIDENTIFIER = NEWID();
DECLARE @AIResponse NVARCHAR(MAX);

EXEC dbo.get_ai_response @UserSessionID, 'Find me AlphaPhone', @AIResponse OUTPUT;
SELECT @AIResponse AS GPT_Response;