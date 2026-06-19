import { Navigate, useLocation } from "react-router-dom";
import { useAppSelector } from "hooks";
import { FC } from "react";

interface Props {
  children: JSX.Element;
}

export const RequireAuth: FC<Props> = ({ children }) => {
  const location = useLocation();
  const loggedIn = useAppSelector((state) => state.login.loggedIn);

  if (!loggedIn) {
    // Redirect them to the /login page, but save the current location they were
    // trying to go to when they were redirected. This allows us to send them
    // along to that page after they login, which is a nicer user experience
    // than dropping them off on the home page.
    return <Navigate to={`login`} state={{ from: location }} replace />;
  }

  return children;
};
