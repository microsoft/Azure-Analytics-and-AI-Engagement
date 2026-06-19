import { Image } from "components";
import { useAppDispatch } from "hooks";
import { useState, useEffect } from "react";
import { setPageType, setPageTitle } from "store";
import { PageType, EmbedType } from "types";
import styles from "./styles.module.scss";
import { PowerBiService } from "utilities";

interface Props {
  pageTitle: string;
  pageType: PageType;
  dashboardId: string;
  topReportId: string;
  topReportName: string;
  apiUrl?: string;
  dashboardImage?: string;
  url?: string;
  reportUrl?: string;
}

const width = 1920;
const height = 1280;
const { APIUrl } = window.config;

export const DashboardWithReport: React.FC<Props> = ({
  pageType,
  pageTitle,
  dashboardId,
  topReportId,
  apiUrl,
  dashboardImage,
  topReportName,
  reportUrl,
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
      PowerBiServiceInstance.load(
        dashboardId,
        {
          type: EmbedType.Dashboard,
          elementId: dashboardId,
          height,
          width,
        },
        url
      );
      PowerBiServiceInstance.load(
        topReportId,
        {
          type: EmbedType.Report,
          elementId: topReportId,
          pageName: topReportName,
          height,
          width,
        },
        reportUrl
      );

      setDashboardLoading(false);
    } catch (error) {
      setDashboardLoading(false);
    }
  }, [dashboardId, dashboardLoading, pageType, topReportId, topReportName]);

  useEffect(() => {
    if (dashboardLoading) {
      return;
    }
    PowerBiServiceInstance.switchPage(dashboardId, "");
  }, [dashboardId, dashboardLoading]);

  return (
    <div key={pageType} className={styles.container}>
      <div>
        {topReportId !== "" && (
          <div id={topReportId} className={styles.topReport} />
        )}

        {dashboardImage ? (
          <Image
            pageTitle={pageTitle}
            pageType={pageType}
            src={dashboardImage}
            className={styles.gifContainer}
          />
        ) : (
          <div id={dashboardId} className={styles.dashboard} />
        )}

        {pageType === PageType.ExecutiveDashboardBefore && (
          <Image
            pageTitle={pageTitle}
            pageType={pageType}
            src="Before_Dashboard_Fabric.gif"
            className={styles.gifContainer}
          />
        )}
        {pageType === PageType.ExecutiveDashboardAfter && (
          <Image
            pageTitle={pageTitle}
            pageType={pageType}
            src="After_Dashboard_Fabric.gif"
            className={styles.gifContainer}
          />
        )}
      </div>
    </div>
  );
};

export default DashboardWithReport;
