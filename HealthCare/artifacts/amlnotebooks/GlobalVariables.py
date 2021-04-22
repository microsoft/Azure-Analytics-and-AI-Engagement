#### Global
STORAGE_ACCOUNT_CONNECTION_STRING="#STORAGE_ACCOUNT_CONNECTION_STRING#"
STORAGE_ACCOUNT_NAME="#STORAGE_ACCOUNT_NAME#"
STORAGE_ACCOUNT_KEY="#STORAGE_ACCOUNT_KEY#"
GLOBAL_CONTAINER_NAME="predictiveanalytics"
GLOBAL_DATASTORE_NAME="predictiveanalytics_store"

#### CT-Scan Images Azure Custom Vision
CT_SCAN_CONTAINER_NAME="covid-azureml-testimages"
CT_SCAN_END_POINT="https://#LOCATION#.api.cognitive.microsoft.com/customvision/v3.0/Prediction/#PROJECT_CTSCAN_ID#/classify/iterations/Iteration1/image"
CT_SCAN_PREDICTION_KEY="#PREDICTION_KEY#"

#### Face Mask Detection
FACE_MASK_CONTAINER_NAME="ppecompliancedetection"
FACE_MASK_INPUT_BLOB_NAME="FaceMask/Input/maskv3.mov"
FACE_MASK_OUTPUT_BLOB_NAME="FaceMask/Output/processed_people.mp4"
FACE_MASK_END_POINT="https://#COGNITIVE_SERVICES_NAME#.cognitiveservices.azure.com/customvision/v3.0/Prediction/#PROJECT_FACE_MASK_ID#/detect/iterations/Iteration1/image"
FACE_MASK_PREDICTION_KEY="#PREDICTION_KEY#"

#### Form Recognizer 
FORM_RECOGNIZER_ENDPOINT=r"https://#FORM_RECOGNIZER_NAME#.cognitiveservices.azure.com/"
FORM_RECOGNIZER_API_KEY="dcb9501d647c41df935ce32843763e80"
FORM_RECOGNIZER_MODEL_ID="#FORM_RECOGNIZER_MODEL_ID#"

#### Readmission Prediction
READMISSION_DATASTORE_NAME="readmission_prediction_store"
READMISSION_INPUT_FILE_NAME="/pbiPatientPredictiveSetv4.csv"

#### Wait Time Forecasting
WAIT_TIME_DATASTORE_NAME="wait_time_prediction_store"
WAIT_TIME_INPUT_FILE_NAME="/pbiPatientPredictiveSet.csv"

#### Bed Occupancy Forecasting
BED_OCCUPANCY_DATASTORE_NAME="total_occupancy_prediction_store"
BED_OCCUPANCY_INPUT_FILE_PATH="/bedoccupancyv4.csv"
TOTAL_BEDS_FILE_PATH="/total_beds.csv"
