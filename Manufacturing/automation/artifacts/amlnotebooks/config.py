# Workspace config
subscription_id="#SUBSCRIPTION_ID#"
resource_group="#RESOURCE_GROUP#"
workspace_name="#WORKSPACE_NAME#"

# External Storage Account
STORAGE_ACCOUNT_NAME = "#STORAGE_ACCOUNT_NAME#"
STORAGE_ACCOUNT_ACCESS_KEY = "#STORAGE_ACCOUNT_KEY#"

# 3a
HARD_HAT_POST_URL = "https://westus2.api.cognitive.microsoft.com/customvision/v3.0/Prediction/#HARD_HAT_ID#/detect/iterations/Iteration1/image"
HARD_HAT_HEADERS = {'Prediction-Key': "#PREDICTION_KEY#","Content-Type":"application/json"}

# 3b 
WELDING_HELMET_POST_URL = "https://westus2.api.cognitive.microsoft.com/customvision/v3.0/Prediction/#HELMET_ID#/detect/iterations/Iteration1/image"
WELDING_HELMET_HEADERS = {'Prediction-Key': "#PREDICTION_KEY#","Content-Type":"application/json"}

# 3c
FACE_MASK_POST_URL = "https://westus2.api.cognitive.microsoft.com/customvision/v3.0/Prediction/#FACE_MASK_ID#/detect/iterations/Iteration1/image"
FACE_MASK_HEADERS = {'Prediction-Key': "#PREDICTION_KEY#","Content-Type":"application/json"}

# 3d
QUALITY_CONTROL_POST_URL = "https://westus2.api.cognitive.microsoft.com/customvision/v3.0/Prediction/#QUALITY_CONTROL_ID#/classify/iterations/Iteration1/image"
QUALITY_CONTROL_HEADERS = {'Prediction-Key': "#PREDICTION_KEY#","Content-Type":"application/json"}
# 4a

FORM_RECOGNIZER_ENDPOINT = "https://#LOCATION#.api.cognitive.microsoft.com/"
# Change if api key is expired
FORM_RECOGNIZER_APIM_KEY = "#APIM_KEY#"
# This model is the one trained on 5 forms
FORM_RECOGNIZER_MODEL_ID = "#MODEL_ID#"

# 4b

TRANLATION_URL = "https://#TRANSLATOR_NAME#.cognitiveservices.azure.com/translator/text/v3.0/translate?api-version=3.0&to="
TRANLATION_HEADERS = {'Ocp-Apim-Subscription-Key': "#TRANSLATION_KEY#","Content-Type":"application/json; charset=UTF-8"}
