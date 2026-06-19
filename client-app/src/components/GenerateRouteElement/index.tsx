import {
  Dashboard,
  DashboardWithReport,
  GenericPopup,
  IFrame,
  Report,
  
  Image,
  LandingPage,
} from "components";
import EndToEnd from "components/EndToEnd";
import { log } from "console";
import { SettingsContext } from "context";
import { useAppDispatch } from "hooks";
import {
  ChatBot,
  ChatBot2,
} from "pages";
import { IncomingCall } from "pages/IncomingCall";
import { ShoppingCopilotMTC } from "pages/ShoppingCopilotMTC";
import React, { FC, useContext, useEffect } from "react";
import { setPersona, setTimeline } from "store";
import { PageType } from "types";
import { getPowerBIData } from "utilities";

interface Props {
  data: any;
}

const { landingPageImage } = window.config;

export const GenerateRouteElement: FC<Props> = ({ data }) => {
  console.log("data in GenerateRouteElement:", data);
  
  const dispatch = useAppDispatch();
  useEffect(() => {
    dispatch(setPersona(data?.personaImageUrl));
    dispatch(setTimeline(data?.componentParameters?.timeline));
  }, [data, dispatch]);
  let url = "";
  if (data.componentParameters.url === undefined)
    url = data.componentParameters[0]?.value;
  else url = data.componentParameters.url;

//   const params = Object.fromEntries(
//   data.componentParameters.map(({ key, value }: any) => [key, value])
// );

let params: Record<string, string> = {};
if (Array.isArray(data.componentParameters)) {
  params = Object.fromEntries(
    data.componentParameters.map(({ key, value }: any) => [key, value])
  );
} else if (typeof data.componentParameters === "object" && data.componentParameters !== null) {
  params = data.componentParameters;
}


  switch (data.componentName.toLowerCase()) {
    case "power bi report":
      const powerBIData = getPowerBIData(url);
      return data.componentParameters.isPopup ? (
        <GenericPopup data={data}>
          <Report
            // apiUrl={data.componentParameters.api}
            id={powerBIData?.id}
            title={data?.title}
            pageTitle={data?.name}
            pageType={data?.name}
            name={powerBIData?.section}
            url={url}
            background={data?.componentParameters?.background}
          />
        </GenericPopup>
      ) : (
        <Report
          // apiUrl={data.componentParameters.api}
          id={powerBIData?.id}
          pageTitle={data?.name}
          title={data?.title}
          pageType={data?.name}
          name={powerBIData?.section}
          url={url}
          background={data?.componentParameters?.background}
        />
      );

   

    case "power bi dashboard":
      const powerBIDashboardData = getPowerBIData(data.componentParameters.url);
      const powerBIReportData: any = data.componentParameters?.reportUrl
        ? getPowerBIData(data.componentParameters.reportUrl)
        : {};

      return data.componentParameters?.reportUrl ? (
        data.componentParameters.isPopup ? (
          <GenericPopup data={data}>
            <DashboardWithReport
              // apiUrl={data.componentParameters.api}
              dashboardId={powerBIDashboardData?.id}
              dashboardImage={data.componentParameters.image}
              topReportId={powerBIReportData?.id}
              topReportName={powerBIReportData?.section}
              pageTitle={data.name}
              pageType={data.name}
              url={data.componentParameters.url}
              reportUrl={data.componentParameters.reportUrl}
            />
          </GenericPopup>
        ) : (
          <DashboardWithReport
            // apiUrl={data.componentParameters.api}
            dashboardId={powerBIDashboardData?.id}
            dashboardImage={data.componentParameters.image}
            topReportId={powerBIReportData?.id}
            topReportName={powerBIReportData?.section}
            pageTitle={data.name}
            pageType={data.name}
            url={data.componentParameters.url}
            reportUrl={data.componentParameters.reportUrl}
          />
        )
      ) : data.componentParameters.isPopup ? (
        <GenericPopup data={data}>
          <Dashboard
            // apiUrl={data.componentParameters.api}
            id={powerBIDashboardData?.id}
            dashboardImage={data.componentParameters.image}
            pageTitle={data.name}
            pageType={data.name}
            url={data.componentParameters.url}
          />
        </GenericPopup>
      ) : (
        <Dashboard
          // apiUrl={data.componentParameters.api}
          id={powerBIDashboardData?.id}
          dashboardImage={data.componentParameters.image}
          pageTitle={data.name}
          url={data.componentParameters.url}
          pageType={data.name}
        />
      );
   
    case "image":
      return data.componentParameters?.isPopup ? (
        <GenericPopup data={data}>
          <Image
            title={data?.title}
            src={data.componentParameters.url}
            pageTitle={data.name}
            pageType={data.name}
            originalSize={data.componentParameters.originalSize}
            backgroundImage={data?.componentParameters?.backgroundImage}
          />
        </GenericPopup>
      ) : (
        <Image
          title={data?.title}
          src={
            data.componentParameters.url == undefined
              ? url
              : data.componentParameters.url
          }
          pageTitle={data.name}
          pageType={data.name}
          originalSize={data.componentParameters.originalSize}
          backgroundImage={data?.componentParameters?.backgroundImage}
        />
      );

    
     
    case "iframe":
      return data.componentParameters?.isPopup ? (
        <GenericPopup data={data}>
          <IFrame
            url={data.componentParameters.url}
            pageTitle={data.name}
            pageType={data.name}
          />
        </GenericPopup>
      ) : (
        <IFrame
          url={data.componentParameters.url}
          pageTitle={data.name}
          pageType={data.name}
        />
      );

    case "landing page":
      return (
        <LandingPage
          pageTitle="Landing Page"
          pageType={PageType.LandingPage}
          src={landingPageImage}
        />
      );

    case "beach view":
   

    // case "ArchImage":
    //   return <ArchImage />;

    case "chat bot":
      return (
        <ChatBot2
          key={data?.componentParameters}
          componentParameters={data?.componentParameters}
        />
      );
   
   
    case "incoming call":
      return <IncomingCall />;
    
    
    case "shopping copilot":
      return <ShoppingCopilotMTC />;
    case "endtoend":
      return <EndToEnd />;
    case "custom landing page":
      return (
        <LandingPage
          src={data.componentParameters.innerImageUrl}
          pageTitle={data.name}
          pageType={data.name}
          originalSize={data.componentParameters.originalSize}
          backgroundImage={data?.componentParameters?.url}
        />
      );
    default:
      return <></>;
  }
};
