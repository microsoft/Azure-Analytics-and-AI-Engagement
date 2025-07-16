import { useRef, useState, useEffect, useContext } from "react";
import styles from "./Chat.module.scss";
import { v4 as uuidv4 } from "uuid";
import {
  chatApi,
  Approaches,
  AskResponse,
  ChatRequest,
  ChatTurn,
  uploadDataChatApi,
  ChatRequest2,
  ChatMessage,
} from "api";
import {
  Answer,
  AnswerError,
  AnswerLoading,
  Example,
} from "components/OpenAIChat";
import { QuestionInput } from "components/OpenAIChat";
import { ExampleList } from "components/OpenAIChat";
import { UserChatMessage } from "components/OpenAIChat";
import { AnalysisPanel, AnalysisPanelTabs } from "components/OpenAIChat";
import { ClearChatButton } from "components/OpenAIChat";
import { Switch, SwitchChangeEvent } from "@progress/kendo-react-inputs";
import { UploadPanel } from "../UploadPanel/UploadPanel";
import { DemoContext } from "context/DemoContext";
import { useMic } from "hooks/useMic";
import { Popup } from "components";
import {
  Camera20Regular,
  Camera24Filled,
  Mic24Filled,
  Mic28Filled,
} from "@fluentui/react-icons";
import { Tooltip } from "@progress/kendo-react-tooltip";
import { setSelectedQuestion } from "store";
import { useAppDispatch, useAppSelector } from "hooks";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { ArchitectureWithTags } from "pages";
import { PageType } from "types";
import { Button } from "@progress/kendo-react-buttons";
import { SidebarToggleIcon } from "assets";
import { PivotItem } from "@fluentui/react";
import { SvgIcon } from "@progress/kendo-react-common";
import { uploadIcon } from "@progress/kendo-svg-icons";
import axios from "axios";
import { setShowPopup } from "store";
import {
  TabStrip,
  TabStripSelectEventArguments,
  TabStripTab,
} from "@progress/kendo-react-layout";
import { ArchitectureIcon } from "assets/ArchitectureIcon";
import { DropDownList } from "@progress/kendo-react-dropdowns";
const {
  endPointURL,
  backgroundImageURL,
  chatImageLogoURL,
  subTitle,
  prompt1,
  prompt2,
  prompt3,
  prompt4,
  questionPlaceHolder,
  title,
  chatApproach,
  chatCompany,
  disableTitle,
  description,
  index,
  container,
  tryYourOwnDataEndpoint,
} = window.config;

export const Chat = (props: any) => {
  const {
    config,
    setBackground,
    setEndpoint,
    setLogo,
    setPrompt1,
    setPrompt2,
    setPrompt3,
    setPrompt4,
    setPlaceholderQuestion,
    setTitle,
  } = useContext(DemoContext);

  const [showSidebar, setShowSidebar] = useState(false);
  const lastQuestionRef = useRef<string>("");
  const chatMessageStreamEnd = useRef<HTMLDivElement | null>(null);
  const timerRef: any = useRef(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<unknown>();
  const [isPressed, setIsPressed] = useState(false);
  const [text] = useState("");
  const [activeCitation, setActiveCitation] = useState<string>();
  const [selectedTap, setSelectedTap] = useState(1);
  const handleSelect = (e: TabStripSelectEventArguments) => {
    setSelectedTap(e.selected);
  };
  const [activeAnalysisPanelTab, setActiveAnalysisPanelTab] = useState<
    AnalysisPanelTabs | undefined
  >(undefined);
  const onTextSend = (text: string) => {
    uploadToggle ? makeCustomUploadApiRequest(text) : makeApiRequest(text);
  };
  const [sttFromMic] = useMic(text, onTextSend);
  const [selectedAnswer, setSelectedAnswer] = useState<number>(0);
  const [answers, setAnswers] = useState<
    [user: string, response: AskResponse][]
  >([]);
  const [externalDomain, setExternalDomain] = useState(false);
  const [uploadToggle, setUploadToggle] = useState(false);
  const [showArchPopup, setShowArchPopup] = useState(false);
  const [popupImage, setPopupImage] = useState<string>("");
  const handlePopupOpen = (image: string) => {
    setPopupImage(image);
    setShowArchPopup(true);
  };
  const [fileUploadResponse, setFileUploadResponse] = useState<any>({
    index_name: "b433cfdc-1720520340196",
    container_name: "c1feefd6-1720520340196",
  });
  let previousMessages: ChatMessage[] = [];
  const [selectedModel, setSelectedModel] = useState("GPT-4"); // Default to GPT-4
  const [showNews, setshowNews] = useState(false);
  const [isImageVisible, setIsImageVisible] = useState(false);
  const [isImage, setIsImage] = useState("");
  const { question } = useAppSelector((state) => state.config);
  const dispatch = useAppDispatch();
  const location = useLocation();
  const handleModelChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSelectedModel(e.target.value);
  };
  // const { showArchPopup, hideTooltips } = useAppSelector(
  //   (state) => state.config
  // );
  let popupTitle = " ";
  useEffect(
    function () {
      if (endPointURL) {
        setEndpoint(endPointURL);
      }
      lastQuestionRef.current = "";
      setAnswers([]);
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [endPointURL]
  );

  const setPromptsTitleAndImages = () => {
    setBackground(
      // localStorage.getItem(`${name}-background`) ??
      backgroundImageURL
    );
    setLogo(
      // localStorage.getItem(`${name}-logo`) ??
      props?.componentParameters?.chatImageLogoURL ?? chatImageLogoURL
    );
    setTitle(
      // localStorage.getItem(`${name}-title`) ??
      subTitle
    );
    setPrompt1(
      // localStorage.getItem(`${name}-prompt1`) ??
      props?.componentParameters?.prompt1 ?? prompt1
    );
    setPrompt2(
      // localStorage.getItem(`${name}-prompt2`) ??
      props?.componentParameters?.prompt2 ?? prompt2
    );
    setPrompt3(
      // localStorage.getItem(`${name}-prompt3`) ??
      props?.componentParameters?.prompt3 ?? prompt3
    );
    setPrompt4(
      // localStorage.getItem(`${name}-prompt3`) ??
      props?.componentParameters?.prompt4 ?? prompt4
    );
    setPlaceholderQuestion(
      // localStorage.getItem(`${name}-question`) ??
      props?.componentParameters?.placeholderQuestion ?? questionPlaceHolder
    );
  };

  useEffect(() => {
    setPromptsTitleAndImages();
    setUploadToggle(false);
    setShowSidebar(false);
    setExternalDomain(false);
    setIsImageVisible(false);

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [title]);

  const makeApiRequest = async (question: string) => {
    lastQuestionRef.current = question;
    error && setError(undefined);
    setIsLoading(true);
    setShowSidebar(false);
    setActiveCitation(undefined);
    setActiveAnalysisPanelTab(undefined);
    const endpoint =
      selectedModel === "GPT-4"
        ? "https://func-rsva-chatbot.azurewebsites.net/api/chat_gpt4o"
        : "https://func-rsva-chatbot.azurewebsites.net/api/chat_o1preview";
    try {
      const history: ChatTurn[] = answers.map((a) => ({
        user: a[0],
        bot: a[1].answer,
      }));
      const userMessage: ChatMessage = {
        id: uuidv4(), // Generating a unique ID for the message
        role: "user",
        content: question,
        date: new Date().toISOString(),
      };
      const requestPayload: any = {
        question: question,
      };
      const result = await chatApi(
        requestPayload,

        endpoint
      );
      const botMessage: ChatMessage = {
        id: uuidv4(),
        role: "assistant",
        content: result.answer,
        date: new Date().toISOString(),
      };

      previousMessages = [...previousMessages, botMessage];
      setAnswers([...answers, [question, result]]);
    } catch (e) {
      setError(e);
    } finally {
      setIsLoading(false);
    }
  };

  const makeCustomUploadApiRequest = async (question: string) => {
    lastQuestionRef.current = question;
    error && setError(undefined);
    setIsLoading(true);
    setActiveCitation(undefined);
    // setActiveAnalysisPanelTab(undefined);

    try {
      const history: ChatTurn[] = answers.map((a) => ({
        user: a[0],
        bot: a[1].answer,
      }));

      const request: ChatRequest = {
        history: [...history, { user: question, bot: undefined }],
        approach: Approaches.ReadRetrieveRead,
        overrides: {
          promptTemplate:
            config?.promptTemplate?.length === 0
              ? undefined
              : config?.promptTemplate,
          excludeCategory:
            config?.excludeCategory?.length === 0
              ? undefined
              : config?.excludeCategory,
          top: config?.retrieveCount,
          semanticRanker: config?.useSemanticRanker,
          semanticCaptions: config?.useSemanticCaptions,
          suggestFollowupQuestions: config?.useSuggestFollowupQuestions,
        },
        enableExternalDomain: externalDomain,
        container: fileUploadResponse.container_name,
        index: fileUploadResponse.index_name,
      };
      const result = await uploadDataChatApi(request, endPointURL + "/chat");
      setAnswers([...answers, [question, result]]);
    } catch (e) {
      setError(e);
    } finally {
      setIsLoading(false);
    }
  };

  const clearChat = () => {
    lastQuestionRef.current = "";
    error && setError(undefined);
    setActiveCitation(undefined);
    setAnswers([]);
    setshowNews(false);
    setIsImageVisible(false);
  };

  useEffect(
    () => chatMessageStreamEnd.current?.scrollIntoView({ behavior: "smooth" }),
    [isLoading]
  );

  useEffect(() => {
    setBackground(
      // localStorage.getItem(`${name}-background`) ??
      backgroundImageURL
    );
    return setLogo(
      // localStorage.getItem(`${name}-logo`) ??
      props?.componentParameters?.chatImageLogoURL ?? chatImageLogoURL
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // useEffect(() => {
  //   const fetchData = async () => {
  //     const response = await axios.get(
  //       "https://sduag1-app-service.azurewebsites.net/api/users"
  //     );
  //     console.log(response);
  //     //setData(response.data);
  //   };

  //   fetchData();
  // }, []);

  useEffect(() => {
    if (props.isClearChat) {
      clearChat();
      setUploadToggle(false);
      setShowSidebar(false);
      setExternalDomain(false);
      setIsImageVisible(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.isClearChat]);

  const onExampleClicked = (example: string) => {
    dispatch(setSelectedQuestion(example));
    makeApiRequest(example);
    // if (example === prompt1) {
    //   //setIsImage("https://nrfcdn.azureedge.net/Arrow-A.png");
    // }
    // if (example === prompt2) {
    //   //setIsImage("https://nrfcdn.azureedge.net/Arrow-B.png");
    // }
    // if (example == prompt1 || example == prompt2) {
    //   //setIsImageVisible(true);
    // }
  };
  const handleMouseDown = () => {
    setIsPressed(true);
    timerRef.current = setTimeout(() => {
      (sttFromMic as any)();
      // Perform the desired action when the button is held down
    }, 1000); // Adjust the duration as needed
  };

  const handleMouseUp = () => {
    clearTimeout(timerRef.current);
    setIsPressed(false);
  };
  const onShowCitation = (citation: string, index: number) => {
    // if (
    //   activeCitation === citation &&
    //   activeAnalysisPanelTab === AnalysisPanelTabs.CitationTab &&
    //   selectedAnswer === index
    // ) {
    //   setActiveAnalysisPanelTab(undefined);
    //   setShowSidebar(false);
    // } else {
    setActiveCitation(citation);
    setActiveAnalysisPanelTab(AnalysisPanelTabs.CitationTab);
    setShowSidebar(true);
    // }

    setSelectedAnswer(index);
  };

  const onContextReady = (result: string) => {};

  const onToggleTab = (tab: AnalysisPanelTabs, index: number) => {
    // if (activeAnalysisPanelTab === tab && selectedAnswer === index) {
    //   setActiveAnalysisPanelTab(undefined);
    // } else {
    setActiveAnalysisPanelTab(tab);
    setShowSidebar(true);
    // }

    setSelectedAnswer(index);
  };

  const onToggleExternalDomain = (event: SwitchChangeEvent) => {
    setExternalDomain(event.target.value);
  };

  const onToggleUploadButton = (event: SwitchChangeEvent) => {
    if (event.target.value) {
      setFileUploadResponse({});
    }
    setExternalDomain(false);
    setUploadToggle(event.target.value);
    if (event.target.value) {
      setShowSidebar(true);
      setActiveAnalysisPanelTab(AnalysisPanelTabs.UploadTab);
    } else {
      setActiveAnalysisPanelTab(undefined);
      setShowSidebar(false);
    }
    clearChat();
  };
  const [copiedQuestion, setCopiedQuestion] = useState("");
  const [isReplay, setIsReplay] = useState(false);
  const onCopyMessage = (message: string) => {
    setCopiedQuestion(message);
  };
  const showNewsImage = () => {
    setshowNews(true);
    //setIsImageVisible(false);
  };
  const [state, setState] = useState({
    value: {
      text: "Azure Portal",
      link: "https://portal.azure.com/#@CloudLabsAIoutlook.onmicrosoft.com/resource/subscriptions/506e86fc-853c-4557-a6e5-ad72114efd2b/resourceGroups/rg-retail3.0-prod/overview",
      id: 1,
    },
  });

  const dropdownOptions = [
    {
      text: "Azure Portal",
      link: "https://portal.azure.com/#@CloudLabsAIoutlook.onmicrosoft.com/resource/subscriptions/506e86fc-853c-4557-a6e5-ad72114efd2b/resourceGroups/rg-retail3.0-prod/overview",
      id: 1,
    },
    // {
    //   text: "Azure AI Foundry",
    //   link: "https://ai.azure.com/managementCenter/hub/overview?tid=f94768c8-8714-4abe-8e2d-37a64b18216a&wsid=/subscriptions/506e86fc-853c-4557-a6e5-ad72114efd2b/resourcegroups/rg-retail3.0-prod/providers/Microsoft.MachineLearningServices/workspaces/hub-retail30-prod-001",
    //   id: 2,
    // },
  ];

  const handleChange = (e: any) => {
    setState({
      value: e.target.value,
    });
  };

  const handleButtonClick = () => {
    const selectedOption = dropdownOptions.find(
      (option) => option.text === state.value.text
    );
    if (selectedOption) {
      const newWindow = window.open(selectedOption.link, "_blank");

      //window.open(selectedOption.link, "_blank");
    }
  };
  return (
    <div key={props?.componentParameters?.prompt1} className={styles.container}>
      <div className={styles.subContainer}>
        <div className={styles.chatRoot}>
          {" "}
          <div className={styles.modelSelection}>
            <label className={styles.radioLabel}>
              <input
                type="radio"
                value="GPT-4"
                checked={selectedModel === "GPT-4"}
                onChange={handleModelChange}
                className={styles.radioInput}
              />
              GPT-4o
            </label>
            <label className={styles.radioLabel}>
              <input
                type="radio"
                value="GPT"
                checked={selectedModel === "GPT"}
                onChange={handleModelChange}
                className={styles.radioInput}
              />
              o1-preview
            </label>
          </div>
          <div
            className={styles.chatContainer}
            style={{
              ...(showSidebar && { marginRight: "25vw" }),
            }}
          >
            <div
              className={styles.chatContainermanufacturingShadow}
              style={{
                paddingBottom: 40,
              }}
            >
              {!lastQuestionRef.current ? (
                <div className={styles.chatDetails}>
                  <div className={styles.imgLogo}>
                    <img
                      src="https://dreamdemoassets.blob.core.windows.net/nrf/mcfr-ai-logo.png"
                      alt=""
                    />
                  </div>

                  <h3 className={styles.startChat}>
                    Retail Strategy Virtual Advisor{" "}
                  </h3>
                  <p>This chatbot is configured to answer your questions</p>
                </div>
              ) : (
                <div className={styles.chatMessageStream}>
                  {answers.map((answer, index) => (
                    <div key={index}>
                      <UserChatMessage
                        message={answer[0]}
                        disabled={isLoading}
                        onCopyMessage={onCopyMessage}
                        setIsReplay={setIsReplay}
                      />
                      <div className={styles.chatMessageGpt}>
                        <Answer
                          key={index}
                          answer={answer[1]}
                          isSelected={
                            selectedAnswer === index &&
                            activeAnalysisPanelTab !== undefined
                          }
                          onCitationClicked={(c) => {
                            onShowCitation(c, index);
                          }}
                          onThoughtProcessClicked={() =>
                            onToggleTab(
                              AnalysisPanelTabs.ThoughtProcessTab,
                              index
                            )
                          }
                          onSupportingContentClicked={() =>
                            onToggleTab(
                              AnalysisPanelTabs.SupportingContentTab,
                              index
                            )
                          }
                          onFollowupQuestionClicked={(q) => makeApiRequest(q)}
                          showFollowupQuestions={
                            config?.useSuggestFollowupQuestions &&
                            answers?.length - 1 === index
                          }
                          endpoint={config?.endPoint}
                          container={
                            !uploadToggle
                              ? props?.componentParameters?.container ??
                                container
                              : fileUploadResponse?.container_name
                          }
                        />
                      </div>
                    </div>
                  ))}
                  {isLoading && (
                    <>
                      <UserChatMessage
                        message={lastQuestionRef.current}
                        disabled={isLoading}
                        onCopyMessage={onCopyMessage}
                        setIsReplay={setIsReplay}
                      />
                      <div className={styles.chatMessageGptMinWidth}>
                        <AnswerLoading />
                      </div>
                    </>
                  )}
                  {error ? (
                    <>
                      <UserChatMessage
                        message={lastQuestionRef.current}
                        disabled={isLoading}
                        onCopyMessage={onCopyMessage}
                        setIsReplay={setIsReplay}
                      />
                      <div className={styles.chatMessageGptMinWidth}>
                        <AnswerError
                          error={error.toString()}
                          onRetry={() =>
                            makeApiRequest(lastQuestionRef.current)
                          }
                        />
                      </div>
                    </>
                  ) : null}
                  <div ref={chatMessageStreamEnd} />
                </div>
              )}
              <div className={styles.chatInput}>
                <QuestionInput
                  key={config.placeholderQuestion}
                  copiedQuestion={copiedQuestion}
                  setCopiedQuestion={setCopiedQuestion}
                  isReplay={isReplay}
                  setIsReplay={setIsReplay}
                  clearOnSend
                  placeholder={
                    props?.componentParameters?.placeholderQuestion ??
                    config?.placeholderQuestion
                  }
                  disabled={isLoading}
                  onSend={(question) =>
                    uploadToggle
                      ? makeCustomUploadApiRequest(question)
                      : makeApiRequest(question)
                  }
                />
                {/* <div className={styles.mic1}
          title="Hold to Speak"
          onMouseDown={handleMouseDown}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          
        >
          <Mic28Filled
                className={styles.mic}
                primaryFill="var(--primary-color)"
              />
        </div> */}
                <div className={styles.chatInputFooter}>
                  <ClearChatButton
                    className={styles.clearChatButton}
                    onClick={() => {
                      clearChat();
                      setShowSidebar(false);
                    }}
                    disabled={!lastQuestionRef.current || isLoading}
                  />
                </div>
              </div>
              {!uploadToggle && (
                <ExampleList
                  examples={[
                    // {
                    //   text:
                    //     // localStorage.getItem(
                    //     //   `${name}-prompt1`
                    //     // ) ??
                    //     props?.componentParameters?.prompt1 ?? prompt1,
                    //   value:
                    //     // localStorage.getItem(
                    //     //   `${name}-prompt1`
                    //     // ) ??
                    //     props?.componentParameters?.prompt1 ?? prompt1,
                    // },
                    {
                      text:
                        // localStorage.getItem(
                        //   `${name}-prompt2`
                        // ) ??
                        props?.componentParameters?.prompt2 ?? prompt2,
                      value:
                        // localStorage.getItem(
                        //   `${name}-prompt2`
                        // ) ??
                        props?.componentParameters?.prompt2 ?? prompt2,
                    },
                    {
                      text:
                        // localStorage.getItem(
                        //   `${name}-prompt3`
                        // ) ??
                        props?.componentParameters?.prompt3 ?? prompt3,
                      value:
                        // localStorage.getItem(
                        //   `${name}-prompt3`
                        // ) ??
                        props?.componentParameters?.prompt3 ?? prompt3,
                    },
                    {
                      text:
                        // localStorage.getItem(
                        //   `${name}-prompt3`
                        // ) ??
                        props?.componentParameters?.prompt4 ?? prompt4,
                      value:
                        // localStorage.getItem(
                        //   `${name}-prompt3`
                        // ) ??
                        props?.componentParameters?.prompt4 ?? prompt4,
                    },
                  ]}
                  onExampleClicked={onExampleClicked}
                />
              )}{" "}
              <div
                className={styles.note}
                style={{
                  marginBottom:
                    uploadToggle && lastQuestionRef.current ? 12 : 0,
                }}
              >
                AI generated content may be incomplete or factually incorrect.
              </div>
            </div>
          </div>
          <div
            className={styles.rightSidebar}
            style={{
              ...(showSidebar && { width: "25vw", padding: "8px 16px" }),
            }}
          >
            <div
              className={styles.sidebarToggleIcon}
              onClick={() => {
                if (activeAnalysisPanelTab || uploadToggle) {
                  setShowSidebar((old) => !old);
                }
              }}
            >
              <SidebarToggleIcon rotate={showSidebar ? "0deg" : "180deg"} />
            </div>

            <div
              style={{
                ...(!showSidebar && { visibility: "hidden" }),
                width: "100%",
                height: "100%",
              }}
            >
              {(activeAnalysisPanelTab !== undefined ||
                activeAnalysisPanelTab !== null) && (
                <AnalysisPanel
                  className={styles.chatAnalysisPanel}
                  activeCitation={activeCitation}
                  onActiveTabChanged={(x) => onToggleTab(x, selectedAnswer)}
                  citationHeight="810px"
                  answer={answers?.[selectedAnswer]?.[1]}
                  activeTab={activeAnalysisPanelTab!}
                  onContextReady={onContextReady}
                  setFileUploadResponse={setFileUploadResponse}
                  uploadToggle={uploadToggle}
                />
              )}
            </div>
          </div>
        </div>
      </div>
      <div className={styles.buttonsContainer}>
        {/* <div className={styles.archButton1}>
          <span className={styles.backed} onClick={handleButtonClick}>
            Backend
          </span>
          <DropDownList
            data={dropdownOptions}
            defaultValue="Azure Portal"
            textField="text"
            value={state.value}
            onChange={handleChange}
            style={{ width: "180px" }}
          />
        </div> */}
        <span
          onClick={() => handlePopupOpen("")}
          // className={"secondaryButton"}
        >
          {/* Architecture Diagram */}
          <ArchitectureIcon />
        </span>
        {/* <div className={styles.archButton}>
              <span className={styles.backed}>Backend</span>
              <div style={{ width: "180px" }}>Retail</div>
        </div> */}
        {/* <a
          target="_blank"
          className={styles.externalArrow}
          href={
            "https://portal.azure.com/#@CloudLabsAIoutlook.onmicrosoft.com/resource/subscriptions/506e86fc-853c-4557-a6e5-ad72114efd2b/resourceGroups/rg-retail3.0-prod/overview"
          }
        >
          Backend
        </a> */}

        <a
          target="_blank"
          className={styles.secondaryButton}
          href={
            "https://retailcognitivesearch.blob.core.windows.net/data/Comparative-Analysis-of-Potential-Acquisitions-for-Contoso.pptx"
          }
        >
          Create Presentation
        </a>
      </div>

      <Popup
        showPopup={showArchPopup}
        title={popupTitle}
        onClose={() => setShowArchPopup(false)}
        dialogWidth={1400}
        dialogHeight={960}
      >
        {/* <ArchitectureWithTags
          pageTitle={"Architecture diagram"}
          pageType={PageType.Architecture}
          imageUrl={popupImage}
          tags={[]}
        /> */}
        <TabStrip selected={selectedTap} onSelect={handleSelect}>
          <TabStripTab title="Architecture Diagram: GPT-4o">
            <ArchitectureWithTags
              pageTitle={"Architecture diagram"}
              pageType={PageType.Architecture}
              imageUrl={
                "https://dreamdemoassets.blob.core.windows.net/nrf/Retail_Strategy_Gpt4.png"
              }
              tags={[
                {
                  tagName: "Enter your question",
                  tagDescription: "Enter your question",
                },
                {
                  tagName: "Extract Keywords",
                  tagDescription: "Extract Keywords",
                },
                {
                  tagName: "Search",
                  tagDescription: "Search",
                },
                {
                  tagName: "Search Results",
                  tagDescription: "Search Results",
                },
                {
                  tagName: "Query and Search Results",
                  tagDescription: "Query and Search Results",
                },
                {
                  tagName: "Response",
                  tagDescription: "Response",
                },
              ]}
            />
          </TabStripTab>
          <TabStripTab title="Architecture Diagram: o1-preview">
            <ArchitectureWithTags
              pageTitle={"Architecture diagram"}
              pageType={PageType.Architecture}
              imageUrl={
                "https://dreamdemoassets.blob.core.windows.net/nrf/Retail_Strategy_O1P.png"
              }
              tags={[
                {
                  tagName: "Enter your question",
                  tagDescription: "Enter your question",
                },
                {
                  tagName: "Extract Keywords",
                  tagDescription: "Extract Keywords",
                },
                {
                  tagName: "Search",
                  tagDescription: "Search",
                },
                {
                  tagName: "Search Results",
                  tagDescription: "Search Results",
                },
                {
                  tagName: "Query and Search Results",
                  tagDescription: "Query and Search Results",
                },
                {
                  tagName: "Response",
                  tagDescription: "Response",
                },
              ]}
            />
          </TabStripTab>
        </TabStrip>
      </Popup>
    </div>
  );
};
