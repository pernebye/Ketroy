<template>
  <section class="users-page">
    <div class="users-page__header" v-if="hasRole('super-admin')">
      <tabs v-model="layoutStore.usersTab" :items="tabItems"/>
      <btn text="Добавить" prepend-icon="mdi-plus" @click="openCreateAdminDialog" class="users-page__add-btn" />
    </div>
    
    <div class="users-page__filters">
      <v-text-field 
        v-model="search" 
        placeholder="Поиск по имени, телефону или городу" 
        prepend-inner-icon="mdi-magnify" 
        dense 
        hide-details
        variant="solo" 
        @input="loadItems"
        class="users-page__search users-page__search--wide"
        clearable
      />
    </div>

    <div class="users-page__table-wrapper">
      <div class="users-page__table-scroll">
        <v-data-table-server
          class="admin-table"
          :headers="headers"
          :items="items"
          :items-length="totalItems"
          :loading="loading"
          :items-per-page="itemsPerPage"
          :page.sync="page"
          :items-per-page-options="[5, 10, 20, 50]"
          v-model:sort-by="sortBy"
          @update:options="loadItems"
          @click:row="onClickRow"
          :row-props="getRowProps"
        >
          <template v-slot:item.name="{ item }">{{ getFullName(item) }}</template>
          <template v-slot:item.prizes="{ item }">{{ item.prizes.map(prize => prize.title).join(', ') }}</template>
          <template v-slot:item.phone_number="{ item }">{{ formatPhone(item.phone_number, 'front') }}</template>
          <template v-slot:item.actions="{ item }">
            <v-icon v-if="hasDelete" color="red" @click.stop="onDelete(item)">mdi-delete</v-icon>
          </template>
          <template v-slot:item.role="{ item }">{{
            item.role === 'super-admin' ? "Супер админ" : "Маркетолог"
          }}</template>
        </v-data-table-server>
      </div>
    </div>

    <!-- Context Menu Activator (invisible element positioned at click) -->
    <div 
      ref="contextMenuActivator"
      class="users-page__context-activator"
      :style="{ left: contextMenuX + 'px', top: contextMenuY + 'px' }"
    ></div>
    
    <!-- Context Menu -->
    <v-menu
      v-model="showContextMenu"
      :activator="contextMenuActivator"
      location="bottom start"
      :close-on-content-click="false"
    >
      <v-list density="compact" class="users-page__context-menu">
        <v-list-item @click.stop="goToProfile" prepend-icon="mdi-account">
          <v-list-item-title>Открыть профиль</v-list-item-title>
        </v-list-item>
        <v-divider />
        <v-list-item @click.stop="openBonusDialog" prepend-icon="mdi-star-plus" class="users-page__context-item--warning">
          <v-list-item-title>Начислить бонусы</v-list-item-title>
        </v-list-item>
        <v-list-item @click.stop="openDiscountDialog" prepend-icon="mdi-percent" class="users-page__context-item--info">
          <v-list-item-title>Изменить скидку</v-list-item-title>
        </v-list-item>
        <v-list-item @click.stop="openGiftDialog" prepend-icon="mdi-gift" class="users-page__context-item--secondary">
          <v-list-item-title>Отправить подарок</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-menu>

    <!-- Dialog: Управление бонусами -->
    <v-dialog v-model="showBonusDialog" max-width="450" persistent>
      <v-card rounded="xl" class="users-page__dialog">
        <v-card-title class="users-page__dialog-title">
          <Icon name="mdi:star-circle" />
          Управление бонусами
          <span class="users-page__dialog-subtitle">{{ selectedUser?.name }}</span>
        </v-card-title>
        <v-card-text>
          <v-radio-group v-model="bonusAction" inline>
            <v-radio label="Начислить" value="add" color="success" />
            <v-radio label="Списать" value="deduct" color="error" />
          </v-radio-group>
          <v-text-field
            v-model.number="bonusAmount"
            type="number"
            label="Сумма бонусов"
            variant="outlined"
            density="compact"
            :min="1"
            rounded="lg"
          />
          <v-text-field
            v-model="bonusComment"
            label="Комментарий"
            variant="outlined"
            density="compact"
            rounded="lg"
          />
          
          <!-- Переключатель отсрочки в стиле iOS (только для начисления) -->
          <div class="users-page__delay-toggle" :class="{ 'users-page__delay-toggle--disabled': bonusAction === 'deduct' }">
            <div class="users-page__delay-info">
              <span class="users-page__delay-label">Отсрочка начисления</span>
              <span class="users-page__delay-hint">
                {{ bonusAction === 'deduct' ? 'Не применяется при списании' : (bonusWithDelay ? 'Бонусы будут доступны через 14 дней' : 'Бонусы доступны сразу') }}
              </span>
            </div>
            <label class="ios-toggle" :class="{ 'ios-toggle--disabled': bonusAction === 'deduct' }">
              <input type="checkbox" v-model="bonusWithDelay" :disabled="bonusAction === 'deduct'" />
              <span class="ios-toggle__slider"></span>
            </label>
          </div>
        </v-card-text>
        <v-card-actions class="users-page__dialog-actions">
          <v-btn variant="text" @click="showBonusDialog = false">Отмена</v-btn>
          <v-btn 
            :color="bonusAction === 'add' ? 'success' : 'error'" 
            variant="flat"
            :loading="actionLoading"
            :disabled="actionLoading"
            @click="handleBonusAction"
          >
            {{ bonusAction === 'add' ? 'Начислить' : 'Списать' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog: Изменение скидки -->
    <v-dialog v-model="showDiscountDialog" max-width="450" persistent>
      <v-card rounded="xl" class="users-page__dialog">
        <v-card-title class="users-page__dialog-title">
          <Icon name="mdi:percent-circle" />
          Изменить скидку
          <span class="users-page__dialog-subtitle">{{ selectedUser?.name }}</span>
        </v-card-title>
        <v-card-text>
          <p class="tw-text-sm tw-text-grey-dark tw-mb-3">Выберите тип дисконтной карты:</p>
          <v-select
            v-model="newDiscount"
            :items="discountOptions"
            item-value="value"
            item-title="title"
            variant="outlined"
            density="comfortable"
            rounded="lg"
            hide-details
          />
        </v-card-text>
        <v-card-actions class="users-page__dialog-actions">
          <v-btn variant="text" @click="showDiscountDialog = false">Отмена</v-btn>
          <v-btn color="primary" variant="flat" :loading="actionLoading" :disabled="actionLoading" @click="handleDiscountChange">
            Сохранить
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog: Отправка подарков -->
    <v-dialog v-model="showGiftDialog" max-width="550" persistent>
      <v-card rounded="xl" class="users-page__dialog">
        <v-card-title class="users-page__dialog-title">
          <Icon name="mdi:gift" />
          Отправить подарки
          <span class="users-page__dialog-subtitle">{{ selectedUser?.name }}</span>
        </v-card-title>
        <v-card-text>
          <div v-if="giftCatalogLoading" class="users-page__dialog-loading">
            <v-progress-circular indeterminate :size="24" />
            <span>Загрузка каталога...</span>
          </div>
          <div v-else-if="giftCatalog.length === 0" class="users-page__dialog-empty">
            <Icon name="mdi:gift-off-outline" />
            <span>В каталоге пока нет подарков</span>
          </div>
          <template v-else>
            <div class="users-page__gift-hint">
              <Icon name="mdi:information-outline" />
              <span>Выберите от 1 до 4 подарков. Пользователь получит один из них случайным образом при активации в магазине.</span>
            </div>
            <div class="users-page__gift-counter">
              <span :class="{ 'users-page__gift-counter--max': selectedGiftIds.length >= 4 }">
                Выбрано: {{ selectedGiftIds.length }} / 4
              </span>
            </div>
            <div class="users-page__gift-grid">
              <div 
                v-for="gift in giftCatalog" 
                :key="gift.id"
                class="users-page__gift-item"
                :class="{ 
                  'users-page__gift-item--selected': selectedGiftIds.includes(gift.id),
                  'users-page__gift-item--disabled': !selectedGiftIds.includes(gift.id) && selectedGiftIds.length >= 4
                }"
                @click="toggleGiftSelection(gift.id)"
              >
                <img v-if="gift.image_url" :src="gift.image_url" :alt="gift.name" class="users-page__gift-image" />
                <div v-else class="users-page__gift-placeholder"><Icon name="mdi:gift" /></div>
                <span class="users-page__gift-name">{{ gift.name }}</span>
                <div v-if="selectedGiftIds.includes(gift.id)" class="users-page__gift-check">
                  <Icon name="mdi:check-circle" />
                  <span class="users-page__gift-number">{{ selectedGiftIds.indexOf(gift.id) + 1 }}</span>
                </div>
              </div>
            </div>
          </template>
        </v-card-text>
        <v-card-actions class="users-page__dialog-actions">
          <v-btn variant="text" @click="showGiftDialog = false">Отмена</v-btn>
          <v-btn color="secondary" variant="flat" :loading="actionLoading" :disabled="selectedGiftIds.length === 0 || actionLoading" @click="handleSendGift">
            Отправить {{ selectedGiftIds.length > 0 ? `(${selectedGiftIds.length})` : '' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog: Создание администратора -->
    <v-dialog v-model="showCreateAdminDialog" max-width="520" persistent>
      <v-card rounded="xl" class="users-page__create-dialog">
        <!-- Header -->
        <div class="users-page__create-header">
          <div class="users-page__create-header-content">
            <div class="users-page__create-icon-wrapper">
              <Icon name="mdi:account-plus" class="users-page__create-icon" />
            </div>
            <div class="users-page__create-header-text">
              <h2 class="users-page__create-title">Новый администратор</h2>
              <p class="users-page__create-subtitle">Заполните данные для создания</p>
            </div>
          </div>
          <v-btn icon variant="text" size="small" @click="closeCreateAdminDialog" class="users-page__create-close">
            <Icon name="mdi:close" />
          </v-btn>
        </div>

        <!-- Form -->
        <v-form ref="createAdminForm" @submit.prevent="handleCreateAdmin">
          <v-card-text class="users-page__create-body">
            <div class="users-page__create-form">
              <!-- Имя и фамилия в одну строку -->
              <div class="users-page__create-row">
                <div class="users-page__create-field">
                  <label class="users-page__create-label">
                    <Icon name="mdi:account" />
                    Имя
                  </label>
                  <v-text-field
                    v-model.trim="newAdmin.name"
                    density="compact"
                    variant="outlined"
                    placeholder="Введите имя"
                    rounded="lg"
                    hide-details="auto"
                    :rules="[v => !!v || 'Обязательное поле']"
                  />
                </div>
                <div class="users-page__create-field">
                  <label class="users-page__create-label">
                    <Icon name="mdi:account-outline" />
                    Фамилия
                  </label>
                  <v-text-field
                    v-model.trim="newAdmin.surname"
                    density="compact"
                    variant="outlined"
                    placeholder="Введите фамилию"
                    rounded="lg"
                    hide-details="auto"
                    :rules="[v => !!v || 'Обязательное поле']"
                  />
                </div>
              </div>

              <!-- Email -->
              <div class="users-page__create-field">
                <label class="users-page__create-label">
                  <Icon name="mdi:email" />
                  Email
                </label>
                <v-text-field
                  v-model.trim="newAdmin.email"
                  density="compact"
                  variant="outlined"
                  type="email"
                  placeholder="admin@example.com"
                  rounded="lg"
                  hide-details="auto"
                  :rules="[
                    v => !!v || 'Обязательное поле',
                    v => /.+@.+\..+/.test(v) || 'Некорректный email'
                  ]"
                />
              </div>

              <!-- Роль -->
              <div class="users-page__create-field">
                <label class="users-page__create-label">
                  <Icon name="mdi:shield-account" />
                  Роль
                </label>
                <v-select
                  v-model="newAdmin.role"
                  :items="adminRoleOptions"
                  item-value="key"
                  item-title="value"
                  density="compact"
                  variant="outlined"
                  placeholder="Выберите роль"
                  rounded="lg"
                  hide-details="auto"
                  :rules="[v => !!v || 'Выберите роль']"
                >
                  <template v-slot:item="{ props, item }">
                    <v-list-item v-bind="props">
                      <template v-slot:prepend>
                        <Icon :name="item.raw.key === 'super-admin' ? 'mdi:crown' : 'mdi:account-tie'" class="users-page__create-role-icon" />
                      </template>
                    </v-list-item>
                  </template>
                </v-select>
              </div>

              <!-- Пароли -->
              <div class="users-page__create-row">
                <div class="users-page__create-field">
                  <label class="users-page__create-label">
                    <Icon name="mdi:lock" />
                    Пароль
                  </label>
                  <v-text-field
                    v-model.trim="newAdmin.password"
                    density="compact"
                    variant="outlined"
                    :type="showPassword ? 'text' : 'password'"
                    placeholder="Мин. 8 символов"
                    rounded="lg"
                    hide-details="auto"
                    :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
                    @click:append-inner="showPassword = !showPassword"
                    :rules="[
                      v => !!v || 'Обязательное поле',
                      v => v.length >= 8 || 'Минимум 8 символов'
                    ]"
                  />
                </div>
                <div class="users-page__create-field">
                  <label class="users-page__create-label">
                    <Icon name="mdi:lock-check" />
                    Подтверждение
                  </label>
                  <v-text-field
                    v-model.trim="newAdmin.password_confirmation"
                    density="compact"
                    variant="outlined"
                    :type="showPassword ? 'text' : 'password'"
                    placeholder="Повторите пароль"
                    rounded="lg"
                    hide-details="auto"
                    :rules="[
                      v => !!v || 'Обязательное поле',
                      v => v === newAdmin.password || 'Пароли не совпадают'
                    ]"
                  />
                </div>
              </div>
            </div>
          </v-card-text>

          <!-- Actions -->
          <v-card-actions class="users-page__create-actions">
            <v-btn variant="text" @click="closeCreateAdminDialog" :disabled="createAdminLoading">
              Отмена
            </v-btn>
            <v-btn 
              type="submit"
              color="primary" 
              variant="flat"
              rounded="lg"
              :loading="createAdminLoading"
              :disabled="createAdminLoading"
              class="users-page__create-submit"
            >
              <Icon name="mdi:check" class="mr-1" />
              Создать администратора
            </v-btn>
          </v-card-actions>
        </v-form>
      </v-card>
    </v-dialog>
  </section>
</template>

<script setup lang="ts">
import {AdminEnums} from '~/types/enums';

const {hasRole} = useAccess()
const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();
const tabItems: Types.Tab[] = Object.values(AdminEnums.UsersItems).map((i) => {
  return {title: () => t(`admin.users.${i}`), value: i};
});
const items = ref([]);
const totalItems = ref(0);
const page = ref(1);
const search = ref('');
const loading = ref(false);
const list = ref<Api.User.Self[]>([]);

// Единый ключ для всех списков
const STORAGE_KEY = 'admin_perPage_global';
const perPageOptions = [5, 10, 20, 50];

// Получаем сохранённое значение из localStorage
const getStoredPerPage = (): number => {
  if (typeof window === 'undefined') return 10;
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored) {
    const value = parseInt(stored, 10);
    // Для таблиц используем ближайшее значение из perPageOptions
    if (perPageOptions.includes(value)) return value;
    // Если значение из AList, преобразуем: 4->5, 8->10, 12->10, 16->20, 20->20
    if (value <= 5) return 5;
    if (value <= 10) return 10;
    if (value <= 20) return 20;
    return 50;
  }
  return 10;
};

const itemsPerPage = ref(getStoredPerPage());

// Слушаем изменения в localStorage от других компонентов  
const handleStorageChange = (e: StorageEvent) => {
  if (e.key === STORAGE_KEY && e.newValue) {
    const value = parseInt(e.newValue, 10);
    let newPerPage = 10;
    if (perPageOptions.includes(value)) {
      newPerPage = value;
    } else if (value <= 5) {
      newPerPage = 5;
    } else if (value <= 10) {
      newPerPage = 10;
    } else if (value <= 20) {
      newPerPage = 20;
    } else {
      newPerPage = 50;
    }
    if (itemsPerPage.value !== newPerPage) {
      itemsPerPage.value = newPerPage;
      page.value = 1;
      loadItems();
    }
  }
};

// Context menu state
const showContextMenu = ref(false);
const contextMenuX = ref(0);
const contextMenuY = ref(0);
const selectedUser = ref<any>(null);
const contextMenuActivator = ref<HTMLElement | null>(null);

// Dialogs
const showBonusDialog = ref(false);
const showDiscountDialog = ref(false);
const showGiftDialog = ref(false);
const actionLoading = ref(false);

// Bonus management
const bonusAction = ref<'add' | 'deduct'>('add');
const bonusAmount = ref(100);
const bonusComment = ref('');
const bonusWithDelay = ref(true); // true = 14 дней, false = сразу

// Discount management - предопределённые скидки из 1С
const discountOptions = [
  { value: 0, title: 'Без скидки (0%)' },
  { value: 5, title: 'Дисконтная карта 5%' },
  { value: 10, title: 'Дисконтная карта 10%' },
  { value: 15, title: 'Дисконтная карта 15%' },
  { value: 20, title: 'Дисконтная карта 20%' },
  { value: 25, title: 'Дисконтная карта 25%' },
  { value: 30, title: 'Дисконтная карта 30%' },
  { value: 50, title: 'Корпоративный клиент 50%' },
  { value: 70, title: 'VIP карта 70%' },
];
const newDiscount = ref(0);

// Gift management
const giftCatalog = ref<Api.GiftCatalog.Self[]>([]);
const giftCatalogLoading = ref(false);
const selectedGiftIds = ref<number[]>([]);

// Create admin dialog
const showCreateAdminDialog = ref(false);
const createAdminLoading = ref(false);
const createAdminForm = ref<any>(null);
const showPassword = ref(false);
const newAdmin = ref({
  name: '',
  surname: '',
  email: '',
  role: '',
  password: '',
  password_confirmation: ''
});
const adminRoleOptions = [
  { key: 'super-admin', value: 'Супер-админ' },
  { key: 'marketer', value: 'Маркетолог' }
];

// Функция для переключения выбора подарка
const toggleGiftSelection = (giftId: number) => {
  const index = selectedGiftIds.value.indexOf(giftId);
  if (index > -1) {
    // Убираем из выбора
    selectedGiftIds.value.splice(index, 1);
  } else if (selectedGiftIds.value.length < 4) {
    // Добавляем в выбор (максимум 4)
    selectedGiftIds.value.push(giftId);
  }
};

// Функция для получения полного имени (имя + фамилия)
const getFullName = (item: any) => {
  const name = item.name || '';
  const surname = item.surname || '';
  return surname ? `${surname} ${name}`.trim() : name;
};
// Параметры сортировки
const sortBy = ref<{ key: string; order: 'asc' | 'desc' }[]>([]);

const headers = computed((): Types.TableHeader<Api.User.Self>[] => {
  switch (layoutStore.usersTab) {
    case 'users': {
      return [
        {title: 'ID', key: 'id', sortable: true},
        {title: 'Имя пользователя', key: 'name', sortable: true},
        {title: 'Номер телефона', key: 'phone', sortable: true},
        {title: 'Город', key: 'city', sortable: true},
        {title: 'Рост', key: 'height', sortable: true},
        {title: 'Раз. обуви', key: 'shoe_size', sortable: true},
        {title: 'Раз. одежды', key: 'clothing_size', sortable: true},
        {title: 'Подарки', key: 'gifts_count', sortable: true},
      ];
    }
    case 'admins': {
      return [
        {title: 'ID', key: 'id', sortable: true},
        {title: 'Имя пользователя', key: 'name', sortable: true},
        {title: 'Роль', key: 'role', sortable: true},
      ];
    }
    default:
      return [];
  }
});

const loadItems = async (options?: { page: number; itemsPerPage: number; sortBy?: { key: string; order: 'asc' | 'desc' }[] }) => {
  loading.value = true;

  if (options) {
    page.value = options.page;
    if (options.itemsPerPage !== itemsPerPage.value) {
      itemsPerPage.value = options.itemsPerPage;
      // Сохраняем в localStorage при изменении через таблицу
      if (typeof window !== 'undefined') {
        localStorage.setItem(STORAGE_KEY, String(options.itemsPerPage));
      }
    }
    // Сохраняем параметры сортировки
    if (options.sortBy !== undefined) {
      sortBy.value = options.sortBy;
    }
  }

  try {
    const params: Record<string, any> = {
      page: page.value,
      per_page: itemsPerPage.value,
    };
    
    // Единый поиск по всем полям (имя, фамилия, телефон, город)
    if (search.value && search.value.trim()) {
      params.search = search.value.trim();
    }

    // Параметры сортировки
    if (sortBy.value && sortBy.value.length > 0) {
      params.sort_by = sortBy.value[0].key;
      params.sort_order = sortBy.value[0].order;
    }

    const response = await api[layoutStore.usersTab].getAll(params);

    if (layoutStore.usersTab === 'users') list.value = response.data.filter((i) => !i.is_admin);
    else list.value = response;

    if (response && response.data) {
      items.value = response.data;
      totalItems.value = response.total;
    } else {
      items.value = response;
      totalItems.value = response.length;
    }
  } catch (err) {
    console.error(err);
  } finally {
    loading.value = false;
  }
};

useHead({
  title: () => (layoutStore.usersTab ? `${t('admin.nav.users')} - ${t(`admin.users.${layoutStore.usersTab}`)}` : t('admin.nav.users')),
});

onMounted(async () => {
  const tab = String(route.query.tab) as AdminEnums.UsersItems;
  if (tab && tab in AdminEnums.UsersItems) {
    if (tab !== layoutStore.usersTab) {
      layoutStore.usersTab = tab;
      await router.replace({query: {tab: tab}});
    }
  } else {
    await router.replace({query: {tab: layoutStore.usersTab}});
  }
  await loadItems();
});

watch(
    () => layoutStore.usersTab,
    async (tab) => {
      if (tab && tab in AdminEnums.UsersItems) {
        await router.replace({query: {tab: tab}});
        page.value = 1;
        await loadItems();
      }
    },
);

const onClickRow = (event: any, row: any) => {
  router.push({name: 'users-tab@id', params: {tab: String(route.query.tab), id: row.item?.id}});
};

// Row props for context menu
const getRowProps = ({ item }: { item: any }) => ({
  onContextmenu: (e: MouseEvent) => onContextMenu(e, item),
});

// Context menu handling (only for regular users, not admins)
const onContextMenu = (e: MouseEvent, item: any) => {
  // Контекстное меню только для обычных пользователей
  if (layoutStore.usersTab !== 'users') return;
  
  e.preventDefault();
  
  // Если меню уже открыто - закрываем его для перерисовки анимации
  if (showContextMenu.value) {
    showContextMenu.value = false;
  }
  
  selectedUser.value = item;
  contextMenuX.value = e.clientX;
  contextMenuY.value = e.clientY;
  
  // Даём время на обновление позиции активатора и перерисовку
  nextTick(() => {
    setTimeout(() => {
      showContextMenu.value = true;
    }, 10);
  });
};

const goToProfile = () => {
  if (selectedUser.value) {
    router.push({name: 'users-tab@id', params: {tab: String(route.query.tab), id: selectedUser.value.id}});
  }
  showContextMenu.value = false;
};

const openBonusDialog = () => {
  showContextMenu.value = false;
  bonusAction.value = 'add';
  bonusAmount.value = 100;
  bonusComment.value = '';
  bonusWithDelay.value = true; // По умолчанию с отсрочкой
  showBonusDialog.value = true;
};

const openDiscountDialog = () => {
  showContextMenu.value = false;
  // Ищем ближайшее допустимое значение скидки
  const currentDiscount = selectedUser.value?.discount || 0;
  const validValues = discountOptions.map(o => o.value);
  newDiscount.value = validValues.includes(currentDiscount) 
    ? currentDiscount 
    : validValues.reduce((prev, curr) => Math.abs(curr - currentDiscount) < Math.abs(prev - currentDiscount) ? curr : prev);
  showDiscountDialog.value = true;
};

const openGiftDialog = async () => {
  showContextMenu.value = false;
  selectedGiftIds.value = [];
  showGiftDialog.value = true;
  if (giftCatalog.value.length === 0) {
    giftCatalogLoading.value = true;
    try {
      const response = await api.prizes.getActive();
      giftCatalog.value = Array.isArray(response) ? response : (response as any).data || [];
    } catch (err) {
      console.error(err);
    } finally {
      giftCatalogLoading.value = false;
    }
  }
};

const handleBonusAction = async () => {
  console.log('[handleBonusAction] Called, actionLoading:', actionLoading.value);
  
  // Защита от повторных кликов
  if (actionLoading.value) {
    console.log('[handleBonusAction] BLOCKED - already loading');
    return;
  }
  if (!selectedUser.value || !bonusAmount.value) {
    console.log('[handleBonusAction] BLOCKED - no user or amount');
    return;
  }
  
  console.log('[handleBonusAction] Starting request...');
  
  try {
    actionLoading.value = true;
    // При списании withDelay не передаём
    const response = bonusAction.value === 'add'
      ? await api.users.addBonuses(selectedUser.value.id, bonusAmount.value, bonusComment.value, bonusWithDelay.value)
      : await api.users.deductBonuses(selectedUser.value.id, bonusAmount.value, bonusComment.value);

    console.log('[handleBonusAction] Response:', response);
    
    if (response?.message) {
      showToaster('success', response.message);
      showBonusDialog.value = false;
    }
  } catch (err: any) {
    console.error('[handleBonusAction] Error:', err);
    showToaster('error', err?.response?.data?.message || 'Ошибка');
  } finally {
    actionLoading.value = false;
    console.log('[handleBonusAction] Finished');
  }
};

const handleDiscountChange = async () => {
  if (actionLoading.value) return;
  if (!selectedUser.value) return;
  
  try {
    actionLoading.value = true;
    const response = await api.users.updateDiscount(selectedUser.value.id, newDiscount.value);

    if (response?.message) {
      showToaster('success', response.message);
      showDiscountDialog.value = false;
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка');
  } finally {
    actionLoading.value = false;
  }
};

const handleSendGift = async () => {
  if (actionLoading.value) return;
  if (!selectedUser.value || selectedGiftIds.value.length === 0) return;
  
  try {
    actionLoading.value = true;
    const response = await api.users.sendGifts(selectedUser.value.id, selectedGiftIds.value);

    if (response?.message) {
      showToaster('success', response.message);
      showGiftDialog.value = false;
      selectedGiftIds.value = [];
      // Обновляем список пользователей для обновления счетчика подарков
      await loadItems();
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка');
  } finally {
    actionLoading.value = false;
  }
};

// Create admin dialog functions
const openCreateAdminDialog = () => {
  newAdmin.value = {
    name: '',
    surname: '',
    email: '',
    role: '',
    password: '',
    password_confirmation: ''
  };
  showPassword.value = false;
  showCreateAdminDialog.value = true;
};

const closeCreateAdminDialog = () => {
  showCreateAdminDialog.value = false;
  createAdminForm.value?.reset();
};

const handleCreateAdmin = async () => {
  if (createAdminLoading.value) return;

  const { valid } = await createAdminForm.value?.validate();
  if (!valid) return;

  try {
    createAdminLoading.value = true;
    const response = await api.admins.add({
      name: newAdmin.value.name,
      surname: newAdmin.value.surname,
      email: newAdmin.value.email,
      role: newAdmin.value.role,
      password: newAdmin.value.password,
      password_confirmation: newAdmin.value.password_confirmation
    });

    if (response) {
      showToaster('success', response.message || 'Администратор успешно создан');
      closeCreateAdminDialog();
      // Переключаемся на вкладку админов и обновляем список
      layoutStore.usersTab = 'admins';
      await loadItems();
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка при создании администратора');
  } finally {
    createAdminLoading.value = false;
  }
};

// Close context menu on click outside & listen for storage changes
onMounted(() => {
  document.addEventListener('click', () => {
    showContextMenu.value = false;
  });
  
  // Слушаем изменения в localStorage
  if (typeof window !== 'undefined') {
    window.addEventListener('storage', handleStorageChange);
  }
});

onUnmounted(() => {
  if (typeof window !== 'undefined') {
    window.removeEventListener('storage', handleStorageChange);
  }
});
</script>

<style scoped>
.users-page {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 600px) {
  .users-page {
    gap: 1.25rem;
  }
}

@media (min-width: 960px) {
  .users-page {
    gap: 1.5rem;
  }
}

.users-page__header {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .users-page__header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 1rem;
  }
}

.users-page__add-btn {
  width: 100%;
}

@media (min-width: 600px) {
  .users-page__add-btn {
    width: auto;
    margin-left: auto;
  }
}

.users-page__filters {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  width: 100%;
}

@media (min-width: 600px) {
  .users-page__filters {
    flex-direction: row;
    flex-wrap: wrap;
    align-items: center;
    gap: 1rem;
  }
}

.users-page__search {
  width: 100%;
}

@media (min-width: 600px) {
  .users-page__search {
    flex: 1;
    min-width: 200px;
    max-width: 400px;
  }
}

@media (min-width: 1280px) {
  .users-page__search {
    max-width: 500px;
  }
}

.users-page__search--wide {
  max-width: none;
}

@media (min-width: 600px) {
  .users-page__search--wide {
    max-width: 500px;
  }
}

@media (min-width: 1280px) {
  .users-page__search--wide {
    max-width: 600px;
  }
}

.users-page__table-wrapper {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-secondary);
}

@media (min-width: 600px) {
  .users-page__table-wrapper {
    gap: 1.25rem;
    padding: 1.25rem;
    border-radius: 1rem;
  }
}

@media (min-width: 960px) {
  .users-page__table-wrapper {
    padding: 1.5rem;
  }
}

@media (min-width: 1280px) {
  .users-page__table-wrapper {
    gap: 1.375rem;
    padding: 2rem;
    border-radius: 1.5rem;
  }
}

.users-page__table-scroll {
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
  .users-page__table-scroll {
    min-height: 300px;
    max-height: calc(100vh - 340px);
  }
}

@media (min-width: 960px) {
  .users-page__table-scroll {
    min-height: 350px;
    max-height: calc(100vh - 350px);
  }
}

@media (min-width: 1280px) {
  .users-page__table-scroll {
    min-height: 400px;
    max-height: calc(100vh - 300px);
  }
}

@media (min-width: 1920px) {
  .users-page__table-scroll {
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

/* Context Menu Activator */
.users-page__context-activator {
  position: fixed;
  width: 1px;
  height: 1px;
  pointer-events: none;
  z-index: 1000;
}

/* Context Menu */
.users-page__context-menu {
  min-width: 200px;
  border-radius: 0.75rem !important;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15) !important;
}

.users-page__context-item--warning :deep(.v-list-item__prepend .v-icon) {
  color: var(--color-warning);
}

.users-page__context-item--info :deep(.v-list-item__prepend .v-icon) {
  color: var(--color-info);
}

.users-page__context-item--secondary :deep(.v-list-item__prepend .v-icon) {
  color: var(--color-secondary);
}

/* Dialogs */
.users-page__dialog {
  padding: 0.5rem;
}

.users-page__dialog-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.1rem;
  font-weight: 600;
  padding: 1rem 1.5rem;
  flex-wrap: wrap;
}

.users-page__dialog-title .iconify {
  font-size: 1.25rem;
  color: var(--color-primary);
}

.users-page__dialog-subtitle {
  font-size: 0.85rem;
  font-weight: 400;
  color: var(--color-text-secondary);
  width: 100%;
  margin-top: 0.25rem;
}

.users-page__dialog-actions {
  padding: 1rem 1.5rem;
  justify-content: flex-end;
  gap: 0.5rem;
}

.users-page__dialog-loading,
.users-page__dialog-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  padding: 2rem;
  color: var(--color-text-secondary);
}

.users-page__dialog-empty .iconify {
  font-size: 3rem;
  opacity: 0.5;
}

/* Gift Grid */
.users-page__gift-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 0.75rem;
  max-height: 300px;
  overflow-y: auto;
  padding: 0.25rem;
}

.users-page__gift-item {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem;
  border-radius: 0.5rem;
  border: 2px solid transparent;
  background: var(--color-bg-secondary);
  cursor: pointer;
  transition: all 0.2s ease;
}

.users-page__gift-item:hover {
  border-color: var(--color-primary-light);
}

.users-page__gift-item--selected {
  border-color: var(--color-primary);
  background: rgba(var(--color-primary-rgb), 0.1);
}

.users-page__gift-image {
  width: 50px;
  height: 50px;
  object-fit: cover;
  border-radius: 0.375rem;
}

.users-page__gift-placeholder {
  width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg-tertiary);
  border-radius: 0.375rem;
  color: var(--color-text-secondary);
}

.users-page__gift-name {
  font-size: 0.7rem;
  font-weight: 500;
  text-align: center;
  word-break: break-word;
}

.users-page__gift-check {
  position: absolute;
  top: 0.125rem;
  right: 0.125rem;
  color: var(--color-primary);
  font-size: 1rem;
  display: flex;
  align-items: center;
  gap: 0.125rem;
}

.users-page__gift-number {
  font-size: 0.65rem;
  font-weight: 700;
  background: var(--color-primary);
  color: white;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.users-page__gift-hint {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  padding: 0.75rem;
  margin-bottom: 1rem;
  background: rgba(var(--color-info-rgb), 0.1);
  border-radius: 0.5rem;
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  line-height: 1.4;
}

.users-page__gift-hint .iconify {
  color: var(--color-info);
  flex-shrink: 0;
  margin-top: 0.1rem;
}

.users-page__gift-counter {
  text-align: right;
  margin-bottom: 0.75rem;
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.users-page__gift-counter--max {
  color: var(--color-warning);
}

.users-page__gift-item--disabled {
  opacity: 0.4;
  pointer-events: none;
}

/* iOS-style Toggle для отсрочки */
.users-page__delay-toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  margin-top: 0.75rem;
  background: var(--color-bg-secondary);
  border-radius: 12px;
  border: 1px solid var(--color-border);
}

.users-page__delay-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.users-page__delay-label {
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.users-page__delay-hint {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

/* iOS Toggle Switch */
.ios-toggle {
  position: relative;
  display: inline-block;
  width: 51px;
  height: 31px;
  flex-shrink: 0;
}

.ios-toggle input {
  opacity: 0;
  width: 0;
  height: 0;
}

.ios-toggle__slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #e9e9eb;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border-radius: 31px;
  box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.04);
}

.ios-toggle__slider::before {
  position: absolute;
  content: "";
  height: 27px;
  width: 27px;
  left: 2px;
  bottom: 2px;
  background-color: white;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border-radius: 50%;
  box-shadow: 
    0 3px 8px rgba(0, 0, 0, 0.15),
    0 3px 1px rgba(0, 0, 0, 0.06);
}

.ios-toggle input:checked + .ios-toggle__slider {
  background-color: #34c759;
}

.ios-toggle input:checked + .ios-toggle__slider::before {
  transform: translateX(20px);
}

.ios-toggle input:focus + .ios-toggle__slider {
  box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.04), 0 0 0 3px rgba(52, 199, 89, 0.3);
}

/* Темная тема для toggle */
:root.dark .ios-toggle__slider {
  background-color: #39393d;
}

:root.dark .ios-toggle input:checked + .ios-toggle__slider {
  background-color: #30d158;
}

/* Disabled состояние */
.users-page__delay-toggle--disabled {
  opacity: 0.5;
  pointer-events: none;
}

.ios-toggle--disabled {
  cursor: not-allowed;
}

.ios-toggle--disabled .ios-toggle__slider {
  background-color: #d1d5db !important;
  cursor: not-allowed;
}

.ios-toggle--disabled .ios-toggle__slider::before {
  box-shadow: none;
}

:root.dark .ios-toggle--disabled .ios-toggle__slider {
  background-color: #4b5563 !important;
}

/* ===== CREATE ADMIN DIALOG ===== */
.users-page__create-dialog {
  overflow: hidden;
}

.users-page__create-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 1.5rem 1.5rem 1rem;
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-dark, #5a7a3d) 100%);
  color: white;
}

.users-page__create-header-content {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.users-page__create-icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 16px;
  backdrop-filter: blur(8px);
}

.users-page__create-icon {
  font-size: 1.75rem;
  color: white;
}

.users-page__create-header-text {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.users-page__create-title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  line-height: 1.3;
}

.users-page__create-subtitle {
  margin: 0;
  font-size: 0.875rem;
  opacity: 0.85;
}

.users-page__create-close {
  color: white !important;
  opacity: 0.8;
  margin-top: -0.5rem;
  margin-right: -0.5rem;
}

.users-page__create-close:hover {
  opacity: 1;
  background: rgba(255, 255, 255, 0.1) !important;
}

.users-page__create-body {
  padding: 1.5rem !important;
}

.users-page__create-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.users-page__create-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

@media (max-width: 480px) {
  .users-page__create-row {
    grid-template-columns: 1fr;
  }
}

.users-page__create-field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.users-page__create-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text-secondary);
}

.users-page__create-label .iconify {
  font-size: 1rem;
  color: var(--color-primary);
}

.users-page__create-role-icon {
  font-size: 1.25rem;
  color: var(--color-primary);
}

.users-page__create-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1rem 1.5rem 1.5rem;
  border-top: 1px solid var(--color-border);
}

.users-page__create-submit {
  min-width: 180px;
}

/* Dark mode для create dialog */
:root.dark .users-page__create-header {
  background: linear-gradient(135deg, #4a6b32 0%, #3d5829 100%);
}

:root.dark .users-page__create-label {
  color: var(--color-text-secondary);
}

:root.dark .users-page__create-actions {
  border-top-color: var(--color-border);
}
</style>
