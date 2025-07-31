import { useAppDispatch } from "hooks";
import { FC, useEffect } from "react";
import { setPageType, setPageTitle } from "store";
import { PageType } from "types";
import styles from "./styles.module.scss";
import { BackArrow } from "components";

interface Props {
  pageTitle: string;
  pageType: PageType;
  url: string;
  id?: string;
}

export const IFrame: FC<Props> = ({ id, pageTitle, pageType, url }) => {
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(setPageType(pageType));
    dispatch(setPageTitle(pageTitle));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className={styles.container}>
      {" "}
      {/* <h1 className={styles.videoTitle}>{pageTitle}</h1> */}
      <div className={styles.subContainer}>
        {/* <BackArrow /> */}
        <iframe
          id={id}
          title={pageTitle}
          allow="autoplay"
          src={url}
          className={styles.iframe}
        />
      </div>
    </div>
  );
};
