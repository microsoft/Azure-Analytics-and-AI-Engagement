CREATE TABLE [dbo].[SalesDataAfterCampaign](
    [Quantity]	INT,
    [Advert]	VARCHAR(512),
    [Price]	FLOAT,
    [Brand]	VARCHAR(512)
);

INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('11225', '1', '2.470000', '0');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('10225', '1', '2.300000', '1');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('11365', '1', '2.270000', '0');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('13315', '0', '2.170000', '0');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('14317', '1', '2.670000', '1');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('17325', '1', '2.110000', '2');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('14317', '1', '2.670000', '1');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('17129', '1', '2.810000', '0');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('19064', '0', '2.990000', '0');
INSERT INTO [dbo].[SalesDataAfterCampaign] ([Quantity], [Advert], [Price], [Brand]) VALUES ('23064', '0', '2.920000', '1');


CREATE TABLE [dbo].[pbiPatientPredictiveSetv4] 
(
    [hospital_id]	VARCHAR(512),
    [department_id]	INT,
    [city]	VARCHAR(512),
    [patient_age]	INT,
    [risk_level]	VARCHAR(512),
    [acute_type]	VARCHAR(512),
    patient_category	VARCHAR(512),
    doctor_id	INT,
    length_of_stay	INT,
    wait_time	INT,
    type_of_stay	VARCHAR(512),
    treatment_cost	INT,
    claim_cost	INT,
    drug_cost	INT,
    hospital_expense	INT,
    follow_up	VARCHAR(512),
    readmitted_patient	VARCHAR(512),
    payment_type	VARCHAR(512),
    [date]	VARCHAR(512),
    [month]	VARCHAR(512),
    [year]	INT,
    reason_for_readmission	VARCHAR(512),
    disease	VARCHAR(512),
    Actual_Flag	VARCHAR(512),
    Predicted_Flag	VARCHAR(512),
    Prediction_Probability	FLOAT,
    Actual_Readmission_Rate	FLOAT,
    Predicted_Readmission_Rate	FLOAT
);

INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('27', '5', 'Anchorage', '71', '1', 'Non Acute', 'InPatient', '7032', '2', '45', 'Surgical', '4714', '4619', '755', '4536', '0', '0', 'Private Insurance', '03-10-2020 09:43', 'Oct', '2020', '', 'endometriosis', 'FALSE', 'FALSE', '0.254890071', '3.22705314', '4.03');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('2', '3', 'Chicago', '16', '5', 'Acute', 'InPatient', '12876', '7', '38', 'Medical', '6037', '5855', '665', '5829', '1', '0', 'Medicare', '16-04-2020 12:15', 'Apr', '2020', '', 'bypass', 'FALSE', 'TRUE', '0.5334988', '6.631351776', '41.50480675');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('2', '5', 'Chicago', '51', '2', 'Non Acute', 'InPatient', '6628', '2', '45', 'Surgical', '4238', '3687', '467', '4040', '1', '0', 'Private Insurance', '24-07-2020 06:00', 'Jul', '2020', '', 'endometriosis', 'FALSE', 'FALSE', '0.359224657', '5.748865356', '41.70448815');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('1', '6', 'Los Angeles', '63', '5', 'Acute', 'InPatient', '12176', '5', '39', 'Surgical', '6110', '4888', '611', '5930', '1', '0', 'Private Insurance', '05-05-2020 13:24', 'May', '2020', '', 'alzheimer', 'FALSE', 'TRUE', '0.557851161', '5.567322239', '32.0927887');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('2', '7', 'Chicago', '30', '2', 'Non Acute', 'InPatient', '8550', '4', '46', 'Surgical', '6314', '5556', '758', '6088', '1', '0', 'Medicaid', '11-02-2020 00:35', 'Feb', '2020', '', 'sinusitis', 'FALSE', 'FALSE', '0.355186005', '4.521829522', '39.77823978');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('1', '7', 'Los Angeles', '23', '1', 'Non Acute', 'InPatient', '13397', '2', '50', 'Medical', '5015', '4563', '703', '4841', '0', '0', 'Private Insurance', '26-05-2020 09:55', 'May', '2020', '', 'flu', 'FALSE', 'FALSE', '0.289163266', '5.567322239', '32.0927887');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('1', '6', 'Los Angeles', '27', '4', 'Acute', 'InPatient', '11695', '4', '37', 'Medical', '6724', '6320', '673', '6478', '1', '0', 'Private Insurance', '09-10-2020 06:39', 'Oct', '2020', '', 'chronic headache', 'FALSE', 'TRUE', '0.547212383', '1.694373402', '2.24');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('9', '7', 'Honolulu', '37', '4', 'Acute', 'InPatient', '912', '3', '50', 'Medical', '5343', '5236', '855', '5173', '0', '0', 'Private Insurance', '13-06-2020 16:48', 'Jun', '2020', '', 'sinusitis', 'FALSE', 'TRUE', '0.592014789', '11.99119912', '42.3679868');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('2', '1', 'Chicago', '70', '1', 'Non Acute', 'InPatient', '11843', '8', '34', 'Medical', '6230', '5544', '810', '5999', '0', '0', 'Medicare', '14-07-2020 07:12', 'Jul', '2020', '', 'chemotherapy', 'FALSE', 'FALSE', '0.302106334', '5.748865356', '41.70448815');
INSERT INTO [dbo].[pbiPatientPredictiveSetv4] ([hospital_id], [department_id], [city], [patient_age], [risk_level], [acute_type], patient_category, doctor_id, length_of_stay, wait_time, type_of_stay, treatment_cost, claim_cost, drug_cost, hospital_expense, follow_up, readmitted_patient, payment_type, [date], [month], [year], reason_for_readmission, disease, Actual_Flag, Predicted_Flag, Prediction_Probability, Actual_Readmission_Rate, Predicted_Readmission_Rate) VALUES ('2', '2', 'Chicago', '38', '4', 'Acute', 'InPatient', '6928', '6', '42', 'Surgical', '6491', '5452', '650', '6263', '0', '0', 'Private Insurance', '14-03-2020 14:29', 'Mar', '2020', '', 'knee osteoarthritis', 'FALSE', 'TRUE', '0.54318873', '6.293706294', '44.04475524');
