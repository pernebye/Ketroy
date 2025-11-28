const colors = require('tailwindcss/colors');

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class', // Темная тема через класс, а не системные настройки
  prefix: 'tw-',
  important: true,
  theme: {
    extend: {
      colors: {
        primary: {
          light: '#EBF3DA',
          DEFAULT: '#34460C',
          dark: '#34460C2e',
        },
        typo: {
          smoke: '#A3AED0',
          light: '#98B35D',
          DEFAULT: '#34460C',
          dark: '#1D1F2C',
        },
        grey: {
          light: '#F9F9FC',
          DEFAULT: '#e2e8f0',
          semidark: '#667085',
          dark: '#858D9D',
        },
      },
    },
    screens: {
      sm: { min: '600px' },
      md: { min: '960px' },
      lg: { min: '1280px' },
      xl: { min: '1920px' },
    },
  },
};
