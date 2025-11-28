<template>
  <section class="gift-issuance">
    <!-- Статистика -->
    <div class="gift-issuance__stats">
      <div class="gift-issuance__stat-card">
        <span class="gift-issuance__stat-value">{{ stats.total }}</span>
        <span class="gift-issuance__stat-label">Всего</span>
      </div>
      <div class="gift-issuance__stat-card gift-issuance__stat-card--pending">
        <span class="gift-issuance__stat-value">{{ stats.pending }}</span>
        <span class="gift-issuance__stat-label">Ожидает выбора</span>
      </div>
      <div class="gift-issuance__stat-card gift-issuance__stat-card--selected">
        <span class="gift-issuance__stat-value">{{ stats.selected }}</span>
        <span class="gift-issuance__stat-label">Выбрано</span>
      </div>
      <div class="gift-issuance__stat-card gift-issuance__stat-card--issued">
        <span class="gift-issuance__stat-value">{{ stats.issued }}</span>
        <span class="gift-issuance__stat-label">Выдано</span>
      </div>
    </div>

    <!-- Фильтры -->
    <div class="gift-issuance__filters">
      <v-text-field 
        v-model="search" 
        placeholder="Поиск по пользователю" 
        prepend-inner-icon="mdi-magnify" 
        dense 
        hide-details
        variant="solo" 
        @input="debouncedLoad"
        class="gift-issuance__search"
      />
      <v-select 
        v-model="statusFilter" 
        :items="statusOptions" 
        item-value="value" 
        item-title="title" 
        label="Статус"
        prepend-inner-icon="mdi-filter" 
        dense
        hide-details 
        variant="solo"
        clearable
        @update:modelValue="loadItems"
        class="gift-issuance__filter"
      />
    </div>

    <!-- Таблица -->
    <div class="gift-issuance__table-wrapper">
      <v-data-table-server
        class="admin-table"
        :headers="headers"
        :items="items"
        :items-length="totalItems"
        :loading="loading"
        :items-per-page="itemsPerPage"
        :page.sync="page"
        :items-per-page-options="[10, 20, 50]"
        @update:options="loadItems"
      >
        <template v-slot:item.user="{ item }">
          <div class="gift-issuance__user">
            <span class="gift-issuance__user-name">{{ item.user?.name }} {{ item.user?.surname }}</span>
            <span class="gift-issuance__user-phone">{{ item.user?.phone }}</span>
          </div>
        </template>

        <template v-slot:item.gift="{ item }">
          <div class="gift-issuance__gift">
            <img v-if="item.image" :src="item.image" :alt="item.name" class="gift-issuance__gift-image" />
            <div v-else class="gift-issuance__gift-placeholder"><Icon name="mdi:gift" /></div>
            <span class="gift-issuance__gift-name">{{ item.name }}</span>
          </div>
        </template>

        <template v-slot:item.status="{ item }">
          <div class="gift-issuance__status-cell">
            <v-menu offset-y>
              <template v-slot:activator="{ props }">
                <v-chip 
                  v-bind="props"
                  :color="getStatusColor(item.status)" 
                  size="small"
                  variant="flat"
                  class="gift-issuance__status-chip"
                  :loading="changingStatusId === item.id"
                >
                  {{ getStatusText(item.status) }}
                </v-chip>
              </template>
              <v-list density="compact" class="gift-issuance__status-menu">
                <v-list-item
                  v-for="option in statusOptions"
                  :key="option.value"
                  @click="changeStatus(item, option.value)"
                  :disabled="changingStatusId === item.id"
                  :class="{ 'gift-issuance__status-menu-active': item.status === option.value }"
                >
                  <template v-slot:prepend>
                    <v-icon
                      :icon="item.status === option.value ? 'mdi-check-circle' : 'mdi-circle-outline'"
                      :color="getStatusColor(option.value)"
                      size="small"
                    />
                  </template>
                  <v-list-item-title>{{ option.title }}</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
          </div>
        </template>

        <template v-slot:item.created_at="{ item }">
          {{ formatDate(item.created_at) }}
        </template>

        <template v-slot:item.actions="{ item }">
          <v-btn 
            v-if="item.status === 'activated'"
            color="success" 
            size="small" 
            variant="flat"
            :loading="issuingId === item.id"
            @click="issueGift(item)"
          >
            <Icon name="mdi:check" class="tw-mr-1" />
            Выдать
          </v-btn>
          <span v-else-if="item.status === 'issued'" class="gift-issuance__issued-date">
            {{ formatDate(item.issued_at) }}
          </span>
          <span v-else class="gift-issuance__waiting">—</span>
        </template>
      </v-data-table-server>
    </div>
  </section>
</template>

<script setup lang="ts">
// Простой debounce без lodash
const debounce = <T extends (...args: any[]) => any>(fn: T, delay: number) => {
  let timeoutId: ReturnType<typeof setTimeout>;
  return (...args: Parameters<T>) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
};

const loading = ref(false);
const items = ref<Api.GiftIssuance.Self[]>([]);
const totalItems = ref(0);
const page = ref(1);
const itemsPerPage = ref(20);
const search = ref('');
const statusFilter = ref<string | null>(null);
const issuingId = ref<number | null>(null);
const changingStatusId = ref<number | null>(null);

const stats = ref<Api.GiftIssuance.Stats>({
  total: 0,
  pending: 0,
  selected: 0,
  activated: 0,
  issued: 0,
});

const statusOptions = [
  { value: 'pending', title: 'Ожидает выбора' },
  { value: 'selected', title: 'Выбрано' },
  { value: 'activated', title: 'Активировано' },
  { value: 'issued', title: 'Выдано' },
];

const headers = [
  { title: 'ID', key: 'id', width: '80px' },
  { title: 'Пользователь', key: 'user' },
  { title: 'Подарок', key: 'gift' },
  { title: 'Статус', key: 'status', width: '140px' },
  { title: 'Дата создания', key: 'created_at', width: '150px' },
  { title: 'Действия', key: 'actions', width: '150px', sortable: false },
];

const loadItems = async (options?: { page: number; itemsPerPage: number }) => {
  loading.value = true;

  if (options) {
    page.value = options.page;
    itemsPerPage.value = options.itemsPerPage;
  }

  try {
    const params: Record<string, any> = {
      page: page.value,
      per_page: itemsPerPage.value,
    };

    if (search.value) params.search = search.value;
    if (statusFilter.value) params.status = statusFilter.value;

    const response = await api.giftIssuance.getAll(params);
    
    if (response) {
      items.value = response.data || [];
      totalItems.value = response.total || 0;
    }
  } catch (err) {
    console.error(err);
  } finally {
    loading.value = false;
  }
};

const loadStats = async () => {
  try {
    const response = await api.giftIssuance.getStats();
    if (response) {
      stats.value = response;
    }
  } catch (err) {
    console.error(err);
  }
};

const debouncedLoad = debounce(() => {
  page.value = 1;
  loadItems();
}, 300);

const issueGift = async (item: Api.GiftIssuance.Self) => {
  if (issuingId.value) return;
  
  issuingId.value = item.id;
  try {
    const response = await api.giftIssuance.issue(item.id);
    if (response?.message) {
      showToaster('success', response.message);
      await loadItems();
      await loadStats();
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка при выдаче подарка');
  } finally {
    issuingId.value = null;
  }
};

const changeStatus = async (item: Api.GiftIssuance.Self, newStatus: string) => {
  if (changingStatusId.value) return;
  if (item.status === newStatus) return;
  
  changingStatusId.value = item.id;
  try {
    // Проверяем, была ли предыдущая переход со статуса "ожидает выбора" и требуется ли автоматический выбор подарка
    const wasWaiting = item.status === 'pending';
    const selectingNow = newStatus === 'selected' || newStatus === 'issued';
    
    const response = await api.giftIssuance.updateStatus(item.id, {
      status: newStatus,
      auto_select_gift: wasWaiting && selectingNow, // Флаг для автоматического выбора подарка
    });
    
    if (response?.message) {
      showToaster('success', `Статус изменен на "${getStatusText(newStatus)}"`);
      
      // Если статус изменен на "выдано", отправляем push-уведомление
      if (newStatus === 'issued' && item.user) {
        try {
          await api.giftIssuance.sendNotification(item.id, {
            title: 'Подарок получен!',
            message: `Поздравляем! Вам выдан подарок: ${item.name}`,
          });
        } catch (notifErr) {
          console.error('Error sending notification:', notifErr);
        }
      }
      
      await Promise.all([loadItems(), loadStats()]);
    }
  } catch (err: any) {
    showToaster('error', err?.response?.data?.message || 'Ошибка при изменении статуса');
  } finally {
    changingStatusId.value = null;
  }
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'pending': return 'warning';
    case 'selected': return 'info';
    case 'activated': return 'primary';
    case 'issued': return 'success';
    default: return 'grey';
  }
};

const getStatusText = (status: string) => {
  const option = statusOptions.find(o => o.value === status);
  return option?.title || status;
};

const formatDate = (date: string | null) => {
  if (!date) return '—';
  return new Date(date).toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

onMounted(async () => {
  await Promise.all([loadItems(), loadStats()]);
});
</script>

<style scoped>
.gift-issuance {
  display: flex;
  flex-direction: column;
  gap: 1.75rem;
}

.gift-issuance__stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1.25rem;
}

.gift-issuance__stat-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1.5rem 1.25rem;
  background: linear-gradient(135deg, var(--color-bg-secondary) 0%, var(--color-bg-secondary) 100%);
  border-radius: 1rem;
  border-left: 4px solid var(--color-border);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.gift-issuance__stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.gift-issuance__stat-card--pending {
  border-left-color: var(--color-warning);
}

.gift-issuance__stat-card--selected {
  border-left-color: var(--color-info);
}

.gift-issuance__stat-card--issued {
  border-left-color: var(--color-success);
}

.gift-issuance__stat-value {
  font-size: 2rem;
  font-weight: 800;
  color: var(--color-text-primary);
  letter-spacing: -0.5px;
}

.gift-issuance__stat-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-secondary);
  text-align: center;
  line-height: 1.3;
}

.gift-issuance__filters {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  background: var(--color-bg-secondary);
  padding: 1.25rem;
  border-radius: 1rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

@media (min-width: 600px) {
  .gift-issuance__filters {
    flex-direction: row;
    gap: 1rem;
    align-items: center;
  }
}

.gift-issuance__search {
  flex: 1;
  max-width: 400px;
}

:deep(.gift-issuance__search .v-field) {
  background: var(--color-bg-tertiary);
  border-radius: 0.75rem;
}

.gift-issuance__filter {
  width: 100%;
}

@media (min-width: 600px) {
  .gift-issuance__filter {
    width: 200px;
  }
}

.gift-issuance__table-wrapper {
  background: var(--color-bg-secondary);
  border-radius: 1.25rem;
  padding: 1.5rem;
  overflow-x: auto;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.gift-issuance__user {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.gift-issuance__user-name {
  font-weight: 600;
  color: var(--color-text-primary);
}

.gift-issuance__user-phone {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
  font-weight: 400;
}

.gift-issuance__gift {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.gift-issuance__gift-image {
  width: 44px;
  height: 44px;
  object-fit: cover;
  border-radius: 0.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.gift-issuance__gift-placeholder {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg-tertiary);
  border-radius: 0.5rem;
  color: var(--color-text-secondary);
  font-size: 1.25rem;
}

.gift-issuance__gift-name {
  font-weight: 600;
  color: var(--color-text-primary);
}

.gift-issuance__issued-date {
  font-size: 0.8125rem;
  color: var(--color-success);
  font-weight: 500;
}

.gift-issuance__waiting {
  color: var(--color-text-tertiary);
  font-weight: 500;
}

/* Улучшенные стили для таблицы */
:deep(.gift-issuance .admin-table) {
  border-collapse: separate;
  border-spacing: 0;
}

:deep(.gift-issuance .admin-table thead tr) {
  background-color: var(--color-bg-tertiary);
}

:deep(.gift-issuance .admin-table th) {
  font-weight: 600;
  color: var(--color-text-primary);
  padding: 1rem !important;
  border-bottom: 2px solid var(--color-border);
  text-transform: uppercase;
  font-size: 0.75rem;
  letter-spacing: 0.5px;
}

:deep(.gift-issuance .admin-table tbody tr) {
  border-bottom: 1px solid var(--color-border);
  transition: background-color 0.2s ease;
}

:deep(.gift-issuance .admin-table tbody tr:hover) {
  background-color: rgba(0, 0, 0, 0.02);
}

:deep(.gift-issuance .admin-table td) {
  padding: 1rem !important;
  color: var(--color-text-primary);
}

:deep(.gift-issuance .admin-table .v-chip) {
  font-weight: 600;
  letter-spacing: 0.3px;
  cursor: pointer;
  transition: all 0.2s ease;
}

/* Статус ячейка */
.gift-issuance__status-cell {
  display: flex;
  align-items: center;
}

.gift-issuance__status-chip {
  cursor: pointer !important;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
}

.gift-issuance__status-chip:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15) !important;
}

/* Меню статусов */
:deep(.gift-issuance__status-menu) {
  border-radius: 0.75rem;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

:deep(.gift-issuance__status-menu .v-list-item) {
  border-radius: 0.5rem;
  margin: 0.25rem;
  transition: all 0.2s ease;
}

:deep(.gift-issuance__status-menu .v-list-item:hover) {
  background-color: var(--color-bg-tertiary);
}

:deep(.gift-issuance__status-menu-active) {
  background-color: var(--color-bg-tertiary) !important;
  font-weight: 600;
}

:deep(.gift-issuance__status-menu .v-list-item-title) {
  font-weight: 500;
}
</style>

