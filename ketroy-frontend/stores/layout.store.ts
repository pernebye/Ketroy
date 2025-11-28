import type { AdminEnums } from '~/types/enums';

export const useLayoutStore = defineStore('layout', () => {
  const navItem = ref<Types.Nav.AdmItem | null>(null);
  const contentTab = ref<keyof typeof AdminEnums.ContentItems>('news');
  const addsTab = ref<keyof typeof AdminEnums.AddsItems>('gamification');
  const gamificationTab = ref<string>('levels'); // Для будущих подтабов геймификации
  const usersTab = ref<keyof typeof AdminEnums.UsersItems>('users');
  const categoriesTab = ref<keyof typeof AdminEnums.CategoryItems>('categories');
  const actualsTab = ref<keyof typeof AdminEnums.ActualItems>('actuals');

  return {
    navItem,
    addsTab,
    contentTab,
    usersTab,
    categoriesTab,
    actualsTab,
    gamificationTab,
  };
});
