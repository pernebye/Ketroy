<template>
  <v-app>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
    <ConfirmDialog />
  </v-app>
</template>

<script setup lang="ts">
import { i18n } from './configs';

const store = useStore();
const colorMode = useColorMode();

const init = () => {
  const auserCookie = useCookie<any>('auser');
  if (auserCookie.value) store.auser = auserCookie.value;
  
  // Инициализируем тему из localStorage
  if (import.meta.client) {
    const savedTheme = localStorage.getItem('nuxt-color-mode-preference');
    if (savedTheme && (savedTheme === 'dark' || savedTheme === 'light')) {
      colorMode.preference = savedTheme as 'dark' | 'light';
    }
    updateColorModeClass();
  }
};

// Синхронизация класса dark с HTML элементом
const updateColorModeClass = () => {
  if (import.meta.client) {
    const isDark = colorMode.value === 'dark';
    if (isDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }
};

// Синхронизация при изменении colorMode
watch(() => colorMode.value, updateColorModeClass, { immediate: true });

onMounted(() => {
  init();
});

useHead({
  titleTemplate: (title) => {
    return title ? `${title} | Ketroy Admin` : 'Ketroy Admin';
  },
  link: [
    {
      rel: 'stylesheet',
      href: 'https://cdn.jsdelivr.net/npm/@mdi/font@7.4.47/css/materialdesignicons.min.css',
    },
  ],
  meta: [
    {
      name: 'theme-color',
      content: '#34460C',
    },
  ],
  htmlAttrs: {
    lang: () => i18n.locale.value,
  },
});
useSeoMeta({
  title: 'Ketroy',
  description: 'Ketroy',
  ogTitle: 'Ketroy',
  ogDescription: 'Ketroy',
  ogImageAlt: 'Ketroy',
  ogLocale: 'ru_RU',
  ogLocaleAlternate: ['ru_RU'],
  twitterCard: 'summary_large_image',
  twitterDescription: 'Ketroy',
  author: 'TRDLN',
  creator: 'TRDLN',
});
</script>

<style>
/* ===== ШРИФТЫ ===== */
@font-face {
  font-family: 'Gilroy';
  src: url('~/assets/fonts/Gilroy-Regular.ttf') format('truetype');
  font-weight: 400;
}
@font-face {
  font-family: 'Gilroy';
  src: url('~/assets/fonts/Gilroy-Medium.ttf') format('truetype');
  font-weight: 500;
}
@font-face {
  font-family: 'Gilroy';
  src: url('~/assets/fonts/Gilroy-Semibold.ttf') format('truetype');
  font-weight: 600;
}
@font-face {
  font-family: 'Gilroy';
  src: url('~/assets/fonts/Gilroy-Bold.ttf') format('truetype');
  font-weight: 700;
}

/* ===== CSS ПЕРЕМЕННЫЕ ДЛЯ ТЕМ ===== */
:root {
  /* Светлая тема (по умолчанию) */
  --color-bg-primary: #F9F9FC;
  --color-bg-secondary: #FFFFFF;
  --color-bg-tertiary: #F4F7FE;
  --color-bg-card: #FFFFFF;
  --color-bg-input: #FFFFFF;
  --color-bg-hover: rgba(52, 70, 12, 0.05);
  
  --color-text-primary: #34460C;
  --color-text-secondary: #667085;
  --color-text-muted: #A3AED0;
  --color-text-inverse: #FFFFFF;
  
  --color-border: #e2e8f0;
  --color-border-light: #F4F7FE;
  --color-divider: rgba(0, 0, 0, 0.12);
  
  --color-accent: #34460C;
  --color-accent-light: #EBF3DA;
  --color-accent-secondary: #98B35D;
  
  --color-shadow: rgba(0, 0, 0, 0.08);
  --color-overlay: rgba(0, 0, 0, 0.5);
}

.dark {
  /* Тёмная тема */
  --color-bg-primary: #0a0a0a;
  --color-bg-secondary: #171717;
  --color-bg-tertiary: #262626;
  --color-bg-card: #1c1c1c;
  --color-bg-input: #262626;
  --color-bg-hover: rgba(255, 255, 255, 0.08);
  
  --color-text-primary: #FFFFFF;
  --color-text-secondary: #b3b3b3;
  --color-text-muted: #999999;
  --color-text-inverse: #171717;
  
  --color-border: #404040;
  --color-border-light: #333333;
  --color-divider: rgba(255, 255, 255, 0.12);
  
  --color-accent: #98B35D;
  --color-accent-light: rgba(152, 179, 93, 0.2);
  --color-accent-secondary: #EBF3DA;
  
  --color-shadow: rgba(0, 0, 0, 0.3);
  --color-overlay: rgba(0, 0, 0, 0.7);
}

/* ===== БАЗОВЫЕ СТИЛИ ===== */
* {
  font-family: 'Gilroy';
}

html {
  background-color: var(--color-bg-primary);
  transition: background-color 0.3s ease;
}

body {
  color: var(--color-text-primary);
  background-color: var(--color-bg-primary);
}

::-moz-selection {
  background: var(--color-accent-light) !important;
  color: var(--color-text-primary) !important;
}

::selection {
  background: var(--color-accent-light) !important;
  color: var(--color-text-primary) !important;
}

/* Скроллбар */
@supports (scrollbar-color: auto) {
  * {
    scrollbar-color: var(--color-accent) var(--color-bg-secondary);
    scrollbar-width: thin;
  }
}

@supports selector(::-webkit-scrollbar) {
  *::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }
  *::-webkit-scrollbar-track {
    background: var(--color-bg-secondary);
  }
  *::-webkit-scrollbar-thumb {
    background: var(--color-accent);
    border-radius: 4px;
  }
  *::-webkit-scrollbar-thumb:hover {
    background: var(--color-accent-secondary);
  }
}

/* ===== VUETIFY ГЛОБАЛЬНЫЕ ПЕРЕОПРЕДЕЛЕНИЯ ===== */

/* V-Application */
.v-application {
  background-color: var(--color-bg-primary) !important;
  color: var(--color-text-primary) !important;
}

/* Breadcrumbs */
.v-breadcrumbs {
  padding: 0 !important;
}
.v-breadcrumbs-item {
  font-weight: 500 !important;
  font-size: 14px !important;
  color: var(--color-text-secondary) !important;
}
.v-breadcrumbs-item--link {
  transition: color 0.2s ease !important;
}
.v-breadcrumbs-item--link:hover {
  color: var(--color-accent) !important;
}
.v-breadcrumbs-divider {
  color: var(--color-text-muted) !important;
}

/* Кнопки */
.v-btn {
  text-transform: none !important;
  letter-spacing: unset !important;
}
.v-btn--variant-text {
  color: var(--color-text-primary) !important;
}
.v-btn--variant-text:hover {
  background-color: var(--color-bg-hover) !important;
}

/* Карточки и Sheets */
.v-card,
.v-sheet {
  background-color: var(--color-bg-card) !important;
  color: var(--color-text-primary) !important;
  transition: background-color 0.3s ease, color 0.3s ease, box-shadow 0.3s ease !important;
}
.v-card--variant-elevated {
  box-shadow: 0 4px 6px -1px var(--color-shadow), 0 2px 4px -1px var(--color-shadow) !important;
}

/* Текстовые поля и инпуты */
.v-field {
  background-color: var(--color-bg-input) !important;
  transition: background-color 0.3s ease !important;
}
.v-field__input,
.v-field__field {
  color: var(--color-text-primary) !important;
}
.v-field--variant-outlined .v-field__outline {
  --v-field-border-opacity: 1;
  color: var(--color-border) !important;
}
.v-field--focused .v-field__outline {
  color: var(--color-accent) !important;
}
.v-label {
  color: var(--color-text-secondary) !important;
  opacity: 1 !important;
}
.v-field__clearable .v-icon,
.v-field__append-inner .v-icon,
.v-field__prepend-inner .v-icon {
  color: var(--color-text-muted) !important;
}
.v-text-field input::placeholder {
  color: var(--color-text-muted) !important;
  opacity: 1 !important;
}

/* Списки */
.v-list {
  background-color: var(--color-bg-card) !important;
  color: var(--color-text-primary) !important;
}
.v-list-item {
  color: var(--color-text-primary) !important;
}
.v-list-item-title {
  color: var(--color-text-primary) !important;
}
.v-list-item-subtitle {
  color: var(--color-text-secondary) !important;
}
.v-list-item:hover {
  background-color: var(--color-bg-hover) !important;
}
.v-list-item--active {
  background-color: var(--color-accent-light) !important;
}

/* Меню и Overlay */
.v-menu > .v-overlay__content {
  background-color: var(--color-bg-card) !important;
  border-radius: 8px !important;
  box-shadow: 0 10px 15px -3px var(--color-shadow), 0 4px 6px -2px var(--color-shadow) !important;
}
.v-overlay__scrim {
  background-color: var(--color-overlay) !important;
}

/* Таблицы */
.v-data-table {
  background-color: transparent !important;
  color: var(--color-text-primary) !important;
}
.v-data-table-header {
  background-color: transparent !important;
}
.v-data-table__th {
  color: var(--color-text-secondary) !important;
  background-color: transparent !important;
  border-bottom: 1px solid var(--color-border) !important;
  font-weight: 600 !important;
}
.v-data-table__td {
  color: var(--color-text-primary) !important;
  border-bottom: 1px solid var(--color-border-light) !important;
}
.v-data-table__tr:hover {
  background-color: var(--color-bg-hover) !important;
}
.v-data-table-footer {
  color: var(--color-text-secondary) !important;
  border-top: 1px solid var(--color-border) !important;
}
.v-data-table-footer__items-per-page {
  color: var(--color-text-secondary) !important;
}

/* Пагинация */
.v-pagination__item {
  color: var(--color-text-primary) !important;
}
.v-pagination__item .v-btn {
  color: var(--color-text-primary) !important;
  background-color: var(--color-bg-tertiary) !important;
}
.v-pagination__item--is-active .v-btn {
  background-color: var(--color-accent) !important;
  color: var(--color-text-inverse) !important;
}
.v-pagination__first .v-btn,
.v-pagination__prev .v-btn,
.v-pagination__next .v-btn,
.v-pagination__last .v-btn {
  color: var(--color-text-primary) !important;
}

/* Диалоги */
.v-dialog {
  background-color: transparent !important;
}
.v-dialog .v-card {
  background-color: var(--color-bg-card) !important;
  color: var(--color-text-primary) !important;
}
.v-dialog .v-card-title {
  color: var(--color-text-primary) !important;
}
.v-dialog .v-card-text {
  color: var(--color-text-secondary) !important;
}

/* Чекбоксы и Радио */
.v-checkbox .v-label,
.v-radio .v-label,
.v-switch .v-label {
  color: var(--color-text-primary) !important;
  opacity: 1 !important;
}
.v-checkbox .v-selection-control__input,
.v-radio .v-selection-control__input {
  color: var(--color-accent) !important;
}

/* Переключатели (Switch) - стили для светлой темы */
.v-switch .v-switch__track {
  background-color: rgba(120, 120, 128, 0.32) !important;
  opacity: 1 !important;
}
.v-switch .v-selection-control--dirty .v-switch__track {
  background-color: #34C759 !important;
}
.v-switch .v-switch__thumb {
  background-color: #FFFFFF !important;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2) !important;
}
.dark .v-switch .v-switch__track {
  background-color: rgba(120, 120, 128, 0.5) !important;
}
.dark .v-switch .v-selection-control--dirty .v-switch__track {
  background-color: #34C759 !important;
}
.dark .v-switch .v-switch__thumb {
  background-color: #FFFFFF !important;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3) !important;
}

/* Табы */
.v-tabs {
  background-color: transparent !important;
}
.v-tab {
  color: var(--color-text-secondary) !important;
}
.v-tab--selected {
  color: var(--color-accent) !important;
}
.v-tabs-slider {
  background-color: var(--color-accent) !important;
}

/* Селекты */
.v-select .v-field__input {
  color: var(--color-text-primary) !important;
}
.v-select .v-select__selection-text {
  color: var(--color-text-primary) !important;
}
.v-select-list {
  background-color: var(--color-bg-card) !important;
}

/* Иконки */
.v-icon {
  color: inherit;
}

/* Разделители */
.v-divider {
  border-color: var(--color-divider) !important;
}

/* Алерты */
.v-alert {
  color: var(--color-text-primary) !important;
}

/* Чипы */
.v-chip {
  background-color: var(--color-bg-tertiary) !important;
  color: var(--color-text-primary) !important;
}

/* Тултипы */
.v-tooltip > .v-overlay__content {
  background-color: var(--color-bg-tertiary) !important;
  color: var(--color-text-primary) !important;
}

/* OTP Input */
.v-otp-input {
  padding: 0 !important;
}
.v-otp-input__content {
  padding: 0 !important;
  gap: 16px !important;
  max-width: 380px !important;
}
.v-otp-input .v-field--variant-outlined .v-field__outline__start {
  flex: 1 !important;
}
.v-otp-input .v-field {
  border-radius: 15px !important;
}

/* ===== ПЛАВНЫЕ ПЕРЕХОДЫ ===== */
*,
*::before,
*::after {
  transition-property: background-color, border-color, color, fill, stroke;
  transition-duration: 0.15s;
  transition-timing-function: ease;
}

/* Исключаем анимации для производительности */
.v-enter-active,
.v-leave-active,
.v-move,
[class*="transition"],
[class*="animate"] {
  transition-property: all;
}
</style>
