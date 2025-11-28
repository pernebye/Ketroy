<template>
  <section class="adds-page">
    <div class="adds-page__header">
      <tabs v-model="layoutStore.addsTab" :items="tabItems"/>
      <expand>
        <NuxtLink v-if="showAddButton && !showTable && !isGamification && !isGiftCatalog && hasRole('super-admin')" class="adds-page__add-btn"
                  :to="{ name: 'adds-tab@id', params: { tab: layoutStore.addsTab, id: 'new' } }">
          <btn text="Добавить" prepend-icon="mdi-plus"/>
        </NuxtLink>
      </expand>
    </div>
    <transition name="content-fade" mode="out-in">
      <!-- Геймификация - специальный интерфейс -->
      <GamificationSettings v-if="isGamification" :key="'gamification'" />
      
      <!-- Выдача подарков - специальный интерфейс -->
      <GiftIssuanceTable v-else-if="isGiftIssuance" :key="'giftIssuance'" />
      
      <!-- Каталог подарков - плиточный интерфейс -->
      <GiftCatalogGrid 
        v-else-if="isGiftCatalog" 
        :key="'giftCatalog'"
        :title="t('admin.adds.prizes')"
        :items="giftCatalogItems"
        :loading="listLoading"
        @refresh="loadGiftCatalog"
      />
      
      <!-- Акции - специальный интерфейс с карточками -->
      <PromotionsGrid 
        v-else-if="isPromotions"
        :key="'promotions'"
        :title="t('admin.adds.discounts')"
        :items="promotionItems"
        :loading="listLoading"
        @refresh="loadPromotions"
      />

      <!-- Стандартный список для других табов -->
      <div v-else :key="layoutStore.addsTab" class="adds-page__content" :class="{ 'adds-page__content--loading': listLoading }">
        <div v-if="showTable" class="adds-page__table-wrapper">
          <div class="adds-page__table-scroll">
            <v-data-table-server
                class="admin-table"
                :headers="headers"
                :items="items"
                :items-length="totalItems"
                :loading="loading"
                :items-per-page="itemsPerPage"
                :page.sync="page"
                :items-per-page-options="[5, 10, 20]"
                @update:options="loadItems"
                @click:row="onClickRow"

            >
              <template v-slot:item.prizes="{ item }">{{ (item.prizes || []).map((prize: any) => prize.title).join(', ') }}</template>
              <template v-slot:item.phone_number="{ item }">{{ item.phone_number }}</template>
              <template v-slot:item.actions="{ item }">
                <v-icon color="red" @click.stop="onDelete(item.id)">mdi-delete</v-icon>
              </template>
            </v-data-table-server>
          </div>
        </div>
        <a-list v-else :title="t(`admin.adds.${layoutStore.addsTab}`)" :list="list" :loading="listLoading" @delete="onDelete"/>
      </div>
    </transition>
  </section>
</template>

<script setup lang="ts">
import { AdminEnums } from '~/types/enums';
import { t } from '~/composables';
const { hasRole } = useAccess()

const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();
const tabItems: Types.Tab[] = Object.values(AdminEnums.AddsItems).map((i) => {
  return {title: () => t(`admin.adds.${i}`), value: i};
});
const list = ref<Types.List>([]);
const items = ref<any[]>([]);
const totalItems = ref(0);
const page = ref(1);
const loading = ref(false);
const listLoading = ref(true);

// Единый ключ для всех списков
const STORAGE_KEY = 'admin_perPage_global';
const perPageOptions = [5, 10, 20];

// Получаем сохранённое значение из localStorage
const getStoredPerPage = (): number => {
  if (typeof window === 'undefined') return 10;
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored) {
    const value = parseInt(stored, 10);
    if (perPageOptions.includes(value)) return value;
    // Преобразуем из AList: 4->5, 8->10, 12->10, 16->20, 20->20
    if (value <= 5) return 5;
    if (value <= 10) return 10;
    return 20;
  }
  return 10;
};

const itemsPerPage = ref(getStoredPerPage());
const showTable = computed(() => {
  return false; // Теперь каталог подарков отображается как список
});

const isGamification = computed(() => layoutStore.addsTab === 'gamification');
const isGiftIssuance = computed(() => layoutStore.addsTab === 'giftIssuance');
const isGiftCatalog = computed(() => layoutStore.addsTab === 'prizes');
const isPromotions = computed(() => layoutStore.addsTab === 'discounts');

// Данные каталога подарков
const giftCatalogItems = ref<Api.GiftCatalog.Self[]>([]);

// Данные акций
const promotionItems = ref<any[]>([]);

const showAddButton = computed(() => {
  if (layoutStore.addsTab === 'gamification') return false;
  if (layoutStore.addsTab === 'giftIssuance') return false;
  if (layoutStore.addsTab === 'prizes') return false; // Каталог подарков имеет свою кнопку добавления
  if (layoutStore.addsTab === 'discounts') return false; // Акции имеют свою кнопку добавления
  return true;
});

const search = ref('');

const filterOptions = ref([
  {key: "name", value: 'Имя пользователя'},
  {key: "city", value: 'Город'},
  {
    key: "phone",
    value: 'Номер телефона'
  }]);
const cities = ref<Api.City[]>([]);
const selectedFilter = ref('name');
const selectedCity = ref('');

const headers = computed(() => {
  switch (layoutStore.addsTab) {
    case 'prizes': {
      return [
        {title: 'ID', key: 'id'},
        {title: 'Имя пользователя', key: 'name'},
        {title: 'Номер телефона', key: 'phone'},
        {title: 'Город', key: 'city'},
        {title: 'Кол. подарков', key: 'gifts_count'},
      ] as const;
    }
    default:
      return [] as const;
  }
});
const loadItems = async (options?: { page: number; itemsPerPage: number }) => {
  loading.value = true;
  listLoading.value = true;

  if (options) {
    page.value = options.page;
    if (options.itemsPerPage !== itemsPerPage.value) {
      itemsPerPage.value = options.itemsPerPage;
      // Сохраняем в localStorage при изменении через таблицу
      if (typeof window !== 'undefined') {
        localStorage.setItem(STORAGE_KEY, String(options.itemsPerPage));
      }
    }
  }

  try {
    const currentApi = api[layoutStore.addsTab] as { getAll: () => Promise<any> };
    const response = await currentApi.getAll();

    // Обрабатываем ответ для списка
    if (response) {
      // Извлекаем массив данных из ответа
      let dataArray: any[] = [];
      
      if (layoutStore.addsTab === 'prizes') {
        // Для каталога подарков - пагинированный ответ с data
        if (response.data && Array.isArray(response.data)) {
          dataArray = response.data;
        } else if (Array.isArray(response)) {
          dataArray = response;
        }
      } else {
        // Для других типов
        dataArray = Array.isArray(response) ? response : (response.data || []);
      }
      
      list.value = dataArray.map((i: any) => ({
        id: i.id,
        title: i.title ?? i.name,
        name: 'adds-tab@id',
        description: i.description,
        // Приоритет: image_url (accessor из модели), затем image
        image: i.image_url || i.image || null,
        file_path: i.file_path || undefined
      }));
    }
  } catch (err) {
    console.error(err);
  } finally {
    loading.value = false;
    listLoading.value = false;
  }
};



const onClickRow = (event: any, row: any) => {
  router.push({name: 'prize-info-tab@id', params: {tab: String(route.query.tab), id: row.item?.id}});
};

const onDelete = async (id: number) => {
  try {
    const currentApi = api[layoutStore.addsTab] as { delete: (id: number) => Promise<any> };
    const response = await currentApi.delete(id);
    if (response.message) showToaster('success', String(response.message));
    await loadItems();
  } catch (err) {
    console.log(err);
  }
};

// Загрузка каталога подарков
const loadGiftCatalog = async () => {
  listLoading.value = true;
  try {
    const response = await api.prizes.getAll();
    if (response) {
      // Обрабатываем оба варианта: массив или пагинированный ответ
      if (Array.isArray(response)) {
        giftCatalogItems.value = response;
      } else if (response.data && Array.isArray(response.data)) {
        giftCatalogItems.value = response.data;
      }
    }
  } catch (err) {
    console.error('Error loading gift catalog:', err);
  } finally {
    listLoading.value = false;
  }
};

// Загрузка акций
const loadPromotions = async () => {
  listLoading.value = true;
  try {
    const response = await api.discounts.getAll();
    if (response) {
      if (Array.isArray(response)) {
        promotionItems.value = response;
      } else if (response.data && Array.isArray(response.data)) {
        promotionItems.value = response.data;
      }
    }
  } catch (err) {
    console.error('Error loading promotions:', err);
  } finally {
    listLoading.value = false;
  }
};

useHead({
  title: () => (layoutStore.addsTab ? `${t('admin.nav.adds')} - ${t(`admin.adds.${layoutStore.addsTab}`)}` : t('admin.nav.adds')),
});

onMounted(async () => {
  const citiesResponse = await api.cities.getAll();
  cities.value = Array.isArray(citiesResponse) ? citiesResponse : (citiesResponse?.data || []); // Replace with your API call

  const tab = String(route.query.tab) as AdminEnums.AddsItems;
  if (tab && tab in AdminEnums.AddsItems) {
    if (tab !== layoutStore.addsTab) {
      layoutStore.addsTab = tab;
      await router.replace({query: {tab: tab}});
    }
  } else {
    await router.replace({query: {tab: layoutStore.addsTab}});
  }
  // Разная логика загрузки для разных табов
  if (isGamification.value || isGiftIssuance.value) {
    // Геймификация и выдача - там своя логика
  } else if (isGiftCatalog.value) {
    await loadGiftCatalog();
  } else if (isPromotions.value) {
    await loadPromotions();
  } else {
    await loadItems();
  }
});

watch(
    () => layoutStore.addsTab,
    async (tab) => {
      if (tab && tab in AdminEnums.AddsItems) {
        router.replace({query: {tab: tab}});
        // Разная логика загрузки для разных табов
        if (tab === 'gamification' || tab === 'giftIssuance') {
          // Геймификация и выдача - там своя логика
        } else if (tab === 'prizes') {
          await loadGiftCatalog();
        } else if (tab === 'discounts') {
          await loadPromotions();
        } else {
          await loadItems();
        }
      }
    },
);
</script>
<style scoped>
.adds-page {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 600px) {
  .adds-page {
    gap: 1.25rem;
  }
}

@media (min-width: 960px) {
  .adds-page {
    gap: 1.5rem;
  }
}

.adds-page__header {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .adds-page__header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }
}

.adds-page__add-btn {
  align-self: flex-end;
  width: 100%;
}

@media (min-width: 600px) {
  .adds-page__add-btn {
    width: auto;
  }
}

.adds-page__filters {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  width: 100%;
}

@media (min-width: 600px) {
  .adds-page__filters {
    flex-direction: row;
    flex-wrap: wrap;
    align-items: center;
    gap: 1rem;
  }
}

.adds-page__search {
  width: 100%;
}

@media (min-width: 600px) {
  .adds-page__search {
    flex: 1;
    min-width: 180px;
    max-width: 300px;
  }
}

@media (min-width: 1280px) {
  .adds-page__search {
    max-width: 400px;
  }
}

.adds-page__filter-select {
  width: 100%;
}

@media (min-width: 600px) {
  .adds-page__filter-select {
    flex: 0 1 180px;
    min-width: 150px;
    width: auto;
  }
}

@media (min-width: 1280px) {
  .adds-page__filter-select {
    flex: 0 1 220px;
  }
}

.adds-page__city-select {
  width: 100%;
}

@media (min-width: 600px) {
  .adds-page__city-select {
    flex: 0 1 180px;
    min-width: 150px;
    width: auto;
  }
}

@media (min-width: 1280px) {
  .adds-page__city-select {
    flex: 0 1 220px;
  }
}

.adds-page__table-wrapper {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-secondary);
}

@media (min-width: 600px) {
  .adds-page__table-wrapper {
    gap: 1.25rem;
    padding: 1.25rem;
    border-radius: 1rem;
  }
}

@media (min-width: 960px) {
  .adds-page__table-wrapper {
    padding: 1.5rem;
  }
}

@media (min-width: 1280px) {
  .adds-page__table-wrapper {
    gap: 1.375rem;
    padding: 2rem;
    border-radius: 1.5rem;
  }
}

.adds-page__table-scroll {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-height: calc(100vh - 320px);
  min-height: 250px;
  overflow-x: auto;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

@media (min-width: 600px) {
  .adds-page__table-scroll {
    min-height: 300px;
    max-height: calc(100vh - 340px);
  }
}

@media (min-width: 960px) {
  .adds-page__table-scroll {
    min-height: 350px;
    max-height: calc(100vh - 350px);
  }
}

@media (min-width: 1280px) {
  .adds-page__table-scroll {
    min-height: 400px;
    max-height: calc(100vh - 300px);
  }
}

@media (min-width: 1920px) {
  .adds-page__table-scroll {
    max-height: calc(100vh - 280px);
  }
}

/* Стили для таблицы на мобильных */
:deep(.admin-table) {
  min-width: 600px;
}

@media (min-width: 960px) {
  :deep(.admin-table) {
    min-width: auto;
  }
}

.adds-page__content {
  transition: opacity 0.2s ease, filter 0.2s ease;
}

.adds-page__content--loading {
  opacity: 0.6;
  filter: blur(1px);
  pointer-events: none;
}

/* Анимация переключения вкладок */
.content-fade-enter-active,
.content-fade-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}

.content-fade-enter-from {
  opacity: 0;
  transform: translateY(10px);
}

.content-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
