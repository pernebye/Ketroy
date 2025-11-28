<template>
  <div class="gift-grid">
    <div class="gift-grid__header">
      <p class="gift-grid__title">{{ title }}</p>
      <div class="gift-grid__header-actions">
        <!-- Кнопка удаления выбранных -->
        <v-btn 
          v-if="selectedIds.length > 0" 
          color="error"
          variant="flat"
          size="small"
          rounded="lg"
          prepend-icon="mdi-delete"
          :loading="deletingMultiple"
          class="gift-grid__delete-selected-btn"
          @click="deleteSelected"
        >
          Удалить ({{ selectedIds.length }})
        </v-btn>
        <btn 
          v-if="!isCreating" 
          text="Добавить" 
          prepend-icon="mdi-plus" 
          @click="startCreating"
        />
      </div>
    </div>

    <div v-if="loading && !items.length" class="gift-grid__loading">
      <v-progress-circular indeterminate color="var(--color-accent)" :size="48" :width="4" />
      <span>Загрузка каталога...</span>
    </div>

    <div v-else class="gift-grid__content">
      <!-- Плитка создания НОВОГО подарка (только когда не редактируем существующий) -->
      <transition name="fade-scale">
        <div v-if="isCreating && !isEditing" class="gift-grid__tile gift-grid__tile--creating">
          <div class="gift-grid__create-form">
            <!-- Загрузка изображения -->
            <div class="gift-grid__image-upload" @click="triggerFileInput">
              <input 
                ref="fileInput"
                type="file"
                accept="image/*"
                hidden
                @change="handleImageUpload"
              />
              <template v-if="newGift.imagePreview">
                <img :src="newGift.imagePreview" alt="Preview" class="gift-grid__preview-image" />
                <button class="gift-grid__remove-image" @click.stop="removeImage">
                  <Icon name="mdi:close" />
                </button>
              </template>
              <template v-else>
                <div class="gift-grid__upload-placeholder">
                  <Icon name="mdi:image-plus" class="gift-grid__upload-icon" />
                  <span>Загрузить фото</span>
                </div>
              </template>
            </div>

            <!-- Поля ввода -->
            <div class="gift-grid__create-fields">
              <v-text-field
                v-model="newGift.name"
                placeholder="Название подарка"
                variant="outlined"
                density="compact"
                rounded="lg"
                hide-details
                class="gift-grid__input"
              />
              <v-textarea
                v-model="newGift.description"
                placeholder="Описание (необязательно)"
                variant="outlined"
                density="compact"
                rounded="lg"
                rows="2"
                hide-details
                class="gift-grid__input"
              />
            </div>

            <!-- Кнопки действий -->
            <div class="gift-grid__create-actions">
              <v-btn 
                variant="text" 
                size="small" 
                @click="cancelCreating"
              >
                Отмена
              </v-btn>
              <v-btn 
                color="primary" 
                size="small"
                :loading="saving"
                :disabled="!canSave"
                @click="saveNewGift"
              >
                Создать
              </v-btn>
            </div>
          </div>
        </div>
      </transition>

      <!-- Существующие подарки -->
      <TransitionGroup name="grid-item" tag="div" class="gift-grid__items">
        <div 
          v-for="gift in paginatedItems" 
          :key="gift.id"
          class="gift-grid__tile"
          :class="{ 
            'gift-grid__tile--selected': selectedIds.includes(gift.id),
            'gift-grid__tile--editing': editingId === gift.id
          }"
        >
          <!-- Режим редактирования на месте -->
          <template v-if="editingId === gift.id">
            <div class="gift-grid__create-form">
              <!-- Загрузка изображения -->
              <div class="gift-grid__image-upload" @click="triggerFileInput">
                <input 
                  ref="fileInput"
                  type="file"
                  accept="image/*"
                  hidden
                  @change="handleImageUpload"
                />
                <template v-if="newGift.imagePreview">
                  <img :src="newGift.imagePreview" alt="Preview" class="gift-grid__preview-image" />
                  <button class="gift-grid__remove-image" @click.stop="removeImage">
                    <Icon name="mdi:close" />
                  </button>
                </template>
                <template v-else>
                  <div class="gift-grid__upload-placeholder">
                    <Icon name="mdi:image-plus" class="gift-grid__upload-icon" />
                    <span>Загрузить фото</span>
                  </div>
                </template>
              </div>

              <!-- Поля ввода -->
              <div class="gift-grid__create-fields">
                <v-text-field
                  v-model="newGift.name"
                  placeholder="Название подарка"
                  variant="outlined"
                  density="compact"
                  rounded="lg"
                  hide-details
                  class="gift-grid__input"
                />
                <v-textarea
                  v-model="newGift.description"
                  placeholder="Описание (необязательно)"
                  variant="outlined"
                  density="compact"
                  rounded="lg"
                  rows="2"
                  hide-details
                  class="gift-grid__input"
                />
              </div>

              <!-- Кнопки действий -->
              <div class="gift-grid__create-actions">
                <v-btn 
                  variant="text" 
                  size="small" 
                  @click="cancelCreating"
                >
                  Отмена
                </v-btn>
                <v-btn 
                  color="primary" 
                  size="small"
                  :loading="saving"
                  :disabled="!canSave"
                  @click="saveNewGift"
                >
                  Сохранить
                </v-btn>
              </div>
            </div>
          </template>

          <!-- Обычный режим отображения -->
          <template v-else>
            <div class="gift-grid__tile-image">
              <img 
                v-if="gift.image_url || gift.image" 
                :src="gift.image_url || gift.image" 
                :alt="gift.name"
                class="gift-grid__img"
              />
              <div v-else class="gift-grid__placeholder">
                <Icon name="mdi:gift" class="gift-grid__placeholder-icon" />
              </div>
              
              <!-- Чекбокс для мультиселекта (появляется при наведении) -->
              <div 
                class="gift-grid__checkbox"
                :class="{ 'gift-grid__checkbox--checked': selectedIds.includes(gift.id) }"
                @click.stop="toggleSelection(gift.id)"
              >
                <Icon v-if="selectedIds.includes(gift.id)" name="mdi:check" />
              </div>
            </div>
            
            <div class="gift-grid__tile-footer">
              <div class="gift-grid__tile-info">
                <span class="gift-grid__tile-name">{{ gift.name }}</span>
                <span v-if="gift.description" class="gift-grid__tile-desc">{{ gift.description }}</span>
              </div>
              
              <!-- Кнопки действий -->
              <div class="gift-grid__tile-actions">
                <!-- Кнопка редактирования -->
                <button class="gift-grid__edit-btn" @click.stop="startEditing(gift)">
                  <Icon name="mdi:pencil-outline" />
                </button>
                <!-- Кнопка удаления -->
                <button class="gift-grid__delete-btn" @click.stop="onDelete(gift.id)">
                  <confirm @delete="confirmDelete(gift.id)" />
                  <Icon name="mdi:trash-can-outline" />
                </button>
              </div>
            </div>
          </template>
        </div>
      </TransitionGroup>

      <!-- Пустое состояние -->
      <div v-if="!items.length && !isCreating && !loading" class="gift-grid__empty">
        <Icon name="mdi:gift-off-outline" class="gift-grid__empty-icon" />
        <p>Каталог пуст</p>
        <span>Добавьте первый подарок</span>
      </div>
    </div>

    <!-- Пагинация -->
    <div v-if="items.length > 0" class="gift-grid__pagination">
      <v-pagination
        v-if="totalPages > 1"
        v-model="currentPage"
        :length="totalPages"
        class="gift-grid__pages"
        rounded="lg"
        next-icon="mdi-menu-right"
        prev-icon="mdi-menu-left"
        :color="'var(--color-accent)'"
        show-first-last-page
      />
      <div class="gift-grid__per-page">
        <span>Показывать:</span>
        <v-select
          v-model="perPage"
          :items="perPageOptions"
          density="compact"
          variant="outlined"
          hide-details
          class="gift-grid__per-page-select"
          @update:model-value="onPerPageChange"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Compressor from 'compressorjs';
import { useConfirm } from '~/composables/useConfirm';

const { confirm: showConfirm } = useConfirm();

const props = defineProps({
  title: {
    type: String,
    default: 'Каталог подарков'
  },
  items: {
    type: Array as PropType<Api.GiftCatalog.Self[]>,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['create', 'delete', 'edit', 'refresh']);
const router = useRouter();

// Состояние
const isCreating = ref(false);
const isEditing = ref(false);
const editingId = ref<number | null>(null);
const saving = ref(false);
const deletingMultiple = ref(false);
const fileInput = ref<HTMLInputElement | null>(null);

// Мультиселект
const selectedIds = ref<number[]>([]);

// Данные нового/редактируемого подарка
const newGift = ref({
  name: '',
  description: '',
  image: '',
  imagePreview: ''
});

// Пагинация
const perPageOptions = [5, 10, 15, 20];
const STORAGE_KEY = 'gift_catalog_perPage';
const currentPage = ref(1);
const perPage = ref(getStoredPerPage());

function getStoredPerPage(): number {
  if (typeof window === 'undefined') return 10;
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored) {
    const value = parseInt(stored, 10);
    if (perPageOptions.includes(value)) return value;
  }
  return 10;
}

function onPerPageChange(value: number) {
  if (typeof window !== 'undefined') {
    localStorage.setItem(STORAGE_KEY, String(value));
  }
  // Сбрасываем на первую страницу при изменении количества
  currentPage.value = 1;
}

// Вычисляемые свойства для пагинации
const totalPages = computed(() => {
  return Math.ceil(props.items.length / perPage.value);
});

const paginatedItems = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  const end = start + perPage.value;
  return props.items.slice(start, end);
});

// Возможность сохранить
const canSave = computed(() => {
  const hasName = newGift.value.name.trim();
  // При редактировании может быть без изображения (оставляем старое)
  // При создании требуется изображение
  const hasImage = newGift.value.image;
  
  if (isEditing.value) {
    // При редактировании нужно только имя
    return hasName;
  } else {
    // При создании нужны и имя, и изображение
    return hasName && hasImage;
  }
});

// Начать создание
function startCreating() {
  isCreating.value = true;
  isEditing.value = false;
  editingId.value = null;
  resetNewGift();
}

// Начать редактирование
function startEditing(gift: Api.GiftCatalog.Self) {
  isCreating.value = true;
  isEditing.value = true;
  editingId.value = gift.id;
  newGift.value = {
    name: gift.name,
    description: gift.description || '',
    image: gift.image_url || gift.image || '',
    imagePreview: gift.image_url || gift.image || ''
  };
}

// Отмена создания/редактирования
function cancelCreating() {
  isCreating.value = false;
  isEditing.value = false;
  editingId.value = null;
  resetNewGift();
}

// Сброс формы
function resetNewGift() {
  newGift.value = {
    name: '',
    description: '',
    image: '',
    imagePreview: ''
  };
}

// Триггер выбора файла
function triggerFileInput() {
  fileInput.value?.click();
}

// Обработка загрузки изображения
async function handleImageUpload(event: Event) {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file) return;

  try {
    // Проверяем формат
    const supportedByCompressor = ['image/jpeg', 'image/png', 'image/jpg'].includes(file.type);
    
    if (supportedByCompressor) {
      new Compressor(file, {
        quality: 0.9,
        maxWidth: 800,
        maxHeight: 800,
        success: async (compressed: File) => {
          const base64 = await convertToBase64(compressed);
          newGift.value.image = base64;
          newGift.value.imagePreview = base64;
        },
        error(err) {
          console.error('Compression error:', err);
          showToaster('error', 'Ошибка сжатия изображения');
        },
      });
    } else {
      // Для WebP и других форматов
      const base64 = await convertImageViaCanvas(file);
      newGift.value.image = base64;
      newGift.value.imagePreview = base64;
    }
  } catch (err) {
    console.error('Upload error:', err);
    showToaster('error', 'Ошибка загрузки изображения');
  }
}

// Конвертация в base64
function convertToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

// Конвертация через canvas
function convertImageViaCanvas(file: File, maxWidth = 800, maxHeight = 800, quality = 0.9): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        let { width, height } = img;
        if (width > maxWidth) {
          height = (height * maxWidth) / width;
          width = maxWidth;
        }
        if (height > maxHeight) {
          width = (width * maxHeight) / height;
          height = maxHeight;
        }
        
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          reject(new Error('Canvas context not available'));
          return;
        }
        ctx.drawImage(img, 0, 0, width, height);
        const base64 = canvas.toDataURL('image/jpeg', quality);
        resolve(base64);
      };
      img.onerror = () => reject(new Error('Failed to load image'));
      img.src = e.target?.result as string;
    };
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsDataURL(file);
  });
}

// Удаление изображения
function removeImage() {
  newGift.value.image = '';
  newGift.value.imagePreview = '';
  if (fileInput.value) {
    fileInput.value.value = '';
  }
}

// Сохранение нового или редактируемого подарка
async function saveNewGift() {
  if (!canSave.value) return;

  saving.value = true;
  try {
    const payload = {
      name: newGift.value.name.trim(),
      description: newGift.value.description.trim() || undefined,
      image: newGift.value.image
    };

    let response;
    if (isEditing.value && editingId.value) {
      // Редактирование существующего подарка
      response = await api.prizes.update(editingId.value, payload);
    } else {
      // Создание нового подарка
      response = await api.prizes.add(payload);
    }
    
    if (response?.message) {
      showToaster('success', response.message);
      isCreating.value = false;
      isEditing.value = false;
      editingId.value = null;
      resetNewGift();
      emit('refresh');
    }
  } catch (err) {
    console.error('Save error:', err);
    showToaster('error', 'Ошибка сохранения');
  } finally {
    saving.value = false;
  }
}

// Клик по плитке - ничего не делаем (редактирование только по кнопке)
function onTileClick(gift: Api.GiftCatalog.Self, event: MouseEvent) {
  // Редактирование только по специальной кнопке
}

// Переключение выбора
function toggleSelection(giftId: number) {
  const idx = selectedIds.value.indexOf(giftId);
  if (idx > -1) {
    selectedIds.value.splice(idx, 1);
  } else {
    selectedIds.value.push(giftId);
  }
}

// Удаление одного
function onDelete(id: number) {
  // Handled by confirm component
}

async function confirmDelete(id: number) {
  try {
    const response = await api.prizes.delete(id);
    if (response?.message) {
      showToaster('success', String(response.message));
      // Убираем из выбранных если был выбран
      const idx = selectedIds.value.indexOf(id);
      if (idx > -1) {
        selectedIds.value.splice(idx, 1);
      }
      emit('refresh');
    }
  } catch (err) {
    console.error('Delete error:', err);
    showToaster('error', 'Ошибка удаления');
  }
}

// Удаление выбранных
async function deleteSelected() {
  if (!selectedIds.value.length) return;

  const count = selectedIds.value.length;
  const confirmed = await showConfirm({
    title: 'Удаление подарков',
    message: `Удалить ${count} подарков? Это действие нельзя отменить.`,
    confirmText: 'Удалить',
    type: 'danger',
  });
  
  if (!confirmed) return;

  deletingMultiple.value = true;
  try {
    // Удаляем по одному (можно заменить на batch delete если есть API)
    const idsToDelete = [...selectedIds.value];
    for (const id of idsToDelete) {
      await api.prizes.delete(id);
    }
    
    showToaster('success', `Удалено: ${count}`);
    selectedIds.value = [];
    emit('refresh');
  } catch (err) {
    console.error('Delete multiple error:', err);
    showToaster('error', 'Ошибка при удалении');
  } finally {
    deletingMultiple.value = false;
  }
}

// Сброс выбора и корректировка страницы при изменении items
watch(() => props.items, () => {
  selectedIds.value = [];
  // Корректируем текущую страницу если она стала больше максимальной
  if (currentPage.value > totalPages.value && totalPages.value > 0) {
    currentPage.value = totalPages.value;
  }
});
</script>

<style scoped>
.gift-grid {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  padding: 1.25rem;
  border-radius: 1rem;
  background-color: var(--color-bg-card);
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .gift-grid {
    padding: 1.5rem;
    border-radius: 1.5rem;
  }
}

@media (min-width: 960px) {
  .gift-grid {
    padding: 2rem;
    border-radius: 1.875rem;
  }
}

.gift-grid__header {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .gift-grid__header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }
}

.gift-grid__title {
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0;
}

@media (min-width: 600px) {
  .gift-grid__title {
    font-size: 1.5rem;
  }
}

.gift-grid__header-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.gift-grid__delete-selected-btn {
  font-weight: 600;
}

.gift-grid__loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 3rem;
  color: var(--color-text-secondary);
}

.gift-grid__content {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .gift-grid__content {
    grid-template-columns: repeat(3, 1fr);
    gap: 1rem;
  }
}

@media (min-width: 960px) {
  .gift-grid__content {
    grid-template-columns: repeat(4, 1fr);
    gap: 1.25rem;
  }
}

@media (min-width: 1280px) {
  .gift-grid__content {
    grid-template-columns: repeat(5, 1fr);
  }
}

.gift-grid__items {
  display: contents;
}

/* Плитка подарка */
.gift-grid__tile {
  position: relative;
  display: flex;
  flex-direction: column;
  background: var(--color-bg-secondary);
  border-radius: 0.75rem;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  box-shadow: 0 2px 8px var(--color-shadow);
}

@media (min-width: 600px) {
  .gift-grid__tile {
    border-radius: 1rem;
  }
}

.gift-grid__tile:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px var(--color-shadow);
}

/* Выделенная плитка */
.gift-grid__tile--selected {
  outline: 2px solid var(--color-accent);
  outline-offset: -2px;
}

.gift-grid__tile--selected .gift-grid__tile-image::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(152, 179, 93, 0.15);
  pointer-events: none;
}

/* Плитка создания */
.gift-grid__tile--creating {
  grid-column: 1;
  grid-row: 1;
  cursor: default;
  border: 2px dashed var(--color-accent);
  background: transparent;
  min-height: 280px;
}

@media (min-width: 600px) {
  .gift-grid__tile--creating {
    min-height: 320px;
  }
}

.gift-grid__tile--creating:hover {
  transform: none;
  box-shadow: none;
}

/* Плитка в режиме редактирования */
.gift-grid__tile--editing {
  cursor: default;
  border: 2px solid var(--color-accent);
  background: var(--color-bg-secondary);
}

.gift-grid__tile--editing:hover {
  transform: none;
  box-shadow: 0 2px 8px var(--color-shadow);
}

.gift-grid__create-form {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: 0.75rem;
  gap: 0.75rem;
}

@media (min-width: 600px) {
  .gift-grid__create-form {
    padding: 1rem;
    gap: 1rem;
  }
}

/* Загрузка изображения */
.gift-grid__image-upload {
  position: relative;
  aspect-ratio: 1;
  border-radius: 0.5rem;
  overflow: hidden;
  cursor: pointer;
  background: var(--color-bg-tertiary);
  border: 2px dashed var(--color-border);
  transition: border-color 0.2s ease, background-color 0.2s ease;
}

.gift-grid__image-upload:hover {
  border-color: var(--color-accent);
  background: rgba(152, 179, 93, 0.05);
}

.gift-grid__upload-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  gap: 0.5rem;
  color: var(--color-text-muted);
  font-size: 0.75rem;
}

.gift-grid__upload-icon {
  font-size: 2rem;
  color: var(--color-accent);
}

.gift-grid__preview-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gift-grid__remove-image {
  position: absolute;
  top: 0.25rem;
  right: 0.25rem;
  width: 1.5rem;
  height: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.6);
  border: none;
  border-radius: 50%;
  color: white;
  cursor: pointer;
  font-size: 0.875rem;
  transition: background 0.2s ease;
}

.gift-grid__remove-image:hover {
  background: rgba(239, 68, 68, 0.9);
}

/* Поля создания */
.gift-grid__create-fields {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  flex: 1;
}

.gift-grid__input :deep(.v-field) {
  background-color: var(--color-bg-tertiary) !important;
  font-size: 0.875rem;
}

.gift-grid__input :deep(.v-field__input) {
  padding: 0.5rem 0.75rem !important;
  min-height: 36px !important;
  color: var(--color-text-primary) !important;
}

.gift-grid__input :deep(.v-field__input::placeholder) {
  color: var(--color-text-muted) !important;
}

/* Кнопки действий создания */
.gift-grid__create-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
  margin-top: auto;
}

.gift-grid__create-actions :deep(.v-btn) {
  min-width: auto;
  padding: 0 0.75rem;
}

/* Изображение в плитке */
.gift-grid__tile-image {
  position: relative;
  aspect-ratio: 1;
  overflow: hidden;
  background: var(--color-bg-tertiary);
}

.gift-grid__img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.gift-grid__tile:hover .gift-grid__img {
  transform: scale(1.05);
}

.gift-grid__placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  color: var(--color-text-muted);
}

.gift-grid__placeholder-icon {
  font-size: 2.5rem;
  opacity: 0.5;
}

/* Чекбокс для мультиселекта */
.gift-grid__checkbox {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  border: 2px solid rgba(255, 255, 255, 0.7);
  background: rgba(0, 0, 0, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  opacity: 0;
  z-index: 10;
  backdrop-filter: blur(4px);
}

.gift-grid__tile:hover .gift-grid__checkbox,
.gift-grid__checkbox--checked {
  opacity: 1;
}

.gift-grid__checkbox:hover {
  border-color: var(--color-accent);
  background: rgba(0, 0, 0, 0.5);
  transform: scale(1.1);
}

.gift-grid__checkbox--checked {
  background: var(--color-accent);
  border-color: var(--color-accent);
}

.gift-grid__checkbox--checked :deep(.iconify) {
  color: white;
  font-size: 14px;
}

/* Футер плитки */
.gift-grid__tile-footer {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 0.75rem;
  gap: 0.5rem;
}

@media (min-width: 600px) {
  .gift-grid__tile-footer {
    padding: 1rem;
  }
}

/* Информация в плитке */
.gift-grid__tile-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
  min-width: 0;
}

.gift-grid__tile-name {
  font-weight: 600;
  font-size: 0.875rem;
  color: var(--color-text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

@media (min-width: 600px) {
  .gift-grid__tile-name {
    font-size: 1rem;
  }
}

.gift-grid__tile-desc {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Кнопки действий в плитке */
.gift-grid__tile-actions {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  flex-shrink: 0;
}

.gift-grid__edit-btn,
.gift-grid__delete-btn {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 6px;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: all 0.2s ease;
  opacity: 0.6;
}

.gift-grid__tile:hover .gift-grid__edit-btn,
.gift-grid__tile:hover .gift-grid__delete-btn {
  opacity: 1;
}

.gift-grid__edit-btn:hover {
  background: rgba(152, 179, 93, 0.15);
  color: var(--color-accent);
}

.gift-grid__delete-btn:hover {
  background: rgba(239, 68, 68, 0.1);
  color: #EF4444;
}

.gift-grid__edit-btn :deep(.iconify),
.gift-grid__delete-btn :deep(.iconify) {
  font-size: 1.125rem;
}

/* Пустое состояние */
.gift-grid__empty {
  grid-column: 1 / -1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 1rem;
  color: var(--color-text-muted);
  text-align: center;
}

.gift-grid__empty-icon {
  font-size: 3rem;
  margin-bottom: 0.75rem;
  opacity: 0.5;
}

.gift-grid__empty p {
  font-weight: 600;
  font-size: 1.125rem;
  margin: 0 0 0.25rem;
  color: var(--color-text-secondary);
}

.gift-grid__empty span {
  font-size: 0.875rem;
}

/* Пагинация */
.gift-grid__pagination {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  align-items: center;
  justify-content: space-between;
  padding-top: 1rem;
  border-top: 1px solid var(--color-border);
}

@media (min-width: 600px) {
  .gift-grid__pagination {
    flex-direction: row;
  }
}

.gift-grid__pages {
  order: 2;
}

@media (min-width: 600px) {
  .gift-grid__pages {
    order: 1;
  }
}

.gift-grid__pages :deep(.v-pagination__item),
.gift-grid__pages :deep(.v-pagination__first),
.gift-grid__pages :deep(.v-pagination__prev),
.gift-grid__pages :deep(.v-pagination__next),
.gift-grid__pages :deep(.v-pagination__last) {
  background-color: var(--color-bg-tertiary) !important;
  border-radius: 8px !important;
}

.gift-grid__pages :deep(.v-pagination__item .v-btn__content),
.gift-grid__pages :deep(.v-pagination__first .v-btn__content),
.gift-grid__pages :deep(.v-pagination__prev .v-btn__content),
.gift-grid__pages :deep(.v-pagination__next .v-btn__content),
.gift-grid__pages :deep(.v-pagination__last .v-btn__content) {
  font-weight: 600;
  color: var(--color-text-primary) !important;
}

.gift-grid__pages :deep(.v-pagination__item.v-pagination__item--is-active) {
  background-color: var(--color-accent) !important;
}

.gift-grid__pages :deep(.v-pagination__item.v-pagination__item--is-active .v-btn__content) {
  color: var(--color-text-inverse) !important;
}

.gift-grid__pages :deep(.v-btn) {
  width: 32px !important;
  height: 32px !important;
}

@media (min-width: 600px) {
  .gift-grid__pages :deep(.v-btn) {
    width: 36px !important;
    height: 36px !important;
  }
}

.gift-grid__pages :deep(.v-pagination__list) {
  justify-content: center !important;
  flex-wrap: wrap;
  gap: 4px;
}

.gift-grid__per-page {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
  color: var(--color-text-secondary);
  order: 1;
}

@media (min-width: 600px) {
  .gift-grid__per-page {
    order: 2;
  }
}

.gift-grid__per-page-select {
  width: 80px;
}

.gift-grid__per-page-select :deep(.v-field) {
  background-color: var(--color-bg-tertiary) !important;
  border-radius: 8px !important;
}

.gift-grid__per-page-select :deep(.v-field__input) {
  padding: 4px 8px !important;
  min-height: 32px !important;
  font-size: 0.875rem;
  color: var(--color-text-primary) !important;
}

/* Анимации */
.fade-scale-enter-active,
.fade-scale-leave-active {
  transition: all 0.3s ease;
}

.fade-scale-enter-from,
.fade-scale-leave-to {
  opacity: 0;
  transform: scale(0.9);
}

.grid-item-enter-active,
.grid-item-leave-active {
  transition: all 0.3s ease;
}

.grid-item-enter-from {
  opacity: 0;
  transform: scale(0.8);
}

.grid-item-leave-to {
  opacity: 0;
  transform: scale(0.8);
}

.grid-item-move {
  transition: transform 0.3s ease;
}
</style>
