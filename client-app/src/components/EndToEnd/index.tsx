import { styled } from "@fluentui/react";
import { useAppSelector } from "hooks";
import React, { useState } from "react";
import { useDispatch } from "react-redux";
import styles from "./styles.module.scss";
import { useNavigate } from "react-router-dom";
import { setCardSelected, setDemoFlowSelected, setDemoMenus } from "store";
import EndToEndRefrestLogo from "assets/EndToEndRefrestLogo";
import EndToEndRefreshWhiteLogo from "assets/EndToEndRefreshWhiteLogo";
import { Backward } from "assets/Backward";
import ITPersona from "assets/ITPersona";
import ITPersonaWhite from "assets/ITPersonaWhite";
const { demoMenu } = window.config;
const EndToEnd = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();
  // dispatch(setDemoFlowSelected("EndToEnd"));
  const { demoMenus, cardSelected, demoFlowSelected } = useAppSelector(
    (state: any) => state.config
  );
  let CardData: any = [
    {
      id: 3,
      CardHeaderImg:
        "https://dreamdemoassets.blob.core.windows.net/nrf/marketing1.png",
      cardTitle: "Marketing",
      cardData: [
        "Unified customer intelligence",
        "Loyalty analytics",
        "Product recommender",
      ],
    },

    {
      id: 2,
      CardHeaderImg:
        "https://dreamdemoassets.blob.core.windows.net/nrf/scm.png",
      cardTitle: "Supply Chain",
      cardData: ["Demand Planing / Forecasting \n (Staff and Inventory)"],
    },
    {
      id: 1,
      CardHeaderImg:
        "https://dreamdemoassets.blob.core.windows.net/nrf/merchandising.png",
      cardTitle: "Merchandising",
      cardData: ["Assortment Planning"],
    },

    {
      id: 4,
      CardHeaderImg:
        "https://dreamdemoassets.blob.core.windows.net/nrf/store.jpg",
      cardTitle: "Store",
      cardData: [
        "Retail time store insights",
        `Next best action \n
        (Stocking and Store Employees)`,
      ],
    },
  ];
  const [cardSelect, setCardSelect] = useState<number>(0);
  const handleProductCardClick = (data: any) => {
    setCardSelect(data.id);
    dispatch(setCardSelected(data.cardTitle));

    // if (data.cardTitle == "Merchandising") {
    //   dispatch(setDemoFlowSelected(data.cardTitle));
    //   dispatch(setDemoMenus(window.config.merchandising));
    //   // window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    // } else if (data.cardTitle == "Supply Chain") {
    //   dispatch(setDemoFlowSelected(data.cardTitle));
    //   dispatch(setDemoMenus(window.config.supplyChain));
    //   // window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    // } else if (data.cardTitle == "Marketing") {
    //   dispatch(setDemoFlowSelected(data.cardTitle));
    //   dispatch(setDemoMenus(window.config.marketing));
    //   // window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    // } else if (data.cardTitle == "Store") {
    //   dispatch(setDemoFlowSelected(data.cardTitle));
    //   dispatch(setDemoMenus(window.config.store));
    //   // window.dispatchEvent(new CustomEvent("demoMenusUpdate"));
    // }

    dispatch(setCardSelected(data.cardTitle));
  };
  const handleEndToEnd = () => {
    setCardSelect(0);
    dispatch(setCardSelected(""));
    dispatch(setDemoFlowSelected("EndToEnd"));
    return dispatch(dispatch(setDemoMenus(window.config.fabricDemoFlow)));
  };
  const handleEndToEndFabAI = () => {
    setCardSelect(0);
    dispatch(setCardSelected(""));
    dispatch(setDemoFlowSelected("EndToEndFabAI"));
    return dispatch(dispatch(setDemoMenus(window.config.demoMenus)));
  };
  const handleEndToEndAIDemoFlow = () => {
    setCardSelect(0);
    dispatch(setCardSelected(""));
    dispatch(setDemoFlowSelected("EndToEndAIDemo"));
    return dispatch(dispatch(setDemoMenus(window.config.aiFlowDemoMenus)));
  };
  const handleITPersona = () => {
    setCardSelect(5);
    dispatch(setCardSelected(""));
    dispatch(setDemoFlowSelected("ITPersona"));
    return dispatch(dispatch(setDemoMenus(window.config.itPersona)));
  };
  return (
    <>
      <div
        onClick={() => {
          navigate("/landing-page");
        }}
        className={styles.Arrows}
      >
        <Backward />
      </div>
      <div className={styles.container}>
        <div className={styles.subContainer}>
          <div className={styles.mainDemoCards}>
            <div className={styles.CardsSection}>
              <div
                className={styles.endToendButton}
                onClick={handleEndToEnd}
                style={
                  demoFlowSelected == "EndToEnd"
                    ? {
                        border: "2px solid #ffffff",
                        color: "#ffffff",
                        background: "linear-gradient(#b361b8, #4e78be)",
                      }
                    : { border: "" }
                }
              >
                {demoFlowSelected == "EndToEnd" ? (
                  <EndToEndRefreshWhiteLogo />
                ) : (
                  <EndToEndRefrestLogo />
                )}
                <span style={{ marginLeft: "20px" }}>
                  {" "}
                  End to End Fabric Demo Flow
                </span>
              </div>
              <div
                className={styles.endToEndAIButton}
                onClick={handleEndToEndAIDemoFlow}
                style={
                  demoFlowSelected == "EndToEndAIDemo"
                    ? {
                        border: "2px solid #ffffff",
                        color: "#ffffff",
                        background: "linear-gradient(#b361b8, #4e78be)",
                      }
                    : { border: "" }
                }
              >
                {demoFlowSelected == "EndToEndAIDemo" ? (
                  <EndToEndRefreshWhiteLogo />
                ) : (
                  <EndToEndRefrestLogo />
                )}
                <span style={{ marginLeft: "20px" }}>
                  {" "}
                  End to End AI Demo Flow
                </span>
              </div>{" "}
              <div
                className={styles.endToEndAIButton}
                onClick={handleEndToEndFabAI}
                style={
                  demoFlowSelected == "EndToEndFabAI"
                    ? {
                        border: "2px solid #ffffff",
                        color: "#ffffff",
                        background: "linear-gradient(#b361b8, #4e78be)",
                      }
                    : { border: "" }
                }
              >
                {demoFlowSelected == "EndToEndFabAI" ? (
                  <EndToEndRefreshWhiteLogo />
                ) : (
                  <EndToEndRefrestLogo />
                )}
                <span style={{ marginLeft: "20px" }}>
                  {" "}
                  End to End Fabric + AI DREAM Demo
                </span>
              </div>
            </div>
            <div className={styles.demoCards}>
              {CardData.map((productCart: any) => (
                <div
                  onClick={(e) => handleProductCardClick(productCart)}
                  className={`${styles.card} 
                  `}
                  style={
                    demoFlowSelected == productCart.cardTitle
                      ? {
                          border: "2px solid transparent",
                          boxShadow: "0px 2px 20px 2px #0078d4",
                        }
                      : { border: "" }
                  }
                >
                  <div className={styles.line}></div>
                  <div className={styles.cardHeader}>
                    <div>
                      <img src={productCart.CardHeaderImg} alt="" />
                    </div>

                    <p>{productCart.cardTitle}</p>
                  </div>
                  <div className={styles.listItem}>
                    <ul>
                      {productCart.cardData.map((list: any) => (
                        <li>{list}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              ))}
            </div>
            <div
              className={styles.itPersona}
              onClick={handleITPersona}
              style={
                demoFlowSelected == "ITPersona"
                  ? {
                      border: "2px solid #ffffff",
                      color: "#ffffff",
                      background: "linear-gradient(#b361b8, #4e78be)",
                    }
                  : { border: "" }
              }
            >
              {demoFlowSelected == "ITPersona" ? (
                <ITPersonaWhite />
              ) : (
                <ITPersona />
              )}
              <span style={{ marginLeft: "20px" }}>IT Persona</span>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default EndToEnd;
