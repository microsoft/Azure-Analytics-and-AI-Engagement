import { FC, useContext, useEffect, useState } from "react";
import {
  Form,
  Field,
  FormElement,
  FormRenderProps,
  FormSubmitClickEvent,
  FieldWrapper,
} from "@progress/kendo-react-form";
import { Button } from "@progress/kendo-react-buttons";
import { useLocation, useNavigate } from "react-router-dom";
import { Input, Popup } from "components";
import { useAppDispatch, useAppSelector } from "hooks";
import { login, setPageTitle } from "store";
import { SettingsContext } from "context";
import styles from "./styles.module.scss";
import { Checkbox } from "@progress/kendo-react-inputs";
import { Error, Label } from "@progress/kendo-react-labels";
import { Disclaimer } from "pages/Disclaimer";
import axios from "axios";
import { DemoMenu } from "types";

const {
  BackendAPIUrl,
  userName,
  demoMenus,
  loginBackground,
  loginBackgroundColor,
  loginBoxImage,
  preFillCredentials,
  password,
  loginTextBoxImage,
} = window.config;
export const Login: FC = () => {
  const dispatch = useAppDispatch();
  const loggedIn = useAppSelector((state) => state.login.loggedIn);
  const [username, setUsername] = useState("april@wideworldimporters.com");
  const [isError, setIsError] = useState(false);
  const [value, setValue] = useState(false);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (userName) setUsername(userName);
  }, []);

  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    if (loggedIn) {
      navigate(`/landing-page`);
    }
    dispatch(setPageTitle("Login"));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleSubmit = ({ values }: FormSubmitClickEvent) => {
    setIsError(false);
    if (!value) {
      return setIsError(true);
    }

    if (values.username === userName && values.password === password) {
      dispatch(login());

      const demos = (demoMenus as DemoMenu[])
        ?.map((demoMenu) => {
          if (demoMenu.demoSubMenus?.length) {
            return demoMenu.demoSubMenus.map((menuItem) => ({
              id: menuItem.id,
              url: menuItem.url?.split("/")?.[1]?.replaceAll("-", "_"),
              name: menuItem.name,
              externalArrows: menuItem.externalArrows,
            }));
          } else {
            return {
              id: demoMenu.id,
              url: demoMenu.url?.split("/")?.[1]?.replaceAll("-", "_"),
              name: demoMenu.name,
              externalArrows: demoMenu.externalArrows,
            };
          }
        })
        .flat();

      navigate(
        location.state?.from ||
          (demos?.length > 0 ? `/${demos[0].url}` : `/landing-page`),
        {
          replace: true,
        }
      );
    } else {
      setIsError(true);
    }
  };

  return (
    <>
      <div
        className={styles.loginWrapper}
        style={{
          backgroundImage: `url(${loginBackground})`,
          backgroundColor: loginBackgroundColor,
        }}
      >
        <div className={styles.loginFormContainer}>
          {/* <img src={loginBoxImage} alt="box" /> */}
          {/* <div className="formContainer"> */}{" "}
          <div className={styles.logoContainer}>
            <div>
              <img src="https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_login_box_logo_new.png" />
            </div>
          </div>
          <Form
            initialValues={{
              ...(preFillCredentials && {
                username: userName,
                password: password,
              }),
            }}
            key={username}
            onSubmitClick={handleSubmit}
            render={({ onSubmit }: FormRenderProps) => (
              <FormElement
                style={{
                  ...(!loginTextBoxImage
                    ? {
                        backgroundColor: "white",
                      }
                    : {
                        color: "white",
                      }),
                }}
              >
                <fieldset className="k-form-fieldset">
                  <Label className={styles.loginLabel}>
                    <Field
                      id="username"
                      name="username"
                      label="Username"
                      type="email"
                      placeholder="Username"
                      component={Input}
                    />
                  </Label>
                  <Label className={styles.passwordLabel}>
                    <Field
                      id="password"
                      name="password"
                      label="Password"
                      type="password"
                      placeholder="Password"
                      component={Input}
                    />

                    {isError && (
                      <FieldWrapper>
                        <Error style={{ color: "#ffc000" }}>
                          {!value
                            ? "Please accept the terms and conditions."
                            : "Invalid username or password. Please try again."}
                           
                        </Error>
                      </FieldWrapper>
                    )}
                    {}
                    {
                      <FieldWrapper
                        style={{
                          display: "flex",
                          gap: 8,
                          alignItems: "center",
                        }}
                      >
                        <Checkbox
                          className={styles.checkBox}
                          value={value}
                          onChange={(e: any) => {
                            setIsError(false);
                            setValue(e.value);
                          }}
                        />
                        <Label className={styles.loginLabel}>
                          I agree with the&nbsp;
                          <span
                            className={styles.tnc}
                            onClick={() => {
                              setVisible(true);
                            }}
                          >
                            terms and conditions.
                          </span>
                        </Label>
                      </FieldWrapper>
                    }

                    <div className="k-form-buttons">
                      <Button
                        className={styles.loginBtn}
                        type={"submit"}
                        onClick={onSubmit}
                      >
                        Login
                      </Button>
                    </div>
                  </Label>
                </fieldset>
              </FormElement>
            )}
          />
          <Popup
            showPopup={visible}
            onClose={() => {
              // setValue(true);
              setVisible(false);
            }}
            customClass="extraStyle"
            title="Disclaimer"
            customClassParent="extraStyleParent"
          >
            <Disclaimer setVisible={setVisible} setValue={setValue} />
          </Popup>
        </div>
      </div>
    </>
  );
};
