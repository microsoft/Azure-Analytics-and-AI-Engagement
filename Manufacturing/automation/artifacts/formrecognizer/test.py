########### Python Form Recognizer Labeled Async Train #############
import json
import time
from requests import get, post

# Endpoint URL
endpoint = r"https://westus2.api.cognitive.microsoft.com/"
post_url = endpoint + r"/formrecognizer/v2.0/custom/models"
#Please provide sas url
source = r"https://dreamdemostrggen2sep21r1.blob.core.windows.net/form-datasets?sv=2019-02-02&sr=c&sig=229zJaQ4tCjSyTb1Eg%2F0E%2Bfh2uNJNU%2Bojeyiivs%2B1L8%3D&se=2020-09-21T11%3A57%3A08Z&sp=rwdl"
prefix = ""
includeSubFolders = False
useLabelFile = True

headers = {
    # Request headers
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': '282a96d7b127431d83322c06bbfbf9e7',
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