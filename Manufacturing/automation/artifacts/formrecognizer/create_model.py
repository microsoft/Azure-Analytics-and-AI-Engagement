import json
import time
from requests import get, post
endpoint = r"https://#LOCATION#.api.cognitive.microsoft.com/"
post_url = endpoint + r"/formrecognizer/v2.0/custom/models"
source = r"https://#STORAGE_ACCOUNT_NAME#.blob.core.windows.net/#CONTAINER_NAME##SAS_TOKEN#"
prefix = ""
includeSubFolders = False
useLabelFile = True

headers = {
    # Request headers
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': '#APIM_KEY#',
}

body =     {
    "source": source,
    "sourceFilter": {
        "prefix": prefix,
        "includeSubFolders": includeSubFolders
    },
    "useLabelFile": useLabelFile
}

try:
    resp = post(url = post_url, json = body, headers = headers)
    if resp.status_code != 201:
        #print("POST model failed (%s):\n%s" % (resp.status_code, json.dumps(resp.json())))
        quit()
    #print("POST model succeeded:\n%s" % resp.headers)
    get_url = resp.headers["location"]
except Exception as e:
    #print("POST model failed:\n%s" % str(e))
    quit() 
print(get_url)