import { NavLink } from "react-router-dom";
import resetIcon from "../../../assets/OpenAIChat/reset.png";
import styles from "./Layout.module.scss";
import { FC, useContext } from "react";
import sms_icon from "../../../assets/OpenAIChat/sms.png";
import { SettingsContext } from "context";

export const OpenAIChatLayout: FC<any> = (props: any) => {
  const setClearChat = () => {
    props.onsetClearChat();
  };

  return (
    <div className={styles.layout}>
      <header className={styles.header} role={"banner"}>
        {/* <div className={styles.headerContainer}>
          <p className={styles.headerRightText} style={{ color: "white" }}>
            Chat with your own data
          </p> 
        
        </div> */}
      </header>
      <div></div>
      {props.children}
    </div>
  );
};
