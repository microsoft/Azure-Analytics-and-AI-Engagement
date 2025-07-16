import {
  GenericPopup,
  
  LandingPage,
} from "components";
import { Image } from "components/Image";
import { log } from "console";
import { SettingsContext } from "context";
import { useAppDispatch } from "hooks";
import {
 
  ArchitectureWithTags,
} from "pages";
// import { ChatBot2 } from "pages/ChatBot2";
import { ShoppingCopilotMTC } from "pages/ShoppingCopilotMTC";
//import { NewReimagined } from "pages/NewReimagined";
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

    case "landing page":
      return (
        <LandingPage
          pageTitle="Landing Page"
          pageType={PageType.LandingPage}
          src={landingPageImage}
        />
      );
    case "shopping copilot":
      return <ShoppingCopilotMTC />
    case "architecture with tags":
      return (
        <ArchitectureWithTags
          pageTitle={data.name}
          pageType={data.name}
          videoURL={data.componentParameters.url}
          tags={data.componentParameters?.tags}
        />
      );
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
