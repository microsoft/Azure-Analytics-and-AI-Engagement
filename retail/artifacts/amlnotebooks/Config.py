#### Global
STORAGE_ACCOUNT_CONNECTION_STRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
CONTAINER_NAME = 'retail-notebook-data'
ACCOUNT_KEY = '#STORAGE_ACCOUNT_KEY#'

subscription_id= "#SUBSCRIPTION_ID#"
resource_group= "#RESOURCE_GROUP#"
workspace_name= "#WORKSPACE_NAME#"
COMPUTE_AIML = '#COMPUTE_NAME#'

### Incident Forms
STORAGE_ACCOUNT_CONNECTION_STRING_INCIDENT_FORMS='DefaultEndpointsProtocol=https;AccountName=stretaildemodev;AccountKey=bMS5qLiRXdMA4To20LPGs2ySw7lzlT00r8zSH+ZKlD9eTCSBFZMhquPCeCYCvSxQUx8YuJaW+KNvVvsertQXhQ==;EndpointSuffix=core.windows.net'

### Language Translation
TRANSLATION_API_KEY = "a28b0661e1d841c29e6386adb0547acb"
TRANSLATION_URL = "https://westus2.cognitiveservices.azure.com/translator/text/v3.0/translate?api-version=3.0&to="

# Customer Churn
CustomerChurnCONNECTIONSTRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
CustomerChurnCONTAINER_NAME = 'customer-churn-data'

CustomerChurnBLOBNAME = 'CustomerChurn.csv'
CCBLOBNAME = 'online_retail_II.csv'

# Market Basket
MBCONNECTIONSTRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
MBCONTAINER_NAME = 'market-basket'

# Price Suggestion
PSCONNECTIONSTRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
PSCONTAINER_NAME = 'retail-notebook-data'
PSBLOBNAME = 'train.tsv'

#form recognizer endpoint, credential, model id and client variable
endpoint = "#FORM_RECOGNIZER_ENDPOINT#"
credential = "#FORM_RECOGNIZER_API_KEY#"
model_id = "#FORM_RECOGNIZER_MODEL_ID#"
