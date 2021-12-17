#blob output folder and connection string for first notebook
CONNECTIONSTRING_first = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
CONTAINER_NAME_first = 'fraud-detection-sample-nyrealestate'
BLOBNAME_first = 'Fraud_Detection_NYC_Data.csv'

#blob output folder and connection string for second notebook
CONNECTIONSTRING_second = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
CONTAINER_NAME_second = 'fraud-detection-sample-nyrealestate'
BLOBNAME_second = 'Fraud_Detection_NYC_Data.csv'

#blob output folder and connection string for third notebook
INPUT_CONTAINER = "formrecogfiles"
CONNECTION_STRING_third = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'

#form recognizer endpoint, credential, model id and client variable
endpoint = "#FORM_RECOGNIZER_ENDPOINT#"
credential = "#FORM_RECOGNIZER_API_KEY#"
model_id = "#FORM_RECOGNIZER_MODEL_ID#"
