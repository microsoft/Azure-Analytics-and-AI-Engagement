import { EmbedType } from "types";

export * from "./powerbi";
export * from "./arrow";
export * from "./speechToText";
export * from "./msalConfig";

export const getPowerBIData = (url: string) => {
  const guidPattern = /\/groups\/([a-fA-F0-9-]+)/;
  const reportPattern = /\/reports\/([a-fA-F0-9-]+)/;
  const dashboardPattern = /\/dashboards\/([a-fA-F0-9-]+)/;
  const reportSectionPattern = /\/([^/?]+)(?:\?|$)/;

  const match = url?.match(guidPattern);
  if (match) {
    // const guid = match[1];
    let id: any;
    let type: any;
    let section: any;
    if (url.includes("report")) {
      const matchId = url.match(reportPattern);

      if (matchId) {
        id = matchId[1];
        type = EmbedType.Report;
      }
      const sectionMatch = url.match(reportSectionPattern);

      if (sectionMatch) {
        section = sectionMatch[1];
      }
    } else if (url.includes("dashboard")) {
      const matchId = url.match(dashboardPattern);
      if (matchId) {
        id = matchId[1];
        type = EmbedType.Dashboard;
      }
    }
    return { id, type, section: section ?? "" };
  }
};
