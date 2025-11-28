<template>
  <div class="admin-list-container">
    <div class="admin-list-header">
      <p v-if="title" class="admin-list-title">{{ title }}</p>
      <div v-if="list && list.length" class="admin-list-per-page">
        <span class="admin-list-per-page__label">Показывать:</span>
        <v-select
          v-model="perPage"
          :items="perPageOptions"
          density="compact"
          variant="outlined"
          hide-details
          class="admin-list-per-page__select"
          @update:model-value="onPerPageChange"
        />
      </div>
    </div>
    <div v-if="list && list.length">
      <v-slide-y-transition group tag="div" class="admin-list">
        <template v-for="(item, index) of list.filter((_, index) => index >= (page - 1) * perPage && index < page * perPage)" :key="index">
          <div class="admin-list-item">
            <div class="admin-list-item__image">
              <fade>
                <img
                  v-if="item && item.image && typeof item.image === 'string' && isImageUrl(item.image)"
                  class="admin-list-item__img"
                  width="80"
                  height="80"
                  :src="item.image"
                  alt="Item Image"
                  draggable="false"
                  @error="handleImageError"
                />
                <video v-else-if="item.image && item.image.path && isVideoUrl(item.image.path)" class="admin-list-item__video" :src="item.image.path"></video>
                <div v-else class="admin-list-item__placeholder">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M21.68 16.96L14.32 7.39C13.8 6.71 13.06 6.32 12.25 6.29C11.44 6.26 10.67 6.6 10.11 7.22L8.59 8.97L7.54 7.54C7 6.82 6.23 6.41 5.39 6.39C4.55 6.36 3.76 6.72 3.18 7.4L1.58 9.32C1.24 9.73 1 10.2 0.88 10.71C0.5 12.32 0.71 14.05 1.46 15.56C2.29 17.23 3.65 18.43 5.39 19C5.94 19.16 6.51 19.25 7.08 19.25H16.92C17.49 19.25 18.06 19.16 18.61 19C20.35 18.43 21.71 17.23 22.54 15.56C22.88 14.88 23.1 14.15 23.18 13.4L21.68 16.96Z" fill="currentColor" opacity="0.4"/>
                    <path d="M9 10.38C10.3144 10.38 11.38 9.31443 11.38 8C11.38 6.68558 10.3144 5.62 9 5.62C7.68558 5.62 6.62 6.68558 6.62 8C6.62 9.31443 7.68558 10.38 9 10.38Z" fill="currentColor"/>
                    <path d="M21.6799 16.96L14.3199 7.39C13.7999 6.71 13.0599 6.32 12.2499 6.29C11.4399 6.26 10.6699 6.6 10.1099 7.22L8.58994 8.97L7.53994 7.54C6.99994 6.82 6.22994 6.41 5.38994 6.39C4.54994 6.36 3.75994 6.72 3.17994 7.4L1.57994 9.32C0.689941 10.4 0.379941 11.83 0.729941 13.17C1.07994 14.51 2.04994 15.58 3.33994 16.04C3.84994 16.22 4.38994 16.32 4.92994 16.32H19.0699C19.6099 16.32 20.1499 16.22 20.6599 16.04C21.0099 15.92 21.3299 15.76 21.6199 15.56" fill="currentColor"/>
                  </svg>
                </div>
              </fade>
            </div>
            <div class="admin-list-item__content">
              <div class="admin-list-item__info">
                <span class="admin-list-item__title">{{ String(item?.title ? item.title: item.name).slice(0, 60) }}</span>
                <expand>
                  <span v-if="item.description" class="admin-list-item__desc">{{
                    item.description.length > 50 ? String(item.description).slice(0, 50) + '...' : item.description
                  }}</span>
                </expand>
              </div>
              <div class="admin-list-actions">
                <fade>
                  <NuxtLink v-if="item.title" class="admin-list-action admin-list-action--edit" :to="{ name: item.name, params: { tab: String($route.query.tab), id: item.id } }">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path
                        d="M16.19 2H7.81C4.17 2 2 4.17 2 7.81V16.18C2 19.83 4.17 22 7.81 22H16.18C19.82 22 21.99 19.83 21.99 16.19V7.81C22 4.17 19.83 2 16.19 2ZM10.95 17.51C10.66 17.8 10.11 18.08 9.71 18.14L7.25 18.49C7.16 18.5 7.07 18.51 6.98 18.51C6.57 18.51 6.19 18.37 5.92 18.1C5.59 17.77 5.45 17.29 5.53 16.76L5.88 14.3C5.94 13.89 6.21 13.35 6.51 13.06L10.97 8.6C11.05 8.81 11.13 9.02 11.24 9.26C11.34 9.47 11.45 9.69 11.57 9.89C11.67 10.06 11.78 10.22 11.87 10.34C11.98 10.51 12.11 10.67 12.19 10.76C12.24 10.83 12.28 10.88 12.3 10.9C12.55 11.2 12.84 11.48 13.09 11.69C13.16 11.76 13.2 11.8 13.22 11.81C13.37 11.93 13.52 12.05 13.65 12.14C13.81 12.26 13.97 12.37 14.14 12.46C14.34 12.58 14.56 12.69 14.78 12.8C15.01 12.9 15.22 12.99 15.43 13.06L10.95 17.51ZM17.37 11.09L16.45 12.02C16.39 12.08 16.31 12.11 16.23 12.11C16.2 12.11 16.16 12.11 16.14 12.1C14.11 11.52 12.49 9.9 11.91 7.87C11.88 7.76 11.91 7.64 11.99 7.57L12.92 6.64C14.44 5.12 15.89 5.15 17.38 6.64C18.14 7.4 18.51 8.13 18.51 8.89C18.5 9.61 18.13 10.33 17.37 11.09Z"
                        fill="currentColor"
                      />
                    </svg>
                  </NuxtLink>
                </fade>
                <fade>
                  <button v-if="showDeleteBtn" class="admin-list-action admin-list-action--delete">
                    <confirm @delete="onDelete(item)" />
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path
                        d="M21.07 5.23C19.46 5.07 17.85 4.95 16.23 4.86V4.85L16.01 3.55C15.86 2.63 15.64 1.25 13.3 1.25H10.68C8.34997 1.25 8.12997 2.57 7.96997 3.54L7.75997 4.82C6.82997 4.88 5.89997 4.94 4.96997 5.03L2.92997 5.23C2.50997 5.27 2.20997 5.64 2.24997 6.05C2.28997 6.46 2.64997 6.76 3.06997 6.72L5.10997 6.52C10.35 6 15.63 6.2 20.93 6.73C20.96 6.73 20.98 6.73 21.01 6.73C21.39 6.73 21.72 6.44 21.76 6.05C21.79 5.64 21.49 5.27 21.07 5.23Z"
                        fill="currentColor"
                      />
                      <path
                        d="M19.23 8.14C18.99 7.89 18.66 7.75 18.32 7.75H5.67999C5.33999 7.75 4.99999 7.89 4.76999 8.14C4.53999 8.39 4.40999 8.73 4.42999 9.08L5.04999 19.34C5.15999 20.86 5.29999 22.76 8.78999 22.76H15.21C18.7 22.76 18.84 20.87 18.95 19.34L19.57 9.09C19.59 8.73 19.46 8.39 19.23 8.14ZM13.66 17.75H10.33C9.91999 17.75 9.57999 17.41 9.57999 17C9.57999 16.59 9.91999 16.25 10.33 16.25H13.66C14.07 16.25 14.41 16.59 14.41 17C14.41 17.41 14.07 17.75 13.66 17.75ZM14.5 13.75H9.49999C9.08999 13.75 8.74999 13.41 8.74999 13C8.74999 12.59 9.08999 12.25 9.49999 12.25H14.5C14.91 12.25 15.25 12.59 15.25 13C15.25 13.41 14.91 13.75 14.5 13.75Z"
                        fill="currentColor"
                      />
                    </svg>
                  </button>
                </fade>
              </div>
            </div>
          </div>
        </template>
      </v-slide-y-transition>
      <expand>
        <v-pagination
          v-if="list.length > perPage"
          v-model="page"
          :length="Math.ceil(list.length / perPage)"
          class="admin-pagination tw-mt-[22px]"
          rounded="lg"
          next-icon="mdi-menu-right"
          prev-icon="mdi-menu-left"
          :color="styles.primary"
          show-first-last-page
        />
      </expand>
    </div>
    <div v-else-if="loading" class="admin-list-loading">
      <div class="admin-list-loading__content">
        <v-progress-circular
          indeterminate
          color="var(--color-accent)"
          :size="48"
          :width="4"
        />
        <span>Загрузка данных...</span>
      </div>
    </div>
    <div v-else class="admin-list-empty">
      <div class="admin-list-empty__content">
        <icon name="pepicons-pencil:list-off" class="admin-list-empty__icon"></icon>
        <span>Нет данных</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  list: {
    type: Array as PropType<Types.List>,
    default: [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
});
const emit = defineEmits(['delete']);

// Опции для выбора количества элементов
const perPageOptions = [4, 8, 12, 16, 20];

// Единый ключ для всех списков
const STORAGE_KEY = 'admin_perPage_global';

// Получаем сохранённое значение из localStorage
const getStoredPerPage = (): number => {
  if (typeof window === 'undefined') return 4;
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored) {
    const value = parseInt(stored, 10);
    if (perPageOptions.includes(value)) return value;
  }
  return 4;
};

const perPage = ref<number>(getStoredPerPage());
const page = ref<number>(1);

// Сохранение в localStorage при изменении
const onPerPageChange = (value: number) => {
  if (typeof window !== 'undefined') {
    localStorage.setItem(STORAGE_KEY, String(value));
  }
  page.value = 1; // Сброс на первую страницу
};

// Слушаем изменения в localStorage от других компонентов
onMounted(() => {
  if (typeof window !== 'undefined') {
    window.addEventListener('storage', (e) => {
      if (e.key === STORAGE_KEY && e.newValue) {
        const value = parseInt(e.newValue, 10);
        if (perPageOptions.includes(value)) {
          perPage.value = value;
          page.value = 1;
        }
      }
    });
  }
});

const showDeleteBtn = computed(() => {
  return true;
});

// Проверка URL изображения - максимально гибкая
const isImageUrl = (url: string): boolean => {
  if (!url || typeof url !== 'string') return false;
  
  // Если это полный URL - показываем (доверяем серверу)
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return true;
  }
  
  // Если это base64 изображение
  if (url.startsWith('data:image/')) {
    return true;
  }
  
  // Локальный путь с /images
  return url.includes('/images') || url.includes('/image');
};

// Проверка URL видео
const isVideoUrl = (url: string): boolean => {
  if (!url) return false;
  const videoExtensions = ['.mp4', '.webm', '.ogg', '.mov', '.avi'];
  const hasVideoExtension = videoExtensions.some(ext => url.toLowerCase().includes(ext));
  const hasVideosPath = url.includes('/videos') || url.includes('/video');
  return hasVideoExtension || hasVideosPath;
};

// Обработка ошибки загрузки изображения
const handleImageError = (event: Event) => {
  const img = event.target as HTMLImageElement;
  if (img) {
    img.style.display = 'none';
    // Показываем placeholder
    const placeholder = img.parentElement?.querySelector('.admin-list-item__placeholder');
    if (placeholder) {
      (placeholder as HTMLElement).style.display = 'flex';
    }
  }
};

const onDelete = (item: any) => {
  if (page.value === Math.ceil(props.list.length / perPage)) if (page.value !== 1) page.value--;
  emit('delete', item.id);
};

watch(
  () => props.title,
  (newVal, oldVal) => {
    if (newVal !== oldVal && page.value !== 1) page.value = 1;
  },
);
</script>

<style>
.admin-list-container {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-card);
  color: var(--color-text-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
}

@media (min-width: 600px) {
  .admin-list-container {
    gap: 1.25rem;
    padding: 1.5rem;
    border-radius: 1.5rem;
  }
}

@media (min-width: 960px) {
  .admin-list-container {
    gap: 1.375rem;
    padding: 2rem;
    border-radius: 1.875rem;
  }
}

.admin-list-header {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

@media (min-width: 600px) {
  .admin-list-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }
}

.admin-list-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--color-text-primary);
  margin: 0;
}

@media (min-width: 600px) {
  .admin-list-title {
    font-size: 1.5rem;
  }
}

.admin-list-per-page {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.admin-list-per-page__label {
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  white-space: nowrap;
}

.admin-list-per-page__select {
  width: 80px;
  flex-shrink: 0;
}

.admin-list-per-page__select .v-field {
  background-color: var(--color-bg-tertiary) !important;
  border-radius: 8px !important;
}

.admin-list-per-page__select .v-field__input {
  padding: 4px 8px !important;
  min-height: 32px !important;
  font-size: 0.875rem;
  color: var(--color-text-primary) !important;
}

.admin-list-per-page__select .v-field__outline {
  --v-field-border-opacity: 0.2;
}

.admin-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

@media (min-width: 600px) {
  .admin-list {
    gap: 16px;
  }
}

@media (min-width: 960px) {
  .admin-list {
    gap: 22px;
  }
}

.admin-list-item {
  display: flex;
  align-items: center;
  min-height: 66px;
  height: auto;
  padding: 8px;
  border-radius: 10px;
  background-color: var(--color-bg-secondary);
  box-shadow: 0 4px 6px -1px var(--color-shadow);
  transition: background-color 0.3s ease, box-shadow 0.3s ease;
}

@media (min-width: 400px) {
  .admin-list-item {
    min-height: 72px;
    padding: 10px;
    border-radius: 12px;
  }
}

@media (min-width: 600px) {
  .admin-list-item {
    min-height: 90px;
    padding: 12px;
    border-radius: 14px;
  }
}

@media (min-width: 960px) {
  .admin-list-item {
    min-height: 108px;
    padding: 14px;
    border-radius: 16px;
  }
}

.admin-list-item:hover {
  box-shadow: 0 10px 15px -3px var(--color-shadow);
}

.admin-list-item__image {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 50px;
  flex-shrink: 0;
  margin-right: 0.5rem;
}

@media (min-width: 400px) {
  .admin-list-item__image {
    width: 56px;
    margin-right: 0.625rem;
  }
}

@media (min-width: 600px) {
  .admin-list-item__image {
    width: 70px;
    margin-right: 1rem;
  }
}

@media (min-width: 960px) {
  .admin-list-item__image {
    width: 80px;
    margin-right: 1.25rem;
  }
}

.admin-list-item__img,
.admin-list-item__video {
  width: 50px;
  height: 50px;
  border-radius: 6px;
  object-fit: cover;
}

@media (min-width: 400px) {
  .admin-list-item__img,
  .admin-list-item__video {
    width: 56px;
    height: 56px;
  }
}

@media (min-width: 600px) {
  .admin-list-item__img,
  .admin-list-item__video {
    width: 70px;
    height: 70px;
    border-radius: 8px;
  }
}

@media (min-width: 960px) {
  .admin-list-item__img,
  .admin-list-item__video {
    width: 80px;
    height: 80px;
  }
}

.admin-list-item__placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 50px;
  height: 50px;
  border-radius: 6px;
  background-color: var(--color-bg-tertiary);
  color: var(--color-text-muted);
  transition: background-color 0.3s ease;
}

@media (min-width: 400px) {
  .admin-list-item__placeholder {
    width: 56px;
    height: 56px;
  }
}

@media (min-width: 600px) {
  .admin-list-item__placeholder {
    width: 70px;
    height: 70px;
    border-radius: 8px;
  }
  
  .admin-list-item__placeholder svg {
    width: 28px;
    height: 28px;
  }
}

@media (min-width: 960px) {
  .admin-list-item__placeholder {
    width: 80px;
    height: 80px;
  }
  
  .admin-list-item__placeholder svg {
    width: 32px;
    height: 32px;
  }
}

.admin-list-item__content {
  display: flex;
  flex-grow: 1;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  min-width: 0;
}

.admin-list-item__info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
  max-width: 100%;
}

@media (min-width: 600px) {
  .admin-list-item__info {
    max-width: 200px;
  }
}

@media (min-width: 960px) {
  .admin-list-item__info {
    max-width: 300px;
  }
}

.admin-list-item__title {
  font-size: 0.875rem;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .admin-list-item__title {
    font-size: 1rem;
  }
}

.admin-list-item__desc {
  font-size: 0.75rem;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: var(--color-text-muted);
}

@media (min-width: 600px) {
  .admin-list-item__desc {
    font-size: 0.875rem;
  }
}

.admin-list-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 120px;
  height: auto;
  padding: 24px;
  border-radius: 12px;
  background-color: var(--color-bg-secondary);
  box-shadow: 0 4px 6px -1px var(--color-shadow);
}

@media (min-width: 600px) {
  .admin-list-loading {
    min-height: 160px;
    border-radius: 16px;
  }
}

.admin-list-loading__content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  color: var(--color-text-secondary);
}

.admin-list-loading__content span {
  font-size: 0.875rem;
  font-weight: 500;
}

@media (min-width: 600px) {
  .admin-list-loading__content span {
    font-size: 1rem;
  }
}

.admin-list-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 80px;
  height: auto;
  padding: 14px;
  border-radius: 12px;
  background-color: var(--color-bg-secondary);
  box-shadow: 0 4px 6px -1px var(--color-shadow);
}

@media (min-width: 600px) {
  .admin-list-empty {
    height: 108px;
    border-radius: 16px;
  }
}

.admin-list-empty__content {
  display: flex;
  flex-direction: column;
  align-items: center;
  opacity: 0.6;
  color: var(--color-text-secondary);
}

.admin-list-empty__icon {
  font-size: 28px;
}

@media (min-width: 600px) {
  .admin-list-empty__icon {
    font-size: 36px;
  }
}

/* Пагинация */
.admin-pagination .v-pagination__item,
.admin-pagination .v-pagination__first,
.admin-pagination .v-pagination__prev,
.admin-pagination .v-pagination__next,
.admin-pagination .v-pagination__last {
  background-color: var(--color-bg-tertiary) !important;
  border-radius: 8px !important;
}

.admin-pagination .v-pagination__item .v-btn__content,
.admin-pagination .v-pagination__first .v-btn__content,
.admin-pagination .v-pagination__prev .v-btn__content,
.admin-pagination .v-pagination__next .v-btn__content,
.admin-pagination .v-pagination__last .v-btn__content {
  font-weight: 600;
  color: var(--color-text-primary) !important;
}

.admin-pagination .v-pagination__item.v-pagination__item--is-active {
  background-color: var(--color-accent) !important;
}

.admin-pagination .v-pagination__item.v-pagination__item--is-active .v-btn__content {
  color: var(--color-text-inverse) !important;
}

.admin-pagination .v-btn {
  width: 32px !important;
  height: 32px !important;
}

@media (min-width: 600px) {
  .admin-pagination .v-btn {
    width: 36px !important;
    height: 36px !important;
  }
}

.admin-pagination .v-pagination__list {
  justify-content: center !important;
  flex-wrap: wrap;
  gap: 4px;
}

@media (min-width: 600px) {
  .admin-pagination .v-pagination__list {
    justify-content: flex-end !important;
  }
}

/* Иконки действий */
.admin-list-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
  margin-right: 0;
}

@media (min-width: 600px) {
  .admin-list-actions {
    gap: 0.75rem;
    margin-right: 1rem;
  }
}

@media (min-width: 960px) {
  .admin-list-actions {
    gap: 1rem;
    margin-right: 3rem;
  }
}

.admin-list-action {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  cursor: pointer;
  transition: color 0.2s ease, transform 0.2s ease;
}

@media (min-width: 600px) {
  .admin-list-action {
    width: 24px;
    height: 24px;
  }
}

.admin-list-action svg {
  width: 100%;
  height: 100%;
}

.admin-list-action--edit {
  color: var(--color-accent);
}

.admin-list-action--edit:hover {
  color: var(--color-accent-secondary);
  transform: scale(1.1);
}

.admin-list-action--delete {
  color: var(--color-accent);
  border: none;
  background: none;
  padding: 0;
}

.admin-list-action--delete:hover {
  color: #EF4444;
  transform: scale(1.1);
}
</style>
