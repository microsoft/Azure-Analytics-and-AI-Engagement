import { FC } from "react";
import { Dialog } from "@progress/kendo-react-dialogs";
import styles from "./styles.module.scss";

interface Props {
  showPopup: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  className?: string;
  dialogWidth?: number;
  dialogHeight?: number;
  customClass?: string;
  customClassParent?: string;
}

export const Popup: FC<Props> = ({
  onClose,
  showPopup,
  title,
  children,
  className,
  customClass,
  customClassParent,
}) => {
  
  return (
    <>
      {showPopup && (
        <Dialog
          className={`${styles.popupContainer} ${className} ${customClassParent}`}
          title={title}
          onClose={onClose}
        >
          <div className={`${styles.childContainer} ${customClass}`}>
            {children}
          </div>
        </Dialog>
      )}
    </>
  );
};
