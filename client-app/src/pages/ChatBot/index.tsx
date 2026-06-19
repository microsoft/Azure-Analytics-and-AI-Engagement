import { Dispatch, FC, SetStateAction, useEffect, useState } from "react";
import { OpenAIChatLayout, ExampleModel, Chat } from "components/OpenAIChat";
import { ConfigPanel } from "components/OpenAIChat/ConfigPanel";

interface ChatBotProps {
  INITIAL_ACTIONS: any; // You can replace 'any' with a more specific type if known
  messages: string;
  setMessages: Dispatch<SetStateAction<string>>;
  actions: any; // Replace 'any' with a specific type if possible
  setActions: Dispatch<SetStateAction<any>>; // Replace 'any' if possible
  type: any; // Replace 'any' with a specific type if possible
  setType: Dispatch<SetStateAction<any>>; // Replace 'any' if possible
}

export const ChatBot: FC<ChatBotProps> = ({
  INITIAL_ACTIONS,
  messages,
  setMessages,
  actions,
  setActions,
  type,
  setType,
}) => {
  const [demo, setDemo] = useState<any>({ name: "", endPointURL: "" });
  const componentParameters = {
    INITIAL_ACTIONS,
    messages,
    setMessages,
    actions,
    setActions,
    type,
    setType,
  };
  const [sampleQuestions, setSampleQuestions] = useState<ExampleModel[]>([
    {
      text: "What are some safety tips for factory floor?",
      value: "What are some safety tips for factory floor?",
    },
    {
      text: "Is there a procedure for reporting unsafe behavior?",
      value: "Is there a procedure for reporting unsafe behavior?",
    },
    {
      text: "What type of PPE is required on the factory floor?",
      value: "What type of PPE is required on the factory floor?",
    },
  ]);

  const [isConfigPanelOpen, setConfigPanelOpen] = useState<boolean>(false);
  const [isClearChat, setClearChat] = useState<boolean>(false);

  const onDemoChange = (demo: any) => {
    setSampleQuestions([
      {
        text: demo.prompt1,
        value: demo.prompt1,
      },
      {
        text: demo.prompt2,
        value: demo.prompt2,
      },
      {
        text: demo.prompt3,
        value: demo.prompt3,
      },
      {
        text: demo.prompt4,
        value: demo.prompt4,
      },
    ]);
    setDemo(demo);
  };

  const onConfigPanelSettingChange = (isPanelOpen: boolean) => {
    setConfigPanelOpen(isPanelOpen);
  };

  const onsetClearChat = () => {
    setClearChat(true);
  };

  useEffect(() => {
    setClearChat(false);
  }, [demo]);

  return (
    <OpenAIChatLayout
      setDemo={setDemo}
      onDemoChange={onDemoChange}
      onConfigPanelSettingChange={onConfigPanelSettingChange}
      onsetClearChat={onsetClearChat}
    >
      <Chat
        demo={demo}
        onConfigPanelSettingChange={onConfigPanelSettingChange}
        isConfigPanelOpen={isConfigPanelOpen}
        sampleQuestions={sampleQuestions}
        isClearChat={isClearChat}
        componentParameters={componentParameters}
      />
      <ConfigPanel />
    </OpenAIChatLayout>
  );
};
