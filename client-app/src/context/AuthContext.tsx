import { createContext, FC, ReactNode, useState } from "react";
import axios from "axios";
import { useMsal } from "@azure/msal-react";

const { LogAPI } = window.config;

interface Props {
  children: ReactNode;
}

const callApi = async (
  email: string,
  url: string,
  ipAddress: string,
  actionType: string,
  details?: string
) => {
  try {
    await axios.post(LogAPI + "Create", {
      email,
      ipAddress,
      url,
      details,
      actionType,
    });
  } catch (err) {
    // Log errors using a consistent logging mechanism
    console.error("API call failed:", err);
  }
};

async function getIPAddress() {
  try {
    const res = await axios.get("https://api.ipify.org/?format=json");
    return res?.data?.ip || "";
  } catch (error) {
    console.error("Error fetching IP address:", error);
    return "";
  }
}

export const AuthContextProvider: FC<Props> = ({ children }) => {
  const { accounts } = useMsal();
  const [ipAddress, setIPAddress] = useState("");

  const trackDemoLoad = async () => {
    if (!ipAddress) {
      const ip = await getIPAddress();
      setIPAddress(ip);
    }

    if (ipAddress && accounts?.length > 0)
      !window.location.href.includes("localhost") &&
        (await callApi(
          accounts?.[0]?.username,
          window.location.href,
          ipAddress,
          "Authentication",
          "Azure Hero DREAM Demos - Prod"
        ));
  };

  const trackNavigation = async (navPageTitle: string) => {
    if (!ipAddress) {
      const ip = await getIPAddress();
      setIPAddress(ip);
    }

    if (ipAddress && accounts?.length > 0)
      !window.location.href.includes("localhost") &&
        (await callApi(
          accounts?.[0]?.username,
          window.location.href,
          ipAddress,
          "Navigation",
          "Azure Hero DREAM Demos - Prod -> " + navPageTitle
        ));
  };

  return (
    <AuthContext.Provider
      value={{
        trackDemoLoad,
        trackNavigation,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const AuthContext = createContext({
  trackDemoLoad: () => {},
  trackNavigation: (title: string) => {},
});
