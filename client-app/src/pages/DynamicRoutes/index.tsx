import { SettingsContext } from "context";
import React, { FC, useContext, useEffect } from "react";
import { Outlet, useParams } from "react-router-dom";

export const DynamicRoutes: FC = () => {
  const query = useParams();
  // const { currentDemo, getCurrentDemoByGUID } = useContext(SettingsContext);

  useEffect(() => {
    // if (currentDemo?.guid && currentDemo.guid === query.id) {
    //   return;
    // }
    // if (query.id) {
    //   return getCurrentDemoByGUID(query.id);
    // }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return <Outlet />;
};
