import streamlit as st
import requests
import json
from azure.identity import InteractiveBrowserCredential

# Constants
GRAPHQL_ENDPOINT = "<PASTE_YOUR_GRAPHQL_ENDPOINT_HERE>"
SCOPE = "https://analysis.windows.net/powerbi/api/.default"

# Streamlit setup
st.set_page_config(page_title="Fabric GraphQL Chat", layout="centered")
st.title("💬 Fabric GraphQL Chat App")

# Authentication
if "access_token" not in st.session_state:
    if st.button("🔐 Authenticate with Browser"):
        try:
            cred = InteractiveBrowserCredential()
            token = cred.get_token(SCOPE)
            st.session_state.access_token = token.token
            st.success("✅ Authentication successful!")
        except Exception as e:
            st.error(f"❌ Authentication failed: {e}")

# If authenticated, show prompt input
if "access_token" in st.session_state:
    st.markdown("### 🤖 Ask your question")
    user_input = st.text_input("Type your prompt", value="Do you have any racing shorts?")

    if st.button("Send"):
        headers = {
            "Authorization": f"Bearer {st.session_state.access_token}",
            "Content-Type": "application/json"
        }

        query = """
            query ($text: String!) {
                executefind_products_chat_api(text: $text) {
                    answer
                }
            }
        """
        variables = {"text": user_input}

        try:
            response = requests.post(
                GRAPHQL_ENDPOINT,
                json={"query": query, "variables": variables},
                headers=headers
            )
            response.raise_for_status()
            data = response.json()

            # ✅ Parse and display response
            answer_list = data["data"].get("executefind_products_chat_api", [])
            if answer_list and isinstance(answer_list, list):
                answer = answer_list[0].get("answer", "No answer found.")
                st.markdown(f"### 🧠 Response:\n{answer}")
            else:
                st.warning("⚠️ No results returned from GraphQL.")
                st.json(data)

        except Exception as error:
            st.error(f"❌ Query failed with error: {error}")
