<template>
  <section class="social-analytics">
    <!-- Общий header с табами -->
    <div class="social-analytics__page-header">
      <h1 class="social-analytics__page-title">Аналитика</h1>
      <div class="social-analytics__tabs">
        <NuxtLink to="/analytics" class="social-analytics__tab">
          <Icon name="mdi:chart-line" />
          <span>Просмотры контента</span>
        </NuxtLink>
        <NuxtLink to="/analytics/social" class="social-analytics__tab social-analytics__tab--active">
          <Icon name="mdi:share-variant" />
          <span>Клики по соцсетям</span>
        </NuxtLink>
        <NuxtLink to="/analytics/referral" class="social-analytics__tab">
          <Icon name="mdi:gift-outline" />
          <span>Подари скидку другу</span>
        </NuxtLink>
      </div>
    </div>

    <div class="social-analytics__layout">
      <!-- Sidebar с фильтрами -->
      <aside class="social-analytics__sidebar">
        <div class="social-analytics__header">
          <h2 class="social-analytics__title">Клики по соцсетям</h2>
          <p class="social-analytics__subtitle">Статистика переходов</p>
        </div>

        <!-- Быстрые пресеты -->
        <div class="social-analytics__presets">
          <button 
            v-for="preset in datePresets" 
            :key="preset.value"
            class="social-analytics__preset"
            :class="{ 'social-analytics__preset--active': activePreset === preset.value }"
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
              class="social-analytics__date-input"
            />
          </template>
          <v-card class="social-analytics__date-picker">
            <v-date-picker v-model="dateRange" multiple="range" show-adjacent-months :max="today" color="primary" />
            <v-card-actions>
              <v-spacer />
              <v-btn variant="text" @click="datePickerOpen = false">Отмена</v-btn>
              <v-btn color="primary" variant="flat" @click="applyDateRange">Применить</v-btn>
            </v-card-actions>
          </v-card>
        </v-menu>

        <!-- Общая статистика -->
        <div class="social-analytics__stats" v-if="statsData">
          <div class="social-analytics__stat social-analytics__stat--primary">
            <Icon name="mdi:cursor-default-click" class="social-analytics__stat-icon" />
            <div class="social-analytics__stat-content">
              <span class="social-analytics__stat-value">{{ statsData.data.total_clicks }}</span>
              <span class="social-analytics__stat-label">Всего кликов</span>
            </div>
          </div>
        </div>

      </aside>

      <!-- Основной контент -->
      <div class="social-analytics__main">
        <!-- Загрузка -->
        <div v-if="isLoading" class="social-analytics__loading">
          <v-progress-circular indeterminate color="primary" size="48" />
          <span>Загрузка данных...</span>
        </div>

        <template v-else-if="statsData">
          <!-- Карточки по соцсетям -->
          <div class="social-analytics__cards">
            <div 
              v-for="item in statsData.data.by_social_type" 
              :key="item.social_type"
              class="social-analytics__card"
              :class="`social-analytics__card--${item.social_type}`"
            >
              <div class="social-analytics__card-icon">
                <Icon :name="getSocialIcon(item.social_type)" />
              </div>
              <div class="social-analytics__card-content">
                <span class="social-analytics__card-value">{{ item.clicks }}</span>
                <span class="social-analytics__card-label">{{ getSocialLabel(item.social_type) }}</span>
              </div>
              <div class="social-analytics__card-percent">
                {{ getPercentage(item.clicks) }}%
              </div>
            </div>
          </div>

          <!-- График по дням -->
          <div class="social-analytics__chart">
            <div class="social-analytics__chart-header">
              <h3 class="social-analytics__chart-title">Клики по дням</h3>
              <span class="social-analytics__chart-period">{{ dateRangeDisplay }}</span>
            </div>
            <div class="social-analytics__chart-container">
              <LineChart v-if="chartData && hasChartData" :chart-data="chartData" :options="chartOptions" />
              <div v-else class="social-analytics__chart-empty">
                <Icon name="mdi:chart-line-variant" />
                <span>Нет данных за выбранный период</span>
              </div>
            </div>
          </div>

          <!-- Таблицы статистики -->
          <div class="social-analytics__tables">
            <!-- По источникам -->
            <div class="social-analytics__table-card">
              <h3 class="social-analytics__table-title">
                <Icon name="mdi:page-layout-body" />
                По страницам
              </h3>
              <table class="social-analytics__table" v-if="statsData.data.by_source_page.length">
                <thead>
                  <tr>
                    <th>Страница</th>
                    <th>Клики</th>
                    <th>%</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in statsData.data.by_source_page" :key="item.source_page">
                    <td>{{ getSourcePageLabel(item.source_page) }}</td>
                    <td class="social-analytics__table-clicks">{{ item.clicks }}</td>
                    <td>
                      <div class="social-analytics__progress">
                        <div class="social-analytics__progress-bar" :style="{ width: getPercentage(item.clicks) + '%' }"></div>
                        <span>{{ getPercentage(item.clicks) }}%</span>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
              <div v-else class="social-analytics__table-empty">Нет данных</div>
            </div>

            <!-- По городам -->
            <div class="social-analytics__table-card">
              <h3 class="social-analytics__table-title">
                <Icon name="mdi:map-marker" />
                По городам
              </h3>
              <table class="social-analytics__table" v-if="statsData.data.by_city.length">
                <thead>
                  <tr>
                    <th>Город</th>
                    <th>Клики</th>
                    <th>%</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in statsData.data.by_city" :key="item.city">
                    <td>{{ item.city || 'Не указан' }}</td>
                    <td class="social-analytics__table-clicks">{{ item.clicks }}</td>
                    <td>
                      <div class="social-analytics__progress">
                        <div class="social-analytics__progress-bar" :style="{ width: getPercentage(item.clicks) + '%' }"></div>
                        <span>{{ getPercentage(item.clicks) }}%</span>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
              <div v-else class="social-analytics__table-empty">Нет данных</div>
            </div>
          </div>

          <!-- Топ магазинов -->
          <div class="social-analytics__section" v-if="statsData.data.top_shops.length">
            <h3 class="social-analytics__section-title">
              <Icon name="mdi:store" />
              Топ магазинов по кликам
            </h3>
            <div class="social-analytics__list">
              <div 
                v-for="(item, index) in statsData.data.top_shops" 
                :key="item.shop_id"
                class="social-analytics__list-item"
              >
                <span class="social-analytics__list-rank">{{ index + 1 }}</span>
                <span class="social-analytics__list-name">{{ item.shop_name || `Магазин #${item.shop_id}` }}</span>
                <span class="social-analytics__list-clicks">{{ item.clicks }} кликов</span>
              </div>
            </div>
          </div>

          <!-- Топ новостей -->
          <div class="social-analytics__section" v-if="statsData.data.top_news.length">
            <h3 class="social-analytics__section-title">
              <Icon name="mdi:newspaper-variant" />
              Топ новостей по WhatsApp кликам
            </h3>
            <div class="social-analytics__list">
              <div 
                v-for="(item, index) in statsData.data.top_news" 
                :key="item.news_id"
                class="social-analytics__list-item"
              >
                <span class="social-analytics__list-rank">{{ index + 1 }}</span>
                <span class="social-analytics__list-name">{{ item.news_name || `Новость #${item.news_id}` }}</span>
                <span class="social-analytics__list-clicks">{{ item.clicks }} кликов</span>
              </div>
            </div>
          </div>

          <!-- Детальная таблица -->
          <div class="social-analytics__detailed" v-if="statsData.data.detailed.length">
            <h3 class="social-analytics__section-title">
              <Icon name="mdi:table" />
              Детализация: соцсеть + страница
            </h3>
            <div class="social-analytics__detailed-table-wrapper">
              <table class="social-analytics__table social-analytics__table--detailed">
                <thead>
                  <tr>
                    <th>Соцсеть</th>
                    <th>Страница</th>
                    <th>Клики</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(item, idx) in statsData.data.detailed" :key="idx">
                    <td>
                      <div class="social-analytics__cell-social">
                        <Icon :name="getSocialIcon(item.social_type)" />
                        {{ getSocialLabel(item.social_type) }}
                      </div>
                    </td>
                    <td>{{ getSourcePageLabel(item.source_page) }}</td>
                    <td class="social-analytics__table-clicks">{{ item.clicks }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </template>

        <!-- Пустое состояние -->
        <div v-else class="social-analytics__empty">
          <Icon name="mdi:chart-box-outline" class="social-analytics__empty-icon" />
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
const statsData = ref<Api.Analytics.SocialClickResponse | null>(null);
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

// Хелперы для отображения
const getSocialIcon = (type?: string) => {
  const icons: Record<string, string> = {
    whatsapp: 'mdi:whatsapp',
    instagram: 'mdi:instagram',
    '2gis': 'mdi:map-marker-radius',
  };
  return icons[type || ''] || 'mdi:link';
};

const getSocialLabel = (type?: string) => {
  const labels: Record<string, string> = {
    whatsapp: 'WhatsApp',
    instagram: 'Instagram',
    '2gis': '2GIS',
  };
  return labels[type || ''] || type || 'Неизвестно';
};

const getSourcePageLabel = (page?: string) => {
  const labels: Record<string, string> = {
    shop_detail: 'Страница магазина',
    news_detail: 'Страница новости',
    nav_bar: 'Боковое меню',
    partners: 'Партнёры',
    certificate: 'Сертификаты',
  };
  return labels[page || ''] || page || 'Неизвестно';
};

const getPercentage = (clicks: number) => {
  if (!statsData.value || statsData.value.data.total_clicks === 0) return 0;
  return Math.round((clicks / statsData.value.data.total_clicks) * 100);
};

const hasChartData = computed(() => {
  return statsData.value?.data.by_date && statsData.value.data.by_date.length > 0;
});

// Загрузка данных
const loadData = async () => {
  isLoading.value = true;
  try {
    const response = await api.analytics.getSocialClickStatistics(startDate.value, endDate.value);
    statsData.value = response;
    updateChartData();
  } catch (error) {
    console.error('Error loading social analytics:', error);
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
        label: (item: any) => `Кликов: ${item.raw}`,
      },
    },
  },
}));

const updateChartData = () => {
  if (!statsData.value?.data.by_date) return;

  const labels = statsData.value.data.by_date.map((item) => {
    const date = new Date(item.date!);
    return date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
  });
  const values = statsData.value.data.by_date.map((item) => item.clicks);

  chartData.value = {
    labels,
    datasets: [
      {
        label: 'Клики',
        data: values,
        borderColor: '#25D366',
        backgroundColor: 'rgba(37, 211, 102, 0.1)',
        tension: 0.4,
        fill: true,
        pointBackgroundColor: '#25D366',
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
  // Скрываем заголовок из лейаута (он дублируется на странице)
  layoutStore.navItem = null;
  loadData();
});
</script>

<style scoped>
.social-analytics {
  padding: 0;
}

/* Page Header с табами */
.social-analytics__page-header {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

@media (min-width: 600px) {
  .social-analytics__page-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }
}

.social-analytics__page-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
  margin: 0;
}

.social-analytics__tabs {
  display: flex;
  gap: 0.5rem;
  background: var(--color-bg-secondary);
  padding: 0.25rem;
  border-radius: 0.75rem;
  flex-wrap: wrap;
}

.social-analytics__tab {
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

.social-analytics__tab:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-tertiary);
}

.social-analytics__tab--active {
  color: #25D366;
  background: rgba(37, 211, 102, 0.15);
}

.social-analytics__tab--active:hover {
  background: rgba(37, 211, 102, 0.2);
}

.social-analytics__layout {
  display: flex;
  gap: 1.5rem;
  flex-direction: column;
}

@media (min-width: 960px) {
  .social-analytics__layout {
    flex-direction: row;
    align-items: flex-start;
  }
}

/* Sidebar */
.social-analytics__sidebar {
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
  .social-analytics__sidebar {
    width: 280px;
  }
}

.social-analytics__header {
  margin-bottom: 0.5rem;
}

.social-analytics__title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.social-analytics__title-icon {
  color: #25D366;
  font-size: 1.25rem;
}

.social-analytics__subtitle {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  margin-top: 0.25rem;
}

/* Presets */
.social-analytics__presets {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.social-analytics__preset {
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

.social-analytics__preset:hover {
  color: var(--color-text-primary);
  background-color: var(--color-bg-input);
}

.social-analytics__preset--active {
  color: #25D366;
  background-color: rgba(37, 211, 102, 0.1);
  border-color: #25D366;
}

/* Date Picker */
.social-analytics__date-input {
  cursor: pointer;
}

.social-analytics__date-input :deep(.v-field) {
  min-height: 44px !important;
  height: 44px !important;
}

.social-analytics__date-input :deep(.v-field__field) {
  height: 44px !important;
}

.social-analytics__date-input :deep(.v-field__input) {
  padding-top: 10px !important;
  padding-bottom: 10px !important;
  min-height: 44px !important;
  font-size: 0.875rem;
}

.social-analytics__date-input :deep(.v-field__prepend-inner) {
  padding-top: 10px !important;
}

.social-analytics__date-input :deep(.v-text-field__prefix),
.social-analytics__date-input :deep(.v-label) {
  font-size: 0.75rem;
}

.social-analytics__date-picker {
  background-color: var(--color-bg-secondary) !important;
}

.social-analytics__date-picker .v-date-picker {
  background-color: transparent !important;
}

/* Stats */
.social-analytics__stats {
  padding-top: 1rem;
  border-top: 1px solid var(--color-border-light);
}

.social-analytics__stat {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  border-radius: 0.75rem;
  background: linear-gradient(135deg, rgba(37, 211, 102, 0.1) 0%, rgba(37, 211, 102, 0.05) 100%);
}

.social-analytics__stat-icon {
  font-size: 2rem;
  color: #25D366;
}

.social-analytics__stat-content {
  display: flex;
  flex-direction: column;
}

.social-analytics__stat-value {
  font-size: 1.75rem;
  font-weight: 700;
  color: #25D366;
}

.social-analytics__stat-label {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

/* Main */
.social-analytics__main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  align-self: stretch;
}

/* Loading */
.social-analytics__loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 4rem 2rem;
  color: var(--color-text-muted);
}

/* Cards */
.social-analytics__cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 1rem;
}

.social-analytics__card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
  position: relative;
  overflow: hidden;
}

.social-analytics__card--whatsapp {
  border-left: 4px solid #25D366;
}

.social-analytics__card--instagram {
  border-left: 4px solid #E1306C;
}

.social-analytics__card--2gis {
  border-left: 4px solid #1DAD5B;
}

.social-analytics__card-icon {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  font-size: 1.5rem;
}

.social-analytics__card--whatsapp .social-analytics__card-icon {
  background-color: rgba(37, 211, 102, 0.1);
  color: #25D366;
}

.social-analytics__card--instagram .social-analytics__card-icon {
  background-color: rgba(225, 48, 108, 0.1);
  color: #E1306C;
}

.social-analytics__card--2gis .social-analytics__card-icon {
  background-color: rgba(29, 173, 91, 0.1);
  color: #1DAD5B;
}

.social-analytics__card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.social-analytics__card-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
}

.social-analytics__card-label {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
}

.social-analytics__card-percent {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-muted);
  background-color: var(--color-bg-tertiary);
  padding: 0.25rem 0.5rem;
  border-radius: 0.5rem;
}

/* Chart */
.social-analytics__chart {
  padding: 1.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
}

.social-analytics__chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.social-analytics__chart-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.social-analytics__chart-period {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.social-analytics__chart-container {
  height: 300px;
}

.social-analytics__chart-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  height: 100%;
  color: var(--color-text-muted);
  font-size: 3rem;
}

.social-analytics__chart-empty span {
  font-size: 0.875rem;
}

/* Tables */
.social-analytics__tables {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.social-analytics__table-card {
  padding: 1.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
}

.social-analytics__table-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin-bottom: 1rem;
}

.social-analytics__table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.875rem;
}

.social-analytics__table th,
.social-analytics__table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid var(--color-border-light);
}

.social-analytics__table th {
  font-weight: 600;
  color: var(--color-text-primary);
  background-color: var(--color-bg-tertiary);
}

.social-analytics__table td {
  color: var(--color-text-primary);
}

.social-analytics__table-clicks {
  font-weight: 600;
  color: #25D366;
}

.social-analytics__table-empty {
  padding: 2rem;
  text-align: center;
  color: var(--color-text-muted);
}

/* Progress */
.social-analytics__progress {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.social-analytics__progress-bar {
  height: 6px;
  background-color: #25D366;
  border-radius: 3px;
  min-width: 4px;
  max-width: 80px;
}

.social-analytics__progress span {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  min-width: 35px;
}

/* Sections */
.social-analytics__section {
  padding: 1.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
}

.social-analytics__section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
  margin-bottom: 1rem;
}

/* List */
.social-analytics__list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.social-analytics__list-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1rem;
  border-radius: 0.5rem;
  background-color: var(--color-bg-tertiary);
}

.social-analytics__list-rank {
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

.social-analytics__list-name {
  flex: 1;
  font-size: 0.875rem;
  color: var(--color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.social-analytics__list-clicks {
  font-size: 0.8125rem;
  font-weight: 600;
  color: #25D366;
}

/* Detailed */
.social-analytics__detailed {
  padding: 1.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
}

.social-analytics__detailed-table-wrapper {
  overflow-x: auto;
  max-height: 400px;
  overflow-y: auto;
}

.social-analytics__cell-social {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* Empty */
.social-analytics__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 4rem 2rem;
  text-align: center;
  color: var(--color-text-muted);
}

.social-analytics__empty-icon {
  font-size: 4rem;
  opacity: 0.5;
}

.social-analytics__empty p {
  font-size: 1rem;
  color: var(--color-text-primary);
}
</style>

