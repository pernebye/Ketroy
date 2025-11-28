<template>
  <div class="promotions-grid">
    <div class="promotions-grid__header">
      <p class="promotions-grid__title">{{ title }}</p>
      <div class="promotions-grid__header-actions">
        <!-- Переключатель архива -->
        <v-btn
          :color="showArchive ? 'warning' : 'default'"
          :variant="showArchive ? 'flat' : 'outlined'"
          size="small"
          rounded="lg"
          :prepend-icon="showArchive ? 'mdi-archive' : 'mdi-archive-outline'"
          @click="toggleArchiveMode"
        >
          {{ showArchive ? 'Выйти из архива' : 'Архив' }}
        </v-btn>
        <btn 
          v-if="!showArchive"
          text="Добавить акцию" 
          prepend-icon="mdi-plus" 
          @click="$router.push({ name: 'adds-tab@id', params: { tab: 'discounts', id: 'new' } })"
        />
      </div>
    </div>

    <div v-if="isLoading" class="promotions-grid__loading">
      <v-progress-circular indeterminate color="var(--color-accent)" :size="48" :width="4" />
      <span>{{ showArchive ? 'Загрузка архива...' : 'Загрузка акций...' }}</span>
    </div>

    <div v-else-if="!displayItems.length" class="promotions-grid__empty">
      <Icon :name="showArchive ? 'mdi:archive-off-outline' : 'mdi:tag-off-outline'" class="promotions-grid__empty-icon" />
      <p>{{ showArchive ? 'Архив пуст' : 'Нет акций' }}</p>
      <span>{{ showArchive ? 'Архивированные акции появятся здесь' : 'Создайте первую акцию' }}</span>
    </div>

    <div v-else class="promotions-grid__content">
      <TransitionGroup name="card-item" tag="div" class="promotions-grid__items">
        <div 
          v-for="promo in paginatedItems" 
          :key="promo.id"
          class="promo-card"
          :class="[
            `promo-card--${promo.type}`,
            { 'promo-card--archived': showArchive },
            { 'promo-card--inactive': !promo.is_active && !showArchive }
          ]"
          @click="navigateToPromo(promo)"
        >
          <!-- Индикатор типа -->
          <div class="promo-card__type-badge">
            <Icon :name="getTypeIcon(promo.type)" class="promo-card__type-icon" />
            <span>{{ getTypeName(promo.type) }}</span>
          </div>

          <!-- Бейдж архива -->
          <div v-if="showArchive" class="promo-card__archived-badge">
            <Icon name="mdi:archive" />
            Архив
          </div>

          <!-- Тумблер активности (только в обычном режиме) -->
          <div v-if="!showArchive" class="promo-card__toggle" @click.stop>
            <v-switch
              :model-value="promo.is_active"
              density="compact"
              hide-details
              color="success"
              class="promo-card__switch"
              :loading="togglingId === promo.id"
              :disabled="togglingId === promo.id"
              @update:model-value="(val: boolean) => toggleActive(promo, val)"
            />
          </div>

          <!-- Контент -->
          <div class="promo-card__content">
            <h3 class="promo-card__name">{{ promo.name }}</h3>
            <p v-if="promo.description" class="promo-card__desc">{{ truncate(promo.description, 80) }}</p>
            
            <!-- Информация о настройках -->
            <div class="promo-card__meta">
              <!-- Для single_purchase -->
              <div v-if="promo.type === 'single_purchase' && getSettings(promo).min_purchase_amount" class="promo-card__meta-item">
                <Icon name="mdi:cash" />
                <span>от {{ formatPrice(getSettings(promo).min_purchase_amount) }} ₸</span>
              </div>
              
              <!-- Для birthday -->
              <div v-if="promo.type === 'birthday'" class="promo-card__meta-item">
                <Icon name="mdi:bell-ring" />
                <span>{{ getNotificationsCount(promo) }} {{ getNotificationsWord(getNotificationsCount(promo)) }}</span>
              </div>
              <div v-if="promo.type === 'birthday'" class="promo-card__meta-item">
                <Icon name="mdi:information-outline" />
                <span>Скидка определяется в 1С</span>
              </div>
              
              <!-- Для date_based -->
              <div v-if="promo.type === 'date_based' && promo.start_date" class="promo-card__meta-item">
                <Icon name="mdi:calendar-range" />
                <span>{{ formatDateRange(promo.start_date, promo.end_date) }}</span>
              </div>
            </div>

            <!-- Подарки -->
            <div v-if="promo.gifts && promo.gifts.length" class="promo-card__gifts">
              <span class="promo-card__gifts-label">Подарки:</span>
              <div class="promo-card__gifts-images">
                <div 
                  v-for="(gift, idx) in promo.gifts.slice(0, 3)" 
                  :key="idx"
                  class="promo-card__gift-thumb"
                >
                  <img 
                    v-if="gift.gift_catalog?.image_url || gift.gift_catalog?.image" 
                    :src="gift.gift_catalog?.image_url || gift.gift_catalog?.image" 
                    :alt="gift.gift_catalog?.name"
                  />
                  <Icon v-else name="mdi:gift" />
                </div>
                <div v-if="promo.gifts.length > 3" class="promo-card__gift-more">
                  +{{ promo.gifts.length - 3 }}
                </div>
              </div>
            </div>
          </div>

          <!-- Кнопки действий -->
          <div class="promo-card__actions">
            <!-- В режиме архива -->
            <template v-if="showArchive">
              <button 
                class="promo-card__action promo-card__action--restore" 
                :disabled="actionLoadingId === promo.id"
                @click.stop="restoreFromArchive(promo)"
              >
                <v-progress-circular v-if="actionLoadingId === promo.id" indeterminate size="16" width="2" />
                <Icon v-else name="mdi:archive-arrow-up-outline" />
                <span>Восстановить</span>
              </button>
              <button 
                class="promo-card__action promo-card__action--delete" 
                :disabled="actionLoadingId === promo.id"
                @click.stop="deletePromo(promo)"
              >
                <Icon name="mdi:delete-outline" />
              </button>
            </template>
            <!-- В обычном режиме -->
            <template v-else>
              <button class="promo-card__action promo-card__action--edit" @click.stop="navigateToPromo(promo)">
                <Icon name="mdi:pencil-outline" />
              </button>
              <button 
                class="promo-card__action promo-card__action--archive" 
                :disabled="actionLoadingId === promo.id"
                @click.stop="archivePromo(promo)"
              >
                <v-progress-circular v-if="actionLoadingId === promo.id" indeterminate size="16" width="2" />
                <Icon v-else name="mdi:archive-arrow-down-outline" />
              </button>
            </template>
          </div>
        </div>
      </TransitionGroup>
    </div>

    <!-- Пагинация -->
    <div v-if="displayItems.length > perPage" class="promotions-grid__pagination">
      <v-pagination
        v-model="currentPage"
        :length="totalPages"
        class="promotions-grid__pages"
        rounded="lg"
        next-icon="mdi-menu-right"
        prev-icon="mdi-menu-left"
        :color="'var(--color-accent)'"
        show-first-last-page
      />
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps({
  title: {
    type: String,
    default: 'Акции'
  },
  items: {
    type: Array as PropType<any[]>,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['refresh']);
const router = useRouter();

// Режим архива
const showArchive = ref(false);
const archivedItems = ref<any[]>([]);
const loadingArchived = ref(false);

// Пагинация
const currentPage = ref(1);
const perPage = 8;

// ID акции, которая сейчас переключается
const togglingId = ref<number | null>(null);
const actionLoadingId = ref<number | null>(null);

// Отображаемые элементы в зависимости от режима
const displayItems = computed(() => showArchive.value ? archivedItems.value : props.items);
const isLoading = computed(() => showArchive.value ? loadingArchived.value : props.loading);

const totalPages = computed(() => Math.ceil(displayItems.value.length / perPage));

const paginatedItems = computed(() => {
  const start = (currentPage.value - 1) * perPage;
  return displayItems.value.slice(start, start + perPage);
});

// Типы акций с информацией
const typeInfo: Record<string, { name: string; icon: string; color: string }> = {
  single_purchase: { name: 'По разовой покупке', icon: 'mdi:shopping', color: '#8B5CF6' },
  accumulation: { name: 'По разовой покупке', icon: 'mdi:shopping', color: '#8B5CF6' }, // legacy
  friend_discount: { name: 'Подари скидку другу', icon: 'mdi:account-multiple', color: '#3B82F6' },
  date_based: { name: 'Лотерея по датам', icon: 'mdi:calendar-star', color: '#F59E0B' },
  birthday: { name: 'День рождения', icon: 'mdi:cake-variant', color: '#EC4899' },
};

function getTypeIcon(type: string): string {
  return typeInfo[type]?.icon || 'mdi:tag';
}

function getTypeName(type: string): string {
  return typeInfo[type]?.name || type;
}

function getSettings(promo: any): any {
  if (!promo.settings) return {};
  return typeof promo.settings === 'string' ? JSON.parse(promo.settings) : promo.settings;
}

function getNotificationsCount(promo: any): number {
  const settings = getSettings(promo);
  return settings.birthday_notifications?.length || 0;
}

function getNotificationsWord(count: number): string {
  const lastDigit = count % 10;
  const lastTwoDigits = count % 100;
  
  if (lastTwoDigits >= 11 && lastTwoDigits <= 19) return 'уведомлений';
  if (lastDigit === 1) return 'уведомление';
  if (lastDigit >= 2 && lastDigit <= 4) return 'уведомления';
  return 'уведомлений';
}

function truncate(text: string, length: number): string {
  if (!text) return '';
  return text.length > length ? text.slice(0, length) + '...' : text;
}

function formatPrice(amount: number): string {
  return new Intl.NumberFormat('ru-RU').format(amount);
}

function formatDateRange(start: string, end: string): string {
  const formatDate = (d: string) => {
    const date = new Date(d);
    return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
  };
  return `${formatDate(start)} — ${formatDate(end)}`;
}

function navigateToPromo(promo: any) {
  router.push({ name: 'adds-tab@id', params: { tab: 'discounts', id: promo.id } });
}

// Загрузка архивированных акций
async function loadArchivedItems() {
  loadingArchived.value = true;
  try {
    const response = await api.discounts.getArchived();
    archivedItems.value = Array.isArray(response) ? response : (response?.data || []);
  } catch (err) {
    console.error('Failed to load archived promotions:', err);
    archivedItems.value = [];
  } finally {
    loadingArchived.value = false;
  }
}

// Переключение режима архива
async function toggleArchiveMode() {
  showArchive.value = !showArchive.value;
  currentPage.value = 1;
  
  if (showArchive.value && archivedItems.value.length === 0) {
    await loadArchivedItems();
  }
}

async function toggleActive(promo: any, newValue: boolean) {
  togglingId.value = promo.id;
  try {
    await api.discounts.toggleActive(promo.id, newValue);
    promo.is_active = newValue;
    showToaster('success', newValue ? 'Акция активирована' : 'Акция деактивирована');
  } catch (err) {
    console.error('Toggle active error:', err);
    showToaster('error', 'Ошибка изменения статуса');
  } finally {
    togglingId.value = null;
  }
}

// Архивировать акцию
async function archivePromo(promo: any) {
  actionLoadingId.value = promo.id;
  try {
    await api.discounts.archive(promo.id);
    showToaster('success', 'Акция архивирована');
    // Перемещаем в архивный список
    archivedItems.value.unshift({ ...promo, is_archived: true, is_active: false });
    emit('refresh');
  } catch (err) {
    console.error('Archive error:', err);
    showToaster('error', 'Ошибка архивации');
  } finally {
    actionLoadingId.value = null;
  }
}

// Восстановить из архива
async function restoreFromArchive(promo: any) {
  actionLoadingId.value = promo.id;
  try {
    await api.discounts.archive(promo.id);
    showToaster('success', 'Акция восстановлена из архива');
    // Удаляем из архивного списка
    archivedItems.value = archivedItems.value.filter(p => p.id !== promo.id);
    emit('refresh');
  } catch (err) {
    console.error('Restore error:', err);
    showToaster('error', 'Ошибка восстановления');
  } finally {
    actionLoadingId.value = null;
  }
}

// Удалить акцию (только из архива)
async function deletePromo(promo: any) {
  if (!confirm('Вы уверены, что хотите удалить акцию? Это действие нельзя отменить.')) {
    return;
  }
  
  actionLoadingId.value = promo.id;
  try {
    await api.discounts.delete(promo.id);
    showToaster('success', 'Акция удалена');
    archivedItems.value = archivedItems.value.filter(p => p.id !== promo.id);
  } catch (err) {
    console.error('Delete error:', err);
    showToaster('error', 'Ошибка удаления');
  } finally {
    actionLoadingId.value = null;
  }
}

watch(() => props.items, () => {
  if (currentPage.value > totalPages.value && totalPages.value > 0) {
    currentPage.value = totalPages.value;
  }
});

watch(displayItems, () => {
  if (currentPage.value > totalPages.value && totalPages.value > 0) {
    currentPage.value = totalPages.value;
  }
});
</script>

<style scoped>
.promotions-grid {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .promotions-grid {
    gap: 1.5rem;
  }
}

@media (min-width: 960px) {
  .promotions-grid {
    gap: 2rem;
  }
}

.promotions-grid__header {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .promotions-grid__header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }
}

.promotions-grid__header-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.promotions-grid__title {
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0;
}

@media (min-width: 600px) {
  .promotions-grid__title {
    font-size: 1.5rem;
  }
}

.promotions-grid__loading,
.promotions-grid__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 3rem;
  color: var(--color-text-secondary);
}

.promotions-grid__empty-icon {
  font-size: 3rem;
  opacity: 0.5;
}

.promotions-grid__empty p {
  font-weight: 600;
  font-size: 1.125rem;
  margin: 0;
}

.promotions-grid__content {
  display: flex;
  flex-direction: column;
}

.promotions-grid__items {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 1rem;
}

@media (min-width: 600px) {
  .promotions-grid__items {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (min-width: 960px) {
  .promotions-grid__items {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (min-width: 1280px) {
  .promotions-grid__items {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}

/* Карточка акции */
.promo-card {
  position: relative;
  display: flex;
  flex-direction: column;
  padding: 1.25rem;
  border-radius: 1.125rem;
  background: var(--color-bg-card);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  min-width: 0; /* Важно для grid - позволяет карточке сжиматься */
  overflow: hidden;
}

.promo-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.15);
}

/* Цвета по типам */
.promo-card--single_purchase .promo-card__type-badge,
.promo-card--accumulation .promo-card__type-badge {
  background: rgba(139, 92, 246, 0.15);
  color: #8B5CF6;
}

.promo-card--friend_discount .promo-card__type-badge {
  background: rgba(59, 130, 246, 0.15);
  color: #3B82F6;
}

.promo-card--date_based .promo-card__type-badge {
  background: rgba(245, 158, 11, 0.15);
  color: #F59E0B;
}

.promo-card--birthday .promo-card__type-badge {
  background: rgba(236, 72, 153, 0.15);
  color: #EC4899;
}

/* Архивная карточка */
.promo-card--archived {
  opacity: 0.85;
  background: var(--color-bg-secondary);
}

.promo-card--archived:hover {
  opacity: 1;
}

.promo-card--archived .promo-card__type-badge {
  background: var(--color-bg-tertiary);
  color: var(--color-text-muted);
}

/* Бейдж архива */
.promo-card__archived-badge {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.5rem;
  border-radius: 0.375rem;
  background: rgba(245, 158, 11, 0.15);
  color: #F59E0B;
  font-size: 0.6875rem;
  font-weight: 600;
  text-transform: uppercase;
}

.promo-card__archived-badge :deep(.iconify) {
  font-size: 0.75rem;
}

/* Неактивная карточка */
.promo-card--inactive {
  opacity: 0.7;
}
.promo-card--inactive::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.03);
  border-radius: inherit;
  pointer-events: none;
}

/* Бейдж типа */
.promo-card__type-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.75rem;
  border-radius: 0.5rem;
  font-size: 0.75rem;
  font-weight: 700;
  width: fit-content;
  max-width: 100%;
  margin-bottom: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.4px;
  backdrop-filter: blur(10px);
  overflow: hidden;
}

.promo-card__type-badge span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.promo-card__type-icon {
  font-size: 0.9375rem;
  flex-shrink: 0;
}

/* Тумблер активности */
.promo-card__toggle {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  z-index: 2;
}

.promo-card__switch {
  margin: 0 !important;
  padding: 0 !important;
}

.promo-card__switch :deep(.v-switch__track) {
  width: 44px !important;
  height: 24px !important;
  border-radius: 12px !important;
  background-color: rgba(120, 120, 128, 0.32) !important;
  opacity: 1 !important;
}

.promo-card__switch :deep(.v-switch--inset .v-switch__track) {
  box-shadow: none !important;
}

.promo-card__switch :deep(.v-selection-control--dirty .v-switch__track) {
  background-color: #34C759 !important;
}

.promo-card__switch :deep(.v-switch__thumb) {
  width: 20px !important;
  height: 20px !important;
  background-color: white !important;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2) !important;
  transform: none !important;
  position: absolute !important;
  left: 2px !important;
  top: 2px !important;
  transition: left 0.2s ease !important;
}

.promo-card__switch :deep(.v-selection-control--dirty .v-switch__thumb) {
  left: 22px !important;
}

.promo-card__switch :deep(.v-selection-control__wrapper) {
  height: 24px !important;
  width: 44px !important;
}

.promo-card__switch :deep(.v-selection-control__input) {
  width: 44px !important;
  height: 24px !important;
  transform: none !important;
}

.promo-card__switch :deep(.v-selection-control__input > .v-icon) {
  display: none !important;
}

/* Контент */
.promo-card__content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  min-width: 0; /* Важно для flex - позволяет сжиматься */
  overflow: hidden;
}

.promo-card__name {
  font-size: 1.0625rem;
  font-weight: 700;
  margin: 0;
  color: var(--color-text-primary);
  padding-right: 4rem;
  letter-spacing: -0.3px;
  word-wrap: break-word;
  overflow-wrap: break-word;
  hyphens: auto;
}

.promo-card--archived .promo-card__name {
  padding-right: 0;
}

.promo-card__desc {
  font-size: 0.8375rem;
  color: var(--color-text-muted);
  margin: 0;
  line-height: 1.5;
  word-wrap: break-word;
  overflow-wrap: break-word;
}

/* Мета информация */
.promo-card__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

.promo-card__meta-item {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  background: var(--color-bg-tertiary);
  padding: 0.25rem 0.5rem;
  border-radius: 0.375rem;
  max-width: 100%;
  word-wrap: break-word;
  overflow-wrap: break-word;
}

.promo-card__meta-item span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 150px;
}

.promo-card__meta-item :deep(.iconify) {
  font-size: 0.875rem;
  opacity: 0.7;
  flex-shrink: 0;
}

/* Подарки */
.promo-card__gifts {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.5rem;
}

.promo-card__gifts-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.promo-card__gifts-images {
  display: flex;
  gap: -0.25rem;
}

.promo-card__gift-thumb {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  overflow: hidden;
  background: var(--color-bg-tertiary);
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid var(--color-bg-secondary);
  margin-left: -6px;
}

.promo-card__gift-thumb:first-child {
  margin-left: 0;
}

.promo-card__gift-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.promo-card__gift-thumb :deep(.iconify) {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.promo-card__gift-more {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: var(--color-bg-tertiary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.625rem;
  font-weight: 600;
  color: var(--color-text-secondary);
  border: 2px solid var(--color-bg-secondary);
  margin-left: -6px;
}

/* Кнопки действий */
.promo-card__actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px solid var(--color-border);
  min-width: 0;
}

.promo-card__action {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.375rem;
  padding: 0.5rem;
  border: none;
  border-radius: 0.5rem;
  background: var(--color-bg-tertiary);
  color: var(--color-text-secondary);
  font-size: 0.8125rem;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 0;
  overflow: hidden;
}

.promo-card__action span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.promo-card__action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.promo-card__action:hover:not(:disabled) {
  background: var(--color-bg-hover);
}

.promo-card__action--edit:hover:not(:disabled) {
  color: var(--color-accent);
}

.promo-card__action--archive:hover:not(:disabled) {
  color: #F59E0B;
}

.promo-card__action--restore {
  flex: 2;
}

.promo-card__action--restore:hover:not(:disabled) {
  color: #10B981;
  background: rgba(16, 185, 129, 0.1);
}

.promo-card__action--delete:hover:not(:disabled) {
  color: #EF4444;
  background: rgba(239, 68, 68, 0.1);
}

.promo-card__action :deep(.iconify) {
  font-size: 1.125rem;
}

/* Пагинация */
.promotions-grid__pagination {
  display: flex;
  justify-content: center;
  padding-top: 1rem;
  border-top: 1px solid var(--color-border);
}

.promotions-grid__pages :deep(.v-pagination__item),
.promotions-grid__pages :deep(.v-pagination__first),
.promotions-grid__pages :deep(.v-pagination__prev),
.promotions-grid__pages :deep(.v-pagination__next),
.promotions-grid__pages :deep(.v-pagination__last) {
  background-color: var(--color-bg-tertiary) !important;
  border-radius: 8px !important;
}

.promotions-grid__pages :deep(.v-pagination__item .v-btn__content) {
  font-weight: 600;
  color: var(--color-text-primary) !important;
}

.promotions-grid__pages :deep(.v-pagination__item.v-pagination__item--is-active) {
  background-color: var(--color-accent) !important;
}

.promotions-grid__pages :deep(.v-pagination__item.v-pagination__item--is-active .v-btn__content) {
  color: var(--color-text-inverse) !important;
}

/* Анимации */
.card-item-enter-active,
.card-item-leave-active {
  transition: all 0.3s ease;
}

.card-item-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.card-item-leave-to {
  opacity: 0;
  transform: scale(0.9);
}

.card-item-move {
  transition: transform 0.3s ease;
}
</style>
