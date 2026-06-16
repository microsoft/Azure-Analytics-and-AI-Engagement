import { Dispatch, SetStateAction } from "react";
import styles from "./UserChatMessage.module.css";

interface Props {
  message: string;
  onCopyMessage: (message: string) => void;
  setIsReplay?: Dispatch<SetStateAction<boolean>>;
  disabled?: boolean;
}

export const UserChatMessage = ({
  message,
  onCopyMessage,
  disabled,
  setIsReplay,
}: Props) => {
  return (
    <div className={styles.container}>
      <div
        className={styles.message}
        style={{ paddingTop: !disabled ? 35 : 20 }}
      >
        {message}
      </div>
      {!disabled && (
        <div className={styles.actions}>
          <span
            title="Copy"
            onClick={() => onCopyMessage(message)}
            className="k-icon k-i-copy"
          />
          <span
            title="Replay"
            onClick={() => {
              onCopyMessage(message);
              setIsReplay?.(true);
            }}
            className="k-icon k-i-reload"
          />
        </div>
      )}
    </div>
  );
};
