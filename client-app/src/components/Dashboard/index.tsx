import { useState, useEffect, FC } from "react";
import styles from "./styles.module.scss";
import { EmbedType, PageType } from "types";
import { useAppDispatch } from "hooks";
import { setPageTitle, setPageType } from "store";
import { height, width } from "common";
import { BackArrow, Image } from "components";
import { PowerBiService } from "utilities";

export interface Props {
  pageTitle: string;
  pageType: PageType;
  id: string;
  name?: string;
  apiUrl?: string;
  dashboardImage?: string;
  url?: string;
}

const { APIUrl } = window.config;

export const Dashboard: FC<Props> = ({
  pageTitle,
  pageType,
  id,
  name,
  apiUrl,
  dashboardImage,
  url,
}) => {
  const [dashboardLoading, setDashboardLoading] = useState(false);
  const dispatch = useAppDispatch();

  const PowerBiServiceInstance = new PowerBiService(apiUrl ?? APIUrl);

  useEffect(() => {
    dispatch(setPageType(pageType));
    dispatch(setPageTitle(pageTitle));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (dashboardLoading) {
      return;
    }

    setDashboardLoading(true);
    try {
      if (name) {
        PowerBiServiceInstance.load(
          id,
          {
            type: EmbedType.Report,
            elementId: id,
            pageName: name,
            height,
            width,
          },
          url
        );
      } else {
        if (id !== "") {
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
      setDashboardLoading(false);
    } catch (error) {
      setDashboardLoading(false);
    }
  }, [id, name, dashboardLoading, pageType]);

  useEffect(() => {
    if (dashboardLoading || !name) {
      return;
    }
    PowerBiServiceInstance.switchPage(id, name);
  }, [id, dashboardLoading, name]);

  return (
    <div key={pageType} className={styles.container}>
      {/* <BackArrow /> */}
      {dashboardImage ? (
        <Image
          pageTitle={pageTitle}
          pageType={pageType}
          src={dashboardImage}
          className={styles.gifContainer}
        />
      ) : (
        <div id={id} className={styles.dashboard}></div>
      )}
    </div>
  );
};
