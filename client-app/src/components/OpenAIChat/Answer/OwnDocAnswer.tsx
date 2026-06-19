import { useMemo } from "react";
import { Stack } from "@fluentui/react";
import DOMPurify from "dompurify";

import styles from "./Answer.module.css";

import { OwnAskResponse, getCitationFilePath } from "api";
import { AnswerIcon } from "./AnswerIcon";

interface Props {
  answer: OwnAskResponse;
  isSelected?: boolean;
  onCitationClicked: (filePath: string) => void;
  onThoughtProcessClicked: () => void;
  onSupportingContentClicked: () => void;
  onFollowupQuestionClicked?: (question: string) => void;
  showFollowupQuestions?: boolean;
  endpoint: string;
}

export const OwnDocAnswer = ({
  answer,
  isSelected,
  onCitationClicked,
  onFollowupQuestionClicked,
  showFollowupQuestions,
  endpoint,
}: Props) => {
  return <></>;
};
