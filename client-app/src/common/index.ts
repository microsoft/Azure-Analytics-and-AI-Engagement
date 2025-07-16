export * from "./persona";
export * from "./menu";
export * from "./constants";
export * from "./powerbiConfig";

export const getIndustry = (id: number) => {
  switch (id) {
    case 1:
      return "retail";
    case 2:
      return "manufacturing";
    case 3:
      return "healthcare";
    case 4:
      return "finance";
    default:
      return "retail";
  }
};
