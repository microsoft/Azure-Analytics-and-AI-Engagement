import os
import re
import json
import logging
import azure.functions as func
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# -------------------------------------------------------------------
# Configuration: Dynamic Environment Variables
# -------------------------------------------------------------------
PROJECT_ENDPOINT = os.environ["PROJECT_ENDPOINT"]
WORKFLOW_NAME = os.environ.get("WORKFLOW_NAME", "FSIIQ-Workflow")

# -------------------------------------------------------------------
# Helper: Azure AI Foundry Workflow Invocation
# -------------------------------------------------------------------
def call_workflow_agent(query: str) -> dict:
    try:
        project_client = AIProjectClient(
            endpoint=PROJECT_ENDPOINT,
            credential=DefaultAzureCredential()
        )
        with project_client:
            openai_client = project_client.get_openai_client()
            conversation = openai_client.conversations.create()

            response = openai_client.responses.create(
                conversation=conversation.id,
                extra_body={"agent_reference": {"name": WORKFLOW_NAME, "type": "agent_reference"}},
                input=query,
                metadata={"x-ms-debug-mode-enabled": "1"},
            )

            output_texts = []
            for item in response.output:
                if getattr(item, "type", None) == "message":
                    for content in getattr(item, "content", []):
                        if getattr(content, "type", None) == "output_text":
                            output_texts.append(content.text)

            first_output = output_texts[0] if output_texts else None
            last_output = output_texts[-1] if output_texts else None
            logging.info(f"Agent output: {last_output}")

            return {
                "first_output": first_output,
                "last_output": last_output
            }
    except Exception as e:
        logging.error(f"Workflow agent call failed: {e}")
        return {"first_output": None, "last_output": None}

# -------------------------------------------------------------------
# Helper: UI Action & Question Mapping
# -------------------------------------------------------------------
def tag_for_ui_action(query: str) -> str:
    if not query:
        return ""
    q = query.strip().lower()
    if "open joe" in q:
        return "open_joe_application"
    elif "missing" in q or "validate" in q:
        return "show_doc_validation"
    elif "nudge" in q or "polite nudge" in q:
        return "show_email_draft"
    elif "send that email" in q or "send immediately" in q:
        return "show_email_sent"
    elif "proceed with the mortgage application" in q or "revised offer" in q:
        return "show_offer_update"
    elif "approve" in q:
        return "update_loan_terms"
    elif "review the newly received documents" in q or "documents_processed" in q:
        return "documents_processed"
    elif "custom offer" in q:
        return "popup_suggested_offer"
    return ""

def get_suggested_questions(query: str) -> list:
    if not query:
        return []
    q = query.strip().lower()
    if "prioritize" in q or "review today" in q:
        return ["Yes, please open Joe Williamson’s application."]
    elif "open joe" in q:
        return ["Yes, show me what’s missing and any mismatches in the validated documents."]
    elif "what's missing" in q or "show me what" in q:
        return ["Okay, we can't move forward without those. Cora, can you send Joe a polite nudge? Tell him exactly what’s wrong so he doesn't just re-upload the same files."]
    elif "nudge" in q:
        return ["Perfect, Go ahead and send that email to Joe immediately."]
    elif "send that email" in q or "send immediately" in q:
        return ["Yes"]
    elif q == "yes":
        return ["What is the status of the credit assessment and underwriting?"]
    elif "underwriting" in q or "affordability" in q:
        return ["Run full financial resilience analysis", "Request a higher down payment from Joe"]
    elif "resilience" in q:
        return ["Present custom offer to Joe based on relationship status and market signals", "Adjust parameters and re-run"]
    elif "approve" in q:
        return ["Thanks, Cora. Please proceed with the mortgage application and notify Joe about the revised offer."]
    return []

# -------------------------------------------------------------------
# Helper: Deterministic Fallbacks (Guarantees zero nulls)
# -------------------------------------------------------------------
def hardcoded_response(query: str) -> dict:
    q = (query or "").strip().lower()

    if "prioritize" in q or "review today" in q:
        return {
            "answer": "Sure, I’d be happy to help. One urgent application stands out: Joe Williamson’s. He needs to make an offer on a house today, so his application is the top priority. Would you like me to open it for you?",
            "documents": [],
            "email": "",
            "suggested_question": ["Yes, please open Joe Williamson’s application."],
            "ui_action": ""
        }
    elif "open joe" in q:
        return {
            "answer": "Opening Joe Williamson’s application now. There’s one thing to note: I’m unable to move this application to the review stage yet because the automated verification system has flagged a few missing items. Would you like me to show the details?",
            "documents": [],
            "email": "",
            "suggested_question": ["Yes, show me what’s missing and any mismatches in the validated documents."],
            "ui_action": "open_joe_application"
        }
    elif "what's missing" in q or "validate" in q:
        return {
            "answer": "Based on the review, here are the remaining requirements to move forward:\n\nDocument Inconsistencies\nDiscrepancies were identified in the name, employer, and address details across Joe’s pay stub, bank statement, and ID.\n\nOutdated Documents\nA few of the provided documents are now outdated.\n\nPending Items from Joe\nWe still need Joe’s Employment Verification form and Certificate of Currency.",
            "documents": [
                {
                    "docName": "JoeDrivingLicense.png",
                    "Conditions Flagged": {"false": ["Address Match"], "true": ["Name Match", "Expiry Date", "Image Quality"]},
                    "docurl": "https://dreamdemoassets.blob.core.windows.net/telco-noa/videos/JoeDL.png"
                },
                {
                    "docName": "JoePayStub.pdf",
                    "Conditions Flagged": {"false": ["Name Match"], "true": ["Pay Period", "Employer Details", "Net Pay Calculation"]},
                    "docurl": "https://dreamdemoassets.blob.core.windows.net/telco-noa/videos/JoePayStub.pdf"
                },
                {
                    "docName": "JoeBankStatement.pdf",
                    "Conditions Flagged": {"false": ["Incorrect Address", "Blank Lines", "Transaction Type Errors"], "true": ["Account Number"]},
                    "docurl": "https://dreamdemoassets.blob.core.windows.net/telco-noa/videos/JoeBankStatement.pdf"
                }
            ],
            "email": "",
            "suggested_question": ["Okay, we can’t move forward without those. Cora, can you send Joe a polite nudge? Tell him exactly what’s wrong so he doesn’t just re-upload the same files."],
            "ui_action": "show_doc_validation"
        }
    elif "nudge" in q:
        return {
            "answer": "Drafting a mail...",
            "documents": [],
            "email": "**Subject:** Action Required: Updates Needed for Your Loan Application – Joe Williamson\n\nDear Joe Williamson,\n\nHope you're doing well.\n\nDuring the review of your loan application, a few items were identified that require your attention before the process can move forward. Some of the submitted documents appear to be outdated, and there are inconsistencies in your name and employer details across the pay stub, bank statement, and driver's license. It would be helpful to have updated and consistent versions of these documents. In addition, the following documents are still required:\n\n- Employment Verification form\n- Certificate of Currency\n\nKindly share the updated and missing documents at your earliest convenience so the application review can continue without delay.\n\nIf you have any questions or need assistance, please feel free to reach out.\n\nBest regards,\nRobin",
            "suggested_question": ["Perfect, Go ahead and send that email to Joe immediately."],
            "ui_action": "show_email_draft"
        }
    elif "send that email" in q or "send immediately" in q:
        return {
            "answer": "Done! The email has been sent to Joe Williamson.",
            "answer1": "All the missing documents from Joe Williamson have now been received. Would you like to proceed now?",
            "documents": [],
            "email": "",
            "suggested_question": ["Yes"],
            "ui_action": "show_email_sent"
        }
    elif q == "yes":
        return {
            "answer": "Okay, Let me review the newly received documents and flag any issues for you.",
            "documents": [],
            "email": "",
            "suggested_question": ["What is the status of the credit assessment and underwriting?"],
            "ui_action": "documents_processed"
        }
    elif "underwriting" in q or "proceed with these documents" in q:
        return {
            "answer": "**I've reviewed Joe's documents. Here's what I found:**\n\n- **Affordability gap detected**\n  - Debt-to-income ratio exceeds standard threshold for the requested loan amount.\n- **Custom offer may be viable**\n  - A deeper financial analysis could open alternative structures for Joe.\n\n**How would you like to proceed?**",
            "documents": [
                {
                    "docName": "JoeDrivingLicense.png",
                    "Conditions Flagged": {"false": [], "true": ["Name Match", "Expiry Date", "Address Match", "Image Quality"]},
                    "docurl": "https://dreamdemoassets.blob.core.windows.net/telco-noa/videos/JoeDL.png"
                },
                {
                    "docName": "JoePayStub.pdf",
                    "Conditions Flagged": {"false": [], "true": ["Name Match", "Pay Period", "Employer Details", "Net Pay Calculation"]},
                    "docurl": "https://dreamdemoassets.blob.core.windows.net/telco-noa/videos/JoePayStub.pdf"
                },
                {
                    "docName": "JoeBankStatement.pdf",
                    "Conditions Flagged": {"false": [], "true": ["Incorrect Address", "Account Number", "Blank Lines", "Transaction Type Errors"]},
                    "docurl": "https://dreamdemoassets.blob.core.windows.net/telco-noa/videos/JoeBankStatement.pdf"
                }
            ],
            "email": "",
            "suggested_question": ["Run full financial resilience analysis", "Request a higher down payment from Joe"],
            "ui_action": ""
        }
    elif "resilience" in q:
        return {
            "answer": "Despite the DTI gap, Joe's savings history and employment stability support a structured offer.",
            "metrics": {
                "credit_score": 724,
                "dti_ratio": "44%",
                "employment_status": "6 yrs stable",
                "savings_pattern": "Consistent"
            },
            "custom_offers": [
                {"option": "Extended term - 30 years", "status": "Best fit", "benefit": "Reduced monthly payment by $60"},
                {"option": "Tiered rate | 3yr fixed/variable", "benefit": "Lower entry rate, reviews at year 3"},
                {"option": "Split loan structure", "benefit": "Part fixed, part offset - maximises flexibility"}
            ],
            "documents": [],
            "email": "",
            "suggested_question": ["Present custom offer to Joe based on relationship status and market signals", "Adjust parameters and re-run"],
            "ui_action": ""
        }
    elif "present custom offer" in q:
        return {
            "answer": "Sure, I'll go ahead and present the custom offer to Joe based on the relationship status and current market signals.",
            "documents": [],
            "email": "",
            "suggested_question": [],
            "ui_action": "popup_suggested_offer"
        }
    elif "approve" in q:
        return {
            "answer": "Good news! The request has been approved by the product team, and Joe's loan amount has been increased.",
            "documents": [],
            "email": "",
            "suggested_question": ["Thanks, Cora. Please proceed with the mortgage application and notify Joe about the revised offer."],
            "ui_action": "update_loan_terms"
        }
    elif "revised offer" in q:
        return {
            "answer": "Absolutely. I've proceeded with the mortgage application and notified Joe about the revised offer.\n\nEverything is progressing as expected.",
            "documents": [],
            "email": "Subject: Mortgage Loan Update - Increase in Approved Loan Amount\n\nHi Joe,\n\nCongratulations Joe Williamson!\n\nGiven your status as a loyal customer of Zava Bank for the last 15 years, we're pleased to share that your revised loan amount has been approved.\n\nWarm regards,\nCora, AI Assistant",
            "suggested_question": [],
            "ui_action": "show_offer_update"
        }
    else:
        return {
            "answer": "I have processed your request for the mortgage workflow.",
            "documents": [],
            "email": "",
            "suggested_question": ["I have a lot of loan applications to review today. Can you help me prioritize which one I should work on first?"],
            "ui_action": ""
        }

# -------------------------------------------------------------------
# Function 1: fsi_iq_api (Live AI Agent Pipeline with Fallback)
# -------------------------------------------------------------------
@app.route(route="fsi_iq_api", methods=["POST"])
def fsi_iq_api(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json()
        query = body.get("query", "")
        logging.info(f"fsi_iq_api received query: {query}")

        result = call_workflow_agent(query)
        output_answer = result.get("last_output")

        if output_answer:
            response_payload = {
                "answer": output_answer,
                "documents": [],
                "email": "",
                "suggested_question": get_suggested_questions(query),
                "ui_action": tag_for_ui_action(query)
            }
        else:
            logging.warning("Agent returned None. Using fallback response.")
            response_payload = hardcoded_response(query)

        return func.HttpResponse(
            json.dumps(response_payload),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Error in fsi_iq_api: {e}")
        query_val = body.get("query", "") if 'body' in locals() and isinstance(body, dict) else ""
        return func.HttpResponse(
            json.dumps(hardcoded_response(query_val)),
            status_code=200,
            mimetype="application/json"
        )

# -------------------------------------------------------------------
# Function 2: fsi_iq_workflow (Deterministic / Demo Pipeline)
# -------------------------------------------------------------------
@app.route(route="fsi_iq_workflow", methods=["POST"])
def fsi_iq_workflow(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json()
        query = body.get("query", "")
        logging.info(f"fsi_iq_workflow received query: {query}")

        answer = hardcoded_response(query)

        return func.HttpResponse(
            json.dumps(answer),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Error in fsi_iq_workflow: {e}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )