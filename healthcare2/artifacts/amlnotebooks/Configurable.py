#### Global
STORAGE_ACCOUNT_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=#STORAGE_ACCOUNT_NAME#;AccountKey=#STORAGE_ACCOUNT_KEY#;EndpointSuffix=core.windows.net"
STORAGE_ACCOUNT_NAME="#STORAGE_ACCOUNT_NAME#"
STORAGE_ACCOUNT_KEY="#STORAGE_ACCOUNT_KEY#"
GLOBAL_CONTAINER_NAME="predictiveanalytics"
GLOBAL_DATASTORE_NAME="predictiveanalytics_store"

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
