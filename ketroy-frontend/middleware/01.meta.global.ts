import { noAuthPages } from '../configs';

export default defineNuxtRouteMiddleware((to) => {
  if (noAuthPages.includes(String(to.name)) === false) to.meta.requiresAuth = true;
});
