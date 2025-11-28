<template>
  <section class="analytics-page">
    <!-- Общий header с табами -->
    <div class="analytics-header">
      <h1 class="analytics-header__title">Аналитика</h1>
      <div class="analytics-tabs">
        <NuxtLink to="/analytics" class="analytics-tab analytics-tab--active">
          <Icon name="mdi:chart-line" />
          <span>Просмотры контента</span>
        </NuxtLink>
        <NuxtLink to="/analytics/social" class="analytics-tab">
          <Icon name="mdi:share-variant" />
          <span>Клики по соцсетям</span>
        </NuxtLink>
        <NuxtLink to="/analytics/referral" class="analytics-tab">
          <Icon name="mdi:gift-outline" />
          <span>Подари скидку другу</span>
        </NuxtLink>
      </div>
    </div>

    <div class="analytics-layout">
      <!-- Left Block - Controls -->
      <aside class="analytics-sidebar">
        <div class="analytics-sidebar__header">
          <h2 class="analytics-sidebar__title">Просмотры контента</h2>
          <p class="analytics-sidebar__subtitle">Статистика просмотров</p>
        </div>

        <div class="analytics-sidebar__controls">
          <v-select 
            v-model="selectedAnalytics" 
            :items="analyticsTypes" 
            label="Тип контента" 
            density="compact" 
            variant="outlined" 
            hide-details 
            rounded="lg" 
          />

          <!-- Быстрые пресеты -->
          <div class="analytics-presets">
            <button 
              v-for="preset in datePresets" 
              :key="preset.value"
              class="analytics-preset"
              :class="{ 'analytics-preset--active': activePreset === preset.value }"
              @click="applyPreset(preset.value)"
            >
              {{ preset.label }}
            </button>
          </div>

          <!-- Date Range Picker -->
          <v-menu 
            v-model="datePickerOpen" 
            :close-on-content-click="false"
            location="bottom"
          >
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
                class="analytics-date-input"
              />
            </template>
            <v-card class="analytics-date-picker">
              <v-date-picker
                v-model="dateRange"
                multiple="range"
                show-adjacent-months
                :max="today"
                color="primary"
              />
              <v-card-actions>
                <v-spacer />
                <v-btn variant="text" @click="datePickerOpen = false">Отмена</v-btn>
                <v-btn color="primary" variant="flat" @click="applyDateRange">Применить</v-btn>
              </v-card-actions>
            </v-card>
          </v-menu>
        </div>

        <!-- Общая статистика -->
        <div class="analytics-sidebar__stats">
          <div class="analytics-stat">
            <span class="analytics-stat__value">{{ totalViews }}</span>
            <span class="analytics-stat__label">Всего просмотров</span>
          </div>
          <div class="analytics-stat">
            <span class="analytics-stat__value">{{ avgPerDay }}</span>
            <span class="analytics-stat__label">В среднем/день</span>
          </div>
          <div class="analytics-stat">
            <span class="analytics-stat__value">{{ daysInRange }}</span>
            <span class="analytics-stat__label">Дней в периоде</span>
          </div>
        </div>

      </aside>

      <!-- Right Block - Chart & Details -->
      <div class="analytics-main">
        <!-- Chart -->
        <div class="analytics-chart">
          <div class="analytics-chart__header">
            <h3 class="analytics-chart__title">
              {{ analyticsTypeTitles[selectedAnalytics] }} — {{ periodTitle }}
            </h3>
            <span class="analytics-chart__period">{{ dateRangeDisplay }}</span>
          </div>
          <div class="analytics-chart__container">
            <LineChart v-if="chartData && hasData" :chart-data="chartData" :options="chartOptions" />
            <div v-else class="analytics-chart__empty">
              <Icon name="mdi:chart-line-variant" class="analytics-chart__empty-icon" />
              <span>Нет данных за выбранный период</span>
            </div>
          </div>
        </div>

        <!-- Details Table by Days -->
        <div class="analytics-details" v-if="detailedData.length > 0">
          <div class="analytics-details__header">
            <h3 class="analytics-details__title">Детализация по дням</h3>
          </div>
          <div class="analytics-details__table-wrapper">
            <table class="analytics-details__table">
              <thead>
                <tr>
                  <th>Дата</th>
                  <th>Просмотры</th>
                  <th>% от общего</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in detailedData" :key="item.date">
                  <td>{{ formatDate(item.date) }}</td>
                  <td>{{ item.total }}</td>
                  <td>
                    <div class="analytics-details__progress">
                      <div 
                        class="analytics-details__progress-bar" 
                        :style="{ width: getPercentage(item.total) + '%' }"
                      ></div>
                      <span>{{ getPercentage(item.total).toFixed(1) }}%</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Top Content Table -->
        <div class="analytics-details analytics-details--content" v-if="topContentData.length > 0">
          <div class="analytics-details__header">
            <h3 class="analytics-details__title">
              Топ {{ contentTypeLabels[selectedAnalytics] }} по просмотрам
            </h3>
          </div>
          <div class="analytics-details__table-wrapper">
            <table class="analytics-details__table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Название</th>
                  <th>Просмотры</th>
                  <th>Последний просмотр</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(item, index) in topContentData" :key="item.item_id">
                  <td class="analytics-details__rank">{{ index + 1 }}</td>
                  <td class="analytics-details__name">{{ item.item_name || `ID: ${item.item_id}` }}</td>
                  <td>
                    <span class="analytics-details__views">{{ item.views }}</span>
                  </td>
                  <td class="analytics-details__date">{{ formatDateTime(item.last_view) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Empty state for detailed content -->
        <div class="analytics-details analytics-details--empty" v-if="hasData && topContentData.length === 0">
          <Icon name="mdi:information-outline" class="analytics-details__empty-icon" />
          <p>Детальная статистика по конкретным {{ contentTypeLabels[selectedAnalytics] }} появится после того, как пользователи начнут их просматривать.</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, ref, watch, computed } from 'vue';

const analyticsTypes = [
  { title: 'Новости', value: 'post' },
  { title: 'Сторис', value: 'story' },
  { title: 'Баннеры', value: 'banner' },
];

const analyticsTypeTitles: Record<string, string> = {
  post: 'Просмотры постов',
  story: 'Просмотры сторис',
  banner: 'Просмотры баннеров',
};

const contentTypeLabels: Record<string, string> = {
  post: 'постам',
  story: 'сторис',
  banner: 'баннерам',
};

// Пресеты для быстрого выбора периода
const datePresets = [
  { label: 'Сегодня', value: 'today' },
  { label: 'Вчера', value: 'yesterday' },
  { label: '7 дней', value: 'week' },
  { label: '30 дней', value: 'month' },
  { label: '90 дней', value: 'quarter' },
  { label: 'Год', value: 'year' },
];

// Утилиты для работы с датами
const today = new Date();
// Форматируем дату в локальном времени (не UTC), чтобы избежать сдвига даты
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
    case 'yesterday':
      start.setDate(start.getDate() - 1);
      end.setDate(end.getDate() - 1);
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
    case 'year':
      start.setFullYear(start.getFullYear() - 1);
      return [start, end];
    default:
      start.setDate(start.getDate() - 29);
      return [start, end];
  }
};

// State
const selectedAnalytics = ref('post');
const activePreset = ref('month');
const datePickerOpen = ref(false);
const dateRange = ref<Date[]>([]);
const startDate = ref(formatDateForApi(getPresetDates('month')[0]));
const endDate = ref(formatDateForApi(getPresetDates('month')[1]));
const chartData = ref<any>(null);
const hasData = ref(false);
const detailedData = ref<any[]>([]);
const topContentData = ref<any[]>([]);
const isLoading = ref(false);

// Применить пресет
const applyPreset = (preset: string) => {
  activePreset.value = preset;
  const [start, end] = getPresetDates(preset);
  startDate.value = formatDateForApi(start);
  endDate.value = formatDateForApi(end);
  updateChartData();
};

// Применить выбранный диапазон из календаря
const applyDateRange = () => {
  if (dateRange.value.length >= 2) {
    const sorted = [...dateRange.value].sort((a, b) => a.getTime() - b.getTime());
    startDate.value = formatDateForApi(sorted[0]);
    endDate.value = formatDateForApi(sorted[sorted.length - 1]);
    activePreset.value = ''; // Сбрасываем активный пресет
    updateChartData();
  }
  datePickerOpen.value = false;
};

// Отображение выбранного периода
const dateRangeDisplay = computed(() => {
  const start = new Date(startDate.value);
  const end = new Date(endDate.value);
  const options: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short', year: 'numeric' };
  
  if (startDate.value === endDate.value) {
    return start.toLocaleDateString('ru-RU', options);
  }
  
  return `${start.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' })} — ${end.toLocaleDateString('ru-RU', options)}`;
});

// Заголовок периода
const periodTitle = computed(() => {
  const presetLabels: Record<string, string> = {
    today: 'за сегодня',
    yesterday: 'за вчера',
    week: 'за 7 дней',
    month: 'за 30 дней',
    quarter: 'за 90 дней',
    year: 'за год',
  };
  return presetLabels[activePreset.value] || 'за период';
});

// Количество дней в периоде
const daysInRange = computed(() => {
  const start = new Date(startDate.value);
  const end = new Date(endDate.value);
  const diff = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;
  return diff;
});

// Вычисляемые значения для статистики
const totalViews = computed(() => {
  return detailedData.value.reduce((sum, item) => sum + item.total, 0);
});

const avgPerDay = computed(() => {
  if (detailedData.value.length === 0) return 0;
  return Math.round(totalViews.value / detailedData.value.length);
});

const getPercentage = (value: number) => {
  if (totalViews.value === 0) return 0;
  return (value / totalViews.value) * 100;
};

const formatDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
};

const formatDateTime = (dateStr: string) => {
  if (!dateStr) return '—';
  const date = new Date(dateStr);
  return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
};

// Цвета для Chart.js (CSS переменные не работают в canvas)
const colorMode = useColorMode();
const isDark = computed(() => colorMode.value === 'dark');

const chartColors = computed(() => ({
  textColor: isDark.value ? '#e0e0e0' : '#667085',
  gridColor: isDark.value ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)',
  tooltipBg: isDark.value ? '#2d2d2d' : '#ffffff',
  tooltipText: isDark.value ? '#ffffff' : '#34460C',
  tooltipSecondary: isDark.value ? '#b3b3b3' : '#667085',
  tooltipBorder: isDark.value ? '#444444' : '#e0e0e0',
  // Брендовый зелёный цвет для графика (зависит от темы)
  lineColor: isDark.value ? '#98B35D' : '#34460C',
  lineBackground: isDark.value ? 'rgba(152, 179, 93, 0.15)' : 'rgba(52, 70, 12, 0.1)',
}));

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  interaction: {
    intersect: false,
    mode: 'index' as const,
  },
  scales: {
    y: {
      beginAtZero: true,
      grid: {
        color: chartColors.value.gridColor,
      },
      ticks: {
        stepSize: 1,
        color: chartColors.value.textColor,
        font: {
          size: 12,
        },
      },
    },
    x: {
      grid: {
        display: false,
      },
      ticks: {
        color: chartColors.value.textColor,
        maxRotation: 45,
        minRotation: 0,
        font: {
          size: 11,
        },
      },
    },
  },
  plugins: {
    legend: {
      display: false,
    },
    tooltip: {
      backgroundColor: chartColors.value.tooltipBg,
      titleColor: chartColors.value.tooltipText,
      bodyColor: chartColors.value.tooltipSecondary,
      borderColor: chartColors.value.tooltipBorder,
      borderWidth: 1,
      padding: 12,
      displayColors: false,
      titleFont: {
        size: 13,
        weight: 'bold' as const,
      },
      bodyFont: {
        size: 12,
      },
      callbacks: {
        title: (items: any) => {
          if (items.length > 0) {
            const date = new Date(items[0].label);
            return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' });
          }
          return '';
        },
        label: (item: any) => `Просмотров: ${item.raw}`,
      },
    },
  },
}));

const fetchAnalyticsData = async (type: string, startDate: string, endDate: string) => {
  try {
    const response = await api.analytics.getEventStatistics(type, startDate, endDate);
    return Array.isArray(response) ? response : [];
  } catch (error) {
    console.error('Error fetching analytics data:', error);
    return [];
  }
};

const fetchDetailedAnalyticsData = async (type: string, startDate: string, endDate: string) => {
  try {
    const response = await api.analytics.getDetailedEventStatistics(type, startDate, endDate);
    return Array.isArray(response) ? response : [];
  } catch (error) {
    console.error('Error fetching detailed analytics data:', error);
    return [];
  }
};

const updateChartData = async () => {
  isLoading.value = true;

  // Загружаем оба типа данных параллельно
  const [dailyData, contentData] = await Promise.all([
    fetchAnalyticsData(selectedAnalytics.value, startDate.value, endDate.value),
    fetchDetailedAnalyticsData(selectedAnalytics.value, startDate.value, endDate.value),
  ]);

  // Сохраняем данные по дням
  detailedData.value = Array.isArray(dailyData) ? dailyData : [];
  hasData.value = detailedData.value.length > 0;

  // Сохраняем данные по конкретным объектам
  topContentData.value = Array.isArray(contentData) ? contentData : [];

  // Форматируем данные для графика
  const labels = detailedData.value.map((item: any) => item.date);
  const values = detailedData.value.map((item: any) => item.total);

  // Адаптивный размер точек в зависимости от количества данных
  const pointRadius = labels.length > 60 ? 0 : labels.length > 30 ? 2 : 4;
  const pointHoverRadius = labels.length > 60 ? 4 : 6;

  chartData.value = {
    labels,
    datasets: [
      {
        label: 'Просмотры',
        data: values,
        borderColor: chartColors.value.lineColor,
        backgroundColor: chartColors.value.lineBackground,
        tension: 0.4,
        fill: true,
        pointBackgroundColor: chartColors.value.lineColor,
        pointBorderColor: isDark.value ? '#1c1c1c' : '#fff',
        pointBorderWidth: 2,
        pointRadius,
        pointHoverRadius,
      },
    ],
  };
  
  isLoading.value = false;
};

// Следим за типом контента
watch(selectedAnalytics, async () => {
  await updateChartData();
});

// Обновляем цвета графика при смене темы
watch(isDark, async () => {
  await updateChartData();
});

const layoutStore = useLayoutStore();

onMounted(async () => {
  // Скрываем заголовок из лейаута (он дублируется на странице)
  layoutStore.navItem = null;
  await updateChartData();
});
</script>

<style scoped>
.analytics-page {
  padding: 0;
}

/* Header с табами */
.analytics-header {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

@media (min-width: 600px) {
  .analytics-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }
}

.analytics-header__title {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
  margin: 0;
}

.analytics-tabs {
  display: flex;
  gap: 0.5rem;
  background: var(--color-bg-secondary);
  padding: 0.25rem;
  border-radius: 0.75rem;
  flex-wrap: wrap;
}

.analytics-tab {
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

.analytics-tab:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-tertiary);
}

.analytics-tab--active {
  color: #25D366;
  background: rgba(37, 211, 102, 0.15);
}

.analytics-tab--active:hover {
  background: rgba(37, 211, 102, 0.2);
}

.analytics-layout {
  display: flex;
  gap: 1rem;
  flex-direction: column;
}

@media (min-width: 600px) {
  .analytics-layout {
    gap: 1.25rem;
  }
}

@media (min-width: 960px) {
  .analytics-layout {
    flex-direction: row;
    gap: 1.5rem;
    align-items: flex-start;
  }
}

@media (min-width: 1280px) {
  .analytics-layout {
    gap: 2rem;
  }
}

/* Sidebar */
.analytics-sidebar {
  width: 100%;
  flex-shrink: 0;
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-secondary);
}

@media (min-width: 600px) {
  .analytics-sidebar {
    padding: 1.25rem;
  }
}

@media (min-width: 960px) {
  .analytics-sidebar {
    width: 260px;
    padding: 1.5rem;
  }
}

@media (min-width: 1280px) {
  .analytics-sidebar {
    width: 300px;
  }
}

.analytics-sidebar__header {
  margin-bottom: 1rem;
}

@media (min-width: 600px) {
  .analytics-sidebar__header {
    margin-bottom: 1.5rem;
  }
}

.analytics-sidebar__title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .analytics-sidebar__title {
    font-size: 1.125rem;
  }
}

.analytics-sidebar__subtitle {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  margin-top: 0.25rem;
}

@media (min-width: 600px) {
  .analytics-sidebar__subtitle {
    font-size: 0.875rem;
  }
}

.analytics-sidebar__controls {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .analytics-sidebar__controls {
    gap: 1rem;
  }
}

/* Presets */
.analytics-presets {
  display: flex;
  flex-wrap: wrap;
  gap: 0.375rem;
}

.analytics-preset {
  padding: 0.375rem 0.625rem;
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--color-text-secondary);
  background-color: var(--color-bg-tertiary);
  border: 1px solid transparent;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.15s ease;
}

.analytics-preset:hover {
  color: var(--color-text-primary);
  background-color: var(--color-bg-input);
}

.analytics-preset--active {
  color: var(--color-accent);
  background-color: rgba(67, 57, 242, 0.1);
  border-color: var(--color-accent);
}

/* Date Picker */
.analytics-date-input {
  cursor: pointer;
}

.analytics-date-input :deep(.v-field) {
  min-height: 40px !important;
}

.analytics-date-input :deep(.v-field__input) {
  padding-top: 8px !important;
  padding-bottom: 8px !important;
  min-height: 40px !important;
}

.analytics-date-picker {
  background-color: var(--color-bg-secondary) !important;
}

.analytics-date-picker .v-date-picker {
  background-color: transparent !important;
}

/* Stats */
.analytics-sidebar__stats {
  display: flex;
  gap: 1rem;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid var(--color-border-light);
}

@media (max-width: 599px) {
  .analytics-sidebar__stats {
    margin-top: 1rem;
  }
}

.analytics-stat {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.analytics-stat__value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-accent);
}

@media (min-width: 600px) {
  .analytics-stat__value {
    font-size: 1.75rem;
  }
}

.analytics-stat__label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.25rem;
}


/* Main area */
.analytics-main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 600px) {
  .analytics-main {
    gap: 1.25rem;
  }
}

/* Chart */
.analytics-chart {
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-secondary);
}

@media (min-width: 600px) {
  .analytics-chart {
    padding: 1.25rem;
  }
}

@media (min-width: 960px) {
  .analytics-chart {
    padding: 1.5rem;
  }
}

.analytics-chart__header {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-bottom: 1rem;
}

@media (min-width: 600px) {
  .analytics-chart__header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }
}

.analytics-chart__title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .analytics-chart__title {
    font-size: 1rem;
  }
}

.analytics-chart__period {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

@media (min-width: 600px) {
  .analytics-chart__period {
    font-size: 0.8125rem;
  }
}

.analytics-chart__container {
  height: 250px;
  min-height: 180px;
}

@media (min-width: 600px) {
  .analytics-chart__container {
    height: 300px;
    min-height: 250px;
  }
}

@media (min-width: 960px) {
  .analytics-chart__container {
    height: 350px;
  }
}

@media (min-width: 1280px) {
  .analytics-chart__container {
    height: 400px;
  }
}

.analytics-chart__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  height: 100%;
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.analytics-chart__empty-icon {
  font-size: 3rem;
  opacity: 0.5;
}

/* Details Table */
.analytics-details {
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-secondary);
}

@media (min-width: 600px) {
  .analytics-details {
    padding: 1.25rem;
  }
}

@media (min-width: 960px) {
  .analytics-details {
    padding: 1.5rem;
  }
}

.analytics-details__header {
  margin-bottom: 1rem;
}

.analytics-details__title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .analytics-details__title {
    font-size: 1rem;
  }
}

.analytics-details__table-wrapper {
  overflow-x: auto;
  max-height: 300px;
  overflow-y: auto;
}

@media (min-width: 600px) {
  .analytics-details__table-wrapper {
    max-height: 400px;
  }
}

.analytics-details__table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8125rem;
}

@media (min-width: 600px) {
  .analytics-details__table {
    font-size: 0.875rem;
  }
}

.analytics-details__table th,
.analytics-details__table td {
  padding: 0.625rem 0.75rem;
  text-align: left;
  border-bottom: 1px solid var(--color-border-light);
}

.analytics-details__table th {
  font-weight: 600;
  color: var(--color-text-primary);
  background-color: var(--color-bg-tertiary);
  position: sticky;
  top: 0;
  z-index: 1;
}

.analytics-details__table td {
  color: var(--color-text-primary);
}

.analytics-details__table tbody tr {
  transition: background-color 0.15s ease;
}

.analytics-details__table tbody tr:hover {
  background-color: rgba(67, 57, 242, 0.1);
}

.analytics-details__progress {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.analytics-details__progress-bar {
  height: 6px;
  background-color: var(--color-accent);
  border-radius: 3px;
  min-width: 4px;
  max-width: 100px;
  transition: width 0.3s ease;
}

.analytics-details__progress span {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  min-width: 45px;
  font-weight: 500;
}

/* Content details specific */
.analytics-details--content .analytics-details__table-wrapper {
  max-height: 350px;
}

@media (min-width: 600px) {
  .analytics-details--content .analytics-details__table-wrapper {
    max-height: 450px;
  }
}

.analytics-details__rank {
  width: 40px;
  font-weight: 600;
  color: var(--color-text-muted);
}

.analytics-details__name {
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

@media (min-width: 600px) {
  .analytics-details__name {
    max-width: 300px;
  }
}

@media (min-width: 960px) {
  .analytics-details__name {
    max-width: 400px;
  }
}

.analytics-details__views {
  font-weight: 600;
  color: var(--color-accent);
}

.analytics-details__date {
  color: var(--color-text-muted);
  font-size: 0.75rem;
}

@media (min-width: 600px) {
  .analytics-details__date {
    font-size: 0.8125rem;
  }
}

/* Empty state */
.analytics-details--empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 2rem 1rem;
  text-align: center;
  color: var(--color-text-muted);
}

.analytics-details__empty-icon {
  font-size: 2.5rem;
  opacity: 0.5;
}

.analytics-details--empty p {
  font-size: 0.8125rem;
  max-width: 400px;
  line-height: 1.5;
}

@media (min-width: 600px) {
  .analytics-details--empty p {
    font-size: 0.875rem;
  }
}

.v-select {
  background-color: var(--color-bg-input);
}
</style>
