import React from "react";
export const MicContext = React.createContext<any>({
  record: false,
  token: "",
});

export const MicContextProvider = (props: any) => {
  const [state, setState] = React.useState({
    record: false,
    token: "",
  });
  const toggleRecord = () => setState({ ...state, record: !state.record });
  return (
    <MicContext.Provider value={{ ...state, toggleRecord }}>
      {props.children}
    </MicContext.Provider>
  );
};
