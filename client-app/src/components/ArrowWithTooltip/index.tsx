import { Tooltip } from "@progress/kendo-react-tooltip";
import React, { FC } from "react";
import { Link } from "react-router-dom";
import styles from "./styles.module.scss";

const { BlobBaseUrl } = window.config;

interface Props {
  href: string;
  img: string;
}

export const ArrowWithTooltip: FC<Props> = ({ href, img }) => {
  return (
    <Tooltip
      tooltipClassName={styles.tooltip}
      position={"left"}
      anchorElement="target"
    >
      <Link to={href} className={styles.arrowTopRight}>
        <img src={`${BlobBaseUrl}${img}`} alt="Nav Arrow" />
      </Link>
    </Tooltip>
  );
};
