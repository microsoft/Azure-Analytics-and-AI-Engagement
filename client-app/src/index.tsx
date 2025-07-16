import React from "react";
import ReactDOM from "react-dom/client";
import "./index.scss";
import App from "./App";
import reportWebVitals from "./reportWebVitals";
import { HashRouter } from "react-router-dom";
import { Provider } from "react-redux";
import { store } from "./store";
import {
  AuthContextProvider,
  DemoContextProvider,
  SettingsContextProvider,
} from "context";
import { initializeIcons } from "@fluentui/react";
import { msalConfig } from "utilities";
import { MsalProvider } from "@azure/msal-react";
import { PublicClientApplication } from "@azure/msal-browser";

// Required with new version of typescript
declare global {
  interface Window {
    config: any;
  }

  interface Microsoft {
    Maps: any;
  }
}
initializeIcons();

const pca = new PublicClientApplication(msalConfig);

const root = ReactDOM.createRoot(
  document.getElementById("root") as HTMLElement
);

root.render(
  <HashRouter>
    <Provider store={store}>
      <MsalProvider instance={pca}>
        <SettingsContextProvider>
          <DemoContextProvider>
            <AuthContextProvider>
              <App />
            </AuthContextProvider>
          </DemoContextProvider>
        </SettingsContextProvider>
      </MsalProvider>
    </Provider>
  </HashRouter>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
