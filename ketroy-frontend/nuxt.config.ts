import path from 'path';
import vuetify from 'vite-plugin-vuetify';
import VueI18nVitePlugin from '@intlify/unplugin-vue-i18n';

export default defineNuxtConfig({
  compatibilityDate: '2024-07-20',

  ssr: false,
  devtools: { 
    enabled: true,
    timeline: {
      enabled: false, // Отключаем timeline - основная причина лагов
    },
  },
  imports: { dirs: ['./types/enums'] },
  nitro: { compressPublicAssets: true },
  experimental: { viewTransition: true },
  future: { typescriptBundlerResolution: false },
  router: { options: { scrollBehaviorType: 'smooth' } },
  components: [{ path: './components', pathPrefix: false }],
  build: { transpile: ['vuetify', 'vue-i18n', 'jwt-decode'] },

  colorMode: {
    preference: 'light', // Светлая тема по умолчанию
    fallback: 'light',
    classSuffix: '',
  },

  modules: [
    '@nuxt/icon',
    '@pinia/nuxt',
    '@vueuse/nuxt',
    '@nuxtjs/color-mode',
    '@nuxtjs/tailwindcss',
    (_options, nuxt) => {
      nuxt.hooks.hook('vite:extendConfig', (config) => {
        // @ts-expect-error
        config.plugins.push(vuetify({ autoImport: true }));
      });
    },
  ],
  vite: {
    plugins: [
      VueI18nVitePlugin.vite({
        include: [path.resolve(__dirname, './i18n/**')],
      }),
    ],
    optimizeDeps: {
      exclude: ['html2canvas'],
    },
    build: {
      rollupOptions: {
        external: [/^\/libs\//],
      },
    },
  },
});