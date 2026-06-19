import { AuthContext, arrayToObject } from "context";
import { useContext, useEffect } from "react";
import { Navigate, Route, Routes, useLocation } from "react-router-dom";
import { DemoMenu } from "types";
import {
  GenerateRouteElement,
  Layout,
  RequireAuth,
  RotateBanner,
} from "./components";
import { Login, Logout, OrgChart } from "./pages";
import "./app.scss";
import { InteractionType } from "@azure/msal-browser";
import {
  MsalAuthenticationTemplate,
  useIsAuthenticated,
} from "@azure/msal-react";
import { useAppDispatch, useArrows } from "hooks";
import {
  setActiveTileGlobally,
  setActiveTileNumber,
  setDemoMenus,
} from "store";
const {
  demoMenus,
  aiPersona,
  primaryColor,
  secondaryColor,
  tabTextColor,
  navBarPrimaryColor,
  navBarSecondaryColor,
  tabPrimaryColor,
  tabSecondaryColor,
  dropdownPrimaryColor,
  dropdownSecondaryColor,
  dropdownTextColor,
  navBarTextColor,
  headerImageUrl,
  loginTextBoxImage,
  headerBgColor,
  chatContainerBackgroundColor,
  scrollBarPrimaryColor,
  scrollBarSecondaryColor,
  backgroundImageURL,
} = window.config;

const getFormattedDemoMenus = (aiPersona: any) =>
  aiPersona?.map((iframe: DemoMenu) => {
    return {
      ...iframe,
      componentParameters: iframe?.componentParameters?.length
        ? arrayToObject(iframe?.componentParameters)
        : [],
      demoSubMenus: iframe?.demoSubMenus?.map((menuItem) => {
        return {
          ...menuItem,
          componentParameters: menuItem?.componentParameters?.length
            ? arrayToObject(menuItem?.componentParameters)
            : [],
        };
      }),
    };
  });

function App() {
  const { trackDemoLoad, trackNavigation } = useContext(AuthContext);
  const isAuthenticated = useIsAuthenticated();
  const { tooltips } = useArrows();
  const location = useLocation();
  const dispatch = useAppDispatch();

  useEffect(() => {
    trackDemoLoad();
    if (!demoMenus) {
      dispatch(setDemoMenus(window.config.demoMenus));
    }
  }, [isAuthenticated]);

  useEffect(() => {
    const item = tooltips?.filter(
      (item) => `/${item.url}` === location.pathname.replaceAll("-", "_")
    )?.[0];
    if (item?.value) {
      trackNavigation(item?.value);
    }
  }, [location, tooltips]);

  useEffect(() => {
    document.body.style.setProperty(
      "--primary-color",
      `${primaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--secondary-color",
      `${secondaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--tab-text-color",
      `${tabTextColor ?? "rgba(255, 255, 255, 1)"}` ?? ""
    );
    document.body.style.setProperty(
      "--navBar-primary-color",
      `${navBarPrimaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--navBar-secondary-color",
      `${navBarSecondaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--tab-primary-color",
      `${tabPrimaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--tab-secondary-color",
      `${tabSecondaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--dropdown-primary-color",
      `${dropdownPrimaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--dropdown-secondary-color",
      `${dropdownSecondaryColor ?? "rgba(0,0,0,.2)"}` ?? ""
    );
    document.body.style.setProperty(
      "--tab-text-color",
      tabTextColor || "rgba(255,255,255,1)"
    );
    document.body.style.setProperty(
      "--dropdown-text-color",
      dropdownTextColor || "rgba(255,255,255,1)"
    );
    document.body.style.setProperty(
      "--navBar-text-color",
      navBarTextColor || "rgba(255,255,255,1)"
    );
    document.body.style.setProperty("--header-image", `url(${headerImageUrl})`);
    document.body.style.setProperty(
      "--login-text-box-img",
      `url(${loginTextBoxImage})`
    );
    document.body.style.setProperty("--header-bg-color", headerBgColor);
    document.body.style.setProperty(
      "--chat-container-bg-color",
      chatContainerBackgroundColor
    );
    document.body.style.setProperty(
      "--scrollBar-primary-color",
      scrollBarPrimaryColor
    );
    document.body.style.setProperty(
      "--scrollBar-secondary-color",
      scrollBarSecondaryColor
    );
    document.body.style.setProperty(
      "--backgroundImageURL",
      `url(${backgroundImageURL})`
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const renderRoutes: any = (menu: DemoMenu) => {
    if (menu.componentId) {
      return (
        <Route
          key={menu.id}
          path={menu?.url?.split("/")[1]}
          element={<GenerateRouteElement data={menu} />}
        />
      );
    }

    if (menu.demoSubMenus?.length) {
      return menu.demoSubMenus.map((subMenu) => renderRoutes(subMenu));
    }
  };

  const routes =
    demoMenus?.length &&
    (getFormattedDemoMenus(demoMenus) as DemoMenu[])?.flatMap((demoMenu) =>
      renderRoutes(demoMenu)
    );

  return (
    <MsalAuthenticationTemplate interactionType={InteractionType.Redirect}>
      <Routes>
        {/* <Route path="settings" element={<Settings />} /> */}
        <Route path="logout" element={<Logout />} />
        {/* <Route path="" element={<Home />} /> */}
        <Route path="login" element={<Login />} />

        <Route
          element={
            <RequireAuth>
              <Layout />
            </RequireAuth>
          }
        >
          <Route path="org-chart-2" element={<OrgChart />} />

          {routes}
        </Route>
        <Route path="*" element={<Navigate to={`/landing-page`} />} />
      </Routes>
      <RotateBanner />
    </MsalAuthenticationTemplate>
  );
}

export default App;
