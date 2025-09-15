## 🔧 Pre-requisites

1. **SQL Database Setup**  
- Execute all required SQL queries to create Embeddings and Retrieval-Augmented Generation (RAG) logic. Refer Module 05- RAG Implementation with Azure OpenAI.

- Expose the stored procedure through your GraphQL API.

2. **Install Python**  
- Download and install Python based on your operating system from the official website:  
     👉 [https://www.python.org/downloads/](https://www.python.org/downloads/)  

3. **Install Required Python Libraries**  
   Open a new terminal in VS Code and run the following commands:

   ```
   py -m pip install --upgrade pip
   ```

   ```
   py -m pip install streamlit
   ```

   ```
   py -m pip install streamlit azure-identity requests
   ```

## ▶️ Run the App

1. **Update GraphQL Endpoint**
- Download or clone this repo.  
- Open `streamlitapp.py` and replace the placeholder with your actual GraphQL endpoint

![](./media/1.png)

2. **Start the Streamlit App**  
- In the terminal, navigate to the directory containing `streamlitapp.py` and run:

     ```
     py -m streamlit run .\streamlitapp.py
     ```

- After running the app, it will open in your default browser.
Click on **Authenticate with browser** and sign in using the same account that was used to create the GraphQL endpoint.

![](./media/2.png)

- Look at the pre-populated prompt in the text box. Click on **Send** to submit the query.

![](./media/3.png)

- Once you receive the response, you can try asking any other question related to the product data.
