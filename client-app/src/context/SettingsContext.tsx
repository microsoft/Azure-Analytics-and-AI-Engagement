import { createContext, useEffect, FC, ReactNode, useState } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import { useAppDispatch } from "hooks";
import { logout } from "store";
import { DemoMenu } from "types";

interface Props {
  children: ReactNode;
}

export interface Industry {
  id: number;
  name: string;
  endPointURL: string;
  florenceAdApi: string;
  florenceDallEApi: string;
  pdfUploadApi: string;
  dalleRegenerateAPI: string;
}

export interface Customer {
  businessName: string;
  industryId: number;
  name: string;
  id: number;
}

export function rgba2hex(orig: string) {
  var a: any,
    rgb: any = orig
      .replace(/\s/g, "")
      .match(/^rgba?\((\d+),(\d+),(\d+),?([^,\s)]+)?/i),
    alpha: any = ((rgb && rgb[4]) || "").trim(),
    hex: any = rgb
      ? (rgb[1] | (1 << 8)).toString(16).slice(1) +
        (rgb[2] | (1 << 8)).toString(16).slice(1) +
        (rgb[3] | (1 << 8)).toString(16).slice(1)
      : orig;

  if (alpha !== "") {
    a = alpha;
  } else {
    a = 0o1;
  }
  // multiply before convert to HEX
  a = ((a * 255) | (1 << 8)).toString(16).slice(1);
  hex = hex + a;

  return hex;
}

const { BackendAPIUrl } = window.config;
// Convert array to object
export function arrayToObject(array: any[]) {
  return array.reduce((result, item) => {
    result[item.key] = item.value;
    return result;
  }, {});
}
export const SettingsContextProvider: FC<Props> = ({ children }) => {
  const [industries, setIndustries] = useState<Industry[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);

  const [customer, setCustomer] = useState<Customer | undefined>(undefined);
  const [industry, setIndustry] = useState<Industry | undefined>(undefined);

  const [currentDemo, setCurrentDemo] = useState<any>();

  const navigate = useNavigate();
  const dispatch = useAppDispatch();

  const getIndustries = () => {
    axios
      .get(BackendAPIUrl + "/demo/GetIndustries")
      .then((res) => setIndustries(res.data))
      .catch((err) => console.log(err));
  };

  const getCustomers = ({
    industryId,
    userId,
  }: {
    userId?: number;
    industryId?: number;
  }) => {
    const formData: any = new FormData();
    formData.append("UserId", userId ?? 1);
    industryId && formData.append("IndustryId", industryId);

    axios
      .post(BackendAPIUrl + "/demo/GetCustomers", formData)
      .then((res) => setCustomers(res.data))
      .catch((err) => console.log(err));
  };

  const getCurrentDemoByGUID = (guid: string) => {
    axios
      .get(BackendAPIUrl + `/demo/GetCustomerDemo?guid=${guid}`)
      .then((res) => {
        const data = { ...res.data };
        data.demoMenus = data?.demoMenus?.map((iframe: DemoMenu) => {
          return {
            ...iframe,
            componentParameters: iframe?.componentParameters.length
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
        setCurrentDemo(data);
      })
      .catch((err) => console.log(err));
  };

  const getCurrentDemo = (customerId: number, reRoute: boolean) => {
    axios
      .get(BackendAPIUrl + `/demo/GetCustomerDemo?customerid=${customerId}`)
      .then((res) => {
        setCurrentDemo(res.data);
        // dispatch(logout());
        reRoute && navigate(`/${res.data.guid}/landing-page`);
      })
      .catch((err) => console.log(err));
  };

  const getDefaultDemo = () => {
    axios
      .get(BackendAPIUrl + "/demo/login?email=ssoni@microsoft.com")
      .then((res) => {
        setCurrentDemo(res.data);
        navigate(`/${res.data.guid}/login`);
      })
      .catch((err) => console.log(err));
  };

  useEffect(() => {
    if (!industry && industries.length && currentDemo?.industryId) {
      const i = industries.filter((i) => i.id === currentDemo.industryId)[0];
      // i.endPointURL = i.endPointURL.split("/chat")[0];
      setIndustry(i);
    }
    if (!customer && customers.length && currentDemo?.industryId) {
      setCustomer(customers.filter((i) => i.id === currentDemo.customerId)[0]);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentDemo, industries, customers]);

  // useEffect(() => {
  //   getIndustries();
  // }, []);

  useEffect(() => {
    industry && getCustomers({ industryId: industry?.id });
  }, [industry]);

  // useEffect(() => {
  //   document.body.style.setProperty(
  //     "--primary-color",
  //     `#${rgba2hex(currentDemo?.primaryColor ?? "rgba(0,0,0,.2)")}` ?? ""
  //   );
  //   document.body.style.setProperty(
  //     "--secondary-color",
  //     `#${rgba2hex(currentDemo?.secondaryColor ?? "rgba(0,0,0,.2)")}` ?? ""
  //   );
  //   document.body.style.setProperty(
  //     "--tab-text-color",
  //     `#${rgba2hex(currentDemo?.tabTextColor ?? "rgba(255, 255, 255, 1)")}` ??
  //       "rgba(255, 255, 255, 1)"
  //   );
  //   document.body.style.setProperty(
  //     "--navBar-primary-color",
  //     `#${rgba2hex(currentDemo?.navBarPrimaryColor ?? "rgba(0,0,0,.2)")}` ?? ""
  //   );
  //   document.body.style.setProperty(
  //     "--navBar-secondary-color",
  //     `#${rgba2hex(currentDemo?.navBarSecondaryColor ?? "rgba(0,0,0,.2)")}` ??
  //       ""
  //   );
  //   document.body.style.setProperty(
  //     "--tab-primary-color",
  //     `#${rgba2hex(currentDemo?.tabPrimaryColor ?? "rgba(0,0,0,.2)")}` ?? ""
  //   );
  //   document.body.style.setProperty(
  //     "--tab-secondary-color",
  //     `#${rgba2hex(currentDemo?.tabSecondaryColor ?? "rgba(0,0,0,.2)")}` ?? ""
  //   );
  //   document.body.style.setProperty(
  //     "--dropdown-primary-color",
  //     `#${rgba2hex(currentDemo?.dropdownPrimaryColor ?? "rgba(0,0,0,.2)")}` ??
  //       ""
  //   );
  //   document.body.style.setProperty(
  //     "--dropdown-secondary-color",
  //     `#${rgba2hex(currentDemo?.dropdownSecondaryColor ?? "rgba(0,0,0,.2)")}` ??
  //       ""
  //   );
  //   document.body.style.setProperty(
  //     "--tab-text-color",
  //     currentDemo?.tabTextColor || "rgba(255,255,255,1)"
  //   );
  //   document.body.style.setProperty(
  //     "--dropdown-text-color",
  //     currentDemo?.dropdownTextColor !== null
  //       ? currentDemo?.dropdownTextColor
  //       : "rgba(255,255,255,1)"
  //   );
  //   document.body.style.setProperty(
  //     "--navBar-text-color",
  //     currentDemo?.navBarTextColor !== "null"
  //       ? currentDemo?.navBarTextColor
  //       : "rgba(255,255,255,1)"
  //   );
  //   document.body.style.setProperty(
  //     "--header-image",
  //     `url(${currentDemo?.headerImageUrl})`
  //   );
  //   currentDemo?.loginTextBoxImage &&
  //     currentDemo?.loginTextBoxImage !== "null" &&
  //     document.body.style.setProperty(
  //       "--login-text-box-img",
  //       `url(${currentDemo?.loginTextBoxImage})`
  //     );
  //   document.body.style.setProperty(
  //     "--header-bg-color",
  //     currentDemo?.headerBgColor
  //   );
  //   document.body.style.setProperty(
  //     "--chat-container-bg-color",
  //     currentDemo?.chatContainerBackgroundColor
  //   );
  //   document.body.style.setProperty(
  //     "--scrollBar-primary-color",
  //     currentDemo?.scrollBarPrimaryColor
  //   );
  //   document.body.style.setProperty(
  //     "--scrollBar-secondary-color",
  //     currentDemo?.scrollBarSecondaryColor
  //   );
  // }, [currentDemo]);

  return (
    <SettingsContext.Provider
      value={{
        customers,
        getCustomersByIndustry: getCustomers,
        industries,
        customer,
        industry,
        setCustomer,
        setIndustry,
        setCurrentDemo,
        currentDemo,
        getDefaultDemo,
        getCurrentDemo,
        getCurrentDemoByGUID,
      }}
    >
      {children}
    </SettingsContext.Provider>
  );
};

interface ContextType {
  customers: Customer[];
  industries: Industry[];
  customer: Customer | undefined;
  industry: Industry | undefined;
  currentDemo: any;
  setCustomer: (customer: Customer) => void;
  setIndustry: (industry: Industry) => void;
  getCustomersByIndustry: (props: { industryId: number }) => void;
  setCurrentDemo: (demo: any) => void;
  getDefaultDemo: () => void;
  getCurrentDemo: (customerId: number, reRoute: boolean) => void;
  getCurrentDemoByGUID: (guid: string) => void;
}

export const SettingsContext = createContext<ContextType>({
  customers: [],
  getCustomersByIndustry: (props) => {},
  industries: [],
  currentDemo: {},
  customer: undefined,
  industry: undefined,
  setCustomer: (value) => {},
  setIndustry: (value) => {},
  setCurrentDemo: (demo) => {},
  getDefaultDemo: () => {},
  getCurrentDemo: (customerId, reRoute) => {},
  getCurrentDemoByGUID: (guid) => {},
});
