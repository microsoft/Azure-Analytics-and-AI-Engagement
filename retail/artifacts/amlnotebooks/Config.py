#### Global
STORAGE_ACCOUNT_CONNECTION_STRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
CONTAINER_NAME = 'retail-notebook-data'
ACCOUNT_KEY = '#STORAGE_ACCOUNT_KEY#'

HEALTHCARE_CONNECTION_STRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
HEALTHCARE_CONTAINER_NAME = 'retail-notebook-data'

SUBSCIPTION_ID= "#SUBSCRIPTION_ID#"
RESOURCE_GROUP= "#RESOURCE_GROUP_NAME#"
WORKSPACE_NAME= "#WORKSPACE_NAME#"
COMPUTE_AIML = '#WORKSPACE_NAME#'


### Incident Forms
STORAGE_ACCOUNT_CONNECTION_STRING_INCIDENT_FORMS='DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'

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

MBBLOBNAME = 'transaction_data.csv'
# -

# Price Suggestion
PSCONNECTIONSTRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'
PSCONTAINER_NAME = 'retail-notebook-data'
PSBLOBNAME = 'train.tsv'

#### Wait Time Forecasting
WAIT_TIME_DATASTORE_NAME="wait_time_prediction_store"
WAIT_TIME_INPUT_FILE_NAME="/pbiPatientPredictiveSet.csv"
WAIT_TIME_STORAGE_ACCOUNT_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=sthealthcareprod001;AccountKey=Qyjt+3JvJggDa6Z7zdm4YMAe5Gofc07nRSo4pxT2Sx5d/owzPTIGst6MRPq9UyCoVKK8FSF+pHFWP+bv1VbhIA==;EndpointSuffix=core.windows.net"
WAIT_TIME_STORAGE_ACCOUNT_NAME="sthealthcareprod001"
WAIT_TIME_STORAGE_ACCOUNT_KEY="Qyjt+3JvJggDa6Z7zdm4YMAe5Gofc07nRSo4pxT2Sx5d/owzPTIGst6MRPq9UyCoVKK8FSF+pHFWP+bv1VbhIA=="
WAIT_TIME_GLOBAL_CONTAINER_NAME="predictiveanalytics"
WAIT_TIME_GLOBAL_DATASTORE_NAME="predictiveanalytics_store"

#form recognizer endpoint, credential, model id and client variable
ENDPOINT = "#FORM_RECOGNIZER_ENDPOINT#"
CREDENTIAL = "#FORM_RECOGNIZER_API_KEY#"
MODEL_ID = "#FORM_RECOGNIZER_MODEL_ID#"