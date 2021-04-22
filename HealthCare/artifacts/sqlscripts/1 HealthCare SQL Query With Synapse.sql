/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md
-- Lets check Observation table record counts.
SELECT FORMAT(COUNT_BIG(1),'#,0') as [Records Count]  FROM dbo.Observations WITH (NOLOCK)

--complex query on 50B records
SET NOCOUNT ON 
SELECT 
  COUNT_BIG(1) TotalEncounters, 
  Sum(E.Total_Claim_cost) AS TotalClaim, 
  P.State, 
  P.City, 
  EncounterClass 
FROM 
  Observations AS O 
  INNER JOIN SynEncounter AS E ON E.Id = O.Encounter 
  INNER JOIN [SynPatientsFinal] AS P ON P.Id = E.Patient 
WHERE 
  O.[IsOrignal] = 1 
  AND e.START > '01/01/2019' 
GROUP BY 
  P.State, 
  P.City, 
  EncounterClass
