import { FC, useEffect, useRef, useState } from "react";
import styles from "./styles.module.scss";
import { useAppDispatch, useAppSelector } from "hooks";
import {
  setActiveTileGlobally,
  setActiveTileNumber,
  setPageTitle,
  setPageType,
  setShowPopup,
} from "store";
import { PageType } from "types";
import { ChatBot } from "components/ChatBot";
import { Button } from "@progress/kendo-react-buttons";

interface Props {
  pageTitle: string;
  pageType: PageType;
  src: string;
  className?: string;
  originalSize?: boolean;
  backgroundImage?: string;
  title?: string;
}

const { BlobBaseUrl, INITIAL_ACTIONS } = window.config;

export const Image: FC<Props> = ({
  pageTitle,
  pageType,
  src,
  title,
  className,
  originalSize,
  backgroundImage,
}) => {
  const dispatch = useAppDispatch();
  //const [showPopup, setShowPopup] = useState(false);
  const { ActiveTileGlobally, ActiveTileNumber, showPopup } = useAppSelector(
    (state) => state.config
  );
  const [actions, setActions] = useState<any>(INITIAL_ACTIONS);
  const [type, setType] = useState("home");

  useEffect(() => {
    const storedTileGlobally = localStorage.getItem("ActiveTileGlobally");
    const storedTileNumber = localStorage.getItem("ActiveTileNumber");

    if (storedTileGlobally) {
      dispatch(setActiveTileGlobally(storedTileGlobally));
    } else {
      dispatch(setActiveTileGlobally("End-to-End Demo"));
    }

    if (storedTileNumber) {
      dispatch(setActiveTileNumber(storedTileNumber));
    } else {
      dispatch(setActiveTileNumber("1"));
    }

    dispatch(setPageType(pageType));
    dispatch(setPageTitle(pageTitle));

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dispatch, pageTitle, pageType]);
  const [messages, setMessages] = useState("");

  return (
    <div className={`${styles.container} ${className}`}>
      <h1 className={styles.imageTitle}>{title}</h1>

      {pageType === PageType.FutureStateArchitecture || originalSize ? (
        <div className={styles.subContainer}>
          <img
            src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
            alt={pageTitle}
            className={styles.image}
          />
        </div>
      ) : pageType.toString() === "Landing Page" ? (
        <>
          <div className={styles.subContainer1}>
            {/* <img
                //src="https://dreamdemoassets.blob.core.windows.net/dataandaidemo/landing_page_center.png"
                src=""
              alt=""
            /> */}
               <img
            src="https://dreamdemoassets.blob.core.windows.net/herodemos/Landing.png"
              //src="https://dreamdemoassets.blob.core.windows.net/dataandaidemo/landing_page_center.png"
              alt=""
            />
            {/* <div className={styles.tileContainer}></div>{" "} */}
            {
              // <img
              //   className={styles.chatIcon}
              //   src={`https://dreamdemoassets.blob.core.windows.net/dataandaidemo/copilot_image.png`}
              //   alt="chat-icon"
              //   onClick={() => dispatch(setShowPopup(true))}
              // />
            }
            {/* {showPopup && (
              <div className={styles.chatBotLandingPageContainer}>
                <ChatBot
                  INITIAL_ACTIONS={INITIAL_ACTIONS}
                  messages={messages}
                  setMessages={setMessages}
                  actions={actions}
                  setActions={setActions}
                  type={type}
                  onPlayClick={null}
                  setType={setType}
                />
              </div>
            )} */}
            {/* <img
              src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
              alt={pageTitle}
              className={`${styles.image} ${styles.landingPageImage}`}
            /> */}
          </div>
        </>
      ) : window.location.href.includes("/sales-report-before") ? (
        <>
          {" "}
          <div className={styles.subLongContainer1}>
            <div className={styles.divForImages}>
              <img
                // src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
                src={
                  "https://dreamdemoassets.blob.core.windows.net/nrf/Sales_Report_Before_Frame.jpg"
                }
                alt={pageTitle}
                // className={styles.image}
              />
              <div className={styles.divForImagesSlide}>
                <img
                  // src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
                  src={
                    "https://dreamdemoassets.blob.core.windows.net/nrf/Sales_Report_Before_Pic.jpg"
                  }
                  alt={pageTitle}
                  // className={styles.image}
                />
              </div>
            </div>
          </div>
        </>
      ) : window.location.href.includes("/sales-report-after") ? (
        <>
          {" "}
          <div className={styles.subLongContainer1}>
            <div className={styles.divForImages}>
              <img
                // src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
                src={
                  "https://dreamdemoassets.blob.core.windows.net/nrf/Sales_Report_After_Frame.jpg"
                }
                alt={pageTitle}
                // className={styles.image}
              />
              <div className={styles.divForImagesSlide}>
                <img
                  // src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
                  src={
                    "https://dreamdemoassets.blob.core.windows.net/nrf/Sales_Report_After_Pic.jpg"
                  }
                  alt={pageTitle}
                  // className={styles.image}
                />
              </div>
            </div>

            {/* <div className={styles.divForImages2}>
              <img
                // src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
                src={
                  "https://dreamdemoassets.blob.core.windows.net/nrf/onlyFilter.png"
                }
                alt={pageTitle}
                // className={styles.image}
              />
            </div> */}
          </div>
        </>
      ) : (
        <div className={styles.subContainer}>
          <img
            src={src.includes("http") ? src : `${BlobBaseUrl}${src}`}
            // src={
            //   "https://dreamdemoassets.blob.core.windows.net/nrf/pageUnderConstructionNRF.png"
            // }
            alt={pageTitle}
            className={styles.image}
          />
        </div>
      )}
    </div>
  );
};
