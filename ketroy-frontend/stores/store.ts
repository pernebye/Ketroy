export const useStore = defineStore('store', () => {
  const atoken = ref<string>();
  const auser = ref<Api.User.Self | null>(null);

  return {
    auser,
    atoken,
  };
});
