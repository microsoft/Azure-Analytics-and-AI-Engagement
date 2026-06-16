import { SettingsContext } from "context";
import { useAppDispatch } from "hooks";
import { FC, useContext, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { logout } from "store";

export const Logout: FC = () => {
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const { currentDemo } = useContext(SettingsContext);

  useEffect(() => {
    dispatch(logout());
    // if (currentDemo?.guid) {
    navigate(`/login`, { replace: true });
    // }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return <></>;
};
