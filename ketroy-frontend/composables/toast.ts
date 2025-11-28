import * as vt from 'vue-toastification';
import 'vue-toastification/dist/index.css';

export const Toast = vt;
export const ToastOptions = {
  position: 'top-center',
  timeout: 3000,
  closeOnClick: true,
  pauseOnFocusLoss: true,
  pauseOnHover: true,
  draggable: true,
  draggablePercent: 0.6,
};
