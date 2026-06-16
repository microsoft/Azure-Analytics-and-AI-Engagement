import { SettingsContext } from "context";
import { FC, useContext, useEffect } from "react";
import { useParams } from "react-router-dom";

export const Home: FC = () => {
  const query = useParams();
  const { currentDemo, getDefaultDemo } = useContext(SettingsContext);

  useEffect(() => {
    // if (!query.id && !currentDemo?.id) {
    //   return getDefaultDemo();
    // }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return <></>;
};
