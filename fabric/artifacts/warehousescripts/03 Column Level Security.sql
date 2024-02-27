/*  Column-level security feature in Microsoft Fabric simplifies the design and coding of security in application. 
    It ensures column level security by restricting column access to protect sensitive data. */
--Step 1: Let us see how this feature in Microsoft Fabric works. Before that let us have a look at the CampaignAnalysis table. 
select  Top 100 * from [Sales_DW].[dbo].[FactCampaignAnalytics]


-- Step:2 Now let us enforcing column level security . 
/*  Let us see how.
    The FactCampaignAnalytics table in the warehouse has information like Region, Country, ProductCategory, Campaign_Name,Cost,ROI,Revenue_Target , and Revenue.
    Of all the information, Revenue generated from every campaign is a classified one and should be hidden from DataAnalystMiami.
    To conceal this information, we execute the following query: */
GRANT SELECT ([Country], [Region], [ProductCategory], [Campaign_Name], [Cost], [ROI]) ON [Sales_DW].[dbo].FactCampaignAnalytics 
TO "<Create_a_new_user_and_replace_the_userId_within_double_quotes>"


-- Step:3 Then, to check if the security has been enforced, we execute the following query with the new user created.

Select * from [Sales_DW].dbo.FactCampaignAnalytics
