<template>
  <section class="referral-analytics">
    <!-- Общий header с табами -->
    <div class="referral-analytics__page-header">
      <h1 class="referral-analytics__page-title">Аналитика</h1>
      <div class="referral-analytics__tabs">
        <NuxtLink to="/analytics" class="referral-analytics__tab">
          <Icon name="mdi:chart-line" />
          <span>Просмотры контента</span>
        </NuxtLink>
        <NuxtLink to="/analytics/social" class="referral-analytics__tab">
          <Icon name="mdi:share-variant" />
          <span>Клики по соцсетям</span>
        </NuxtLink>
        <NuxtLink to="/analytics/referral" class="referral-analytics__tab referral-analytics__tab--active">
          <Icon name="mdi:gift-outline" />
          <span>Подари скидку другу</span>
        </NuxtLink>
      </div>
    </div>

    <div class="referral-analytics__layout">
      <!-- Sidebar с фильтрами -->
      <aside class="referral-analytics__sidebar">
        <div class="referral-analytics__header">
          <h2 class="referral-analytics__title">
            <Icon name="mdi:gift-outline" class="referral-analytics__title-icon" />
            Подари скидку другу
          </h2>
          <p class="referral-analytics__subtitle">Статистика реферальной программы</p>
        </div>

        <!-- Быстрые пресеты -->
        <div class="referral-analytics__presets">
          <button 
            v-for="preset in datePresets" 
            :key="preset.value"
            class="referral-analytics__preset"
            :class="{ 'referral-analytics__preset--active': activePreset === preset.value }"
            @click="applyPreset(preset.value)"
          >
            {{ preset.label }}
          </button>
        </div>

        <!-- Date Range Picker -->
        <v-menu v-model="datePickerOpen" :close-on-content-click="false" location="bottom">
          <template v-slot:activator="{ props }">
            <v-text-field
              v-bind="props"
              :model-value="dateRangeDisplay"
              label="Период"
              readonly
              density="compact"
              variant="outlined"
              hide-details
              rounded="lg"
              prepend-inner-icon="mdi-calendar-range"
              class="referral-analytics__date-input"
            />
          </template>
          <v-card class="referral-analytics__date-picker">
            <v-date-picker v-model="dateRange" multiple="range" show-adjacent-months :max="today" color="primary" />
            <v-card-actions>
              <v-spacer />
              <v-btn variant="text" @click="datePickerOpen = false">Отмена</v-btn>
              <v-btn color="primary" variant="flat" @click="applyDateRange">Применить</v-btn>
            </v-card-actions>
          </v-card>
        </v-menu>

        <!-- Информация об акции -->
        <div class="referral-analytics__promo-info" v-if="statsData?.data.promotion">
          <div class="referral-analytics__promo-header">
            <span class="referral-analytics__promo-status" :class="{ 'referral-analytics__promo-status--active': statsData.data.promotion.is_active }">
              {{ statsData.data.promotion.is_active ? 'Активна' : 'Неактивна' }}
            </span>
          </div>
          <div class="referral-analytics__promo-details">
            <div class="referral-analytics__promo-item">
              <span class="referral-analytics__promo-label">Скидка новому пользователю</span>
              <span class="referral-analytics__promo-value">{{ statsData.data.promotion.new_user_discount_percent }}%</span>
            </div>
            <div class="referral-analytics__promo-item">
              <span class="referral-analytics__promo-label">Бонус рефереру</span>
              <span class="referral-analytics__promo-value">{{ statsData.data.promotion.referrer_bonus_percent }}%</span>
            </div>
            <div class="referral-analytics__promo-item">
              <span class="referral-analytics__promo-label">Макс. покупок для бонуса</span>
              <span class="referral-analytics__promo-value">{{ statsData.data.promotion.referrer_max_purchases }}</span>
            </div>
          </div>
        </div>

        <!-- Статистика за всё время -->
        <div class="referral-analytics__total-stat" v-if="statsData">
          <Icon name="mdi:account-group" class="referral-analytics__total-icon" />
          <div class="referral-analytics__total-content">
            <span class="referral-analytics__total-value">{{ statsData.data.total_applied_all_time }}</span>
            <span class="referral-analytics__total-label">Всего применений за всё время</span>
          </div>
        </div>
      </aside>

      <!-- Основной контент -->
      <div class="referral-analytics__main">
        <!-- Загрузка -->
        <div v-if="isLoading" class="referral-analytics__loading">
          <v-progress-circular indeterminate color="primary" size="48" />
          <span>Загрузка данных...</span>
        </div>

        <template v-else-if="statsData">
          <!-- Карточки с основными метриками -->
          <div class="referral-analytics__cards">
            <div class="referral-analytics__card referral-analytics__card--primary">
              <div class="referral-analytics__card-icon">
                <Icon name="mdi:ticket-percent" />
              </div>
              <div class="referral-analytics__card-content">
                <span class="referral-analytics__card-value">{{ statsData.data.total_applied }}</span>
                <span class="referral-analytics__card-label">Применено промокодов</span>
              </div>
            </div>

            <div class="referral-analytics__card referral-analytics__card--success">
              <div class="referral-analytics__card-icon">
                <Icon name="mdi:account-plus" />
              </div>
              <div class="referral-analytics__card-content">
                <span class="referral-analytics__card-value">{{ statsData.data.new_referred_users }}</span>
                <span class="referral-analytics__card-label">Новых пользователей</span>
              </div>
            </div>

            <div class="referral-analytics__card referral-analytics__card--info">
              <div class="referral-analytics__card-icon">
                <Icon name="mdi:account-star" />
              </div>
              <div class="referral-analytics__card-content">
                <span class="referral-analytics__card-value">{{ statsData.data.unique_referrers }}</span>
                <span class="referral-analytics__card-label">Уникальных рефереров</span>
              </div>
            </div>

            <div class="referral-analytics__card referral-analytics__card--warning">
              <div class="referral-analytics__card-icon">
                <Icon name="mdi:percent" />
              </div>
              <div class="referral-analytics__card-content">
                <span class="referral-analytics__card-value">{{ statsData.data.conversion_rate }}%</span>
                <span class="referral-analytics__card-label">Конверсия в покупку</span>
              </div>
            </div>
          </div>

          <!-- Статистика покупок и подарков -->
          <div class="referral-analytics__stats-row">
            <div class="referral-analytics__stat-card">
              <Icon name="mdi:shopping" class="referral-analytics__stat-icon" />
              <div class="referral-analytics__stat-content">
                <span class="referral-analytics__stat-value">{{ statsData.data.referred_with_purchases }}</span>
                <span class="referral-analytics__stat-label">Рефералов с покупками</span>
              </div>
            </div>
            <div class="referral-analytics__stat-card">
              <Icon name="mdi:cart" class="referral-analytics__stat-icon" />
              <div class="referral-analytics__stat-content">
                <span class="referral-analytics__stat-value">{{ statsData.data.purchase_stats.total_purchases }}</span>
                <span class="referral-analytics__stat-label">Покупок рефералов</span>
              </div>
            </div>
            <div class="referral-analytics__stat-card">
              <Icon name="mdi:currency-kzt" class="referral-analytics__stat-icon" />
              <div class="referral-analytics__stat-content">
                <span class="referral-analytics__stat-value">{{ formatAmount(statsData.data.purchase_stats.total_amount) }}</span>
                <span class="referral-analytics__stat-label">Сумма покупок</span>
              </div>
            </div>
            <div class="referral-analytics__stat-card">
              <Icon name="mdi:gift" class="referral-analytics__stat-icon" />
              <div class="referral-analytics__stat-content">
                <span class="referral-analytics__stat-value">{{ statsData.data.gifts_to_referrers }}</span>
                <span class="referral-analytics__stat-label">Подарков выдано</span>
              </div>
            </div>
          </div>

          <!-- График по дням -->
          <div class="referral-analytics__chart">
            <div class="referral-analytics__chart-header">
              <h3 class="referral-analytics__chart-title">Применения промокодов по дням</h3>
              <span class="referral-analytics__chart-period">{{ dateRangeDisplay }}</span>
            </div>
            <div class="referral-analytics__chart-container">
              <LineChart v-if="chartData && hasChartData" :chart-data="chartData" :options="chartOptions" />
              <div v-else class="referral-analytics__chart-empty">
                <Icon name="mdi:chart-line-variant" />
                <span>Нет данных за выбранный период</span>
              </div>
            </div>
          </div>

          <!-- Топ рефереров -->
          <div class="referral-analytics__section" v-if="statsData.data.top_referrers.length">
            <h3 class="referral-analytics__section-title">
              <Icon name="mdi:trophy" />
              Топ рефереров
            </h3>
            <div class="referral-analytics__list">
              <div 
                v-for="(item, index) in statsData.data.top_referrers" 
                :key="item.referrer_id"
                class="referral-analytics__list-item"
              >
                <span class="referral-analytics__list-rank" :class="{ 'referral-analytics__list-rank--top': index < 3 }">
                  {{ index + 1 }}
                </span>
                <div class="referral-analytics__list-user">
                  <span class="referral-analytics__list-name">{{ item.referrer_name }}</span>
                  <span class="referral-analytics__list-phone" v-if="item.referrer_phone">{{ item.referrer_phone }}</span>
                </div>
                <span class="referral-analytics__list-count">{{ item.referred_count }} приглашённых</span>
              </div>
            </div>
          </div>

          <!-- Последние применения -->
          <div class="referral-analytics__section" v-if="statsData.data.recent_applications.length">
            <h3 class="referral-analytics__section-title">
              <Icon name="mdi:history" />
              Последние применения
            </h3>
            <div class="referral-analytics__applications-table-wrapper">
              <table class="referral-analytics__table">
                <thead>
                  <tr>
                    <th>Дата</th>
                    <th>Новый пользователь</th>
                    <th>Реферер</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in statsData.data.recent_applications" :key="item.id">
                    <td class="referral-analytics__table-date">{{ formatDateTime(item.applied_at) }}</td>
                    <td>
                      <div class="referral-analytics__table-user">
                        <span>{{ item.user.name }}</span>
                        <small v-if="item.user.phone">{{ item.user.phone }}</small>
                      </div>
                    </td>
                    <td>
                      <div class="referral-analytics__table-user">
                        <span>{{ item.referrer.name }}</span>
                        <small v-if="item.referrer.phone">{{ item.referrer.phone }}</small>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </template>

        <!-- Пустое состояние -->
        <div v-else class="referral-analytics__empty">
          <Icon name="mdi:gift-off-outline" class="referral-analytics__empty-icon" />
          <p>Нет данных для отображения</p>
          <span>Выберите период и нажмите "Применить"</span>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';

// Пресеты дат
const datePresets = [
  { label: 'Сегодня', value: 'today' },
  { label: '7 дней', value: 'week' },
  { label: '30 дней', value: 'month' },
  { label: '90 дней', value: 'quarter' },
];

const today = new Date();

const formatDateForApi = (date: Date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const getPresetDates = (preset: string): [Date, Date] => {
  const end = new Date();
  const start = new Date();
  
  switch (preset) {
    case 'today':
      return [start, end];
    case 'week':
      start.setDate(start.getDate() - 6);
      return [start, end];
    case 'month':
      start.setDate(start.getDate() - 29);
      return [start, end];
    case 'quarter':
      start.setDate(start.getDate() - 89);
      return [start, end];
    default:
      start.setDate(start.getDate() - 29);
      return [start, end];
  }
};

// State
const activePreset = ref('month');
const datePickerOpen = ref(false);
const dateRange = ref<Date[]>([]);
const startDate = ref(formatDateForApi(getPresetDates('month')[0]));
const endDate = ref(formatDateForApi(getPresetDates('month')[1]));
const statsData = ref<Api.Analytics.ReferralStatisticsResponse | null>(null);
const isLoading = ref(false);
const chartData = ref<any>(null);

// Применить пресет
const applyPreset = (preset: string) => {
  activePreset.value = preset;
  const [start, end] = getPresetDates(preset);
  startDate.value = formatDateForApi(start);
  endDate.value = formatDateForApi(end);
  loadData();
};

// Применить диапазон из календаря
const applyDateRange = () => {
  if (dateRange.value.length >= 2) {
    const sorted = [...dateRange.value].sort((a, b) => a.getTime() - b.getTime());
    startDate.value = formatDateForApi(sorted[0]);
    endDate.value = formatDateForApi(sorted[sorted.length - 1]);
    activePreset.value = '';
    loadData();
  }
  datePickerOpen.value = false;
};

// Отображение периода
const dateRangeDisplay = computed(() => {
  const start = new Date(startDate.value);
  const end = new Date(endDate.value);
  const options: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short', year: 'numeric' };
  
  if (startDate.value === endDate.value) {
    return start.toLocaleDateString('ru-RU', options);
  }
  
  return `${start.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' })} — ${end.toLocaleDateString('ru-RU', options)}`;
});

// Форматирование
const formatDateTime = (dateStr: string) => {
  if (!dateStr) return '—';
  const date = new Date(dateStr);
  return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
};

const formatAmount = (amount: number) => {
  if (!amount) return '0 ₸';
  return new Intl.NumberFormat('ru-RU').format(amount) + ' ₸';
};

const hasChartData = computed(() => {
  return statsData.value?.data.by_date && statsData.value.data.by_date.length > 0;
});

// Загрузка данных
const loadData = async () => {
  isLoading.value = true;
  try {
    const response = await api.analytics.getReferralStatistics(startDate.value, endDate.value);
    statsData.value = response;
    updateChartData();
  } catch (error) {
    console.error('Error loading referral analytics:', error);
  } finally {
    isLoading.value = false;
  }
};

// Обновление графика
const colorMode = useColorMode();
const isDark = computed(() => colorMode.value === 'dark');

const chartColors = computed(() => ({
  textColor: isDark.value ? '#e0e0e0' : '#667085',
  gridColor: isDark.value ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)',
}));

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  interaction: { intersect: false, mode: 'index' as const },
  scales: {
    y: {
      beginAtZero: true,
      grid: { color: chartColors.value.gridColor },
      ticks: { stepSize: 1, color: chartColors.value.textColor },
    },
    x: {
      grid: { display: false },
      ticks: { color: chartColors.value.textColor, maxRotation: 45 },
    },
  },
  plugins: {
    legend: { display: false },
    tooltip: {
      callbacks: {
        label: (item: any) => `Применений: ${item.raw}`,
      },
    },
  },
}));

const updateChartData = () => {
  if (!statsData.value?.data.by_date) return;

  const labels = statsData.value.data.by_date.map((item) => {
    const date = new Date(item.date);
    return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
  });
  const values = statsData.value.data.by_date.map((item) => item.applications);

  chartData.value = {
    labels,
    datasets: [
      {
        label: 'Применения',
        data: values,
        borderColor: '#F59E0B',
        backgroundColor: 'rgba(245, 158, 11, 0.1)',
        tension: 0.4,
        fill: true,
        pointBackgroundColor: '#F59E0B',
        pointBorderColor: '#fff',
        pointBorderWidth: 2,
        pointRadius: labels.length > 30 ? 0 : 4,
        pointHoverRadius: 6,
      },
    ],
  };
};

const layoutStore = useLayoutStore();

onMounted(() => {
  layoutStore.navItem = null;
  loadData();
});
</script>

<style scoped>
.referral-analytics {
  padding: 0;
}

/* Page Header с табами */
.referral-analytics__page-header {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

@media (min-width: 600px) {
  .referral-analytics__page-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }
}

.referral-analytics__page-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
  margin: 0;
}

.referral-analytics__tabs {
  display: flex;
  gap: 0.5rem;
  background: var(--color-bg-secondary);
  padding: 0.25rem;
  border-radius: 0.75rem;
  flex-wrap: wrap;
}

.referral-analytics__tab {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.625rem 1rem;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-secondary);
  text-decoration: none;
  transition: all 0.15s ease;
  white-space: nowrap;
}

.referral-analytics__tab:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-tertiary);
}

.referral-analytics__tab--active {
  color: #F59E0B;
  background: rgba(245, 158, 11, 0.15);
}

.referral-analytics__tab--active:hover {
  background: rgba(245, 158, 11, 0.2);
}

.referral-analytics__layout {
  display: flex;
  gap: 1.5rem;
  flex-direction: column;
}

@media (min-width: 960px) {
  .referral-analytics__layout {
    flex-direction: row;
    align-items: flex-start;
  }
}

/* Sidebar */
.referral-analytics__sidebar {
  width: 100%;
  flex-shrink: 0;
  padding: 1.25rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

@media (min-width: 960px) {
  .referral-analytics__sidebar {
    width: 300px;
  }
}

.referral-analytics__header {
  margin-bottom: 0.5rem;
}

.referral-analytics__title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.referral-analytics__title-icon {
  color: #F59E0B;
  font-size: 1.25rem;
}

.referral-analytics__subtitle {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  margin-top: 0.25rem;
}

/* Presets */
.referral-analytics__presets {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.referral-analytics__preset {
  padding: 0.5rem 0.75rem;
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text-secondary);
  background-color: var(--color-bg-tertiary);
  border: 1px solid transparent;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.15s ease;
}

.referral-analytics__preset:hover {
  color: var(--color-text-primary);
  background-color: var(--color-bg-input);
}

.referral-analytics__preset--active {
  color: #F59E0B;
  background-color: rgba(245, 158, 11, 0.1);
  border-color: #F59E0B;
}

/* Date Picker */
.referral-analytics__date-input {
  cursor: pointer;
}

.referral-analytics__date-input :deep(.v-field) {
  min-height: 44px !important;
  height: 44px !important;
}

.referral-analytics__date-input :deep(.v-field__input) {
  padding-top: 10px !important;
  padding-bottom: 10px !important;
  min-height: 44px !important;
}

.referral-analytics__date-picker {
  background-color: var(--color-bg-secondary) !important;
}

/* Promo Info */
.referral-analytics__promo-info {
  padding: 1rem;
  border-radius: 0.75rem;
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.1) 0%, rgba(245, 158, 11, 0.05) 100%);
  border: 1px solid rgba(245, 158, 11, 0.2);
}

.referral-analytics__promo-header {
  margin-bottom: 0.75rem;
}

.referral-analytics__promo-status {
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  background: rgba(239, 68, 68, 0.2);
  color: #EF4444;
}

.referral-analytics__promo-status--active {
  background: rgba(34, 197, 94, 0.2);
  color: #22C55E;
}

.referral-analytics__promo-details {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.referral-analytics__promo-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.referral-analytics__promo-label {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
}

.referral-analytics__promo-value {
  font-size: 0.875rem;
  font-weight: 600;
  color: #F59E0B;
}

/* Total stat */
.referral-analytics__total-stat {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border-radius: 0.75rem;
  background: var(--color-bg-tertiary);
  border-top: 1px solid var(--color-border-light);
}

.referral-analytics__total-icon {
  font-size: 2rem;
  color: #F59E0B;
}

.referral-analytics__total-content {
  display: flex;
  flex-direction: column;
}

.referral-analytics__total-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
}

.referral-analytics__total-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

/* Main */
.referral-analytics__main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Loading */
.referral-analytics__loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 4rem 2rem;
  color: var(--color-text-muted);
}

/* Cards */
.referral-analytics__cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.referral-analytics__card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
  position: relative;
  overflow: hidden;
}

.referral-analytics__card--primary {
  border-left: 4px solid #F59E0B;
}

.referral-analytics__card--success {
  border-left: 4px solid #22C55E;
}

.referral-analytics__card--info {
  border-left: 4px solid #3B82F6;
}

.referral-analytics__card--warning {
  border-left: 4px solid #A855F7;
}

.referral-analytics__card-icon {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  font-size: 1.5rem;
}

.referral-analytics__card--primary .referral-analytics__card-icon {
  background-color: rgba(245, 158, 11, 0.1);
  color: #F59E0B;
}

.referral-analytics__card--success .referral-analytics__card-icon {
  background-color: rgba(34, 197, 94, 0.1);
  color: #22C55E;
}

.referral-analytics__card--info .referral-analytics__card-icon {
  background-color: rgba(59, 130, 246, 0.1);
  color: #3B82F6;
}

.referral-analytics__card--warning .referral-analytics__card-icon {
  background-color: rgba(168, 85, 247, 0.1);
  color: #A855F7;
}

.referral-analytics__card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.referral-analytics__card-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
}

.referral-analytics__card-label {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
}

/* Stats row */
.referral-analytics__stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
}

.referral-analytics__stat-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-secondary);
}

.referral-analytics__stat-icon {
  font-size: 1.5rem;
  color: #F59E0B;
}

.referral-analytics__stat-content {
  display: flex;
  flex-direction: column;
}

.referral-analytics__stat-value {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.referral-analytics__stat-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

/* Chart */
.referral-analytics__chart {
  padding: 1.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
}

.referral-analytics__chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.referral-analytics__chart-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.referral-analytics__chart-period {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.referral-analytics__chart-container {
  height: 300px;
}

.referral-analytics__chart-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  height: 100%;
  color: var(--color-text-muted);
  font-size: 3rem;
}

.referral-analytics__chart-empty span {
  font-size: 0.875rem;
}

/* Sections */
.referral-analytics__section {
  padding: 1.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
}

.referral-analytics__section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin-bottom: 1rem;
}

/* List */
.referral-analytics__list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.referral-analytics__list-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1rem;
  border-radius: 0.5rem;
  background-color: var(--color-bg-tertiary);
}

.referral-analytics__list-rank {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text-muted);
  background-color: var(--color-bg-secondary);
  border-radius: 50%;
}

.referral-analytics__list-rank--top {
  background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%);
  color: white;
}

.referral-analytics__list-user {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.referral-analytics__list-name {
  font-size: 0.875rem;
  color: var(--color-text-primary);
}

.referral-analytics__list-phone {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.referral-analytics__list-count {
  font-size: 0.8125rem;
  font-weight: 600;
  color: #F59E0B;
}

/* Table */
.referral-analytics__applications-table-wrapper {
  overflow-x: auto;
  max-height: 400px;
  overflow-y: auto;
}

.referral-analytics__table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.875rem;
}

.referral-analytics__table th,
.referral-analytics__table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid var(--color-border-light);
}

.referral-analytics__table th {
  font-weight: 600;
  color: var(--color-text-primary);
  background-color: var(--color-bg-tertiary);
  position: sticky;
  top: 0;
  z-index: 1;
}

.referral-analytics__table td {
  color: var(--color-text-primary);
}

.referral-analytics__table-date {
  white-space: nowrap;
  color: var(--color-text-muted);
  font-size: 0.8125rem;
}

.referral-analytics__table-user {
  display: flex;
  flex-direction: column;
}

.referral-analytics__table-user small {
  color: var(--color-text-muted);
  font-size: 0.75rem;
}

/* Empty */
.referral-analytics__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 4rem 2rem;
  text-align: center;
  color: var(--color-text-muted);
}

.referral-analytics__empty-icon {
  font-size: 4rem;
  opacity: 0.5;
}

.referral-analytics__empty p {
  font-size: 1rem;
  color: var(--color-text-primary);
}
</style>




