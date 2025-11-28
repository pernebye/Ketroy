import { createI18n } from 'vue-i18n';

import ru from '../i18n/ru.json';

const instance = createI18n({
  ssr: true,
  legacy: false,
  globalInjection: true,
  locale: 'ru',
  messages: {
    ru,
  },
});

export default instance;
export const i18n = instance.global;
