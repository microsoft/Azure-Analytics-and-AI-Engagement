import { useParams, useLocation } from "react-router-dom";
import {
  objProp,
  pipe,
  add,
  converge,
  identity,
  always,
  defaultTo,
} from "fp-tools";
import { indexOf } from "ramda";
import { rootPath } from "utilities";

export const useNav = ({ arrowConfig, routeDefinitions }: any) => {
  const { persona } = useParams<{ persona: string }>();
  const { pathname } = useLocation();
  // index :: persona -> number
  const index = pipe(
    defaultTo("mainFlow"),
    objProp(routeDefinitions),
    converge(indexOf, [always(rootPath(`${pathname}`)), identity])
  );

  // nextIndex :: persona -> number
  const nextIndex = pipe(index, defaultTo(0), add(1));
  const previousIndex = pipe(index, defaultTo(0), add(-1));

  // nextPage :: persona | unit -> string
  const nextPage = pipe(
    defaultTo("mainFlow"),
    converge(objProp, [objProp(routeDefinitions), nextIndex]),
    defaultTo("landing_page")
  );

  const previousPage = pipe(
    defaultTo("mainFlow"),
    converge(objProp, [objProp(routeDefinitions), previousIndex]),
    defaultTo("landing_page")
  );

  const nextArrowName = () => {
    return `Arrow-${nextIndex(persona)}.png`;
  };

  const previousArrowName = () => {
    return `Arrow-${previousIndex(persona)}.png`;
  };

  const data = {
    arrows: pipe(
      always(rootPath(`${pathname}`)),
      objProp(arrowConfig),
      defaultTo([])
    )(persona),
    nextPage: {
      n: persona ? nextPage(persona) + `/${persona}` : nextPage(persona),
      a: nextArrowName(),
    },
    previousPage: {
      n: persona
        ? previousPage(persona) + `/${persona}`
        : previousPage(persona),
      a: previousArrowName(),
    },
  };
  return data;
};
