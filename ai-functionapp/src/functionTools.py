from mimetypes import guess_type
import os
import base64
from openai import AzureOpenAI  
from dotenv import load_dotenv
load_dotenv()

azure_deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT")
api_version = os.environ.get("AZURE_OPENAI_API_VERSION")
azure_endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT")
api_key = os.environ.get("AZURE_OPENAI_KEY")
model_name = os.environ.get("AZURE_OPENAI_MODEL")

az_model_client = AzureOpenAI(
    azure_deployment="gpt-4o",
    api_version=api_version,
    azure_endpoint=azure_endpoint,
    api_key=api_key,
)

def image_describing_tool(image_input, feedback = None, mime_type=None):
    try:
        if isinstance(image_input, str):
            if image_input.startswith("http://") or image_input.startswith("https://"):
                # For HTTP(S) image URL: Use URL directly
                image_mode = "url"
                image_url = image_input
                if mime_type is None:
                    # Guess mime_type (optional)
                    mime_type, _ = guess_type(image_input)
            else:
                # Local file path
                if not os.path.isfile(image_input):
                    return f"Error: File '{image_input}' does not exist. Please check the path."
                if mime_type is None:
                    mime_type, _ = guess_type(image_input)
                with open(image_input, "rb") as image_file:
                    image_bytes = image_file.read()
                    if len(image_bytes) == 0:
                        return f"Error: File '{image_input}' is empty."
                image_mode = "bytes"
        elif isinstance(image_input, bytes):
            if not image_input:
                return "Error: Provided image bytes are empty."
            image_bytes = image_input
            image_mode = "bytes"
        else:
            return "Error: image_input must be a URL, file path (str), or bytes object."
    except Exception as e:
        return f"Error reading image: {str(e)}"

    # ----------------------------
    # Construct chat prompt
    common_prompt = "Please look at the image provided and the feedback and."

    if feedback:
        common_prompt += f"\nThe feedback from user is: {feedback}"

    chat_prompt = [
        {
            "role": "system",
            "content": "You are an AI assistant whose task is to describe the image as required by the user."
        }
    ]

    if image_mode == "url":
        # HTTP image: use image URL
        chat_prompt.append({
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": common_prompt
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": image_url
                    }
                }
            ]
        })
    else:
        # Local file or bytes, use data URL (base64)
        if mime_type is None:
            mime_type = "application/octet-stream"
        try:
            base64_encoded_data = base64.b64encode(image_bytes).decode('utf-8')
        except Exception as e:
            return f"Error: failed to base64-encode image ({str(e)})."
        chat_prompt.append({
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": common_prompt
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:{mime_type};base64,{base64_encoded_data}"
                    }
                }
            ]
        })

    # Step 3: Model call with error handling
    try:
        completion = az_model_client.chat.completions.create(
            model="gpt-4o",
            messages=chat_prompt,
            max_tokens=1200,
            temperature=0.7,
            top_p=0.95,
            frequency_penalty=0,
            presence_penalty=0,
            stop=None,
            stream=False
        )
    except Exception as e:
        return f"Error: Model call failed ({str(e)}). Check network connection and credentials."

    response_dict = completion.model_dump()
    response_message = response_dict["choices"][0]["message"]["content"]
    
    return response_message