import requests
import json
import time


create_populate_KB_url = "https://westus.api.cognitive.microsoft.com/qnamaker/v4.0/knowledgebases/create"
KBID_url = "https://westus.api.cognitive.microsoft.com/qnamaker/v4.0/knowledgebases"


QnA_resource_Key = '#QNA_MAKER_KEY#'
QnA_Cognitive_Resource = '#QNA_MAKER_NAME#'
def read_data():
  with open('data.json') as f:
    data = json.load(f)
    return data

def Create_Populate_KB(create_populate_KB_url, data,QnA_resource_Key):
  url = create_populate_KB_url
  payload = json.dumps({
    # nam of KB
    "name": "QnA Maker FAQ",
    "qnaList":  data['qnaDocuments'],
    # "urls": [
    #   "https://azure.microsoft.com/en-us/services/cognitive-services/qna-maker/faq/"
    # ]
  })
  headers = {
    'Content-Type': 'application/json',
    # qnamaker keys and endpoint - key1
    # Get keys from the created QnA resource
    'Ocp-Apim-Subscription-Key': QnA_resource_Key
  }

  response = requests.request("POST", url, headers=headers, data=payload)
  
  # print(response.text)


# List KBID
def getKbID(KBID_url,QnA_resource_Key):
  url = KBID_url
  payload={}
  headers = {
    'Ocp-Apim-Subscription-Key': QnA_resource_Key
  }
  response = requests.request("GET", url, headers=headers, data=payload)
  response = json.loads(response.text)
  # print(type(response))
  return response


def publish_KB(QnA_resource_Key,id):
  url = "https://westus.api.cognitive.microsoft.com/qnamaker/v4.0/knowledgebases/"+id
  payload={}
  headers = {
    'Ocp-Apim-Subscription-Key': QnA_resource_Key
  }
  response = requests.request("POST", url, headers=headers, data=payload)

def get_endpointkey(qnamakerresource):
    url = f"https://{qnamakerresource}.cognitiveservices.azure.com/qnamaker/v4.0/endpointkeys"
    headers = {
  'Ocp-Apim-Subscription-Key': QnA_resource_Key
}
    payload={}
    response = requests.request("GET", url, headers=headers, data=payload)
    response = json.loads(response.text)
    return response
data=read_data()
Create_Populate_KB(create_populate_KB_url,data,QnA_resource_Key)
time.sleep(10)
KBID = getKbID(KBID_url, QnA_resource_Key)
id = next((item["id"] for item in KBID['knowledgebases'] if item["name"] == "QnA Maker FAQ"), None)
knowledgebase_id=id
publish_KB(QnA_resource_Key,id)
endpoint_key=get_endpointkey(QnA_Cognitive_Resource)
out_json = json.dumps({'KBID': knowledgebase_id, 'KBKey': endpoint_key["primaryEndpointKey"]})
print(out_json)
