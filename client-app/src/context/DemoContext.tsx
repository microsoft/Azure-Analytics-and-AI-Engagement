import {
  createContext,
  FC,
  ReactNode,
  useContext,
  useEffect,
  useState,
} from "react";
import { SettingsContext } from "./SettingsContext";
import { useLocation } from "react-router-dom";

interface Props {
  children: ReactNode;
}

/**
 * TODO: Change all any types to proper types
 */
export const DemoContextProvider: FC<Props> = ({ children }) => {
  const [demos, setDemos] = useState<any>([]);
  const [config, setConfig] = useState<any>({});
  const [isConfigPanelOpen, setIsConfigPanelOpen] = useState(false);
  const location = useLocation();
  const { currentDemo } = useContext(SettingsContext);
  useEffect(() => {
    if (location.pathname !== "/settings")
      document.body.style.backgroundImage = `url(${config?.background})`;
    document.body.style.backgroundSize = "cover";

    switch (currentDemo?.name) {
      case "Retail":
        document.body.classList.add("retail-demo");
        document.body.classList.remove("manufacturing-demo");
        break;
      case "Manufacturing":
      case "GM":
        document.body.classList.add("manufacturing-demo");
        document.body.classList.remove("retail-demo");
        break;
      default:
        document.body.classList.remove("retail-demo");
        document.body.classList.remove("manufacturing-demo");
        break;
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentDemo, config?.background]);

  useEffect(() => {
    if (location.pathname === "/settings")
      document.body.style.backgroundImage = "";
  }, [location]);

  useEffect(() => {
    if (currentDemo?.name) {
      setConfig((old: any) => ({
        ...old,
        logo: currentDemo.logoImageURL,
        title: currentDemo.title,
        endPoint: currentDemo.endPointURL,
        prompt1: currentDemo.prompt1,
        prompt2: currentDemo.prompt2,
        prompt3: currentDemo.prompt3,
        prompt4: currentDemo.prompt4,
        placeholderQuestion: currentDemo.questionPlaceHolder,
      }));
    }
  }, [currentDemo]);

  const setRetrieveCount = (value: number) => {
    setConfig((old: any) => ({ ...old, retrieveCount: value }));
  };

  const setUseSemanticRanker = (value: boolean) => {
    setConfig((old: any) => ({ ...old, useSemanticRanker: value }));
  };

  const setUseSemanticCaptions = (value: boolean) => {
    setConfig((old: any) => ({ ...old, useSemanticCaptions: value }));
  };

  const setExcludeCategory = (value: string) => {
    setConfig((old: any) => ({ ...old, excludeCategory: value }));
  };

  const setUseSuggestFollowupQuestions = (value: boolean) => {
    setConfig((old: any) => ({ ...old, useSuggestFollowupQuestions: value }));
  };

  const setPromptTemplate = (value: string) => {
    setConfig((old: any) => ({ ...old, promptTemplate: value }));
  };

  const setEndpoint = (value: string) => {
    if (currentDemo?.endPointURL) {
      localStorage.setItem(
        `${currentDemo.name}-endpoint`,
        value ?? currentDemo?.endPointURL
      );
    }
    setConfig((old: any) => ({
      ...old,
      endPoint:
        //  localStorage.getItem(`${currentDemo?.name}-endpoint`) ??
        value,
    }));
  };

  const setPlaceholderQuestion = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-question`, value);
    setConfig((old: any) => ({
      ...old,
      placeholderQuestion:
        // localStorage.getItem(`${currentDemo?.name}-question`) ??
        value,
    }));
  };

  const setPrompt1 = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-prompt1`, value);
    setConfig((old: any) => ({
      ...old,
      prompt1:
        // localStorage.getItem(`${currentDemo?.name}-prompt1`) ??
        value,
    }));
  };

  const setPrompt2 = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-prompt2`, value);
    setConfig((old: any) => ({
      ...old,
      prompt2:
        // localStorage.getItem(`${currentDemo?.name}-prompt2`) ??
        value,
    }));
  };

  const setPrompt3 = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-prompt3`, value);
    setConfig((old: any) => ({
      ...old,
      prompt3:
        //  localStorage.getItem(`${currentDemo?.name}-prompt3`) ??
        value,
    }));
  };
  const setPrompt4 = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-prompt4`, value);
    setConfig((old: any) => ({
      ...old,
      prompt3:
        //  localStorage.getItem(`${currentDemo?.name}-prompt3`) ??
        value,
    }));
  };
  const setLogo = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-logo`, value);
    setConfig((old: any) => ({
      ...old,
      logo:
        // localStorage.getItem(`${currentDemo?.name}-logo`) ??
        value,
    }));
  };

  const setTitle = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-title`, value);
    setConfig((old: any) => ({
      ...old,
      title:
        // localStorage.getItem(`${currentDemo?.name}-title`) ??
        value,
    }));
  };

  const setBackground = (value: string) => {
    if (currentDemo?.name)
      localStorage.setItem(`${currentDemo.name}-background`, value);
    setConfig((old: any) => ({
      ...old,
      background:
        // localStorage.getItem(`${currentDemo?.name}-background`) ??
        value,
    }));
  };

  const setConfigPanel = (value: boolean) => {
    setIsConfigPanelOpen(value);
  };

  return (
    <DemoContext.Provider
      value={{
        config,
        demos,
        isConfigPanelOpen,
        setBackground,
        setConfigPanel,
        setEndpoint,
        setExcludeCategory,
        setLogo,
        setPlaceholderQuestion,
        setPrompt1,
        setPrompt2,
        setPrompt3,
        setPrompt4,
        setRetrieveCount,
        setTitle,
        setUseSemanticCaptions,
        setUseSemanticRanker,
        setUseSuggestFollowupQuestions,
        setDemos,
        setPromptTemplate,
      }}
    >
      {children}
    </DemoContext.Provider>
  );
};

interface ContextType {
  config: any;
  demos: any[];
  isConfigPanelOpen: boolean;
  setRetrieveCount: (value: number) => void;
  setUseSemanticRanker: (value: boolean) => void;
  setUseSemanticCaptions: (value: boolean) => void;
  setExcludeCategory: (value: string) => void;
  setUseSuggestFollowupQuestions: (value: boolean) => void;
  setEndpoint: (value: string) => void;
  setPlaceholderQuestion: (value: string) => void;
  setPrompt1: (value: string) => void;
  setPrompt2: (value: string) => void;
  setPrompt3: (value: string) => void;
  setPrompt4: (value: string) => void;
  setLogo: (value: string) => void;
  setTitle: (value: string) => void;
  setBackground: (value: string) => void;
  setConfigPanel: (value: boolean) => void;
  setDemos: (value: any[]) => void;
  setPromptTemplate: (value: string) => void;
}

export const DemoContext = createContext<ContextType>({
  config: {},
  demos: [],
  isConfigPanelOpen: false,
  setRetrieveCount: (value: number) => {},
  setUseSemanticRanker: (value: boolean) => {},
  setUseSemanticCaptions: (value: boolean) => {},
  setExcludeCategory: (value: string) => {},
  setUseSuggestFollowupQuestions: (value: boolean) => {},
  setEndpoint: (value: string) => {},
  setPlaceholderQuestion: (value: string) => {},
  setPrompt1: (value: string) => {},
  setPrompt2: (value: string) => {},
  setPrompt3: (value: string) => {},
  setPrompt4: (value: string) => {},
  setLogo: (value: string) => {},
  setTitle: (value: string) => {},
  setBackground: (value: string) => {},
  setConfigPanel: (value: boolean) => {},
  setDemos: (value: any[]) => {},
  setPromptTemplate: (value: string) => {},
});
