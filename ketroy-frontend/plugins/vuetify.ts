import 'vuetify/styles';
import { createVuetify, useDisplay, type ThemeDefinition } from 'vuetify';

// Кастомная светлая тема
const lightTheme: ThemeDefinition = {
  dark: false,
  colors: {
    background: '#F9F9FC',
    surface: '#FFFFFF',
    primary: '#34460C',
    'primary-darken-1': '#1D1F2C',
    secondary: '#98B35D',
    'secondary-darken-1': '#EBF3DA',
    error: '#ef4444',
    info: '#3b82f6',
    success: '#22c55e',
    warning: '#f59e0b',
    'on-background': '#34460C',
    'on-surface': '#34460C',
  },
};

// Кастомная тёмная тема
const darkTheme: ThemeDefinition = {
  dark: true,
  colors: {
    background: '#171717', // neutral-900
    surface: '#262626', // neutral-800
    primary: '#98B35D',
    'primary-darken-1': '#EBF3DA',
    secondary: '#34460C',
    'secondary-darken-1': '#1D1F2C',
    error: '#ef4444',
    info: '#3b82f6',
    success: '#22c55e',
    warning: '#f59e0b',
    'on-background': '#FFFFFF',
    'on-surface': '#FFFFFF',
  },
};

export default defineNuxtPlugin((nuxtApp) => {
  const colorMode = useColorMode();

  const vuetify = createVuetify({
    theme: {
      defaultTheme: colorMode.value === 'dark' ? 'dark' : 'light',
      themes: {
        light: lightTheme,
        dark: darkTheme,
      },
    },
  });

  nuxtApp.vueApp.use(vuetify);

  // Синхронизация темы Vuetify с Nuxt Color Mode
  watch(
    () => colorMode.value,
    (newMode) => {
      vuetify.theme.global.name.value = newMode === 'dark' ? 'dark' : 'light';
    },
    { immediate: true }
  );

  return {
    provide: {
      display: useDisplay,
    },
  };
});
