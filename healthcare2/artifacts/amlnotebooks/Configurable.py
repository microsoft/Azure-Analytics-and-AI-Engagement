#### Global
STORAGE_ACCOUNT_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net"
STORAGE_ACCOUNT_NAME="#STORAGE_ACCOUNT_NAME#"
STORAGE_ACCOUNT_KEY="#STORAGE_ACCOUNT_KEY#"
GLOBAL_CONTAINER_NAME="predictiveanalytics"
GLOBAL_DATASTORE_NAME="predictiveanalytics_store"

#### CT-Scan Images Azure Custom Vision
# CT_SCAN_CONTAINER_NAME="covid-azureml-testimages"
# CT_SCAN_END_POINT="https://westus2.api.cognitive.microsoft.com/customvision/v3.0/Prediction/7b58bba3-f88e-43c8-bdf9-8cd62e6c4a37/classify/iterations/Iteration2/image"
# CT_SCAN_PREDICTION_KEY="0ea6df654a9f47a4b9a3da65988f461e"

#### Face Mask Detection
# FACE_MASK_CONTAINER_NAME="ppecompliancedetection"
# FACE_MASK_INPUT_BLOB_NAME="FaceMask/Input/maskv3.mov"
# FACE_MASK_OUTPUT_BLOB_NAME="FaceMask/Output/processed_people.mp4"
# FACE_MASK_END_POINT="https://westus2.api.cognitive.microsoft.com/customvision/v3.0/Prediction/7f83145b-8f94-4198-b9eb-3bab1d813fc5/detect/iterations/Iteration1/image"
# FACE_MASK_PREDICTION_KEY="0ea6df654a9f47a4b9a3da65988f461e"

#### Form Recognizer 
FORM_RECOGNIZER_ENDPOINT=r"#FORM_RECOGNIZER_ENDPOINT#"
FORM_RECOGNIZER_API_KEY="#FORM_RECOGNIZER_API_KEY#"
FORM_RECOGNIZER_MODEL_ID="#FORM_RECOGNIZER_MODEL_ID#"

# #### Readmission Prediction
READMISSION_DATASTORE_NAME="readmission_prediction_store"
READMISSION_INPUT_FILE_NAME="/pbiPatientPredictiveSetv4.csv"

#### Wait Time Forecasting
WAIT_TIME_DATASTORE_NAME="wait_time_prediction_store"
WAIT_TIME_INPUT_FILE_NAME="/pbiPatientPredictiveSet.csv"

#### Bed Occupancy Forecasting
BED_OCCUPANCY_DATASTORE_NAME="total_occupancy_prediction_store"
BED_OCCUPANCY_INPUT_FILE_PATH="/bedoccupancyv4.csv"
TOTAL_BEDS_FILE_PATH="/total_beds.csv"
