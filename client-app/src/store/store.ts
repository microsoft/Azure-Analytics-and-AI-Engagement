import { configureStore } from "@reduxjs/toolkit";
import loginSlice from "./slice/loginSlice";
import configSlice from "./slice/configSlice";

export const store = configureStore({
  reducer: {
    config: configSlice,
    login: loginSlice,
  },
});

// Infer the `RootState` and `AppDispatch` types from the store itself
export type RootState = ReturnType<typeof store.getState>;
// Inferred type: {posts: PostsState, comments: CommentsState, users: UsersState}
export type AppDispatch = typeof store.dispatch;
