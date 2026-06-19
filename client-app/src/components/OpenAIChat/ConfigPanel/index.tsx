import {
  Checkbox,
  DefaultButton,
  Panel,
  SpinButton,
  TextField,
} from "@fluentui/react";
import React, { FC, useContext } from "react";
import styles from "./styles.module.scss";
import { DemoContext } from "context/DemoContext";
import { SettingsContext } from "context";

const {
  backgroundImageURL,
  logoImageURL,
  endPointURL,
  disableTitle,
  subTitle,
  prompt1,
  prompt2,
  prompt3,
  prompt4,
  questionPlaceHolder,
} = window.config;

export const ConfigPanel: FC = () => {
  const {
    config,
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
    setPromptTemplate,
  } = useContext(DemoContext);

  const setPromptsTitleAndImages = () => {
    setBackground(
      // localStorage.getItem(`${name}-background`) ??
      backgroundImageURL
    );
    setLogo(
      // localStorage.getItem(`${name}-logo`) ??
      logoImageURL
    );
    setTitle(
      // localStorage.getItem(`${name}-title`) ??
      subTitle
    );
    setPrompt1(
      // localStorage.getItem(`${name}-prompt1`) ??
      prompt1
    );
    setPrompt2(
      // localStorage.getItem(`${name}-prompt2`) ??
      prompt2
    );
    setPrompt3(
      // localStorage.getItem(`${name}-prompt3`) ??
      prompt3
    );
    setPrompt4(
      // localStorage.getItem(`${name}-prompt3`) ??
      prompt4
    );
    setPlaceholderQuestion(
      // localStorage.getItem(`${name}-question`) ??
      questionPlaceHolder
    );
  };

  const onPromptTemplateChange = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setPromptTemplate(newValue || "");
  };

  const onEndPointChange = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setEndpoint(newValue || "");
    // localStorage.setItem(`${name}-endpoint`, newValue ?? "");
  };

  const onLogoChange = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setLogo(newValue || "");
    // localStorage.setItem(`${name}-logo`, newValue ?? "");
    // setPrompt((old: any) => [newValue, old[1], old[2]]);
  };

  const onBackgroundImageChange = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setBackground(newValue || "");
    // localStorage.setItem(`${name}-bg`, newValue ?? "");
    // setPrompt((old: any) => [newValue, old[1], old[2]]);
  };

  const onTitleChange = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setTitle(newValue || "");
  };

  const onPrompt1Change = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setPrompt1(newValue || "");
  };
  const onPrompt2Change = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setPrompt2(newValue || "");
  };
  const onPrompt3Change = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setPrompt3(newValue || "");
  };
  const onPrompt4Change = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setPrompt4(newValue || "");
  };

  const onPlaceholderQuestionChange = (
    _ev?: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    setPlaceholderQuestion(newValue || "");
  };

  const onRetrieveCountChange = (
    _ev?: React.SyntheticEvent<HTMLElement, Event>,
    newValue?: string
  ) => {
    setRetrieveCount(parseInt(newValue || "3"));
  };

  const onUseSemanticRankerChange = (
    _ev?: React.FormEvent<HTMLElement | HTMLInputElement>,
    checked?: boolean
  ) => {
    setUseSemanticRanker(!!checked);
  };

  const onUseSemanticCaptionsChange = (
    _ev?: React.FormEvent<HTMLElement | HTMLInputElement>,
    checked?: boolean
  ) => {
    setUseSemanticCaptions(!!checked);
  };

  const onExcludeCategoryChanged = (
    _ev?: React.FormEvent,
    newValue?: string
  ) => {
    setExcludeCategory(newValue || "");
  };

  const onUseSuggestFollowupQuestionsChange = (
    _ev?: React.FormEvent<HTMLElement | HTMLInputElement>,
    checked?: boolean
  ) => {
    setUseSuggestFollowupQuestions(!!checked);
  };

  return (
    <Panel
      headerText="Configure answer generation"
      isOpen={isConfigPanelOpen}
      isBlocking={false}
      onDismiss={() => setConfigPanel(false)}
      closeButtonAriaLabel="Close"
      className={styles.panel}
      onRenderFooterContent={() => (
        <>
          <DefaultButton
            className={styles.saveButton}
            onClick={() => setConfigPanel(false)}
          >
            Save
          </DefaultButton>
          <DefaultButton
            onClick={() => {
              localStorage.clear();
              setEndpoint(endPointURL);
              setPromptsTitleAndImages();
            }}
            className={styles.resetButton}
          >
            Reset
          </DefaultButton>
        </>
      )}
      isFooterAtBottom={true}
    >
      <TextField
        className={styles.chatSettingsSeparator}
        defaultValue={config?.promptTemplate}
        label="Override prompt template"
        multiline
        autoAdjustHeight
        onChange={onPromptTemplateChange}
      />

      <SpinButton
        className={styles.chatSettingsSeparator}
        label="Retrieve this many documents from search:"
        min={1}
        max={50}
        defaultValue={config?.retrieveCount?.toString()}
        onChange={onRetrieveCountChange}
      />
      <TextField
        className={styles.chatSettingsSeparator}
        label="Exclude category"
        onChange={onExcludeCategoryChanged}
      />
      <Checkbox
        className={styles.chatSettingsSeparator}
        checked={config?.useSemanticRanker}
        label="Use semantic ranker for retrieval"
        onChange={onUseSemanticRankerChange}
      />
      <Checkbox
        className={styles.chatSettingsSeparator}
        checked={config?.useSemanticCaptions}
        label="Use query-contextual summaries instead of whole documents"
        onChange={onUseSemanticCaptionsChange}
        disabled={!config?.useSemanticRanker}
      />
      <Checkbox
        className={styles.chatSettingsSeparator}
        checked={config?.useSuggestFollowupQuestions}
        label="Suggest follow-up questions"
        onChange={onUseSuggestFollowupQuestionsChange}
      />

      <TextField
        className={styles.chatSettingsSeparator}
        value={config?.logo}
        label="Logo"
        autoAdjustHeight
        onChange={onLogoChange}
      />
      <TextField
        className={styles.chatSettingsSeparator}
        value={config?.background}
        label="Background Image"
        autoAdjustHeight
        onChange={onBackgroundImageChange}
      />

      <TextField
        className={styles.chatSettingsSeparator}
        label="OpenAI Endpoint URL"
        autoAdjustHeight
        value={config?.endPoint}
        onChange={onEndPointChange}
      />

      {!disableTitle && (
        <TextField
          className={styles.chatSettingsSeparator}
          value={config?.title}
          label="Title"
          autoAdjustHeight
          onChange={onTitleChange}
        />
      )}

      <TextField
        className={styles.chatSettingsSeparator}
        value={config?.placeholderQuestion}
        label="Placeholder Question"
        autoAdjustHeight
        onChange={onPlaceholderQuestionChange}
      />

      {/* <TextField
        className={styles.chatSettingsSeparator}
        value={config?.prompt1}
        label="Prompt 1"
        autoAdjustHeight
        onChange={onPrompt1Change}
      /> */}
      <TextField
        className={styles.chatSettingsSeparator}
        value={config?.prompt2}
        label="Prompt 2"
        autoAdjustHeight
        onChange={onPrompt2Change}
      />
      <TextField
        className={styles.chatSettingsSeparator}
        value={config?.prompt3}
        label="Prompt 3"
        autoAdjustHeight
        onChange={onPrompt3Change}
      />
      <TextField
        className={styles.chatSettingsSeparator}
        value={config?.prompt4}
        label="Prompt 4"
        autoAdjustHeight
        onChange={onPrompt4Change}
      />
    </Panel>
  );
};
