import Maska from 'maska';
import i18n from '~/configs/i18n';
import { Toast } from '~/composables/toast';

export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.vueApp.use(Maska);
  nuxtApp.vueApp.use(i18n);
  nuxtApp.vueApp.use(Toast.default, {
    transition: 'Vue-Toastification__fade',
    maxToasts: 5,
    newestOnTop: true,
  });

  return {
    provide: {
      rules: rules,
      masks: masks,
    },
  };
});
