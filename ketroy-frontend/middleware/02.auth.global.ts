export default defineNuxtRouteMiddleware((to, from) => {
  const atoken = useStore().atoken ?? useCookie('atoken').value;
  if (to.meta.requiresAuth === true) {
    if (!atoken) return navigateTo({ name: 'auth' });
  } else {
    if (atoken && to.name === 'auth') return navigateTo({ name: 'index' });
  }
});
