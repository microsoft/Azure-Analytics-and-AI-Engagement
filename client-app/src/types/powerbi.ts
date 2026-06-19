export enum EmbedType {
  Report = "report",
  Dashboard = "dashboard",
  Tile = "tile",
}
export interface Filter {
  table: string;
  column: string;
  value: string;
}

export interface EmbedConfig {
  type: EmbedType;
  elementId: string;
  filter?: Filter;
  height?: number;
  width?: number;
  height1?: number;
  width1?: number;
  pageName?: string;
  editMode?: boolean;
  onRendered?: Function;
  onClick?: Function;
}
