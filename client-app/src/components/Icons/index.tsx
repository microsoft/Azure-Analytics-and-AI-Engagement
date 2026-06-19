import React from 'react';
import styles from "./styles.module.scss";

const { NumberIconBlobBaseUrl } = window.config;
interface Props {
  iconName: string;
}

export const Icons: React.FC<Props> = ({ iconName }) => {
  const imagePath = NumberIconBlobBaseUrl+`${iconName}.png`;
  return (
    <div>
      <img src={imagePath} alt={iconName} className={styles.iconImage}/>
    </div>
  );
};
