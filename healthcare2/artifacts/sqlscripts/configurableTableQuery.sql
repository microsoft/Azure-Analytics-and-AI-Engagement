CREATE TABLE [dbo].[Chat Bot]
( 
	[URL] [varchar](400)  NULL,
	[URL 1] [varchar](400)  NULL
)

INSERT INTO [Chat Bot] ([URL], [URL 1])
VALUES ('<!DOCTYPE html><html><body><iframe sandbox="allow-same-origin allow-scripts" style="width: 375px; height: 608px; border: 0px;" src="#OPEN_AI_APP_ENDPOINT#" title="Chat Bot"></iframe></body></html>', '#OPEN_AI_APP_ENDPOINT#');

CREATE TABLE [dbo].[Chat Bot Global Safety]
( 
	[URL] [varchar](400)  NULL
)

INSERT INTO [Chat Bot Global Safety] ([URL])
VALUES ('<!DOCTYPE html><html><body><iframe sandbox="allow-same-origin allow-scripts" style="width: 446px; height: 751px; border: 0px;" src="#OPEN_AI_APP_ENDPOINT#/#/incident-report" title="Chat Bot"></iframe></body></html>');

CREATE TABLE [patientData]
(
    [Patient Ref Id]	VARCHAR(512),
    [subject.reference]	VARCHAR(512),
    Name	VARCHAR(512),
    [Image URL]	VARCHAR(512)
);

INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/1fc861ee-7a5c-8e81-ef88-fbba459d387f', 'Patient/1fc861ee-7a5c-8e81-ef88-fbba459d387f', 'Leandro Lind', '');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/26c4d6de-07c8-ba91-6f90-3cde926f0073', 'Patient/26c4d6de-07c8-ba91-6f90-3cde926f0073', 'Nathan Jacobson', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Nathan Jacobson 21 white.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/325aa9e0-e64f-9158-582b-9b52dc40afa4', 'Patient/325aa9e0-e64f-9158-582b-9b52dc40afa4', 'Julee Paucek', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Julee Paucek 82 white.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/75f2b39e-6fae-7451-7667-c8737a7e66f7', 'Patient/75f2b39e-6fae-7451-7667-c8737a7e66f7', 'Cornelia Gleichner', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Cornelia Gleichner.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/88506867-cb4f-e394-1baf-93e988f44d1a', 'Patient/88506867-cb4f-e394-1baf-93e988f44d1a', 'Grady Goyette', '');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/8cb95294-68d7-2adf-4702-6345dbdaaeb4', 'Patient/8cb95294-68d7-2adf-4702-6345dbdaaeb4', 'Gilberto de Anda', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Gilberto de Anda.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/8e06a5ff-30fa-2657-4cba-9c265121f4db', 'Patient/8e06a5ff-30fa-2657-4cba-9c265121f4db', 'Nicol Beier', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Nicol Beier 61 White.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/a592157a-9af4-0bb5-533c-aad9cacb4935', 'Patient/a592157a-9af4-0bb5-533c-aad9cacb4935', 'Keshia Kozey', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Keshia Kozey.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/bb8fe0d5-33c0-7eeb-c4f0-58b706c0b501', 'Patient/bb8fe0d5-33c0-7eeb-c4f0-58b706c0b501', 'Andres Effertz', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Andres Effertz.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/be39a45c-8290-5b06-91fa-81217b0cf056', 'Patient/be39a45c-8290-5b06-91fa-81217b0cf056', 'Eustolia Romaguera', '');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/c4249e66-ed88-9c91-353a-302ff81c80a7', 'Patient/c4249e66-ed88-9c91-353a-302ff81c80a7', 'Omar Ward', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Omar Ward.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/f7b0f737-f877-56d5-e5ad-5486dae34abc', 'Patient/f7b0f737-f877-56d5-e5ad-5486dae34abc', 'Edmund Sanford', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Edmund Sanford.png');
INSERT INTO [patientData] ([Patient Ref Id], [subject.reference], Name, [Image URL]) VALUES ('Patient/fce90956-57be-4ec8-ad68-dccfc5129ad1', 'Patient/fce90956-57be-4ec8-ad68-dccfc5129ad1', 'Reta Taylor', 'https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/sthealthcare2/Patient Images/Reta Taylor.png');

