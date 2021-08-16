/******Important – Do not use in production, for demonstration purposes only – please review the legal notices by clicking the following link****/
---DisclaimerLink:  https://healthcaredemoapp.azurewebsites.net/#/disclaimer
---License agreement: https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/HealthCare/License.md

/* **DISCLAIMER**
By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code: (1) is not subject to SOC 1 and SOC 2 compliance audits; (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional; (3) is not designed, intended or made available as a medical device; and (4) is not designed or intended to be a substitute for professional medical advice, diagnosis, treatment or judgement. Do not use this code to replace, substitute, or provide professional financial advice or judgment, or to replace, substitute or provide medical advice, diagnosis, treatment or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part. */

/* Materialized View also know as snapshots in Azure Synapse is Snapshots acts like a physical table 
because data from snapshots are storing in to physical memory.Snapshot retrieves data very fast.
So for performance tuning Snapshots are used
Let's see how we can implement this in Azure Synapse.*/

--Step 1 MV_PatientDetails is a Materialized view that count the number of patients city wise.
DROP view IF EXISTS MV_PatientDetails
GO
Create MATERIALIZED view MV_PatientDetails
WITH (distribution = HASH(city),FOR_APPEND)
as
select count(Id) as patient_count,city from dbo.synpatient
WHERE city is NOT NULL
group by city

--Step 2 City wise patient count
select patient_count,city from MV_PatientDetails

--Step 3 We can filter data for any specific city
select patient_count,city from MV_PatientDetails WHERE city='New Boston'