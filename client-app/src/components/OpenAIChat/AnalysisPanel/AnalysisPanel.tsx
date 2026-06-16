import { Pivot, PivotItem } from "@fluentui/react";
import DOMPurify from "dompurify";

import styles from "./AnalysisPanel.module.css";

import { SupportingContent } from "../SupportingContent";
import { AskResponse } from "api";
import { AnalysisPanelTabs } from "./AnalysisPanelTabs";
import {
  TabStrip,
  TabStripSelectEventArguments,
  TabStripTab,
} from "@progress/kendo-react-layout";
import { useEffect, useState } from "react";
import { UploadPanel } from "../UploadPanel";
import { UploadFileInfo } from "@progress/kendo-react-upload";

interface Props {
  className: string;
  activeTab: AnalysisPanelTabs;
  onActiveTabChanged: (tab: AnalysisPanelTabs) => void;
  activeCitation: string | undefined;
  citationHeight: string;
  answer: AskResponse;
  onContextReady: any;
  setFileUploadResponse: any;
  uploadToggle: boolean;
}

const pivotItemDisabledStyle = { disabled: true, primaryDisabled: true };

export const AnalysisPanel = ({
  answer,
  activeTab,
  activeCitation,
  citationHeight,
  className,
  onActiveTabChanged,
  onContextReady,
  setFileUploadResponse,
  uploadToggle,
}: Props) => {
  const isDisabledThoughtProcessTab: boolean = !answer?.thoughts;
  const isDisabledSupportingContentTab: boolean = !answer?.data_points?.length;
  const isDisabledCitationTab: boolean = !activeCitation;
  const [files, setFiles] = useState<UploadFileInfo[]>([]);

  const sanitizedThoughts = DOMPurify.sanitize(answer?.thoughts!);

  const [selected, setSelected] = useState<number>(+activeTab);

  const handleSelect = (e: TabStripSelectEventArguments) => {
    setSelected(e.selected);
  };

  useEffect(() => {
    setSelected(+activeTab);
  }, [activeTab]);
  return (
    <TabStrip
      selected={selected}
      onSelect={handleSelect}
      style={{ height: "calc(100% - 40px)" }}
      className={styles.tabStrip}
      renderAllContent
      keepTabsMounted={true}
    >
      <TabStripTab
        // className={styles.chatAnalysisPivotItem}
        // itemKey={AnalysisPanelTabs.ThoughtProcessTab}
        title="Thought process"
        disabled={!answer?.answer || isDisabledThoughtProcessTab}
      >
        {answer?.thoughts && (
          <div
            className={styles.thoughtProcess}
            dangerouslySetInnerHTML={{ __html: sanitizedThoughts }}
          ></div>
        )}
      </TabStripTab>
      <TabStripTab
        // className={styles.chatAnalysisPivotItem}
        // itemKey={AnalysisPanelTabs.SupportingContentTab}
        title="Supporting content"
        disabled={!answer?.answer || isDisabledSupportingContentTab}
      >
        {answer?.data_points && (
          <SupportingContent supportingContent={answer.data_points} />
        )}
      </TabStripTab>
      <TabStripTab
        // className={styles.chatAnalysisPivotItem}
        // itemKey={AnalysisPanelTabs.CitationTab}
        title="Citation"
        disabled={!answer?.answer || isDisabledCitationTab}
      >
        {activeCitation && (
          <iframe
            style={{ marginTop: 12 }}
            title="Citation"
            src={activeCitation}
            width="100%"
            height={citationHeight}
          />
        )}
      </TabStripTab>
      <TabStripTab
        // className={styles.chatAnalysisPivotItem}
        // itemKey={AnalysisPanelTabs.CitationTab}
        title="Upload"
        // disabled={isDisabledCitationTab}
        disabled={!uploadToggle}
      >
        <UploadPanel
          onContextReady={onContextReady}
          setFileUploadResponse={setFileUploadResponse}
          files={files}
          setFiles={setFiles}
          style={{ marginTop: 12 }}
        />
      </TabStripTab>
    </TabStrip>
  );
};
