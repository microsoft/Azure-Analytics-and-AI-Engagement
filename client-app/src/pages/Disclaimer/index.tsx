import { Dispatch, FC, SetStateAction, useEffect } from "react";
import { useAppDispatch } from "hooks";
import { setPageTitle, setPageType } from "store";
import { PageType } from "types";
import styles from "./styles.module.scss";
import { Button } from "@progress/kendo-react-buttons";

interface Props {
  setValue: Dispatch<SetStateAction<boolean>>;
  setVisible: Dispatch<SetStateAction<boolean>>;
}

export const Disclaimer: FC<Props> = ({ setValue, setVisible }) => {
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(setPageType(PageType.Disclaimer));
    dispatch(setPageTitle("Disclaimer"));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <>
      <div className={styles.legalNoticeContainer}>
        <p>
          This presentation, demonstration, and demonstration model are for
          informational purposes only and (1) are not subject to SOC 1 and SOC 2
          compliance audits, and (2) are not designed, intended or made
          available as a medical device(s) or as a substitute for professional
          medical advice, diagnosis, treatment or judgement.{" "}
          <strong>
            Microsoft makes no warranties, express or implied, in this
            presentation, demonstration, and demonstration model.
          </strong>{" "}
          Nothing in this presentation, demonstration or demonstration model
          modifies any of the terms and conditions of Microsoft's written and
          signed agreements. This is not an offer and applicable terms and the
          information provided are subject to revision and may be changed at any
          time by Microsoft.
        </p>
        <p>
          This presentation, demonstration, and demonstration model do not give
          you or your organization any license to any patents, trademarks,
          copyrights, or other intellectual property covering the subject matter
          in this presentation, demonstration, and demonstration model.
        </p>
        <p>
          The information contained in this presentation, demonstration and
          demonstration model represents the current view of Microsoft on the
          issues discussed as of the date of presentation and/or demonstration,
          for the duration of your access to the demonstration model. Because
          Microsoft must respond to changing market conditions, it should not be
          interpreted to be a commitment on the part of Microsoft, and Microsoft
          cannot guarantee the accuracy of any information presented after the
          date of presentation and/or demonstration and for the duration of your
          access to the demonstration model.The information contained in this
          presentation, demonstration and demonstration model represents the
          current view of Microsoft on the issues discussed as of the date of
          presentation and/or demonstration, for the duration of your access to
          the demonstration model. Because Microsoft must respond to changing
          market conditions, it should not be interpreted to be a commitment on
          the part of Microsoft, and Microsoft cannot guarantee the accuracy of
          any information presented after the date of presentation and/or
          demonstration and for the duration of your access to the demonstration
          model.
        </p>
        <p>
          No Microsoft technology, nor any of its component technologies,
          including the demonstration model, is intended or made available as a
          substitute for the professional advice, opinion, or judgement of (1) a
          certified financial services professional, or (2) a certified medical
          professional. Partners or customers are responsible for ensuring the
          regulatory compliance of any solution they build using Microsoft
          technologies.
        </p>
        <p>© Microsoft Corporation. All rights reserved.</p>
      </div>
      <div className={styles.stickyFooter}>
        <Button
          className={styles.btn}
          onClick={() => {
            setVisible(false);
            setValue(true);
          }}
        >
          Agree
        </Button>
      </div>
    </>
  );
};
