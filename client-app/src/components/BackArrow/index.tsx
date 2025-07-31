import React, { FC } from "react";
import { IoIosArrowBack } from "react-icons/io";
import { Link } from "react-router-dom";
import styles from "./styles.module.scss";

export const BackArrow: FC = () => {
  return (
    <div className={styles.backArrow}>
      <Link to={"/mega-map"}>
        <IoIosArrowBack color="white" />
        <span>Back</span>
      </Link>
    </div>
  );
};
