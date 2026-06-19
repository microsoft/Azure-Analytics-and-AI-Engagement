import { Dispatch, SetStateAction, useEffect, useRef, useState } from "react";
import { Stack, TextField } from "@fluentui/react";
import { Mic28Filled, Send28Filled } from "@fluentui/react-icons";

import styles from "./QuestionInput.module.scss";
import { useMic } from "hooks/useMic";

interface Props {
  onSend: (question: string) => void;
  disabled: boolean;
  placeholder?: string;
  clearOnSend?: boolean;
  copiedQuestion?: string;
  setCopiedQuestion?: Dispatch<SetStateAction<string>>;
  isReplay?: boolean;
  setIsReplay?: Dispatch<SetStateAction<boolean>>;
}

export const QuestionInput = ({
  copiedQuestion = "",
  isReplay,
  setIsReplay,
  setCopiedQuestion,
  onSend,
  disabled,
  placeholder,
  clearOnSend,
}: Props) => {
  const [question, setQuestion] = useState<string>("");
  const [isPressed, setIsPressed] = useState(false);
  const timerRef: any = useRef(null);

  const onSTT = (question: string) => {
    onSend(question);
  };

  const [sttFromMic, active] = useMic(question, onSTT);

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

  useEffect(() => {
    if (copiedQuestion) {
      setQuestion(copiedQuestion);
      setCopiedQuestion?.("");

      if (isReplay) {
        onSend(copiedQuestion);
        setIsReplay?.(false);
        setCopiedQuestion?.("");
        setQuestion("");
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [copiedQuestion, isReplay]);

  const sendQuestion = () => {
    if (disabled || !question.trim()) {
      return;
    }

    onSend(question);

    if (clearOnSend) {
      setQuestion("");
    }
  };

  const onEnterPress = (ev: React.KeyboardEvent<Element>) => {
    if (ev.key === "Enter" && !ev.shiftKey) {
      ev.preventDefault();
      sendQuestion();
    }
  };

  const onQuestionChange = (
    _ev: React.FormEvent<HTMLInputElement | HTMLTextAreaElement>,
    newValue?: string
  ) => {
    if (!newValue) {
      setQuestion("");
    } else if (newValue.length <= 1000) {
      setQuestion(newValue);
    }
    setCopiedQuestion?.("");
  };

  const sendQuestionDisabled = disabled || !question.trim();

  return (
    <Stack horizontal className={styles.questionInputContainer}>
      <TextField
        className={styles.questionInputTextArea}
        placeholder={placeholder}
        multiline
        resizable={false}
        borderless
        value={question}
        onChange={onQuestionChange}
        onKeyDown={onEnterPress}
      />
      <div className={styles.questionInputButtonsContainer}>
        <div
          className={`${styles.questionInputSendButton} ${
            sendQuestionDisabled ? styles.questionInputSendButtonDisabled : ""
          }`}
          aria-label="Ask question button"
          onClick={sendQuestion}
        >
          <Send28Filled primaryFill="var(--primary-color)" />
        </div>
        <div
          title="Hold to Speak"
          onMouseDown={handleMouseDown}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
        >
          <Mic28Filled
            className={styles.mic}
            primaryFill="var(--primary-color)"
          />
        </div>
      </div>
    </Stack>
  );
};
