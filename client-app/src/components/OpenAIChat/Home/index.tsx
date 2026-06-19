import React from "react";
import { Navigate } from "react-router-dom";

export const Home = () => {
  return <Navigate to={"/chat"} />;
};
