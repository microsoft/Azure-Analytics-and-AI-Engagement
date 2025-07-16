import { useEffect, useState } from "react";
import { DemoMenu } from "types";
import { useAppSelector } from "./useAppSelector";

export type ArrowConfig = {
  c?: string; // classname
  a?: string; // arrowname
  l?: string; // link
  n?: keyof any; // next
  openInNewTab?: boolean;
  t?: string;
  top?: number;
  right?: number;
};

export const useArrows = () => {
  const { demoMenus } = useAppSelector((state: any) => state.config);

  const [tooltips, setTooltips] = useState<
    {
      id: number;
      url: string;
      value: string;
    }[]
  >([]);

  const [mainFlow, setMainFlow] = useState<string[]>([]);
  const [arrowConfig, setArrowConfig] = useState<{
    [key: string]: ArrowConfig[];
  }>({});

  useEffect(() => {
    if (demoMenus) {
      setTooltips([]);
      setMainFlow([]);
      setArrowConfig({});

      const demos = (demoMenus as DemoMenu[])
        ?.map((demoMenu) => {
          // Handle second and third level menus
          if (demoMenu.demoSubMenus?.length) {
            return demoMenu.demoSubMenus
              .map((subMenu) => {
                if (subMenu.demoSubMenus?.length) {
                  // Handle third level menus
                  return subMenu.demoSubMenus.map((thirdLevelMenu) => ({
                    id: thirdLevelMenu.id,
                    url: thirdLevelMenu.url
                      ?.split("/")?.[1]
                      ?.replaceAll("-", "_"),
                    name: thirdLevelMenu.name,
                    arrowIcon: thirdLevelMenu.arrowIcon,
                    externalArrows: thirdLevelMenu.externalArrows,
                    skip: thirdLevelMenu.skip,
                  }));
                } else {
                  return {
                    id: subMenu.id,
                    url: subMenu.url?.split("/")?.[1]?.replaceAll("-", "_"),
                    name: subMenu.name,
                    arrowIcon: subMenu.arrowIcon,
                    externalArrows: subMenu.externalArrows,
                    skip: subMenu.skip,
                  };
                }
              })
              .flat();
          } else {
            return {
              id: demoMenu.id,
              url: demoMenu.url?.split("/")?.[1]?.replaceAll("-", "_"),
              name: demoMenu.name,
              arrowIcon: demoMenu.arrowIcon,
              externalArrows: demoMenu.externalArrows,
              skip: demoMenu.skip,
            };
          }
        })
        .flat();

      demos
        .filter((d) => !d.skip)
        .forEach(
          ({ url, name, id, arrowIcon, externalArrows }, index: number) => {
            if (url) {
              const obj = [
                {
                  t: "default",
                  ...(arrowIcon ? { a: arrowIcon } : {}),
                  ...(index === demos?.length - 1 ? { n: "landing_page" } : {}),
                },
              ];

              if (externalArrows?.length > 0) {
                externalArrows.forEach((arrow) => {
                  obj.push({
                    t: "default",
                    openInNewTab: arrow.openInNewTab,
                    a: arrow.icon,
                    tooltip: arrow.name,
                    l: arrow.link,
                    top: arrow.topPosition,
                    right: arrow.rightPosition,
                  } as any);
                });
              }

              setTooltips((old) => {
                return !old?.length
                  ? [{ id, url: url, value: name }]
                  : [...old, { id, url: url, value: name }];
              });
              setMainFlow((old) => (!old?.length ? [url] : [...old, url]));
              setArrowConfig((old) => {
                return {
                  ...old,
                  [url]: obj,
                };
              });
            }
          }
        );
    } else {
      setTooltips([]);
      setMainFlow([]);
      setArrowConfig({});
    }
  }, [demoMenus]);

  return { tooltips, routeDefinitions: { mainFlow }, arrowConfig };
};
