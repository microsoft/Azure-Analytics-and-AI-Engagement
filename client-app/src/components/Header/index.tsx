import {
  AppBar,
  AppBarSection,
  AppBarSpacer,
  Avatar,
} from "@progress/kendo-react-layout";
import { FC, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "hooks";
import styles from "./styles.module.scss";
import { Helmet } from "react-helmet";
import { Button } from "@progress/kendo-react-buttons";
import {
  setActiveTileGlobally,
  setActiveTileNumber,
  setChildNodes,
  setDemoMenus,
  setPageTitle,
  setPageType,
  setPreviousTileGlobally,
  setShowPopup,
  setSolutionPlay,
  setSolutionPlayGlobally,
  setSwitchOn,
  setCurrentTile,
  setPersonaID,
  setUseCaseID,
  setshowAIPersona,
} from "store";
interface Props {
  expanded: boolean;
  setExpanded: React.Dispatch<React.SetStateAction<boolean>>;
}

const { headerImageUrl, headerBgColor, logoImageURL, disableTitle, title } =
  window.config;

export const Header: FC<Props> = ({ expanded, setExpanded }) => {
  const { BlobBaseUrl } = window.config;
  const { pageTitle, persona, timeline, ActiveTileGlobally } = useAppSelector(
    (state) => state.config
  );
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const [showTile, setShowTile] = useState(false);
  const handleClick = () => {
    setExpanded(!expanded);
  };
  const handleImgClick = () => {
    // console.log(showTile);
    // setShowTile(!showTile);
    // dispatch(setshowAIPersona(!showTile));
    // if (showTile) {
    //   dispatch(setDemoMenus(window.config.demoMenus));
    // } else {
    //   dispatch(setDemoMenus(window.config.aiPersona));
    // }
  };
  return (
    <>
      {/* <Helmet> */}
        <title>Azure Hero DREAM Demos- {pageTitle}</title>
      {/* </Helmet> */}
      <AppBar className={styles.appBar} style={{}}>
        <AppBarSection>
          <div
            className={styles.logo}
            // onClick={() => navigate("/legal-notice")}
          >
            {showTile ? (
              <img
                src="https://dreamdemoassets.blob.core.windows.net/nrf/clickLogoV1.png"
                alt="logo"
                onClick={handleImgClick}
              />
               
            ) : (
              // <img src={logoImageURL} alt="logo" onClick={handleImgClick} />
              <img
              src={
                "https://dreamdemoassets.blob.core.windows.net/herodemos/zava_new.png"
              }
              alt="logo"
              onClick={handleImgClick}
            /> 
            )}
            {!disableTitle && (
              <p
                style={{
                  color: "white",
                  fontSize: 22,
                  fontWeight: 600,
                  marginBottom: 0,
                }}
              >
                {title?.toUpperCase()}
              </p>
            )}
          </div>
        </AppBarSection>

        <AppBarSpacer />

        {/* <div className={styles.selectedComponentsText}>
          {ActiveTileGlobally}
        </div> */}

        {/* {persona && (
          <AppBarSection>
            <button className="k-button k-button-md k-rounded-md k-button-flat k-button-flat-base">
              <Avatar type="image" className={styles.avatar} size="large">
                <img src={persona} alt="persona" />
              </Avatar>
            </button>
          </AppBarSection>
        )} */}
        {/* <AppBarSection>
          <NavLink
            to="/logout"
            className="k-button k-button-md k-rounded-md k-button-flat k-button-flat-base"
          >
            Sign Out
            <img
              src={`${BlobBaseUrl}header_icon_logout.png`}
              alt="header_icon_logout"
            />
          </NavLink>
        </AppBarSection> */}
      </AppBar>
    </>
  );
};
