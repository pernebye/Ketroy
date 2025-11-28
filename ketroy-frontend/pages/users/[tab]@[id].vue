<template>
  <div class="user-profile">
    <!-- Header with Breadcrumbs and Action Buttons -->
    <div class="user-profile__top-header">
      <div class="user-profile__breadcrumbs">
        <v-breadcrumbs :items="brItems">
          <template v-slot:divider>
            <Icon name="bi:caret-right-fill" class="user-profile__breadcrumb-divider" />
          </template>
        </v-breadcrumbs>
      </div>
      
      <div class="user-profile__action-buttons">
        <!-- Кнопки только для обычных пользователей (не для админов/маркетологов) -->
        <template v-if="which === 'users' || which === 'winners'">
          <v-btn 
            color="success" 
            variant="flat"
            rounded="lg"
            :loading="refreshing"
            @click="refreshData"
            class="user-profile__action-btn"
          >
            <Icon name="mdi:refresh" class="user-profile__action-btn-icon" />
            Обновить
          </v-btn>

          <v-btn 
            color="warning" 
            variant="flat"
            rounded="lg"
            @click="showBonusDialog = true"
            class="user-profile__action-btn"
          >
            <Icon name="mdi:star-plus" class="user-profile__action-btn-icon" />
            Бонусы
          </v-btn>

          <v-btn 
            color="info" 
            variant="flat"
            rounded="lg"
            @click="showDiscountDialog = true"
            class="user-profile__action-btn"
          >
            <Icon name="mdi:percent" class="user-profile__action-btn-icon" />
            Скидка
          </v-btn>

          <v-btn 
            color="secondary" 
            variant="flat"
            rounded="lg"
            @click="openGiftDialog"
            class="user-profile__action-btn"
          >
            <Icon name="mdi:gift" class="user-profile__action-btn-icon" />
            Подарок
          </v-btn>

          <v-btn 
            color="purple" 
            variant="flat"
            rounded="lg"
            :loading="testNotificationLoading"
            @click="handleTestNotification"
            class="user-profile__action-btn"
          >
            <Icon name="mdi:bell-ring" class="user-profile__action-btn-icon" />
            Тест Push
          </v-btn>
        </template>
      </div>
    </div>

    <!-- Dialog: Управление бонусами -->
    <v-dialog v-model="showBonusDialog" max-width="450" persistent>
      <v-card rounded="xl" class="user-profile__dialog">
        <v-card-title class="user-profile__dialog-title">
          <Icon name="mdi:star-circle" class="user-profile__dialog-icon" />
          Управление бонусами
        </v-card-title>
        <v-card-text>
          <div class="user-profile__dialog-current">
            Текущий баланс: <strong>{{ formatNumber(user?.bonus_amount || 0) }} ₸</strong>
          </div>
          <v-radio-group v-model="bonusAction" inline class="user-profile__dialog-radio">
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
            label="Комментарий (необязательно)"
            variant="outlined"
            density="compact"
            rounded="lg"
          />
          
          <!-- Переключатель отсрочки в стиле iOS (только для начисления) -->
          <div class="user-profile__delay-toggle" :class="{ 'user-profile__delay-toggle--disabled': bonusAction === 'deduct' }">
            <div class="user-profile__delay-info">
              <span class="user-profile__delay-label">Отсрочка начисления</span>
              <span class="user-profile__delay-hint">
                {{ bonusAction === 'deduct' ? 'Не применяется при списании' : (bonusWithDelay ? 'Бонусы будут доступны через 14 дней' : 'Бонусы доступны сразу') }}
              </span>
            </div>
            <label class="ios-toggle" :class="{ 'ios-toggle--disabled': bonusAction === 'deduct' }">
              <input type="checkbox" v-model="bonusWithDelay" :disabled="bonusAction === 'deduct'" />
              <span class="ios-toggle__slider"></span>
            </label>
          </div>
        </v-card-text>
        <v-card-actions class="user-profile__dialog-actions">
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
      <v-card rounded="xl" class="user-profile__dialog">
        <v-card-title class="user-profile__dialog-title">
          <Icon name="mdi:percent-circle" class="user-profile__dialog-icon" />
          Изменить скидку
        </v-card-title>
        <v-card-text>
          <div class="user-profile__dialog-current tw-mb-4">
            Текущая скидка: <strong>{{ user?.discount || 0 }}%</strong>
          </div>
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
        <v-card-actions class="user-profile__dialog-actions">
          <v-btn variant="text" @click="showDiscountDialog = false">Отмена</v-btn>
          <v-btn 
            color="primary" 
            variant="flat"
            :loading="actionLoading"
            :disabled="actionLoading"
            @click="handleDiscountChange"
          >
            Сохранить
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog: Отправка подарка (до 4 штук) -->
    <v-dialog v-model="showGiftDialog" max-width="600" persistent>
      <v-card rounded="xl" class="user-profile__dialog">
        <v-card-title class="user-profile__dialog-title">
          <Icon name="mdi:gift" class="user-profile__dialog-icon" />
          Отправить подарок
        </v-card-title>
        <v-card-text>
          <div class="user-profile__gift-hint">
            <Icon name="mdi:information-outline" />
            <span>Выберите от 1 до 4 подарков. Пользователь случайно получит один из них при активации.</span>
          </div>
          <div v-if="selectedGiftIds.length > 0" class="user-profile__gift-selected-count">
            Выбрано: <strong>{{ selectedGiftIds.length }}</strong> из 4
          </div>
          <div v-if="giftCatalogLoading" class="user-profile__dialog-loading">
            <v-progress-circular indeterminate :size="24" />
            <span>Загрузка каталога...</span>
          </div>
          <div v-else-if="giftCatalog.length === 0" class="user-profile__dialog-empty">
            <Icon name="mdi:gift-off-outline" />
            <span>В каталоге пока нет подарков</span>
          </div>
          <div v-else class="user-profile__gift-grid">
            <div 
              v-for="gift in giftCatalog" 
              :key="gift.id"
              class="user-profile__gift-item"
              :class="{ 
                'user-profile__gift-item--selected': selectedGiftIds.includes(gift.id),
                'user-profile__gift-item--disabled': selectedGiftIds.length >= 4 && !selectedGiftIds.includes(gift.id)
              }"
              @click="toggleGiftSelection(gift.id)"
            >
              <img 
                v-if="gift.image_url" 
                :src="gift.image_url" 
                :alt="gift.name"
                class="user-profile__gift-image"
              />
              <div v-else class="user-profile__gift-placeholder">
                <Icon name="mdi:gift" />
              </div>
              <span class="user-profile__gift-name">{{ gift.name }}</span>
              <div v-if="selectedGiftIds.includes(gift.id)" class="user-profile__gift-check">
                <Icon name="mdi:check-circle" />
                <span class="user-profile__gift-order">{{ selectedGiftIds.indexOf(gift.id) + 1 }}</span>
              </div>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="user-profile__dialog-actions">
          <v-btn variant="text" @click="showGiftDialog = false">Отмена</v-btn>
          <v-btn 
            color="secondary" 
            variant="flat"
            :loading="actionLoading"
            :disabled="selectedGiftIds.length === 0 || actionLoading"
            @click="handleSendGift"
          >
            Отправить {{ selectedGiftIds.length > 1 ? `(${selectedGiftIds.length} шт.)` : '' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Loading state -->
    <div v-if="!user" class="user-profile__loading">
      <v-progress-circular indeterminate color="var(--color-accent)" :size="48" :width="4" />
      <span>Загрузка профиля...</span>
    </div>

    <!-- Profile content -->
    <v-form v-else ref="form" class="user-profile__content">
      <div class="user-profile__layout">
        <!-- Profile Card -->
        <section class="user-profile__card">
          <!-- Header with background -->
          <div class="user-profile__header">
            <div class="user-profile__header-bg"></div>
            <div class="user-profile__avatar-wrapper">
              <div class="user-profile__avatar">
                <img 
                  v-if="image && image.length" 
                  :src="imagePreview(image)" 
                  alt="User image"
                  class="user-profile__avatar-img"
                  draggable="false"
                />
                <img 
                  v-else-if="user.avatar_image" 
                  :src="user.avatar_image" 
                  alt="User avatar"
                  class="user-profile__avatar-img"
                  draggable="false"
                />
                <img 
                  v-else-if="user.image && user.image.path" 
                  :src="fileUrlValidator(user.image.path)" 
                  alt="User image"
                  class="user-profile__avatar-img"
                  draggable="false"
                />
                <div 
                  v-else 
                  class="user-profile__avatar-initials"
                >
                  {{ getInitials(user) }}
                </div>
                <button class="user-profile__avatar-edit" @click="image = []; user.image = undefined;">
                  <Icon name="mdi:pencil" />
                </button>
              </div>
              <v-file-input v-model="image" ref="imageInput" class="user-profile__file-input" accept="image/*" />
            </div>
            <h2 class="user-profile__name">{{ (user.surname ?? '') + ' ' + user.name }}</h2>
          </div>

          <!-- Divider -->
          <div class="user-profile__divider"></div>

          <!-- User Info -->
          <div class="user-profile__info">
            <div class="user-profile__info-item">
              <div class="user-profile__info-icon">
                <Icon name="mdi:phone" />
              </div>
              <div class="user-profile__info-content">
                <span class="user-profile__info-label">Номер телефона</span>
                <span class="user-profile__info-value">{{ user.phone || '—' }}</span>
              </div>
            </div>

            <div class="user-profile__info-item">
              <div class="user-profile__info-icon">
                <Icon name="mdi:calendar" />
              </div>
              <div class="user-profile__info-content">
                <span class="user-profile__info-label">Дата рождения</span>
                <span class="user-profile__info-value">{{ user.birthdate || '—' }}</span>
              </div>
            </div>

            <div v-if="user.city" class="user-profile__info-item">
              <div class="user-profile__info-icon">
                <Icon name="mdi:map-marker" />
              </div>
              <div class="user-profile__info-content">
                <span class="user-profile__info-label">Город</span>
                <span class="user-profile__info-value">{{ user.city }}</span>
              </div>
            </div>

            <div v-if="user.referrer_id" class="user-profile__info-item">
              <div class="user-profile__info-icon">
                <Icon name="mdi:account-group" />
              </div>
              <div class="user-profile__info-content">
                <span class="user-profile__info-label">ФИО реферала</span>
                <span class="user-profile__info-value">{{ user.referrer || '—' }}</span>
              </div>
            </div>

            <div v-if="user.height" class="user-profile__info-item">
              <div class="user-profile__info-icon">
                <Icon name="mdi:human-male-height" />
              </div>
              <div class="user-profile__info-content">
                <span class="user-profile__info-label">Рост</span>
                <span class="user-profile__info-value">{{ user.height }}</span>
              </div>
            </div>

            <div v-if="user.clothing_size" class="user-profile__info-item">
              <div class="user-profile__info-icon">
                <Icon name="mdi:tshirt-crew" />
              </div>
              <div class="user-profile__info-content">
                <span class="user-profile__info-label">Размер одежды</span>
                <span class="user-profile__info-value">{{ user.clothing_size }}</span>
              </div>
            </div>

            <div v-if="user.shoe_size" class="user-profile__info-item">
              <div class="user-profile__info-icon">
                <Icon name="mdi:shoe-sneaker" />
              </div>
              <div class="user-profile__info-content">
                <span class="user-profile__info-label">Размер обуви</span>
                <span class="user-profile__info-value">{{ user.shoe_size }}</span>
              </div>
            </div>
          </div>

          <!-- Role change button -->
          <div v-if="hasRole('super-admin')" class="user-profile__role-section">
            <v-btn 
              v-if="user?.is_admin" 
              color="primary" 
              :loading="adminLoading" 
              @click="changeRole"
              class="user-profile__role-btn"
            >
              Сделать маркетологом
            </v-btn>
            <v-btn 
              v-else 
              color="primary" 
              :loading="adminLoading" 
              @click="changeRole"
              class="user-profile__role-btn"
            >
              Сделать админом
            </v-btn>
          </div>
        </section>

        <!-- Stats Section -->
        <section v-if="which === 'users' || which === 'winners'" class="user-profile__stats">
          <!-- Main Stats Row -->
          <div class="user-profile__main-stats">
            <div class="user-profile__big-stat user-profile__big-stat--primary">
              <div class="user-profile__big-stat-header">
                <Icon name="mdi:wallet" class="user-profile__big-stat-icon" />
                <span class="user-profile__big-stat-label">Баланс бонусов</span>
              </div>
              <div class="user-profile__big-stat-value">{{ formatNumber(user?.bonus_amount || 0) }}</div>
              <div class="user-profile__big-stat-suffix">тенге</div>
              <div class="user-profile__big-stat-bg">
                <Icon name="mdi:cash-multiple" />
              </div>
            </div>

            <div class="user-profile__big-stat user-profile__big-stat--secondary">
              <div class="user-profile__big-stat-header">
                <Icon name="mdi:shopping-outline" class="user-profile__big-stat-icon" />
                <span class="user-profile__big-stat-label">Общие покупки</span>
              </div>
              <div class="user-profile__big-stat-value">{{ formatNumber(user?.purchases_sum || 0) }}</div>
              <div class="user-profile__big-stat-suffix">тенге</div>
              <div class="user-profile__big-stat-bg">
                <Icon name="mdi:cart" />
              </div>
            </div>
          </div>

          <!-- Mini Stats Grid -->
          <div class="user-profile__mini-stats">
            <div class="user-profile__mini-stat">
              <div class="user-profile__mini-stat-icon user-profile__mini-stat-icon--discount">
                <Icon name="mdi:percent-outline" />
              </div>
              <div class="user-profile__mini-stat-content">
                <span class="user-profile__mini-stat-value">{{ user?.discount || 0 }}%</span>
                <span class="user-profile__mini-stat-label">Скидка</span>
              </div>
            </div>

            <div class="user-profile__mini-stat">
              <div class="user-profile__mini-stat-icon user-profile__mini-stat-icon--gifts">
                <Icon name="mdi:gift-outline" />
              </div>
              <div class="user-profile__mini-stat-content">
                <span class="user-profile__mini-stat-value">{{ user?.gifts_count || 0 }}</span>
                <span class="user-profile__mini-stat-label">Подарков</span>
              </div>
            </div>

            <div class="user-profile__mini-stat">
              <div class="user-profile__mini-stat-icon user-profile__mini-stat-icon--orders">
                <Icon name="mdi:shopping" />
              </div>
              <div class="user-profile__mini-stat-content">
                <span class="user-profile__mini-stat-value">{{ user?.purchases_count || 0 }}</span>
                <span class="user-profile__mini-stat-label">Покупок</span>
              </div>
            </div>

            <div class="user-profile__mini-stat">
              <div class="user-profile__mini-stat-icon user-profile__mini-stat-icon--referrals">
                <Icon name="mdi:account-group-outline" />
              </div>
              <div class="user-profile__mini-stat-content">
                <span class="user-profile__mini-stat-value">{{ user?.referrals_count || 0 }}</span>
                <span class="user-profile__mini-stat-label">Рефералов</span>
              </div>
            </div>
          </div>

          <!-- Info Cards -->
          <div class="user-profile__info-cards">
            <div class="user-profile__info-card">
              <div class="user-profile__info-card-icon">
                <Icon name="mdi:calendar-account" />
              </div>
              <div class="user-profile__info-card-content">
                <span class="user-profile__info-card-label">Дата регистрации</span>
                <span class="user-profile__info-card-value">{{ formatDate(user?.created_at) || '—' }}</span>
              </div>
            </div>

            <div class="user-profile__info-card">
              <div class="user-profile__info-card-icon">
                <Icon name="mdi:clock-outline" />
              </div>
              <div class="user-profile__info-card-content">
                <span class="user-profile__info-card-label">Последняя активность</span>
                <span class="user-profile__info-card-value">{{ formatDate(user?.last_activity) || '—' }}</span>
              </div>
            </div>

            <div class="user-profile__info-card">
              <div class="user-profile__info-card-icon user-profile__info-card-icon--loyalty" :style="user?.loyalty_level?.color ? { backgroundColor: user.loyalty_level.color + '25', color: user.loyalty_level.color } : {}">
                <span v-if="user?.loyalty_level?.icon" class="user-profile__loyalty-emoji">{{ user.loyalty_level.icon }}</span>
                <Icon v-else name="mdi:star-circle" />
              </div>
              <div class="user-profile__info-card-content">
                <span class="user-profile__info-card-label">Уровень лояльности</span>
                <span class="user-profile__info-card-value user-profile__info-card-value--loyalty" :style="user?.loyalty_level?.color ? { color: user.loyalty_level.color } : {}">
                  {{ user?.loyalty_level?.name || '—' }}
                </span>
              </div>
            </div>

            <div class="user-profile__info-card">
              <div class="user-profile__info-card-icon user-profile__info-card-icon--verified">
                <Icon name="mdi:check-decagram" />
              </div>
              <div class="user-profile__info-card-content">
                <span class="user-profile__info-card-label">Статус аккаунта</span>
                <span class="user-profile__info-card-value user-profile__info-card-value--verified">
                  Верифицирован
                </span>
              </div>
            </div>
          </div>

          <!-- Purchase History -->
          <div class="user-profile__purchases">
            <div class="user-profile__purchases-header">
              <Icon name="mdi:receipt-text-outline" class="user-profile__purchases-icon" />
              <h3 class="user-profile__purchases-title">История покупок</h3>
            </div>
            
            <div v-if="purchasesLoading" class="user-profile__purchases-loading">
              <v-progress-circular indeterminate color="var(--color-accent)" :size="24" :width="2" />
              <span>Загрузка...</span>
            </div>
            
            <div v-else-if="!purchaseData?.purchases?.length" class="user-profile__purchases-empty">
              <Icon name="mdi:shopping-outline" class="user-profile__purchases-empty-icon" />
              <span>Нет данных о покупках</span>
            </div>
            
            <div v-else class="user-profile__purchases-list">
              <div 
                v-for="(purchase, index) in purchaseData.purchases" 
                :key="index"
                class="user-profile__purchase-item"
              >
                <div class="user-profile__purchase-date">
                  <Icon name="mdi:calendar" />
                  <span>{{ formatPurchaseDate(purchase.purchaseDate) }}</span>
                </div>
                <div class="user-profile__purchase-amount">
                  {{ formatNumber(purchase.purchaseAmount) }} ₸
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>

      <!-- Delete button -->
      <div v-if="hasRole('super-admin') && canDelete" class="user-profile__actions">
        <v-btn 
          class="user-profile__delete-btn" 
          color="error" 
          variant="outlined" 
          rounded="lg"
        >
          <confirm @delete="onDelete" />
          <Icon name="mdi:delete" class="user-profile__delete-icon" />
          Удалить пользователя
        </v-btn>
      </div>
    </v-form>
  </div>
</template>

<script setup lang="ts">
import { AdminEnums } from '~/types/enums';

const { hasRole } = useAccess();

const store = useStore();
const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();

const form = ref();
const imageInput = ref();
const loading = ref<boolean>(false);
const user = ref<Api.User.Self | null>(null);
const image = ref<File[]>([]);

// Данные о покупках из 1С
const purchaseData = ref<Api.User.PurchaseHistory | null>(null);
const purchasesLoading = ref<boolean>(false);
const refreshing = ref<boolean>(false);

// Диалоги управления пользователем
const showBonusDialog = ref<boolean>(false);
const showDiscountDialog = ref<boolean>(false);
const showGiftDialog = ref<boolean>(false);
const actionLoading = ref<boolean>(false);

// Управление бонусами
const bonusAction = ref<'add' | 'deduct'>('add');
const bonusAmount = ref<number>(100);
const bonusComment = ref<string>('');
const bonusWithDelay = ref<boolean>(true); // true = 14 дней, false = сразу

// Управление скидкой - предопределённые скидки из 1С
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
const newDiscount = ref<number>(0);

// Отправка подарка (до 4 штук)
const giftCatalog = ref<Api.GiftCatalog.Self[]>([]);
const giftCatalogLoading = ref<boolean>(false);
const selectedGiftIds = ref<number[]>([]);

// Тестовые уведомления
const testNotificationLoading = ref<boolean>(false);

const which = computed(() => String(route.params.tab) as keyof typeof AdminEnums.UsersItems);
const id = computed<number>(() => Number(route.params.id));
const canDelete = computed(() => !!user.value && !!store.auser && store.auser.id !== id.value);
const brItems: Types.Crumb[] = [
  { title: t(`admin.users.${which.value}`), to: { name: 'users', query: { tab: which.value } }, disabled: false },
  { title: 'Профиль пользователя', to: { ...route }, disabled: false },
];

const save = useDebounceFn(
  async () => {
    await form.value.validate().then(async (v: Types.VFormValidation) => {
      if (v.valid && user.value) {
        try {
          loading.value = true;
          const formData = new FormData();
          formData.append('_method', 'PATCH');
          const img = image.value ? image.value[0] : undefined;
          if (img) formData.append('image', img);
          formData.append('first_name', user.value.first_name);
          if (user.value.email) formData.append('email', String(user.value.email ?? ''));
          if (user.value.age) formData.append('age', String(user.value.age ?? ''));
          if (user.value.city) formData.append('city_id', String(user.value.city.id));
          formData.append('is_admin', String(user.value.is_admin));
          // @ts-ignore
          const response = await api.users.update(id.value, formData);
          await get();
        } catch (err) {
          console.log(err);
        } finally {
          loading.value = false;
        }
      }
    });
  },
  500,
  { maxWait: 3000 },
);

const onDelete = async () => {
  try {
    if (canDelete.value && !!user.value) {
      await api.users.delete(user.value.id);
      await router.push({ name: 'users', query: { tab: which.value } });
    }
  } catch (err) {
    console.log(err);
  }
};

const get = async () => {
  try {
    let response;
    if (which.value == 'admins') {
      response = await api.admins.get(id.value);
    } else {
      response = await api.users.get(id.value);
    }
    if (response) user.value = structuredClone(response);
    if (!!user.value && !!store.auser && store.auser.id === id.value) {
      const auser = useCookie('auser');
      auser.value = JSON.stringify(response);
      store.auser = response;
    }
  } catch (err) {
    console.log(err);
    await router.push({ name: 'users', query: { tab: which.value } });
  }
};

useHead({
  title: () => 'Профиль ' + `${user.value ? (user.value.first_name ?? '') + ' ' + (user.value.last_name ?? '') : ''}`,
});

onBeforeMount(() => {
  const tab = String(route.params.tab) as AdminEnums.UsersItems;
  if (tab && tab in AdminEnums.UsersItems) {
    if (layoutStore.usersTab !== tab) layoutStore.usersTab = tab;
  } else router.push({ name: 'users' });
});

// Загрузка истории покупок из 1С
const getPurchases = async () => {
  try {
    purchasesLoading.value = true;
    const response = await api.users.getPurchases(id.value);
    if (response) {
      purchaseData.value = response;
    }
  } catch (err) {
    console.log('Ошибка загрузки покупок:', err);
  } finally {
    purchasesLoading.value = false;
  }
};

// Обновление всех данных из 1С
const refreshData = async () => {
  try {
    refreshing.value = true;
    await Promise.all([get(), getPurchases()]);
  } catch (err) {
    console.log('Ошибка обновления данных:', err);
  } finally {
    refreshing.value = false;
  }
};

// Загрузка каталога подарков
const loadGiftCatalog = async () => {
  try {
    giftCatalogLoading.value = true;
    const response = await api.prizes.getActive();
    giftCatalog.value = Array.isArray(response) ? response : (response as any).data || [];
  } catch (err) {
    console.error('Ошибка загрузки каталога:', err);
  } finally {
    giftCatalogLoading.value = false;
  }
};

// Открыть диалог отправки подарка
const openGiftDialog = async () => {
  selectedGiftIds.value = [];
  showGiftDialog.value = true;
  if (giftCatalog.value.length === 0) {
    await loadGiftCatalog();
  }
};

// Переключить выбор подарка (макс 4)
const toggleGiftSelection = (giftId: number) => {
  const index = selectedGiftIds.value.indexOf(giftId);
  if (index > -1) {
    // Убираем из выбранных
    selectedGiftIds.value.splice(index, 1);
  } else if (selectedGiftIds.value.length < 4) {
    // Добавляем, если меньше 4
    selectedGiftIds.value.push(giftId);
  }
};

// Обработка бонусов
const handleBonusAction = async () => {
  // Защита от повторных кликов
  if (actionLoading.value) return;
  
  if (!bonusAmount.value || bonusAmount.value < 1) {
    showToaster('error', 'Укажите сумму бонусов');
    return;
  }

  try {
    actionLoading.value = true;
    // При списании withDelay не передаём
    const response = bonusAction.value === 'add'
      ? await api.users.addBonuses(id.value, bonusAmount.value, bonusComment.value, bonusWithDelay.value)
      : await api.users.deductBonuses(id.value, bonusAmount.value, bonusComment.value);

    if (response?.message) {
      showToaster('success', response.message);
      if (user.value) {
        user.value.bonus_amount = response.bonus_amount;
      }
      showBonusDialog.value = false;
      bonusAmount.value = 100;
      bonusComment.value = '';
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка при операции с бонусами');
  } finally {
    actionLoading.value = false;
  }
};

// Изменение скидки
const handleDiscountChange = async () => {
  if (actionLoading.value) return;
  
  try {
    actionLoading.value = true;
    const response = await api.users.updateDiscount(id.value, newDiscount.value);

    if (response?.message) {
      showToaster('success', response.message);
      if (user.value) {
        user.value.discount = response.discount;
      }
      showDiscountDialog.value = false;
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка при изменении скидки');
  } finally {
    actionLoading.value = false;
  }
};

// Отправка подарка
const handleSendGift = async () => {
  if (actionLoading.value) return;
  
  if (selectedGiftIds.value.length === 0) {
    showToaster('error', 'Выберите хотя бы один подарок');
    return;
  }

  try {
    actionLoading.value = true;
    const response = await api.users.sendGifts(id.value, selectedGiftIds.value);

    if (response?.message) {
      showToaster('success', response.message);
      showGiftDialog.value = false;
      selectedGiftIds.value = [];
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка при отправке подарка');
  } finally {
    actionLoading.value = false;
  }
};

// Отправка тестового push-уведомления
const handleTestNotification = async () => {
  if (testNotificationLoading.value) return;
  
  try {
    testNotificationLoading.value = true;
    const response = await api.users.sendTestNotification(id.value);
    
    if (response?.success) {
      showToaster('success', response.message);
    } else {
      showToaster('error', response?.message || 'Ошибка при отправке уведомления');
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка при отправке тестового уведомления');
  } finally {
    testNotificationLoading.value = false;
  }
};

// Инициализация скидки при открытии диалога
watch(showDiscountDialog, (val) => {
  if (val && user.value) {
    // Ищем ближайшее допустимое значение скидки
    const currentDiscount = user.value.discount || 0;
    const validValues = discountOptions.map(o => o.value);
    newDiscount.value = validValues.includes(currentDiscount) 
      ? currentDiscount 
      : validValues.reduce((prev, curr) => Math.abs(curr - currentDiscount) < Math.abs(prev - currentDiscount) ? curr : prev);
  }
});

onMounted(async () => {
  await get();
  await getPurchases();
});

const adminLoading = ref<boolean>(false);

// Форматирование числа с разделителями
const formatNumber = (num: number | undefined) => {
  if (!num) return '0';
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
};

// Форматирование даты
const formatDate = (dateStr: string | undefined) => {
  if (!dateStr) return null;
  const date = new Date(dateStr);
  return date.toLocaleDateString('ru-RU', { 
    day: 'numeric', 
    month: 'long', 
    year: 'numeric' 
  });
};

// Форматирование даты покупки
const formatPurchaseDate = (dateStr: string | undefined) => {
  if (!dateStr) return '—';
  const date = new Date(dateStr);
  return date.toLocaleDateString('ru-RU', { 
    day: '2-digit', 
    month: '2-digit', 
    year: 'numeric' 
  });
};

const changeRole = async () => {
  try {
    adminLoading.value = true;
    const role = user.value?.is_admin ? 'marketer' : 'super-admin';
    await api.admins.changeRole({ userId: id.value, role: role });
    await get();
    await router.push({ name: 'users', query: { tab: which.value } });
  } catch (err) {
    console.error('Error assigning marketer role:', err);
  } finally {
    adminLoading.value = false;
  }
};

// Получение инициалов пользователя
const getInitials = (u: Api.User.Self | null) => {
  if (!u) return '?';
  const name = u.name || u.first_name || '';
  const surname = u.surname || u.last_name || '';
  const firstInitial = name.charAt(0).toUpperCase();
  const secondInitial = surname.charAt(0).toUpperCase();
  return firstInitial + secondInitial || firstInitial || '?';
};
</script>

<style scoped>
.user-profile {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Top Header */
.user-profile__top-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

/* Breadcrumbs */
.user-profile__breadcrumbs {
  display: flex;
  align-items: center;
}

/* Action Buttons Container */
.user-profile__action-buttons {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.user-profile__action-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 500;
}

.user-profile__action-btn-icon {
  font-size: 1.1rem;
}

@media (max-width: 768px) {
  .user-profile__action-buttons {
    width: 100%;
    justify-content: flex-end;
  }
  
  .user-profile__action-btn {
    flex: 1;
    min-width: 100px;
    font-size: 0.75rem;
    padding: 0 0.5rem;
  }
}

/* Dialogs */
.user-profile__dialog {
  padding: 0.5rem;
}

.user-profile__dialog-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
  padding: 1rem 1.5rem;
}

.user-profile__dialog-icon {
  font-size: 1.5rem;
  color: var(--color-primary);
}

.user-profile__dialog-current {
  background: var(--color-bg-secondary);
  padding: 0.75rem 1rem;
  border-radius: 0.75rem;
  margin-bottom: 1rem;
  font-size: 0.95rem;
}

.user-profile__dialog-radio {
  margin-bottom: 0.5rem;
}

.user-profile__dialog-slider {
  margin-top: 1rem;
}

.user-profile__dialog-actions {
  padding: 1rem 1.5rem;
  justify-content: flex-end;
  gap: 0.5rem;
}

.user-profile__dialog-loading,
.user-profile__dialog-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  padding: 2rem;
  color: var(--color-text-secondary);
}

.user-profile__dialog-empty .iconify {
  font-size: 3rem;
  opacity: 0.5;
}

/* Gift Grid */
.user-profile__gift-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 1rem;
  max-height: 350px;
  overflow-y: auto;
  padding: 0.25rem;
}

.user-profile__gift-item {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  border-radius: 0.75rem;
  border: 2px solid transparent;
  background: var(--color-bg-secondary);
  cursor: pointer;
  transition: all 0.2s ease;
}

.user-profile__gift-item:hover {
  border-color: var(--color-primary-light);
  transform: translateY(-2px);
}

.user-profile__gift-item--selected {
  border-color: var(--color-primary);
  background: rgba(var(--color-primary-rgb), 0.1);
}

.user-profile__gift-image {
  width: 70px;
  height: 70px;
  object-fit: cover;
  border-radius: 0.5rem;
}

.user-profile__gift-placeholder {
  width: 70px;
  height: 70px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg-tertiary);
  border-radius: 0.5rem;
  color: var(--color-text-secondary);
  font-size: 1.5rem;
}

.user-profile__gift-name {
  font-size: 0.8rem;
  font-weight: 500;
  text-align: center;
  word-break: break-word;
}

.user-profile__gift-check {
  position: absolute;
  top: 0.25rem;
  right: 0.25rem;
  color: var(--color-primary);
  font-size: 1.25rem;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.user-profile__gift-order {
  font-size: 0.7rem;
  font-weight: 700;
  background: var(--color-primary);
  color: white;
  width: 1rem;
  height: 1rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-profile__gift-item--disabled {
  opacity: 0.4;
  pointer-events: none;
}

.user-profile__gift-hint {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: rgba(var(--v-theme-info), 0.1);
  border-radius: 0.75rem;
  margin-bottom: 1rem;
  font-size: 0.85rem;
  color: rgb(var(--v-theme-info));
}

.user-profile__gift-hint .iconify {
  flex-shrink: 0;
  margin-top: 0.1rem;
}

.user-profile__gift-selected-count {
  padding: 0.5rem 0;
  font-size: 0.9rem;
  color: var(--color-text-secondary);
}

/* Refresh Button (legacy support) */
.user-profile__refresh-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 500;
}

.user-profile__refresh-icon {
  font-size: 1.25rem;
}

.user-profile__breadcrumbs :deep(.v-breadcrumbs) {
  padding: 0;
}

.user-profile__breadcrumbs :deep(.v-breadcrumbs-item) {
  color: var(--color-text-secondary);
  font-weight: 500;
}

.user-profile__breadcrumb-divider {
  color: var(--color-text-muted);
  font-size: 0.625rem;
}

/* Loading */
.user-profile__loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  min-height: 400px;
  color: var(--color-text-secondary);
}

/* Content */
.user-profile__content {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.user-profile__layout {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

@media (min-width: 1024px) {
  .user-profile__layout {
    flex-direction: row;
    align-items: flex-start;
  }
}

/* Profile Card */
.user-profile__card {
  display: flex;
  flex-direction: column;
  background-color: var(--color-bg-card);
  border-radius: 1rem;
  box-shadow: 0 4px 6px -1px var(--color-shadow);
  overflow: hidden;
  transition: background-color 0.3s ease, box-shadow 0.3s ease;
}

@media (min-width: 1024px) {
  .user-profile__card {
    width: 340px;
    flex-shrink: 0;
  }
}

/* Header */
.user-profile__header {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0 1rem 1rem;
}

.user-profile__header-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 100px;
  background: linear-gradient(135deg, var(--color-accent) 0%, var(--color-accent-secondary) 100%);
  border-radius: 0 0 50% 50% / 0 0 20px 20px;
}

.user-profile__avatar-wrapper {
  position: relative;
  z-index: 1;
  margin-top: 40px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.user-profile__avatar {
  position: relative;
  width: 120px;
  height: 120px;
}

@media (min-width: 600px) {
  .user-profile__avatar {
    width: 140px;
    height: 140px;
  }
}

.user-profile__avatar-img {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
  border: 4px solid var(--color-bg-card);
  box-shadow: 0 4px 12px var(--color-shadow);
}

.user-profile__avatar-placeholder {
  width: 100% !important;
  height: 100% !important;
  border-radius: 50% !important;
  background-color: var(--color-bg-tertiary) !important;
  color: var(--color-text-muted) !important;
}

.user-profile__avatar-initials {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, var(--color-accent) 0%, var(--color-accent-secondary) 100%);
  color: white;
  font-size: 2.5rem;
  font-weight: 700;
  border: 4px solid var(--color-bg-card);
  box-shadow: 0 4px 12px var(--color-shadow);
  text-transform: uppercase;
}

.user-profile__avatar-edit {
  position: absolute;
  bottom: 4px;
  right: 4px;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--color-accent);
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  transition: transform 0.2s ease, background-color 0.2s ease;
}

.user-profile__avatar-edit:hover {
  transform: scale(1.1);
  background-color: var(--color-accent-secondary);
}

.user-profile__file-input {
  display: none;
}

.user-profile__name {
  margin-top: 1rem;
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text-primary);
  text-align: center;
}

/* Divider */
.user-profile__divider {
  height: 1px;
  margin: 0 1.5rem;
  background-color: var(--color-border);
}

/* Info */
.user-profile__info {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1.5rem;
}

.user-profile__info-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.user-profile__info-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background-color: var(--color-bg-tertiary);
  color: var(--color-accent);
  font-size: 1.25rem;
  flex-shrink: 0;
  transition: background-color 0.3s ease;
}

.user-profile__info-content {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.user-profile__info-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.user-profile__info-value {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

/* Role section */
.user-profile__role-section {
  padding: 1rem 1.5rem 1.5rem;
  display: flex;
  justify-content: center;
}

.user-profile__role-btn {
  width: 100%;
  max-width: 240px;
}

/* Stats Section */
.user-profile__stats {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 600px) {
  .user-profile__stats {
    gap: 1.25rem;
  }
}

/* Main Stats - Big Cards */
.user-profile__main-stats {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

@media (min-width: 600px) {
  .user-profile__main-stats {
    grid-template-columns: repeat(2, 1fr);
  }
}

.user-profile__big-stat {
  position: relative;
  display: flex;
  flex-direction: column;
  padding: 1.5rem;
  border-radius: 1.25rem;
  overflow: hidden;
  min-height: 140px;
}

@media (min-width: 600px) {
  .user-profile__big-stat {
    padding: 1.75rem;
    min-height: 160px;
  }
}

.user-profile__big-stat--primary {
  background: linear-gradient(135deg, #98B35D 0%, #7A9A45 100%);
  color: white;
}

.user-profile__big-stat--secondary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.user-profile__big-stat-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}

.user-profile__big-stat-icon {
  font-size: 1.25rem;
  opacity: 0.9;
}

.user-profile__big-stat-label {
  font-size: 0.875rem;
  font-weight: 500;
  opacity: 0.9;
}

.user-profile__big-stat-value {
  font-size: 2rem;
  font-weight: 800;
  line-height: 1;
  margin-bottom: 0.25rem;
}

@media (min-width: 600px) {
  .user-profile__big-stat-value {
    font-size: 2.5rem;
  }
}

.user-profile__big-stat-suffix {
  font-size: 0.875rem;
  font-weight: 500;
  opacity: 0.8;
}

.user-profile__big-stat-bg {
  position: absolute;
  right: -10px;
  bottom: -10px;
  font-size: 6rem;
  opacity: 0.15;
  pointer-events: none;
}

@media (min-width: 600px) {
  .user-profile__big-stat-bg {
    font-size: 7rem;
  }
}

/* Mini Stats */
.user-profile__mini-stats {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .user-profile__mini-stats {
    grid-template-columns: repeat(4, 1fr);
    gap: 1rem;
  }
}

.user-profile__mini-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  padding: 1.25rem 1rem;
  background-color: var(--color-bg-card);
  border-radius: 1rem;
  box-shadow: 0 2px 8px var(--color-shadow);
  transition: all 0.3s ease;
}

.user-profile__mini-stat:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 16px var(--color-shadow);
}

.user-profile__mini-stat-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  font-size: 1.5rem;
}

.user-profile__mini-stat-icon--discount {
  background: linear-gradient(135deg, rgba(33, 150, 243, 0.15) 0%, rgba(33, 150, 243, 0.25) 100%);
  color: #2196F3;
}

.user-profile__mini-stat-icon--gifts {
  background: linear-gradient(135deg, rgba(233, 30, 99, 0.15) 0%, rgba(233, 30, 99, 0.25) 100%);
  color: #E91E63;
}

.user-profile__mini-stat-icon--orders {
  background: linear-gradient(135deg, rgba(255, 152, 0, 0.15) 0%, rgba(255, 152, 0, 0.25) 100%);
  color: #FF9800;
}

.user-profile__mini-stat-icon--referrals {
  background: linear-gradient(135deg, rgba(0, 188, 212, 0.15) 0%, rgba(0, 188, 212, 0.25) 100%);
  color: #00BCD4;
}

.user-profile__mini-stat-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.125rem;
}

.user-profile__mini-stat-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
}

.user-profile__mini-stat-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  text-align: center;
}

/* Info Cards */
.user-profile__info-cards {
  display: grid;
  grid-template-columns: 1fr;
  gap: 0.75rem;
}

@media (min-width: 480px) {
  .user-profile__info-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}

.user-profile__info-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem 1.25rem;
  background-color: var(--color-bg-card);
  border-radius: 0.875rem;
  border-left: 4px solid var(--color-border);
  transition: all 0.3s ease;
}

.user-profile__info-card:hover {
  border-left-color: var(--color-accent);
  transform: translateX(4px);
}

.user-profile__info-card-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 0.625rem;
  background-color: var(--color-bg-tertiary);
  color: var(--color-text-muted);
  font-size: 1.25rem;
  flex-shrink: 0;
  transition: all 0.3s ease;
}

.user-profile__info-card:hover .user-profile__info-card-icon {
  background-color: var(--color-accent-light);
  color: var(--color-accent);
}

.user-profile__info-card-icon--loyalty {
  background-color: rgba(255, 193, 7, 0.15);
  color: #FFC107;
}

.user-profile__loyalty-emoji {
  font-size: 1.25rem;
  line-height: 1;
}

.user-profile__info-card-icon--verified {
  background-color: rgba(76, 175, 80, 0.15);
  color: #4CAF50;
}

.user-profile__info-card-icon--unverified {
  background-color: rgba(158, 158, 158, 0.15);
  color: #9E9E9E;
}

.user-profile__info-card-content {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
  min-width: 0;
}

.user-profile__info-card-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.user-profile__info-card-value {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.user-profile__info-card-value--loyalty {
  color: #FFC107;
}

.user-profile__info-card-value--verified {
  color: #4CAF50;
}

/* Actions */
.user-profile__actions {
  display: flex;
  justify-content: flex-start;
}

.user-profile__delete-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.user-profile__delete-icon {
  font-size: 1.25rem;
}

/* Purchase History */
.user-profile__purchases {
  margin-top: 1rem;
  background-color: var(--color-bg-card);
  border-radius: 1rem;
  padding: 1.25rem;
  box-shadow: 0 2px 8px var(--color-shadow);
}

.user-profile__purchases-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid var(--color-border);
}

.user-profile__purchases-icon {
  font-size: 1.5rem;
  color: var(--color-accent);
}

.user-profile__purchases-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.user-profile__purchases-loading,
.user-profile__purchases-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 2rem 1rem;
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.user-profile__purchases-empty-icon {
  font-size: 2.5rem;
  opacity: 0.5;
}

.user-profile__purchases-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 300px;
  overflow-y: auto;
}

.user-profile__purchase-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  background-color: var(--color-bg-tertiary);
  border-radius: 0.5rem;
  transition: background-color 0.2s ease;
}

.user-profile__purchase-item:hover {
  background-color: var(--color-bg-hover);
}

.user-profile__purchase-date {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
}

.user-profile__purchase-date .icon {
  font-size: 1rem;
  color: var(--color-text-muted);
}

.user-profile__purchase-amount {
  font-weight: 600;
  color: var(--color-accent);
  font-size: 0.9375rem;
}

/* iOS-style Toggle для отсрочки */
.user-profile__delay-toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  margin-top: 0.75rem;
  background: var(--color-bg-secondary);
  border-radius: 12px;
  border: 1px solid var(--color-border);
}

.user-profile__delay-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.user-profile__delay-label {
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.user-profile__delay-hint {
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
.user-profile__delay-toggle--disabled {
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
</style>
