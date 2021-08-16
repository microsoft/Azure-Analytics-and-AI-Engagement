/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

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
