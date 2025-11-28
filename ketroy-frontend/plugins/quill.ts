import { defineNuxtPlugin } from '#app';

export default defineNuxtPlugin(async (nuxtApp) => {
  if (import.meta.client) {
    const Quill = (await import('quill')).default;
    const ImageResize = (await import('quill-image-resize-module-ts')).default;

    if (Quill && ImageResize) {
      Quill.register('modules/imageResize', ImageResize);
      nuxtApp.vueApp.provide('quill', Quill);
    }
  }
});
