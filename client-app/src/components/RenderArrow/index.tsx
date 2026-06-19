import { FC } from "react";
import { ArrowConfig } from "common";
import { useAppSelector, useNav } from "hooks";
import { Arrow } from "./arrow";

export const RenderArrows: FC<any> = ({ arrowConfig, routeDefinitions }) => {
  const { arrows, nextPage, previousPage } = useNav({
    arrowConfig,
    routeDefinitions,
  });
  const { personaID, useCaseID } = useAppSelector((state) => state.config);

  return arrows.map((arrow: ArrowConfig, index: number) =>
    arrow.a === "" ? (
      <span key={index}></span>
    ) : (
      <Arrow
        key={index}
        className={arrow.c}
        to={arrow.n ? arrow.n : arrow.l ? arrow.l : nextPage.n}
        previous={arrow.n ? arrow.n : arrow.l ? arrow.l : previousPage.n}
        name={arrow.a ?? nextPage.a}
        openInNewTab={arrow.openInNewTab}
        type={arrow.t}
        tooltip={arrow?.tooltip}
        top={(arrow as any)?.top}
        right={(arrow as any)?.right}
      />
    )
  );
};
