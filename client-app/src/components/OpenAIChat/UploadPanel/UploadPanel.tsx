import * as React from "react";
import {
  ExternalDropZone,
  Upload,
  UploadFileInfo,
  UploadOnAddEvent,
  UploadOnBeforeRemoveEvent,
  UploadOnBeforeUploadEvent,
  UploadOnProgressEvent,
  UploadOnRemoveEvent,
  UploadOnStatusChangeEvent,
} from "@progress/kendo-react-upload";
import styles from "./UploadPanel.module.scss";
import { useEffect, useState } from "react";
import { Button } from "@progress/kendo-react-buttons";
import { Popup } from "components";
import { PDFViewer } from "@progress/kendo-react-pdf-viewer";
import { SettingsContext } from "context";
import { v4 as uuidv4 } from "uuid";
import { PDFIcon } from "assets";
import { Error } from "@progress/kendo-react-labels";
import { ProgressBar } from "@progress/kendo-react-progressbars";
import { Dismiss16Regular } from "@fluentui/react-icons";

const uploadRef = React.createRef<Upload>();

const { pdfUploadApi } = window.config;

function upsert(array: any[], element: any) {
  const i = array.findIndex((_element) => _element?.uid === element?.uid);
  if (i > -1) array[i] = element; // (2)
  else array.push(element);
}

export const UploadPanel = (props: any) => {
  const [showResetBtn, setShowResetBtn] = useState(false);
  const [isVisible, setIsVisible] = useState(false);
  const [string, setString] = useState<any>("");
  const [disableSelectFiles, setDisableSelectFiles] = useState(false);
  const [indexName, setIndexName] = useState("");
  const [containerName, setContainerName] = useState("");
  const [uploadProgress, setUploadProgress] = useState<any[]>([]);

  useEffect(() => {
    setIndexName(`${uuidv4().split("-")[0]}-${Date.now()}`);
    setContainerName(`${uuidv4().split("-")[0]}-${Date.now()}`);
  }, []);

  const fileUpload = (event: UploadOnStatusChangeEvent) => {
    props.setFiles(event.newState);
    if (event?.response?.response) {
      event.newState?.length === 3 && setShowResetBtn(true);
      props.setFileUploadResponse(event.response.response);
      setIndexName(event.response.response.index_name);
      setContainerName(event.response.response.container_name);
    }
  };

  const onAdd = (e: UploadOnAddEvent) => {
    if (e.affectedFiles.length + props.files.length > 3) {
      alert("You can only upload up to 3 pdf files.");
      return props.setFiles((old: any) => old);
    } else {
      const filteredFiles = e.affectedFiles
        .filter(
          (f) => f.extension !== ".pdf" || (f?.size && f.size >= 10240000)
        )
        .map((f) => f.uid);

      if (filteredFiles.length) {
        alert("You can only upload .pdf file(s) with size less than 10 MB.");
        return props.setFiles((old: any) =>
          old.filter((f: any) => !filteredFiles.includes(f.uid))
        );
      }

      return props.setFiles((old: any) => {
        return [...old, ...e.affectedFiles];
      });
    }
  };

  const onBeforeUpload = (e: UploadOnBeforeUploadEvent) => {
    const newFiles = e.files.map((file) => ({ ...file, progress: 0 }));
    setUploadProgress((prev) => [...prev, ...newFiles]);

    e.additionalData.index_name = indexName;
    e.additionalData.container_name = containerName;
    return e;
  };

  const onProgress = (event: UploadOnProgressEvent) => {
    setUploadProgress((prev) =>
      prev.map((file) =>
        file.uid === event.affectedFiles[0].uid
          ? { ...file, progress: event.affectedFiles[0].progress }
          : file
      )
    );
  };

  const onRemove = (file: UploadFileInfo) => {
    props.setFiles((old: any) => old.filter((f: any) => f.uid !== file.uid));
    fetch(pdfUploadApi.split("/api")[0] + "/api/deleteDocument", {
      method: "post",
      body: JSON.stringify({
        index_name: indexName,
        file_name: file.name,
      }),
    })
      .then((res) => console.log(res))
      .catch((e) => console.log(e));
  };

  const onPreview = (file: UploadFileInfo) => {
    file
      ?.getRawFile?.()
      ?.arrayBuffer()
      .then((res) => {
        setString(res);
        setIsVisible(true);
      });
  };

  return (
    <div style={props?.style}>
      <Popup
        title="File Preview"
        showPopup={isVisible}
        onClose={() => setIsVisible(false)}
        className={styles.popup}
      >
        <PDFViewer
          style={{ width: "100%", height: "100%" }}
          arrayBuffer={string}
        />
      </Popup>
      {!props.hideExternalDropZone && !showResetBtn && (
        <ExternalDropZone
          uploadRef={uploadRef}
          disabled={props.files.length === 3}
          customHint={`Drag and Drop Here\nor\nBrowse Files\nYou can upload up to 3 pdf files.\n File size limit: 10 MB (per file)`}
          className={styles.externalDropZone}
        />
      )}
      <div style={{ height: "12px" }} />
      {props.files.length > 0 && props.files[0].status !== 4 && (
        <Error style={{ fontSize: 14, color: "black" }}>
          Please click on the upload button to upload files.
        </Error>
      )}
      <div className={styles.uploadFeature}>
        <Upload
          className={`${styles.uploadArea} ${
            (props.files.length === 3 || disableSelectFiles) &&
            styles.disableSelectFileBtn
          }`}
          autoUpload={false}
          onRemove={() => props.setFiles([])}
          listItemUI={(p) => {
            return (
              <div
                style={{
                  display: "flex",
                  flexDirection: "column",
                  width: "100%",
                  gap: 8,
                }}
              >
                {p.files.map((file) => (
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 8,
                      margin: "8px 0",
                      position: "relative",
                      height: 34,
                      width: "100%",
                    }}
                    key={file.uid}
                  >
                    <div style={{ width: 32, height: 32 }}>
                      <PDFIcon color={props.className && "white"} />
                    </div>
                    <div style={{ flex: 1 }}>
                      <div>{file.name}</div>
                      <div
                        style={{
                          color:
                            file.status === 4
                              ? "#37b400"
                              : file.status === 0
                              ? "#ff2a14"
                              : "black",
                        }}
                      >
                        {file.status === 4 && "File uploaded successfully."}
                        {file.status === 0 && "File upload failed."}
                      </div>
                    </div>
                    <div
                      className={`${styles.btnContainer} ${
                        props.className && styles.btnContainerInChat
                      }`}
                    >
                      {file.status === 3 && <div className={styles.loader} />}

                      <Button
                        onClick={() => onPreview(file)}
                        className={styles.previewBtn}
                      >
                        Preview File
                      </Button>
                      <Dismiss16Regular
                        onClick={() => onRemove(file)}
                        style={{ cursor: "pointer" }}
                      />
                      {/* <span
                        className={`k-icon k-i-close ${styles.removeBtn}`}
                      ></span> */}
                    </div>
                  </div>
                ))}
              </div>
            );
          }}
          ref={uploadRef}
          batch={false}
          multiple={true}
          files={props.files}
          onBeforeUpload={onBeforeUpload}
          onProgress={onProgress}
          removeField="file_name"
          onAdd={onAdd}
          withCredentials={false}
          restrictions={{
            maxFileSize: 10 * 1024 * 1000,
            allowedExtensions: ["pdf"],
          }}
          saveUrl={pdfUploadApi}
          saveField="pdf"
          onStatusChange={fileUpload}
        />
      </div>
    </div>
  );
};
