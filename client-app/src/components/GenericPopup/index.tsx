import { Popup } from "components/Popup";
import { SettingsContext } from "context";
import React, { FC, ReactNode, useContext, useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router";

interface Props {
  children: ReactNode;
  data: any;
}

export const GenericPopup: FC<Props> = ({ children, data }) => {
  const [showPopup, setShowPopup] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    if (location.pathname === `/${data?.url}`) {
      setShowPopup(true);
    } else {
      setShowPopup(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location]);

  return (
    <>
      <Popup
        showPopup={showPopup}
        title={data?.componentParameters?.popupTitle}
        onClose={() => {
          setShowPopup(false);
          navigate("/" + data?.componentParameters?.popupClose);
        }}
      >
        {children}
      </Popup>
    </>
  );
};
