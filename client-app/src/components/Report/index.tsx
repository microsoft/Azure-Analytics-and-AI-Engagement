import { FC, useEffect, useRef, useState } from "react";
import { height, width } from "common";
import { useAppDispatch, useAppSelector } from "hooks";
import { setPageTitle, setPageType } from "store";
import { EmbedType, PageType } from "types";
import { PowerBiService } from "utilities";
import styles from "./styles.module.scss";
import { useLocation } from "react-router-dom";
import { ifElse } from "ramda";

interface Props {
  pageType: PageType | any;
  pageTitle: string;
  id: string;
  name?: string;
  background?: "transparent" | "black" | "white";
  reportWithoutName?: boolean;
  removeBackArrow?: boolean;
  apiUrl?: string;
  url?: string;
  title?: string;
}

const { APIUrl } = window.config;

export const Report: FC<Props> = ({
  id,
  title,
  pageType,
  name,
  pageTitle,
  background = "white",
  reportWithoutName = false,
  apiUrl,
  removeBackArrow = true,
  url,
}) => {
  const location = useLocation();
  const imgRef = useRef<HTMLImageElement>(null);
  const [scaledCoords, setScaledCoords] = useState([]);
  const [scaledCoords1, setScaledCoords1] = useState<any>();
  const [reportLoading, setReportLoading] = useState(false);
  const dispatch = useAppDispatch();
  const { cardSelected } = useAppSelector((state) => state.config);
  const PowerBiServiceInstance = new PowerBiService(apiUrl ?? APIUrl);
  useEffect(() => {
    if (cardSelected == "Merchandising") {
      let cardSelectedCss = {
        width: "19.5%",
        height: "75.5%",
        top: "22.5%",
        left: "41%",
        position: "absolute",

        boxShadow: "0 0 5px 5px rgba(30, 144, 255, 0.6)",
        // animation: "pulse 1s infinite alternate",
      };

      setScaledCoords1(cardSelectedCss);
    } else if (cardSelected == "Supply Chain") {
      let cardSelectedCss = {
        width: "19.5%",
        height: "75.5%",
        top: "22.5%",
        left: "21%",
        position: "absolute",

        boxShadow: "0 0 5px 5px rgba(30, 144, 255, 0.6)",
        // animation: "pulse 1s infinite alternate",
      };

      setScaledCoords1(cardSelectedCss);
    } else if (cardSelected == "Marketing") {
      let cardSelectedCss = {
        width: "19.5%",
        height: "75.5%",
        top: "22.5%",
        left: "1.2%",
        position: "absolute",
        boxShadow: "0 0 5px 5px rgba(30, 144, 255, 0.6)",
        // animation: "pulse 1s infinite alternate",
      };
      setScaledCoords1(cardSelectedCss);
    } else if (cardSelected == "Store") {
      let cardSelectedCss = {
        width: "19.5%",
        height: "75.5%",
        top: "22.5%",
        right: "20%",
        position: "absolute",
        boxShadow: "0 0 5px 10px rgba(30, 144, 255, 0.6)",
        // animation: "pulse 1s infinite alternate",
      };
      setScaledCoords1(cardSelectedCss);
    } else if (cardSelected == "All Personas") {
      let cardSelectedCss = {
        width: "0%",
        height: "0%",
        top: "0%",
        right: "0%",
        position: "absolute",
        boxShadow: "0 0 0px 0px",
        // animation: "pulse 1s infinite alternate",
      };
      setScaledCoords1(cardSelectedCss);
    }
  }, [cardSelected]);

  useEffect(() => {
    dispatch(setPageType(pageType));
    dispatch(setPageTitle(pageTitle));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (reportLoading) {
      return;
    }

    setReportLoading(true);
    try {
      if (reportWithoutName) {
        PowerBiServiceInstance.load(
          id,
          {
            type: EmbedType.Report,
            elementId: id,
            height,
            width,
          },
          url
        );
      } else {
        if (name) {
          PowerBiServiceInstance.load(
            id,
            {
              type: EmbedType.Report,
              elementId: name,
              pageName: name,
              height,
              width,
            },
            url
          );
        } else {
          PowerBiServiceInstance.load(
            id,
            {
              type: EmbedType.Dashboard,
              elementId: id,
              height,
              width,
            },
            url
          );
        }
      }

      setReportLoading(false);
    } catch (error) {
      setReportLoading(false);
    }
  }, [reportLoading, pageType, name, id, reportWithoutName]);

  useEffect(() => {
    if (reportLoading || !name) {
      return;
    }
    PowerBiServiceInstance.switchPage(id, name);
  }, [reportLoading, name, id, PowerBiServiceInstance]);

  return (
    <div key={id + name} className={`${styles.container} ${name}`}>
      <h1 className={styles.title}>{title}</h1>
      <div key={id + name} className={`${styles.subContainer}`}>
        {(location.pathname === "/executive-dashboard-before" ||
          location.pathname === "/executive-dashboard-after") && (
          <div style={scaledCoords1}></div>
        )}
        {id !== "" && (
          <div
            key={name}
            id={name ?? id}
            className={`${styles.report} ${styles[background]} `}
          />
        )}
      </div>
    </div>
  );
};
