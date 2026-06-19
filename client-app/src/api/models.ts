// export const enum Approaches {
//   RetrieveThenRead = "rtr",
//   ReadRetrieveRead = "rrr",
//   ReadDecomposeAsk = "rda",
//   GMReadRetrieveRead = "gm_rrr",
// }

// export type AskRequestOverrides = {
//   semanticRanker?: boolean;
//   semanticCaptions?: boolean;
//   excludeCategory?: string;
//   top?: number;
//   temperature?: number;
//   promptTemplate?: string;
//   promptTemplatePrefix?: string;
//   promptTemplateSuffix?: string;
//   suggestFollowupQuestions?: boolean;
// };

// export type AskRequest = {
//   question: string;
//   approach: Approaches;
//   overrides?: AskRequestOverrides;
//   enableExternalDomain?: boolean;
// };

// export type OwnAskRequest = {
//   prompt: string;
//   text: string;
//   enableExternalDomain?: boolean;
// };

// export type OwnAskResponse = {
//   result: string;
//   error?: string;
// };

// export type AskResponse = {
//   answer: string;
//   thoughts?: string | null;
//   data_points?: string[];
//   error?: string;
// };

// export type ChatTurn = {
//   user: string;
//   bot?: string;
// };

// export type ChatRequest = {
//   history: ChatTurn[];
//   approach: Approaches;
//   overrides?: AskRequestOverrides;
//   enableExternalDomain?: boolean;
//   container?: string;
//   index?: string;
//   company?: string;
//   industry?: string;
// };
// export type ChatRequest2 = {
//   conversation_id: string;
//   messages: ChatMessage[];
//   client_id: string;
// };
// export type ChatMessage = {
//   id: string;
//   role: "user" | "assistant";
//   content: string;
//   date: string;
// };
export const enum Approaches {
  RetrieveThenRead = "rtr",
  ReadRetrieveRead = "rrr",
  ReadDecomposeAsk = "rda",
  GMReadRetrieveRead = "gm_rrr",
}

export type AskRequestOverrides = {
  semanticRanker?: boolean;
  semanticCaptions?: boolean;
  excludeCategory?: string;
  top?: number;
  temperature?: number;
  promptTemplate?: string;
  promptTemplatePrefix?: string;
  promptTemplateSuffix?: string;
  suggestFollowupQuestions?: boolean;
};

export type AskRequest = {
  question: string;
  approach: Approaches;
  overrides?: AskRequestOverrides;
  enableExternalDomain?: boolean;
};

export type OwnAskRequest = {
  prompt: string;
  text: string;
  enableExternalDomain?: boolean;
};

export type OwnAskResponse = {
  result: string;
  error?: string;
};

export type AskResponse = {
  answer: string;
  thoughts?: string | null;
  data_points?: string[];
  error?: string;
};

export type ChatTurn = {
  user: string;
  bot?: string;
};

export type ChatRequest = {
  history: ChatTurn[];
  approach: Approaches;
  overrides?: AskRequestOverrides;
  enableExternalDomain?: boolean;
  container?: string;
  index?: string;
  company?: string;
  industry?: string;
};
export type ChatRequest2 = {
  conversation_id: string;
  messages: ChatMessage[];
  client_id: string;
};
export type ChatMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
  date: string;
};
