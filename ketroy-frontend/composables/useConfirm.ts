import { ref, reactive } from 'vue';

export interface ConfirmOptions {
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: 'danger' | 'warning' | 'info';
  showCancel?: boolean;
}

interface ConfirmState {
  isOpen: boolean;
  title: string;
  message: string;
  confirmText: string;
  cancelText: string;
  type: 'danger' | 'warning' | 'info';
  showCancel: boolean;
  resolve: ((value: boolean) => void) | null;
}

const state = reactive<ConfirmState>({
  isOpen: false,
  title: '',
  message: '',
  confirmText: 'Да',
  cancelText: 'Отмена',
  type: 'danger',
  showCancel: true,
  resolve: null,
});

export const useConfirm = () => {
  const confirm = (options: ConfirmOptions): Promise<boolean> => {
    return new Promise((resolve) => {
      state.isOpen = true;
      state.title = options.title || 'Подтвердите действие';
      state.message = options.message;
      state.confirmText = options.confirmText || 'Да';
      state.cancelText = options.cancelText || 'Отмена';
      state.type = options.type || 'danger';
      state.showCancel = options.showCancel !== false;
      state.resolve = resolve;
    });
  };

  const alert = (options: Omit<ConfirmOptions, 'showCancel'>): Promise<boolean> => {
    return confirm({
      ...options,
      showCancel: false,
      confirmText: options.confirmText || 'OK',
      type: options.type || 'info',
    });
  };

  const handleConfirm = () => {
    if (state.resolve) {
      state.resolve(true);
    }
    close();
  };

  const handleCancel = () => {
    if (state.resolve) {
      state.resolve(false);
    }
    close();
  };

  const close = () => {
    state.isOpen = false;
    state.resolve = null;
  };

  return {
    state,
    confirm,
    alert,
    handleConfirm,
    handleCancel,
  };
};






