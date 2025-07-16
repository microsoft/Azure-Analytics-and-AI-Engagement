export * from "./pageType";
export * from "./menu";
export * from "./powerbi";
export * from "./singlePatient";

export interface DemoMenu {
  id: number;
  demoId?: number;
  url: null | string;
  name: string;
  order: number;
  icon: string;
  demoSubMenus?: DemoMenu[];
  componentParameters: ComponentParameter[];
  componentId: number | null;
  component: null;
  externalArrows: ExternalArrow[];
  arrowIcon?: string;
  skip?: boolean;
  toolTip?: string;
}

export interface ExternalArrow {
  id: number;
  icon: string;
  name: string;
  link: string;
  topPosition: number;
  rightPosition: number;
  openInNewTab: boolean;
}

export interface ComponentParameter {
  [key: string]: string;
}
