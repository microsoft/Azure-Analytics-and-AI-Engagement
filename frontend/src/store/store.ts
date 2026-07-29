import { configureStore } from '@reduxjs/toolkit';
import medicationReducer from './medicationSlice';
import cartReducer from './cartSlice';

export const store = configureStore({
  reducer: {
    medications: medicationReducer,
    cart: cartReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
