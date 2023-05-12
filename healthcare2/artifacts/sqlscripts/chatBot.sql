CREATE TABLE [dbo].[Chat Bot]
( 
	[URL] [varchar](400)  NULL,
	[URL 1] [varchar](400)  NULL
)

INSERT INTO [Chat Bot] ([URL], [URL 1])
VALUES ('<!DOCTYPE html><html><body><iframe sandbox="allow-same-origin allow-scripts" style="width: 375px; height: 608px; border: 0px;" src="#OPEN_AI_ENDPOINT#" title="Chat Bot"></iframe></body></html>', '#OPEN_AI_ENDPOINT#');
