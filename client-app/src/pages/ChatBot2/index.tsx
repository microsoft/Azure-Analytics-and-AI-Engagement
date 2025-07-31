import { FC, useEffect, useState } from "react";
import { OpenAIChatLayout, ExampleModel, Chat } from "components/OpenAIChat";
import { ConfigPanel } from "components/OpenAIChat/ConfigPanel";

interface Props {
  componentParameters?: any;
}

export const ChatBot2: FC<Props> = ({ componentParameters }) => {
  const [demo, setDemo] = useState<any>({ name: "", endPointURL: "" });

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
