// import {
//   AskRequest,
//   AskResponse,
//   ChatRequest,
//   ChatRequest2,
//   OwnAskRequest,
//   OwnAskResponse,
// } from "./models";

// export async function askApi(
//   options: AskRequest,
//   endpoint: string
// ): Promise<AskResponse> {
//   const response = await fetch(endpoint + "/ask", {
//     method: "POST",
//     headers: {
//       "Content-Type": "application/json",
//     },
//     body: JSON.stringify({
//       question: options.question,
//       approach: options.approach,
//       overrides: {
//         semantic_ranker: options.overrides?.semanticRanker,
//         semantic_captions: options.overrides?.semanticCaptions,
//         top: options.overrides?.top,
//         temperature: options.overrides?.temperature,
//         prompt_template: options.overrides?.promptTemplate,
//         prompt_template_prefix: options.overrides?.promptTemplatePrefix,
//         prompt_template_suffix: options.overrides?.promptTemplateSuffix,
//         exclude_category: options.overrides?.excludeCategory,
//       },
//       enableExternalDomain: options.enableExternalDomain,
//     }),
//   });

//   const parsedResponse: AskResponse = await response.json();
//   if (response.status > 299 || !response.ok) {
//     throw Error(parsedResponse.error || "Unknown error");
//   }

//   return parsedResponse;
// }

// export async function askYourDocument(
//   options: OwnAskRequest
// ): Promise<OwnAskResponse> {
//   const response = await fetch(
//     "https://azure-formrecog-openai-func.azurewebsites.net/api/OpenAIAnalyze",
//     {
//       method: "POST",
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: JSON.stringify({
//         prompt: options.prompt,
//         text: options.text,
//         enableExternalDomain: options.enableExternalDomain,
//       }),
//     }
//   );

//   const parsedResponse: OwnAskResponse = await response.json();
//   if (response.status > 299 || !response.ok) {
//     throw Error(parsedResponse.error || "Unknown error");
//   }

//   return parsedResponse;
// }

// export async function chatApi(
//   options: ChatRequest,
//   endpoint: string
// ): Promise<AskResponse> {
//   const response = await fetch(endpoint, {
//     method: "POST",
//     headers: {
//       "Content-Type": "application/json",
//     },

//     body: endpoint.includes("func-adb-ragchat-dev-001")
//       ? JSON.stringify({
//           data_json: {
//             dataframe_split: {
//               columns: ["query"],
//               data: [options.history[0].user],
//             },
//           },
//         })
//       : JSON.stringify({
//           history: options.history,
//           approach: options.approach,
//           overrides: {
//             semantic_ranker: options.overrides?.semanticRanker,
//             semantic_captions: options.overrides?.semanticCaptions,
//             top: options.overrides?.top,
//             temperature: options.overrides?.temperature,
//             prompt_template: options.overrides?.promptTemplate,
//             prompt_template_prefix: options.overrides?.promptTemplatePrefix,
//             prompt_template_suffix: options.overrides?.promptTemplateSuffix,
//             exclude_category: options.overrides?.excludeCategory,
//             suggest_followup_questions:
//               options.overrides?.suggestFollowupQuestions,
//           },
//           index: options.index,
//           industry: options.industry,
//           container: options.container,
//           company: options.company,
//           enableExternalDomain: options.enableExternalDomain,
//         }),
//   });

//   const parsedResponse: any = await response.json();
//   if (response.status > 299 || !response.ok) {
//     throw Error(parsedResponse.error || "Unknown error");
//   }
//   return endpoint.includes("func-adb-ragchat-dev-001")
//     ? { answer: parsedResponse?.predictions?.[0] }
//     : parsedResponse;
// }

// export async function imageChatApi(
//   options: any,
//   endpoint: string
// ): Promise<AskResponse> {
//   const formData: any = new FormData();
//   formData.append("image", options.image);
//   const response = await fetch(endpoint, {
//     method: "POST",
//     body: formData,
//   });

//   const parsedResponse: AskResponse = await response.json();
//   if (response.status > 299 || !response.ok) {
//     throw Error(parsedResponse.error || "Unknown error");
//   }

//   return parsedResponse;
// }

// export async function uploadDataChatApi(
//   options: ChatRequest,
//   endpoint: string
// ): Promise<AskResponse> {
//   const response = await fetch(endpoint, {
//     method: "POST",
//     headers: {
//       "Content-Type": "application/json",
//     },
//     body: JSON.stringify({
//       history: options.history,
//       approach: options.approach,
//       overrides: {
//         semantic_ranker: options.overrides?.semanticRanker,
//         semantic_captions: options.overrides?.semanticCaptions,
//         top: options.overrides?.top,
//         temperature: options.overrides?.temperature,
//         prompt_template: options.overrides?.promptTemplate,
//         prompt_template_prefix: options.overrides?.promptTemplatePrefix,
//         prompt_template_suffix: options.overrides?.promptTemplateSuffix,
//         exclude_category: options.overrides?.excludeCategory,
//         suggest_followup_questions: options.overrides?.suggestFollowupQuestions,
//       },
//       enableExternalDomain: options.enableExternalDomain,
//       container: options.container,
//       index: options.index,
//     }),
//   });

//   const parsedResponse: AskResponse = await response.json();
//   if (response.status > 299 || !response.ok) {
//     throw Error(parsedResponse.error || "Unknown error");
//   }

//   return parsedResponse;
// }

// export function getCitationFilePath(
//   citation: string,
//   endpoint: string,
//   container?: string,
//   isGMDemo?: boolean
// ): string {
//   return container
//     ? `${endpoint}/content/${citation}?container=${container}`
//     : isGMDemo
//     ? `${endpoint}/content/${citation}?container=gm-demo`
//     : `${endpoint}/content/${citation}`;
// }
import {
  AskRequest,
  AskResponse,
  ChatRequest,
  ChatRequest2,
  OwnAskRequest,
  OwnAskResponse,
} from "./models";

export async function askApi(
  options: AskRequest,
  endpoint: string
): Promise<AskResponse> {
  const response = await fetch(endpoint + "/ask", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      question: options.question,
      approach: options.approach,
      overrides: {
        semantic_ranker: options.overrides?.semanticRanker,
        semantic_captions: options.overrides?.semanticCaptions,
        top: options.overrides?.top,
        temperature: options.overrides?.temperature,
        prompt_template: options.overrides?.promptTemplate,
        prompt_template_prefix: options.overrides?.promptTemplatePrefix,
        prompt_template_suffix: options.overrides?.promptTemplateSuffix,
        exclude_category: options.overrides?.excludeCategory,
      },
      enableExternalDomain: options.enableExternalDomain,
    }),
  });

  const parsedResponse: AskResponse = await response.json();
  if (response.status > 299 || !response.ok) {
    throw Error(parsedResponse.error || "Unknown error");
  }

  return parsedResponse;
}

export async function askYourDocument(
  options: OwnAskRequest
): Promise<OwnAskResponse> {
  const response = await fetch(
    "https://azure-formrecog-openai-func.azurewebsites.net/api/OpenAIAnalyze",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        prompt: options.prompt,
        text: options.text,
        enableExternalDomain: options.enableExternalDomain,
      }),
    }
  );

  const parsedResponse: OwnAskResponse = await response.json();
  if (response.status > 299 || !response.ok) {
    throw Error(parsedResponse.error || "Unknown error");
  }

  return parsedResponse;
}

export async function chatApi(
  userQuestion: string,

  endpoint: string
): Promise<AskResponse> {
  const userMessage = {
    user: userQuestion,
    // Set the current date and time for the message
  };

  // Append the new user message to the existing messages array
  let persona = "po1";
  const updatedMessages = [userMessage];
  // switch (userId) {
  //   case "cc1":
  //     persona = "po1";
  //     break;
  //   case "cc2":
  //     persona = "po2";
  //     break;
  //   case "cc3":
  //     persona = "po3";
  //     break;
  //   case "cc4":
  //     persona = "po4";
  //     break;
  // }
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(
      userQuestion
      //persona_id: persona,
    ),
  });

  const parsedResponse: AskResponse = await response.json();
  if (response.status > 299 || !response.ok) {
    throw Error(parsedResponse.error || "Unknown error");
  }

  return parsedResponse;
}

export async function imageChatApi(
  options: any,
  endpoint: string
): Promise<AskResponse> {
  const formData: any = new FormData();
  formData.append("image", options.image);
  const response = await fetch(endpoint, {
    method: "POST",
    body: formData,
  });

  const parsedResponse: AskResponse = await response.json();
  if (response.status > 299 || !response.ok) {
    throw Error(parsedResponse.error || "Unknown error");
  }

  return parsedResponse;
}

export async function uploadDataChatApi(
  options: ChatRequest,
  endpoint: string
): Promise<AskResponse> {
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      history: options.history,
      approach: options.approach,
      overrides: {
        semantic_ranker: options.overrides?.semanticRanker,
        semantic_captions: options.overrides?.semanticCaptions,
        top: options.overrides?.top,
        temperature: options.overrides?.temperature,
        prompt_template: options.overrides?.promptTemplate,
        prompt_template_prefix: options.overrides?.promptTemplatePrefix,
        prompt_template_suffix: options.overrides?.promptTemplateSuffix,
        exclude_category: options.overrides?.excludeCategory,
        suggest_followup_questions: options.overrides?.suggestFollowupQuestions,
      },
      enableExternalDomain: options.enableExternalDomain,
      container: options.container,
      index: options.index,
    }),
  });

  const parsedResponse: AskResponse = await response.json();
  if (response.status > 299 || !response.ok) {
    throw Error(parsedResponse.error || "Unknown error");
  }

  return parsedResponse;
}

export function getCitationFilePath(
  citation: string,
  endpoint: string,
  container?: string,
  isGMDemo?: boolean
): string {
  return container
    ? `https://retailcognitivesearch.blob.core.windows.net/mcfr-nrf-demo-company-data/${citation}?container=${container}`
    : `https://retailcognitivesearch.blob.core.windows.net/mcfr-nrf-demo-company-data/${citation}`;
}
