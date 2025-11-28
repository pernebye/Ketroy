export default defineNuxtPlugin(() => {
  const store = useStore();
  const layoutStore = useLayoutStore();
  return {
    provide: {
      store: store,
      layoutStore: layoutStore,
    },
  };
});
