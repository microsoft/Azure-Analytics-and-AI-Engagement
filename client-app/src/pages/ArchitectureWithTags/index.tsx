import { FC, useEffect } from "react";

import { useAppDispatch } from "hooks";
import { setPageTitle, setPageType } from "store";
import { PageType } from "types";

import styles from "./styles.module.scss";

interface Tag {
  tagName: string;
  tagDescription: string;
}

interface Props {
  pageType: PageType;
  pageTitle: string;
  videoURL?: string;
  tags?: Tag[] | [];
  imageUrl?: string;
}

const { BlobBaseUrl } = window.config;

export const ArchitectureWithTags: FC<Props> = ({
  tags = [],
  pageTitle,
  pageType,
  videoURL = BlobBaseUrl,
  imageUrl,
}) => {
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(setPageType(pageType));
    dispatch(setPageTitle(pageTitle));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className={styles.container}>
      {imageUrl ? (
        <img src={imageUrl} alt="" style={{ width: "86%", height: "90%" }} />
      ) : (
        <video
          src={videoURL}
          style={{ width: "70%", height: "70%" }}
          autoPlay
          controls
        />
      )}
      <div className={styles.legendContainer}>
        {tags?.length > 0 && (
          <div className={styles.legends}>
            {tags?.map((tag, index) => (
              <>
                <div className={styles.legend}>
                  <div className={styles.tooltiContainer}>
                    <div className={styles.infoIcon}>{index + 1}</div>
                    <span className={styles.tooltiptext}>
                      {tag.tagDescription}
                    </span>
                  </div>
                  <div>{tag.tagName}</div>
                </div>
              </>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
