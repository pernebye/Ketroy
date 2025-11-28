<template>
  <section class="push-page">
    <!-- Статистика -->
    <div class="push-stats">
      <div class="push-stats__item push-stats__item--total">
        <Icon name="mdi:bell-outline" class="push-stats__icon" />
        <div class="push-stats__content">
          <span class="push-stats__value">{{ stats.total }}</span>
          <span class="push-stats__label">Всего</span>
        </div>
      </div>
      <div class="push-stats__item push-stats__item--scheduled">
        <Icon name="mdi:clock-outline" class="push-stats__icon" />
        <div class="push-stats__content">
          <span class="push-stats__value">{{ stats.scheduled }}</span>
          <span class="push-stats__label">Запланировано</span>
        </div>
      </div>
      <div class="push-stats__item push-stats__item--sent">
        <Icon name="mdi:check-circle-outline" class="push-stats__icon" />
        <div class="push-stats__content">
          <span class="push-stats__value">{{ stats.sent }}</span>
          <span class="push-stats__label">Отправлено</span>
        </div>
      </div>
      <div class="push-stats__item push-stats__item--failed">
        <Icon name="mdi:alert-circle-outline" class="push-stats__icon" />
        <div class="push-stats__content">
          <span class="push-stats__value">{{ stats.failed }}</span>
          <span class="push-stats__label">Ошибки</span>
        </div>
      </div>
    </div>

    <!-- Хедер с фильтрами и кнопкой создания -->
    <div class="push-header">
      <div class="push-filters">
        <v-select
          v-model="statusFilter"
          :items="statusOptions"
          item-title="label"
          item-value="value"
          density="compact"
          variant="outlined"
          hide-details
          class="push-filters__select"
        />
        <v-text-field
          v-model="searchQuery"
          placeholder="Поиск..."
          density="compact"
          variant="outlined"
          hide-details
          prepend-inner-icon="mdi-magnify"
          clearable
          class="push-filters__search"
          @update:model-value="debouncedSearch"
        />
      </div>
      <btn 
        text="Создать уведомление" 
        prepend-icon="mdi-plus"
        @click="openCreateModal"
      />
    </div>

    <!-- Таблица уведомлений -->
    <div class="push-table-wrapper">
      <div v-if="loading" class="push-loading">
        <v-progress-circular indeterminate color="var(--color-accent)" :size="48" :width="4" />
        <span>Загрузка...</span>
      </div>
      
      <div v-else-if="notifications.length === 0" class="push-empty">
        <Icon name="mdi:bell-off-outline" class="push-empty__icon" />
        <p>{{ t('admin.pushNotifications.empty') }}</p>
        <btn text="Создать первое уведомление" prepend-icon="mdi-plus" @click="openCreateModal" />
      </div>
      
      <div v-else class="push-table-scroll">
        <table class="push-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Заголовок</th>
              <th>Статус</th>
              <th>Запланировано</th>
              <th>Таргетинг</th>
              <th>Получатели</th>
              <th>Создано</th>
              <th>Действия</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="notification in notifications" 
              :key="notification.id"
              class="push-table__row"
              @click="openEditModal(notification)"
            >
              <td class="push-table__id">#{{ notification.id }}</td>
              <td class="push-table__title">
                <div class="push-table__title-content">
                  <strong>{{ notification.title }}</strong>
                  <span class="push-table__body">{{ truncate(notification.body, 60) }}</span>
                </div>
              </td>
              <td>
                <span 
                  class="push-status" 
                  :class="`push-status--${notification.status}`"
                >
                  {{ getStatusLabel(notification.status) }}
                </span>
              </td>
              <td class="push-table__date">
                {{ notification.scheduled_at ? formatDate(notification.scheduled_at) : '—' }}
              </td>
              <td class="push-table__targeting">
                <div v-if="hasTargeting(notification)" class="push-targeting">
                  <span v-if="notification.target_cities?.length" class="push-targeting__badge">
                    <Icon name="mdi:city" /> {{ notification.target_cities.length }}
                  </span>
                  <span v-if="notification.target_clothing_sizes?.length" class="push-targeting__badge">
                    <Icon name="mdi:tshirt-crew" /> {{ notification.target_clothing_sizes.length }}
                  </span>
                  <span v-if="notification.target_shoe_sizes?.length" class="push-targeting__badge">
                    <Icon name="mdi:shoe-formal" /> {{ notification.target_shoe_sizes.length }}
                  </span>
                </div>
                <span v-else class="push-targeting__all">Все</span>
              </td>
              <td class="push-table__recipients">
                <span class="push-recipients">
                  <Icon name="mdi:account-group" />
                  {{ notification.recipients_count }}
                  <template v-if="notification.sent_count > 0">
                    <span class="push-recipients__sent">({{ notification.sent_count }} отправлено)</span>
                  </template>
                </span>
              </td>
              <td class="push-table__date">
                {{ formatDate(notification.created_at) }}
              </td>
              <td class="push-table__actions" @click.stop>
                <div class="push-actions">
                  <v-tooltip text="Редактировать" location="top">
                    <template #activator="{ props }">
                      <button 
                        v-bind="props"
                        class="push-action push-action--edit"
                        :disabled="!isEditable(notification)"
                        @click="openEditModal(notification)"
                      >
                        <Icon name="mdi:pencil" />
                      </button>
                    </template>
                  </v-tooltip>
                  
                  <v-tooltip text="Отправить сейчас" location="top">
                    <template #activator="{ props }">
                      <button 
                        v-bind="props"
                        class="push-action push-action--send"
                        :disabled="!canSend(notification)"
                        @click="handleSendNow(notification)"
                      >
                        <Icon name="mdi:send" />
                      </button>
                    </template>
                  </v-tooltip>
                  
                  <v-tooltip text="Дублировать" location="top">
                    <template #activator="{ props }">
                      <button 
                        v-bind="props"
                        class="push-action push-action--duplicate"
                        @click="handleDuplicate(notification)"
                      >
                        <Icon name="mdi:content-copy" />
                      </button>
                    </template>
                  </v-tooltip>
                  
                  <v-tooltip text="Отменить" location="top">
                    <template #activator="{ props }">
                      <button 
                        v-bind="props"
                        class="push-action push-action--cancel"
                        :disabled="!canCancel(notification)"
                        @click="handleCancel(notification)"
                      >
                        <Icon name="mdi:cancel" />
                      </button>
                    </template>
                  </v-tooltip>
                  
                  <v-tooltip text="Удалить" location="top">
                    <template #activator="{ props }">
                      <button 
                        v-bind="props"
                        class="push-action push-action--delete"
                        :disabled="!canDelete(notification)"
                        @click="handleDelete(notification)"
                      >
                        <Icon name="mdi:delete" />
                      </button>
                    </template>
                  </v-tooltip>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <!-- Пагинация -->
      <div v-if="totalPages > 1" class="push-pagination">
        <v-pagination
          v-model="currentPage"
          :length="totalPages"
          :total-visible="5"
          density="compact"
          @update:model-value="loadNotifications"
        />
      </div>
    </div>

    <!-- Модальное окно создания/редактирования -->
    <v-dialog v-model="showModal" max-width="700" persistent>
      <v-card class="push-modal">
        <v-card-title class="push-modal__title">
          {{ editingNotification ? 'Редактировать уведомление' : 'Создать уведомление' }}
        </v-card-title>
        
        <v-card-text class="push-modal__content">
          <v-form ref="formRef" @submit.prevent="handleSubmit">
            <!-- Заголовок -->
            <v-text-field
              v-model="form.title"
              label="Заголовок"
              variant="outlined"
              :rules="[rules.required, rules.maxLength(255)]"
              counter="255"
            />
            
            <!-- Текст уведомления -->
            <v-textarea
              v-model="form.body"
              label="Текст уведомления"
              variant="outlined"
              :rules="[rules.required, rules.maxLength(2000)]"
              counter="2000"
              rows="4"
              auto-grow
            />
            
            <!-- Время отправки -->
            <div class="push-modal__schedule">
              <v-checkbox
                v-model="form.send_immediately"
                label="Отправить сразу"
                hide-details
                color="var(--color-accent)"
              />
              
              <div v-if="!form.send_immediately" class="push-modal__datetime">
                <v-text-field
                  v-model="form.scheduled_date"
                  label="Дата"
                  type="date"
                  variant="outlined"
                  :rules="[!form.send_immediately ? rules.required : () => true]"
                />
                <v-text-field
                  v-model="form.scheduled_time"
                  label="Время"
                  type="time"
                  variant="outlined"
                  :rules="[!form.send_immediately ? rules.required : () => true]"
                />
              </div>
            </div>
            
            <!-- Таргетинг -->
            <div class="push-modal__targeting">
              <h4 class="push-modal__section-title">
                <Icon name="mdi:target" />
                Таргетинг
                <span class="push-modal__targeting-hint">(фильтры суммируются)</span>
              </h4>
              
              <v-select
                v-model="form.target_cities"
                :items="targetingOptions.cities"
                label="Города"
                variant="outlined"
                multiple
                chips
                closable-chips
                clearable
                @update:model-value="previewRecipients"
              />
              
              <v-select
                v-model="form.target_clothing_sizes"
                :items="targetingOptions.clothing_sizes"
                label="Размеры одежды"
                variant="outlined"
                multiple
                chips
                closable-chips
                clearable
                @update:model-value="previewRecipients"
              />
              
              <v-select
                v-model="form.target_shoe_sizes"
                :items="targetingOptions.shoe_sizes"
                label="Размеры обуви"
                variant="outlined"
                multiple
                chips
                closable-chips
                clearable
                @update:model-value="previewRecipients"
              />
              
              <!-- Предпросмотр получателей -->
              <div class="push-modal__preview">
                <Icon name="mdi:account-group" />
                <span>
                  Получателей: 
                  <strong :class="{ 'push-modal__preview--loading': previewLoading }">
                    {{ previewLoading ? '...' : recipientsPreview }}
                  </strong>
                </span>
              </div>
            </div>
          </v-form>
        </v-card-text>
        
        <v-card-actions class="push-modal__actions">
          <v-spacer />
          <v-btn variant="text" @click="closeModal">Отмена</v-btn>
          <v-btn 
            color="var(--color-accent)" 
            variant="flat"
            :loading="submitting"
            @click="handleSubmit"
          >
            {{ editingNotification ? 'Сохранить' : (form.send_immediately ? 'Создать и отправить' : 'Создать') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Диалог подтверждения -->
    <v-dialog v-model="showConfirmDialog" max-width="400">
      <v-card>
        <v-card-title>{{ confirmDialog.title }}</v-card-title>
        <v-card-text>{{ confirmDialog.message }}</v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="showConfirmDialog = false">Отмена</v-btn>
          <v-btn 
            :color="confirmDialog.color || 'var(--color-accent)'" 
            variant="flat"
            :loading="confirmDialog.loading"
            @click="confirmDialog.action"
          >
            {{ confirmDialog.confirmText }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </section>
</template>

<script setup lang="ts">
import { t } from '~/composables';

// Простой debounce без внешних зависимостей
const debounce = <T extends (...args: any[]) => any>(fn: T, delay: number) => {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
};

useHead({
  title: () => t('admin.pushNotifications.title'),
});

// Состояние
const loading = ref(true);
const submitting = ref(false);
const notifications = ref<Api.PushNotification.Self[]>([]);
const stats = ref<Api.PushNotification.Stats>({
  total: 0,
  draft: 0,
  scheduled: 0,
  sent: 0,
  failed: 0,
  cancelled: 0,
  total_sent_count: 0,
  total_recipients: 0,
});

// Фильтры и пагинация
const statusFilter = ref('all');
const searchQuery = ref('');
const currentPage = ref(1);
const totalPages = ref(1);
const perPage = 15;

const statusOptions = [
  { label: 'Все статусы', value: 'all' },
  { label: 'Черновики', value: 'draft' },
  { label: 'Запланировано', value: 'scheduled' },
  { label: 'Отправлено', value: 'sent' },
  { label: 'Ошибки', value: 'failed' },
  { label: 'Отменено', value: 'cancelled' },
];

// Модальное окно
const showModal = ref(false);
const editingNotification = ref<Api.PushNotification.Self | null>(null);
const formRef = ref<any>(null);

const form = reactive({
  title: '',
  body: '',
  send_immediately: true,
  scheduled_date: '',
  scheduled_time: '',
  target_cities: [] as string[],
  target_clothing_sizes: [] as string[],
  target_shoe_sizes: [] as string[],
});

// Опции таргетинга
const targetingOptions = ref<Api.PushNotification.TargetingOptions>({
  cities: [],
  clothing_sizes: [],
  shoe_sizes: [],
});

// Предпросмотр получателей
const recipientsPreview = ref(0);
const previewLoading = ref(false);

// Диалог подтверждения
const showConfirmDialog = ref(false);
const confirmDialog = reactive({
  title: '',
  message: '',
  confirmText: 'Подтвердить',
  color: 'var(--color-accent)',
  loading: false,
  action: () => {},
});

// Правила валидации
const rules = {
  required: (v: string) => !!v || 'Обязательное поле',
  maxLength: (max: number) => (v: string) => !v || v.length <= max || `Максимум ${max} символов`,
};

// Методы
const loadNotifications = async () => {
  loading.value = true;
  try {
    const response = await api.pushNotifications.getAll({
      page: currentPage.value,
      per_page: perPage,
      status: statusFilter.value !== 'all' ? statusFilter.value : undefined,
      search: searchQuery.value || undefined,
    });
    
    notifications.value = response.data;
    totalPages.value = response.last_page;
  } catch (error) {
    console.error('Error loading notifications:', error);
    showToaster('error', 'Ошибка загрузки уведомлений');
  } finally {
    loading.value = false;
  }
};

const loadStats = async () => {
  try {
    const response = await api.pushNotifications.getStats();
    stats.value = response;
  } catch (error) {
    console.error('Error loading stats:', error);
  }
};

const loadTargetingOptions = async () => {
  try {
    const response = await api.pushNotifications.getTargetingOptions();
    targetingOptions.value = response;
  } catch (error) {
    console.error('Error loading targeting options:', error);
  }
};

const previewRecipients = debounce(async () => {
  previewLoading.value = true;
  try {
    const response = await api.pushNotifications.previewRecipients({
      target_cities: form.target_cities.length > 0 ? form.target_cities : undefined,
      target_clothing_sizes: form.target_clothing_sizes.length > 0 ? form.target_clothing_sizes : undefined,
      target_shoe_sizes: form.target_shoe_sizes.length > 0 ? form.target_shoe_sizes : undefined,
    });
    recipientsPreview.value = response.recipients_count;
  } catch (error) {
    console.error('Error previewing recipients:', error);
  } finally {
    previewLoading.value = false;
  }
}, 300);

const debouncedSearch = debounce(() => {
  currentPage.value = 1;
  loadNotifications();
}, 300);

const openCreateModal = () => {
  editingNotification.value = null;
  resetForm();
  previewRecipients();
  showModal.value = true;
};

const openEditModal = (notification: Api.PushNotification.Self) => {
  if (!isEditable(notification)) return;
  
  editingNotification.value = notification;
  form.title = notification.title;
  form.body = notification.body;
  form.send_immediately = !notification.scheduled_at;
  
  if (notification.scheduled_at) {
    const date = new Date(notification.scheduled_at);
    form.scheduled_date = date.toISOString().split('T')[0];
    form.scheduled_time = date.toTimeString().slice(0, 5);
  }
  
  form.target_cities = notification.target_cities || [];
  form.target_clothing_sizes = notification.target_clothing_sizes || [];
  form.target_shoe_sizes = notification.target_shoe_sizes || [];
  
  recipientsPreview.value = notification.recipients_count;
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  editingNotification.value = null;
  resetForm();
};

const resetForm = () => {
  form.title = '';
  form.body = '';
  form.send_immediately = true;
  form.scheduled_date = '';
  form.scheduled_time = '';
  form.target_cities = [];
  form.target_clothing_sizes = [];
  form.target_shoe_sizes = [];
  recipientsPreview.value = 0;
};

const handleSubmit = async () => {
  const { valid } = await formRef.value?.validate();
  if (!valid) return;
  
  submitting.value = true;
  
  try {
    const data: Api.PushNotification.New = {
      title: form.title,
      body: form.body,
      send_immediately: form.send_immediately,
      target_cities: form.target_cities.length > 0 ? form.target_cities : null,
      target_clothing_sizes: form.target_clothing_sizes.length > 0 ? form.target_clothing_sizes : null,
      target_shoe_sizes: form.target_shoe_sizes.length > 0 ? form.target_shoe_sizes : null,
    };
    
    if (!form.send_immediately && form.scheduled_date && form.scheduled_time) {
      data.scheduled_at = `${form.scheduled_date}T${form.scheduled_time}:00`;
    }
    
    if (editingNotification.value) {
      await api.pushNotifications.update(editingNotification.value.id, data);
      showToaster('success', 'Уведомление обновлено');
    } else {
      await api.pushNotifications.create(data);
      showToaster('success', form.send_immediately ? 'Уведомление создано и отправляется' : 'Уведомление создано');
    }
    
    closeModal();
    loadNotifications();
    loadStats();
  } catch (error) {
    console.error('Error submitting notification:', error);
    showToaster('error', 'Ошибка при сохранении');
  } finally {
    submitting.value = false;
  }
};

const handleSendNow = (notification: Api.PushNotification.Self) => {
  confirmDialog.title = 'Отправить уведомление?';
  confirmDialog.message = `Уведомление "${notification.title}" будет отправлено ${notification.recipients_count} получателям.`;
  confirmDialog.confirmText = 'Отправить';
  confirmDialog.color = 'var(--color-accent)';
  confirmDialog.action = async () => {
    confirmDialog.loading = true;
    try {
      await api.pushNotifications.sendNow(notification.id);
      showToaster('success', 'Уведомление отправляется');
      showConfirmDialog.value = false;
      loadNotifications();
      loadStats();
    } catch (error) {
      showToaster('error', 'Ошибка при отправке');
    } finally {
      confirmDialog.loading = false;
    }
  };
  showConfirmDialog.value = true;
};

const handleDuplicate = async (notification: Api.PushNotification.Self) => {
  try {
    await api.pushNotifications.duplicate(notification.id);
    showToaster('success', 'Копия создана');
    loadNotifications();
    loadStats();
  } catch (error) {
    showToaster('error', 'Ошибка при дублировании');
  }
};

const handleCancel = (notification: Api.PushNotification.Self) => {
  confirmDialog.title = 'Отменить уведомление?';
  confirmDialog.message = `Уведомление "${notification.title}" будет отменено и не будет отправлено.`;
  confirmDialog.confirmText = 'Отменить';
  confirmDialog.color = 'warning';
  confirmDialog.action = async () => {
    confirmDialog.loading = true;
    try {
      await api.pushNotifications.cancel(notification.id);
      showToaster('success', 'Уведомление отменено');
      showConfirmDialog.value = false;
      loadNotifications();
      loadStats();
    } catch (error) {
      showToaster('error', 'Ошибка при отмене');
    } finally {
      confirmDialog.loading = false;
    }
  };
  showConfirmDialog.value = true;
};

const handleDelete = (notification: Api.PushNotification.Self) => {
  confirmDialog.title = 'Удалить уведомление?';
  confirmDialog.message = `Уведомление "${notification.title}" будет удалено безвозвратно.`;
  confirmDialog.confirmText = 'Удалить';
  confirmDialog.color = 'error';
  confirmDialog.action = async () => {
    confirmDialog.loading = true;
    try {
      await api.pushNotifications.delete(notification.id);
      showToaster('success', 'Уведомление удалено');
      showConfirmDialog.value = false;
      loadNotifications();
      loadStats();
    } catch (error) {
      showToaster('error', 'Ошибка при удалении');
    } finally {
      confirmDialog.loading = false;
    }
  };
  showConfirmDialog.value = true;
};

// Хелперы
const getStatusLabel = (status: Api.PushNotification.Status) => {
  const labels: Record<Api.PushNotification.Status, string> = {
    draft: 'Черновик',
    scheduled: 'Запланировано',
    sending: 'Отправляется',
    sent: 'Отправлено',
    failed: 'Ошибка',
    cancelled: 'Отменено',
  };
  return labels[status] || status;
};

const formatDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const truncate = (text: string, length: number) => {
  return text.length > length ? text.slice(0, length) + '...' : text;
};

const hasTargeting = (notification: Api.PushNotification.Self) => {
  return (notification.target_cities?.length || 0) > 0 ||
         (notification.target_clothing_sizes?.length || 0) > 0 ||
         (notification.target_shoe_sizes?.length || 0) > 0;
};

const isEditable = (notification: Api.PushNotification.Self) => {
  return ['draft', 'scheduled'].includes(notification.status);
};

const canSend = (notification: Api.PushNotification.Self) => {
  return ['draft', 'scheduled', 'failed'].includes(notification.status);
};

const canCancel = (notification: Api.PushNotification.Self) => {
  return ['draft', 'scheduled'].includes(notification.status);
};

const canDelete = (notification: Api.PushNotification.Self) => {
  return !['sending', 'sent'].includes(notification.status);
};

// Watchers
watch(statusFilter, () => {
  currentPage.value = 1;
  loadNotifications();
});

// Lifecycle
onMounted(async () => {
  await Promise.all([
    loadNotifications(),
    loadStats(),
    loadTargetingOptions(),
  ]);
});
</script>

<style scoped>
.push-page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Статистика */
.push-stats {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

@media (min-width: 768px) {
  .push-stats {
    grid-template-columns: repeat(4, 1fr);
  }
}

.push-stats__item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  border-radius: 1rem;
  background: var(--color-bg-card);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.push-stats__item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.push-stats__icon {
  font-size: 2rem;
  opacity: 0.8;
}

.push-stats__item--total .push-stats__icon { color: var(--color-accent); }
.push-stats__item--scheduled .push-stats__icon { color: #f59e0b; }
.push-stats__item--sent .push-stats__icon { color: #10b981; }
.push-stats__item--failed .push-stats__icon { color: #ef4444; }

.push-stats__content {
  display: flex;
  flex-direction: column;
}

.push-stats__value {
  font-size: 1.75rem;
  font-weight: 700;
  color: var(--color-text-primary);
  line-height: 1;
}

.push-stats__label {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin-top: 0.25rem;
}

/* Хедер */
.push-header {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

@media (min-width: 768px) {
  .push-header {
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
  }
}

.push-filters {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  flex: 1;
}

@media (min-width: 600px) {
  .push-filters {
    flex-direction: row;
    gap: 1rem;
  }
}

.push-filters__select {
  min-width: 180px;
}

.push-filters__search {
  max-width: 300px;
}

/* Таблица */
.push-table-wrapper {
  background: var(--color-bg-card);
  border-radius: 1rem;
  overflow: hidden;
}

.push-loading,
.push-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 4rem 2rem;
  text-align: center;
  color: var(--color-text-muted);
}

.push-empty__icon {
  font-size: 4rem;
  opacity: 0.5;
}

.push-table-scroll {
  overflow-x: auto;
}

.push-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 900px;
}

.push-table th,
.push-table td {
  padding: 1rem;
  text-align: left;
  border-bottom: 1px solid var(--color-border);
}

.push-table th {
  font-weight: 600;
  color: var(--color-text-muted);
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background: var(--color-bg-secondary);
}

.push-table__row {
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.push-table__row:hover {
  background: var(--color-bg-hover);
}

.push-table__id {
  font-weight: 600;
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.push-table__title-content {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.push-table__title-content strong {
  color: var(--color-text-primary);
}

.push-table__body {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.push-table__date {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  white-space: nowrap;
}

/* Статус */
.push-status {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.push-status--draft {
  background: rgba(107, 114, 128, 0.15);
  color: #6b7280;
}

.push-status--scheduled {
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
}

.push-status--sending {
  background: rgba(59, 130, 246, 0.15);
  color: #3b82f6;
}

.push-status--sent {
  background: rgba(16, 185, 129, 0.15);
  color: #10b981;
}

.push-status--failed {
  background: rgba(239, 68, 68, 0.15);
  color: #ef4444;
}

.push-status--cancelled {
  background: rgba(156, 163, 175, 0.15);
  color: #9ca3af;
}

/* Таргетинг */
.push-targeting {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.push-targeting__badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.5rem;
  border-radius: 0.375rem;
  background: var(--color-bg-secondary);
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.push-targeting__all {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

/* Получатели */
.push-recipients {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  font-weight: 500;
  color: var(--color-text-primary);
}

.push-recipients__sent {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

/* Действия */
.push-actions {
  display: flex;
  gap: 0.5rem;
}

.push-action {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 0.5rem;
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.2s ease;
}

.push-action:hover:not(:disabled) {
  background: var(--color-bg-secondary);
}

.push-action:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.push-action--edit:hover:not(:disabled) { color: #3b82f6; }
.push-action--send:hover:not(:disabled) { color: #10b981; }
.push-action--duplicate:hover:not(:disabled) { color: #8b5cf6; }
.push-action--cancel:hover:not(:disabled) { color: #f59e0b; }
.push-action--delete:hover:not(:disabled) { color: #ef4444; }

/* Пагинация */
.push-pagination {
  display: flex;
  justify-content: center;
  padding: 1rem;
  border-top: 1px solid var(--color-border);
}

/* Модальное окно */
.push-modal {
  background: var(--color-bg-card) !important;
}

.push-modal__title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text-primary);
  padding: 1.5rem 1.5rem 1rem;
}

.push-modal__content {
  padding: 0 1.5rem 1rem;
}

.push-modal__schedule {
  margin: 1rem 0;
}

.push-modal__datetime {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-top: 1rem;
}

.push-modal__targeting {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--color-border);
}

.push-modal__section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.push-modal__targeting-hint {
  font-size: 0.75rem;
  font-weight: 400;
  color: var(--color-text-muted);
}

.push-modal__preview {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem;
  margin-top: 1rem;
  border-radius: 0.75rem;
  background: var(--color-bg-secondary);
  color: var(--color-text-secondary);
}

.push-modal__preview strong {
  color: var(--color-accent);
}

.push-modal__preview--loading {
  opacity: 0.5;
}

.push-modal__actions {
  padding: 1rem 1.5rem 1.5rem;
}
</style>

