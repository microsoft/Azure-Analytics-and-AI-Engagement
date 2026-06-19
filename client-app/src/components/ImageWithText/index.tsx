import { FC } from "react";
import styles from "./styles.module.scss";

interface Props {
  imgSrc: string;
  text: React.ReactNode;
}

const { BlobBaseUrl } = window.config;

// For Tabs (i.e. form recognizer, hospital incident insights)
export const ImageWithText: FC<Props> = ({ imgSrc, text }) => {
  return (
    <div className={styles.tabContainer}>
      <div className={styles.tabImg}>
        <img alt={imgSrc} src={`${BlobBaseUrl}${imgSrc}`} />
      </div>
      <div className={styles.tabText}>
        <div className={styles.textWrapper}>
          <h3>JSON</h3>
          {text}
        </div>
      </div>
    </div>
  );
};
