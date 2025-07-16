import { CSSProperties, FC, useContext, useState, useEffect } from "react";
import { Outlet } from "react-router-dom";

import { Drawer, Header,  Popup } from "components";
import styles from "./styles.module.scss";
import { SettingsContext } from "context";
import { useAppDispatch, useArrows } from "hooks";
import { arrowConfig, routeDefinitions } from "common";
import { ArchitectureWithTags } from "pages/ArchitectureWithTags";
import { PageType } from "types/pageType";
import { Architecture } from "assets/Architecture";
import { useAppSelector } from "../../hooks/useAppSelector";
import { SpeakerIcon } from "assets";

import { Button } from "@progress/kendo-react-buttons";
import { BackendArrow } from "assets/BackendArrow";
import {
  setActiveTileGlobally,
  setActiveTileNumber,
  setDemoMenus,
} from "store";
import { ArchitectureIcon } from "assets/ArchitectureIcon";

export const Layout: FC = () => {
  const [expanded, setExpanded] = useState(false);
  const { demoMenus, previousTileGlobally } = useAppSelector(
    (state: any) => state.config
  );
  const [isMuted, setIsMuted] = useState(false);
  const dynamicArrows = useArrows();
  let popupTitle = " ";
  const [showArchPopup, setShowArchPopup] = useState(false);
  const [showArchPopup1, setShowArchPopup1] = useState(false);
  let imageUrl;
  let imageUrl2;
  const dispatch = useAppDispatch();
  if (window.location.href.includes("old-website")) {
    imageUrl =
      "https://dreamdemoassets.blob.core.windows.net/appspluscosmos/old-architectureV1.png";
  } else if (window.location.href.includes("reimagined-website-with-scaling")) {
    imageUrl =
      "https://dreamdemoassets.blob.core.windows.net/appspluscosmos/technical_reference_architectureV2.png";
    imageUrl2 =
      "https://dreamdemoassets.blob.core.windows.net/openai/ai_first_shopping_assistant_arch_diagram.png";
  } else {
    imageUrl =
      "https://dreamdemoassets.blob.core.windows.net/appspluscosmos/mid-term-architectureV2.png";
  }

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
    if (storedTileNumber == "2") {
      dispatch(setDemoMenus(window.config.Microsoft_Purview));

      window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    } else if (storedTileNumber == "3") {
      dispatch(setDemoMenus(window.config.Microsoft_Fabric));

      window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    } else if (storedTileNumber == "4") {
      dispatch(setDemoMenus(window.config.Microsoft_Purview));

      window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    } else if (storedTileNumber == "5") {
      dispatch(setDemoMenus(window.config.Microsoft_Purview));

      window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    } else if (storedTileNumber == "6") {
      dispatch(setDemoMenus(window.config.Microsoft_Purview));

      window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    } else if (storedTileNumber == "7") {
      dispatch(setDemoMenus(window.config.Microsoft_Purview));

      window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    } else {
      dispatch(setDemoMenus(window.config.demoMenus));
    }
  }, []);

  return (
    <div>
      <Header expanded={expanded} setExpanded={setExpanded} />
      {/* <NavBar /> */}
      <Drawer expanded={expanded} setExpanded={setExpanded}>
        <Outlet />
        {(window.location.href.includes("old-website") ||
          window.location.href.includes("/reimagined-website") ||
          window.location.href.includes("reimagined-website-with-scaling")) && (
          <div className={styles.actionButtonsContainer}>
            {/* {location.pathname.includes("reimagined-website-with-scaling") ?:  */}

            {/* <Button
              onClick={() => setShowArchPopup(true)}
              // className={"secondaryButton1"}
            >
              {" "}
              Architecture Diagram
            </Button> */}
            <a onClick={() => setShowArchPopup(true)}>
              <ArchitectureIcon />
            </a>

            {/* <span
              title="Architecture Diagram"
              onClick={() => setShowArchPopup(true)}
              className={styles.architectureIcon}
            >
              {" "}
              <Architecture />
            </span> */}

            {/* {!isMuted && (
              <span title="Mute" className={styles.speakerIcon}>
                <SpeakerIcon />
              </span>
            )}{" "} */}
          </div>
        )}
      </Drawer>
      <Popup
        showPopup={showArchPopup}
        title={popupTitle}
        onClose={() => setShowArchPopup(false)}
        dialogWidth={1400}
        dialogHeight={960}
      >
        <ArchitectureWithTags
          pageTitle={"Architecture diagram"}
          pageType={PageType.Architecture}
          imageUrl={imageUrl}
          tags={[]}
        />
      </Popup>
      ;
    </div>
  );
};
