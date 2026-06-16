import { createSlice } from "@reduxjs/toolkit";

interface LoginState {
  loggedIn: boolean;
  componentHistory: string[];
}

const initialState: LoginState = {
  loggedIn: localStorage.getItem("LoggedIn") ? true : false,
  componentHistory: [],
};

const loginSlice = createSlice({
  name: "login",
  initialState,
  reducers: {
    login: (state: LoginState) => {
      state.loggedIn = true;
      localStorage.setItem("LoggedIn", "true");
    },
    logout: (state: LoginState) => {
      state.loggedIn = false;
      localStorage.removeItem("LoggedIn");
    },
  },
});

export const { login, logout } = loginSlice.actions;
export default loginSlice.reducer;
