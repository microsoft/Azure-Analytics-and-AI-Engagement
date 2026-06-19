import { useContext, useEffect, useMemo } from "react";
import { Stack, IconButton } from "@fluentui/react";
import DOMPurify from "dompurify";

import styles from "./Answer.module.css";

import { AskResponse, getCitationFilePath } from "api";
import { AnswerIcon } from "./AnswerIcon";
import { SettingsContext } from "context";
import { useAppSelector } from "hooks";
import { render } from "react-dom";
import { parseAnswer } from "./AnswerParser";

interface Props {
  answer: AskResponse;
  isSelected?: boolean;
  onCitationClicked: (filePath: string) => void;
  onThoughtProcessClicked: () => void;
  onSupportingContentClicked: () => void;
  onFollowupQuestionClicked?: (question: string) => void;
  showFollowupQuestions?: boolean;
  endpoint: string;
  container?: string;
}

const { customerId, prompt1, prompt2 } = window.config;

const Citation = ({ citation, index, path, onCitationClicked }: any) => {
  return (
    <span
      className="supContainer"
      title={citation}
      onClick={() => onCitationClicked(path)}
    >
      <sup>{index}</sup>
    </span>
  );
};

export const Answer = ({
  answer,
  isSelected,
  onCitationClicked,
  onThoughtProcessClicked,
  onSupportingContentClicked,
  onFollowupQuestionClicked,
  showFollowupQuestions,
  endpoint,
  container,
}: Props) => {
  // const { currentDemo } = useContext(SettingsContext);

  const { question } = useAppSelector((state) => state.config);
  const formatTextWithBold = (input: string) => {
    const formattedText = input.replace(
      /\*\*(.*?)\*\*/g, // Regex to match text inside **
      (_, match) => `<strong>${match}</strong>` // Wrap matched text in <strong>
    );
    return DOMPurify.sanitize(formattedText); // Sanitize the HTML
  };
  const { answerHtml, citations } = parseAnswer(
    formatTextWithBold(answer.answer)
  );

  // const parsedAnswer = useMemo(
  //   () =>
  //     parseAnswerToHtml(
  //       answer.answer,
  //       endpoint,
  //       onCitationClicked,
  //       container,
  //       customerId === 1
  //     ),
  //   [answer]
  // );

  useEffect(() => {
    citations.forEach(({ citation, index }) => {
      const path = getCitationFilePath(
        citation,
        endpoint,
        container,
        customerId === 1
      );
      const citationElements = document.querySelectorAll(`#citation-${index}`);
      citationElements.forEach((citationElement) => {
        render(
          <Citation
            key={index}
            citation={citation}
            index={index}
            path={path}
            onCitationClicked={onCitationClicked}
          />,
          citationElement
        );
      });
    });
  }, [answerHtml, citations, endpoint, container, onCitationClicked]);

  const sanitizedAnswerHtml = DOMPurify.sanitize(answerHtml);

  return (
    <Stack
      className={`${styles.answerContainer} ${isSelected && styles.selected}`}
      verticalAlign="space-between"
    >
      <Stack.Item>
        <Stack horizontal horizontalAlign="end">
          {/* <AnswerIcon /> */}
          <div>
            <IconButton
              style={{ color: "black" }}
              iconProps={{ iconName: "Lightbulb" }}
              title="Show thought process"
              ariaLabel="Show thought process"
              onClick={() => onThoughtProcessClicked()}
              disabled={!answer?.thoughts}
            />
            <IconButton
              style={{ color: "black" }}
              iconProps={{ iconName: "ClipboardList" }}
              title="Show supporting content"
              ariaLabel="Show supporting content"
              onClick={() => onSupportingContentClicked()}
              disabled={!answer?.data_points?.length}
            />
          </div>
        </Stack>
      </Stack.Item>

      <Stack.Item grow>
        <div
          className={styles.answerText}
          dangerouslySetInnerHTML={{ __html: answerHtml }}
        ></div>
      </Stack.Item>
      {!!answer.data_points?.length && (
        <Stack.Item>
          <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
            <span className={styles.citationLearnMore}>Citations:</span>
            {answer?.data_points.map((x, i) => {
              x = x.split(": ")[0];
              const path = getCitationFilePath(
                x,
                endpoint,
                container,
                customerId === 1
              );
              return (
                <a
                  key={i}
                  className={styles.citation}
                  title={x}
                  onClick={() => onCitationClicked(path)}
                >
                  {`${++i}. ${x}`}
                </a>
              );
            })}
          </Stack>
        </Stack.Item>
      )}

      {/* {!!parsedAnswer?.followupQuestions.length &&
        showFollowupQuestions &&
        onFollowupQuestionClicked && (
          <Stack.Item>
            <Stack
              horizontal
              wrap
              className={`${
                !!parsedAnswer?.citations.length
                  ? styles.followupQuestionsList
                  : ""
              }`}
              tokens={{ childrenGap: 6 }}
            >
              <span className={styles.followupQuestionLearnMore}>
                Follow-up questions:
              </span>
              {parsedAnswer.followupQuestions.map((x, i) => {
                return (
                  <a
                    key={i}
                    className={styles.followupQuestion}
                    title={x}
                    onClick={() => onFollowupQuestionClicked(x)}
                  >
                    {`${x}`}
                  </a>
                );
              })}
            </Stack>
          </Stack.Item>
        )} */}
    </Stack>
  );
};
