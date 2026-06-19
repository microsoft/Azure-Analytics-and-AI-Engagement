import { useState, useRef, FC, useEffect } from "react";
import {
  Action,
  Chat,
  ChatMessageBoxProps,
  ChatMessageSendEvent,
  Message,
} from "@progress/kendo-react-conversational-ui";
import { useMic } from "../../hooks/useMic";
import { useAppDispatch, useAppSelector } from "../../hooks";

import {
  Delete24Regular,
  Dismiss24Regular,
  Mic24Filled,
} from "@fluentui/react-icons";
import styles from "./styles.module.scss";
import axios from "axios";
import {
  setActiveTileGlobally,
  setActiveTileNumber,
  setShowPopup,
  setPreviousTileGlobally,
  setSolutionPlay,
} from "store";
import { useNodesState } from "@xyflow/react";
import { AllNodes } from "components/LandingPage/allnodes";

const {
  CHAT_BOT_API,
  BMAA_INITIAL_ACTIONS,
  SQL_INITIAL_ACTIONS,
  FRH_INITIAL_ACTIONS,
  AZURE_TV_INITIAL_ACTIONS,
  DELAY_TIME,
  INITIAL_ACTIONS: ACTIONS,
  isHardcodingEnabled,
} = window.config;

interface Props {
  isVideoCopilot?: boolean;
  INITIAL_ACTIONS: any;
  messages: any;
  setMessages: React.Dispatch<React.SetStateAction<any>>;
  actions: any;
  setActions: React.Dispatch<React.SetStateAction<any>>;
  type: string;
  onPlayClick: (nodeId: string, label: string) => void;
  setType: React.Dispatch<React.SetStateAction<string>>;
}

//TO AWAIT
function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const SUGGESTED_ACTIONS: Action[] = [
  {
    type: "reply",
    value: "Do you have any demos for AI Design Wins?",
  },
  {
    type: "reply",
    value: "Do you have any demos for Fabric with Databricks?",
  },

  {
    type: "reply",
    value: "Are there any demos available for the latest Fabric features?",
  },
  {
    type: "reply",
    value:
      "Do you have any demo that shows integration of Microsoft Purview and Microsoft Fabric?",
  },
];

const COPILOT_API =
  "https://func-data-ai-demo-assistant.azurewebsites.net/api/chat";

export const ChatBot: FC<Props> = ({
  isVideoCopilot,
  INITIAL_ACTIONS,

  actions,
  onPlayClick,
  setActions,
  type,
}) => {
  const [text] = useState("");
  const [isPressed, setIsPressed] = useState(false);
  const timerRef: any = useRef(null);
  const dispatch = useAppDispatch();
  setActions(SUGGESTED_ACTIONS);
  const onTextSend = (text: string) => {
    //addNewMessage(undefined, text);
  };
  const authors = [
    {
      id: "bot",
      avatarUrl:
        "https://fabricresourceshub.blob.core.windows.net/assets/fabric_resources_bot.png",
    },
    {
      id: "user",
      avatarUrl:
        "https://fabricresourceshub.blob.core.windows.net/assets/fabric_resources_user.png",
    },
  ];
  const [sttFromMic]: any = useMic(text, onTextSend);

  const handleMouseDown = () => {
    setIsPressed(true);
    timerRef.current = setTimeout(() => {
      sttFromMic();
      // Perform the desired action when the button is held down
    }, 1000); // Adjust the duration as needed
  };

  const INITIAL_MESSAGE = [
    {
      author: authors[0],
      text: "Hi, How can I help you?",
      suggestedActions: SUGGESTED_ACTIONS,
      tokens: 13,
    },
  ];

  const [messages, setMessages] = useState<any[]>(INITIAL_MESSAGE);
  const [nodes, setNodes, onNodesChange] = useNodesState(AllNodes);
  const handleMouseUp = () => {
    clearTimeout(timerRef.current);
    setIsPressed(false);
  };

  const customMessage = (props: ChatMessageBoxProps) => {
    return (
      <>
        {props.messageInput}
        {props.sendButton}
        <div
          title="Hold to Speak"
          onMouseDown={handleMouseDown}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          style={{
            opacity: !isPressed ? 1 : 0.5,
            marginTop: 5,
            color: isPressed ? "red" : "initial",
          }}
        >
          <Mic24Filled className={styles.mic} />
        </div>
      </>
    );
  };

  const onMessageSend = async (e?: ChatMessageSendEvent, text?: string) => {
    //isChatEnded && setIsChatEnded(false);
    const userMessage = {
      author: authors[1],
      text: text?.trim() ?? e!.message.text?.trim(),
      timestamp: e?.message.timestamp ?? new Date(),
    };
    const filteredSuggestedActions = SUGGESTED_ACTIONS.filter(
      (item: any) => item.value !== e?.message.text
    );
    setMessages((old) => [
      ...old,
      userMessage,
      { author: authors[0], typing: true },
    ]);

    const historyMessages = [...messages, userMessage];
    historyMessages.shift();
    const messageText = e?.message.text;
    // Check if the message is equal to "data security"
    if (messageText === INITIAL_ACTIONS[0]) {
      // Set the predefined API response
      await delay(DELAY_TIME);
      setMessages((old) => {
        const newArray = [
          ...old.slice(0, old.length - 2),
          { ...userMessage, tokens: 0 }, // Optional: add token information
          {
            author: authors[0],
            text: `Yes, we have AI Design Wins Demo scenarios showcasing how Contoso used AI to create an enterprise chatbot, build a personalized shopping assistant, analyze customer interactions, and customize machine learning models. The demo scenarios included showcase Azure AI Search, GPT-4 Turbo, and Microsoft Fabric.  Please refer to the AI Design Wins as well as Apps + Azure Cosmos DB Demo flows.`,
            solution_play: "AI Design Wins",
            timestamp: new Date(),
            tokens: 0, // Optional: add token information
            suggestedActions: filteredSuggestedActions,
          } as Message,
        ];
        let tileTitle: string;
        dispatch(
          setPreviousTileGlobally("Microsoft Fabric + Azure Databricks")
        );
        dispatch(setActiveTileGlobally("Innovate with Azure AI Platform"));
        dispatch(setActiveTileNumber("home"));
        localStorage.setItem(
          "ActiveTileGlobally",
          "Innovate with Azure AI Platform"
        );
        localStorage.setItem("ActiveTileNumber", "home");
        dispatch(setSolutionPlay("AI Design Wins"));
        return newArray;
      });
    } else if (messageText === INITIAL_ACTIONS[1]) {
      await delay(DELAY_TIME);
      // Set the predefined API response
      setMessages((old) => {
        const newArray = [
          ...old.slice(0, old.length - 2),
          { ...userMessage, tokens: 0 }, // Optional: add token information
          {
            author: authors[0],
            text: `Yes, we have a demo illustrating the combined capabilities of Microsoft Fabric and Azure Databricks with Unity Catalog to build an end-to-end analytics project. It focuses on persona-based experiences, eliminating data silos, and updating Databricks notebooks using OneLake endpoints.`,
            solution_play: "Microsoft Fabric + Azure Databricks",
            timestamp: new Date(),
            tokens: 0, // Optional: add token information
            suggestedActions: filteredSuggestedActions,
          } as Message,
        ];
        let tileTitle: string;
        dispatch(setSolutionPlay("Microsoft Fabric + Azure Databricks"));
        dispatch(
          setPreviousTileGlobally("Microsoft Fabric + Azure Databricks")
        );
        dispatch(
          setActiveTileGlobally(
            "Unify your Intelligent Data and Analytics Platform"
          )
        );
        dispatch(setActiveTileNumber("home"));
        localStorage.setItem(
          "ActiveTileGlobally",
          "Innovate with Azure AI Platform"
        );
        localStorage.setItem("ActiveTileNumber", "home");
        return newArray;
      });
    } else if (messageText === INITIAL_ACTIONS[2]) {
      // Set the predefined API response
      await delay(DELAY_TIME);

      setMessages((old) => {
        const newArray = [
          ...old.slice(0, old.length - 2),
          { ...userMessage, tokens: 0 }, // Optional: add token information
          {
            author: authors[0],
            text: `Yes, we have demo scenarios showcasing exciting new features of Microsoft Fabric, including Copilot to Dataflows Gen2, Real-Time Intelligence, OneLake Data Access Roles, Fast Copy, and Fabric AI Skill`,
            solution_play: "Microsoft Fabric",
            timestamp: new Date(),
            tokens: 0, // Optional: add token information
            suggestedActions: filteredSuggestedActions,
          } as Message,
        ];
        let tileTitle: string;
        dispatch(
          setPreviousTileGlobally("Microsoft Fabric + Azure Databricks")
        );
        dispatch(
          setActiveTileGlobally(
            "Unify your Intelligent Data and Analytics Platform"
          )
        );
        dispatch(setActiveTileNumber("home"));
        localStorage.setItem(
          "ActiveTileGlobally",
          "Unify your Intelligent Data and Analytics Platform"
        );
        localStorage.setItem("ActiveTileNumber", "home");
        dispatch(setSolutionPlay("Microsoft Fabric"));
        return newArray;
      });
    } else if (
      messageText === "Show me a demo for data security solution play?"
    ) {
      // Set the predefined API response
      await delay(DELAY_TIME);

      await setMessages((old) => {
        const newArray = [
          ...old.slice(0, old.length - 2),
          { ...userMessage, tokens: 0 }, // Optional: add token information
          {
            author: authors[0],
            text: `Yes, we have a demo showcasing how Microsoft Purview and Microsoft Fabric work together to store, analyze, and govern data, ensuring data discoverability, compliance, and security.`,
            solution_play: "Data Security",
            timestamp: new Date(),
            tokens: 0, // Optional: add token information
            suggestedActions: filteredSuggestedActions,
          } as Message,
        ];
        let tileTitle: string;
        dispatch(
          setPreviousTileGlobally("Microsoft Fabric + Azure Databricks")
        );
        dispatch(setActiveTileGlobally("Data Security"));
        dispatch(setActiveTileNumber("home"));
        localStorage.setItem("ActiveTileGlobally", "Data Security");
        localStorage.setItem("ActiveTileNumber", "home");
        return newArray;
      });
    } else {
      // Continue with the normal API call for other messages
      axios
        .post(COPILOT_API, {
          query: e?.message.text,
        })
        .then(({ data }) => {
          if (data?.answer) {
            setMessages((old) => {
              const newArray = [
                ...old.slice(0, old.length - 2),
                { ...userMessage, tokens: data?.question_tokens },
                {
                  author: authors[0],
                  text: `${data?.answer} \n Please visit the following link: <a href="${data?.link}" rel="noopener noreferrer">${data?.link}</a>`,
                  timestamp: new Date(),
                  data_points: data?.data_points,
                  thoughts: data?.thoughts,
                  tokens: data?.answer_tokens,
                  suggestedActions: data?.suggestions?.map((s: any) => ({
                    type: "reply",
                    value: s,
                  })),
                } as Message,
              ];
              dispatch(setSolutionPlay("Microsoft Purview"));
              return newArray;
            });
          } else {
            setMessages((old) => [...old.slice(0, old.length - 1)]);
          }
        })
        .catch((e) => console.log(e));
    }
  };

  const MessageTemplate = (props: any) => {
    return (
      props.item.text && (
        <div className="k-chat-bubble" key={props.item?.id}>
          {props?.item?.answer && (
            <strong style={{ marginTop: 4, paddingTop: 4 }}>Answer:</strong>
          )}

          <div
            dangerouslySetInnerHTML={{
              __html: props.item?.answer ?? props.item.text,
            }}
          />
          {props?.item?.author?.id == "bot" &&
            (props?.item?.resources?.length > 0 ||
              props?.item?.endToEndTrainings?.length > 0 ||
              props?.item?.decks?.length > 0) && (
              <>
                <br />

                <strong style={{ marginTop: 4, paddingTop: 4 }}>
                  Resources:
                </strong>

                {(
                  props?.item?.resources ||
                  props?.item?.endToEndTrainings ||
                  props?.item?.decks
                )?.length > 0 && (
                  <div className={styles.resourcesContainer}></div>
                )}
              </>
            )}
        </div>
      )
    );
  };
  useEffect(() => {
    const ele = document.getElementsByClassName(
      "k-message-list k-avatars"
    )?.[0];
    if (ele) {
      ele.scrollTop = ele.scrollHeight;
    }
  }, [messages]);
  return (
    <div className={styles.chatBot}>
      <div className={styles.chatHeader}>
        <div className={styles.headerTitle}>
          <h5>
            <strong>
              {isVideoCopilot
                ? "Copilot for Video"
                : "Data and AI DREAM Demo Assistant"}
            </strong>
          </h5>
          <Dismiss24Regular
            onClick={() => dispatch(setShowPopup(false))}
            style={{ cursor: "pointer" }}
          />
          {/* <Delete24Regular
            onClick={() => {
              setActions(INITIAL_ACTIONS);

              setMessages([
                {
                  author: {
                    id: "bot",
                    avatarUrl:
                      "https://fabricresourceshub.blob.core.windows.net/assets/fabric_resources_bot.png",
                  },
                  text: "Hello, I am Cora - your Data and AI Resources Copilot. How can I help you?",
                  suggestedActions: INITIAL_ACTIONS,
                },
              ]);
            }}
            className={styles.deleteIcon}
          /> */}
          {/* <span>Powered by Azure OpenAI Service</span> */}
        </div>
      </div>
      <Chat
        user={authors[1]}
        messages={messages}
        placeholder="Search demo..."
        onMessageSend={onMessageSend}
        messageBox={customMessage}
        messageTemplate={MessageTemplate}
      />
      <div className={styles.disclaimerText}>
        AI generated content may be incomplete or factually incorrect.
      </div>
    </div>
  );
};
