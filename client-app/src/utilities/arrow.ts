import { pipe, eq } from "fp-tools";
import { replace } from "ramda";

// current :: string -> string -> boolean
export const current = (pathname: string) => (path: string) =>
  pipe(rootPath, replace(/_/g, "-"), eq(path))(pathname);

// rootPAth :: string -> string
export const rootPath = (pathname: string) => {
  return pathname.split("/").length > 1
    ? pathname.split("/")[1].replace(/-/g, "_")
    : "";
};

// urlify :: string -> string
export const urlify = (routeDef: string) => {
  return `/${routeDef.replace(/_/g, "-")}`;
};
