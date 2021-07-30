#### Global
STORAGE_ACCOUNT_CONNECTION_STRING = 'DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net'

#### Face Mask Detection
FACE_MASK_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net"
FACE_MASK_CONTAINER_NAME="ppecompliancedetection"
FACE_MASK_INPUT_BLOB_NAME="Facemasks/Input/input_fsi_video.mp4"
FACE_MASK_OUTPUT_BLOB_NAME="Facemasks/Output/processed_fsi_video.mp4"
FACE_MASK_END_POINT="https://marketdatacgsvc.cognitiveservices.azure.com/customvision/v3.0/Prediction/3583c0a3-0c45-4fea-9dae-270a8250992e/detect/iterations/Iteration7/image"
FACE_MASK_PREDICTION_KEY="#FACE_MASK_PREDICTION_KEY#"


#### GlobalVariable for Account Opening Forms - Nootbook Number 5
STORAGE_ACCOUNT_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net"
ACC_OPEN_CONTAINER_NAME="accountopeningforms-analysis"
ACC_OPEN_API_KEY="#FORM_RECOGNIZER_API_KEY#"
ACC_OPEN_OUTPUT_CONTAINER="azure-ml-output-accountopeningforms"

#### GlobalVariable for Account Opening Forms - Nootbook Number 6
STORAGE_ACCOUNT_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net"
INCIDENT_CONTAINER_NAME="azureml-incident-input"
INCIDENT_API_KEY="#FORM_RECOGNIZER_API_KEY#"
OUTPUT_CONTAINER_NAME="azuremloutput-incident"

#### GlobalVariable for Search for highly relevant financial information - Nootbook Number 7
SEARCH_API_KEY="#SEARCH_API_KEY#"
SEARCH_URI="#SEARCH_URI#"
SEARCH_INDEX="edgar-10k"

#Workspace details and Compute
subscription_id= "#SUBSCRIPTION_ID#"
resource_group= "#RESOURCE_GROUP_NAME#"
workspace_name= "#WORKSPACE_NAME#"
COMPUTE_AIML = '#CPU_SHELL#'

### Incident Forms
STORAGE_ACCOUNT_CONNECTION_STRING_INCIDENT_FORMS="DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net"

### Form Recognizer
FORM_RECOGNIZER_ENDPOINT = "#FORM_RECOGNIZER_ENDPOINT#"
FORM_RECOGNIZER_API_KEY = "#FORM_RECOGNIZER_API_KEY#"
ACCOUNT_OPENING_FORM_RECOGNIZER_MODEL_ID = "#ACCOUNT_OPENING_FORM_RECOGNIZER_MODEL_ID#"
INCIDENT_FORM_RECOGNIZER_MODEL_ID = "#INCIDENT_FORM_RECOGNIZER_MODEL_ID#"


### Account opening forms
ACCFORM_RECOGNIZER_ENDPOINT = "#FORM_RECOGNIZER_ENDPOINT#"
ACC_FORM_RECOGNIZER_MODEL_ID = "#ACCOUNT_OPENING_FORM_RECOGNIZER_MODEL_ID#"

### Language Translation
TRANSLATION_API_KEY = "#TRANSLATOR_SERVICE_KEY#"
TRANSLATION_URL = "https://#TRANSLATOR_SERVICE_NAME#.cognitiveservices.azure.com/translator/text/v3.0/translate?api-version=3.0&to="
