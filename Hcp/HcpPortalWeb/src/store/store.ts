import { configureStore } from '@reduxjs/toolkit';
import medicationReducer from './medicationSlice';
import cartReducer from './cartSlice';
import hcpPortalReducer from './hcpPortalSlice';

export const store = configureStore({
  reducer: {
    medications: medicationReducer,
    cart: cartReducer,
    hcpPortal: hcpPortalReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
