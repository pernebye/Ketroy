<template>
  <div 
    class="file-input-wrapper"
    :class="{ 
      'file-input-wrapper--dragging': isDragging,
      'file-input-wrapper--hover': isHovering 
    }"
    @dragenter.prevent="onDragEnter"
    @dragover.prevent="onDragOver"
    @dragleave.prevent="onDragLeave"
    @drop.prevent="onDrop"
    @mouseenter="isHovering = true"
    @mouseleave="isHovering = false"
  >
    <!-- Overlay для drag -->
    <div v-if="isDragging" class="file-input-overlay">
      <Icon name="mdi:cloud-upload" class="file-input-overlay__icon" />
      <span class="file-input-overlay__text">Отпустите для загрузки</span>
    </div>

    <!-- Контент по умолчанию -->
    <div v-if="!hasData" class="file-input-content">
      <slot></slot>
      
      <!-- Кнопка загрузки из буфера -->
      <button 
        type="button"
        class="file-input-clipboard-btn"
        @click.stop="pasteFromClipboard"
      >
        <Icon name="mdi:clipboard-arrow-down" />
        Вставить из буфера
      </button>
    </div>

    <v-file-input
      v-model="files"
      class="admin-file-input tw-flex tw-h-full tw-w-full tw-grow tw-flex-col"
      variant="solo"
      :flat="true"
      prepend-icon=""
      :bg-color="'transparent'"
      height="auto"
      :accept="accept"
      :rules="rules"
      @change="onFileChange"
    />

    <v-dialog v-model="cropDialog" max-width="800px" persistent>
      <v-card class="file-input-dialog">
        <v-card-title class="file-input-dialog__title">
          <Icon name="mdi:crop" />
          Редактирование изображения
        </v-card-title>
        <v-card-text>
          <div v-if="imageUrl" class="crop-container">
            <img ref="image" class="editable-image" :src="imageUrl" alt="Editable Image" />
          </div>
          <div v-else class="file-input-dialog__loading">
            <v-progress-circular indeterminate />
            <p>Загрузка изображения...</p>
          </div>
        </v-card-text>
        <v-card-actions class="file-input-dialog__actions">
          <v-btn variant="text" @click="cancelCrop">Отмена</v-btn>
          <v-btn color="primary" variant="flat" @click="cropImage">
            <Icon name="mdi:check" />
            Сохранить
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue';
import Cropper from 'cropperjs';
import 'cropperjs/dist/cropper.css';

const files = ref<File[]>([]);
const cropDialog = ref(false);
const cropper = ref<Cropper | null>(null);
const imageUrl = ref<string | null>(null);
const croppedImage = ref<string | null>(null);
const isDragging = ref(false);
const isHovering = ref(false);
const dragCounter = ref(0);

const emit = defineEmits(['handlePhotoUpload']);

const props = defineProps({
  accept: {
    type: String,
    default: '',
  },
  rules: {
    type: Array as PropType<any[]>,
    default: () => [],
  },
  aspectRatio: {
    type: Number,
    default: undefined, // Свободное кадрирование по умолчанию
  },
});

const hasData = computed(() => files.value.length > 0);

// Drag & Drop handlers
const onDragEnter = (e: DragEvent) => {
  dragCounter.value++;
  isDragging.value = true;
};

const onDragOver = (e: DragEvent) => {
  isDragging.value = true;
};

const onDragLeave = (e: DragEvent) => {
  dragCounter.value--;
  if (dragCounter.value === 0) {
    isDragging.value = false;
  }
};

const onDrop = (e: DragEvent) => {
  isDragging.value = false;
  dragCounter.value = 0;
  
  const droppedFiles = e.dataTransfer?.files;
  if (droppedFiles && droppedFiles.length > 0) {
    processFile(droppedFiles[0]);
  }
};

// Paste from clipboard
const pasteFromClipboard = async () => {
  try {
    const clipboardItems = await navigator.clipboard.read();
    
    for (const item of clipboardItems) {
      const imageType = item.types.find(type => type.startsWith('image/'));
      
      if (imageType) {
        const blob = await item.getType(imageType);
        const file = new File([blob], 'clipboard-image.png', { type: imageType });
        processFile(file);
        return;
      }
    }
    
    // Если изображения нет в буфере
    showToaster('warning', 'В буфере обмена нет изображения');
  } catch (err) {
    console.error('Clipboard error:', err);
    showToaster('error', 'Не удалось прочитать буфер обмена');
  }
};

// Process uploaded file
const processFile = (file: File) => {
  const isImage = file.type.startsWith('image/');
  const isVideo = file.type.startsWith('video/');
  const acceptsVideo = props.accept.includes('video');
  const acceptsImage = props.accept.includes('image') || !props.accept;
  
  // Проверяем соответствие типа файла разрешённым типам
  if (!isImage && !isVideo) {
    showToaster('error', 'Неподдерживаемый формат файла');
    return;
  }
  
  if (isVideo && !acceptsVideo) {
    showToaster('error', 'Пожалуйста, выберите изображение');
    return;
  }
  
  if (isImage && !acceptsImage) {
    showToaster('error', 'Пожалуйста, выберите видео');
    return;
  }
  
  // Видео - передаём напрямую без кропа
  if (isVideo) {
    const reader = new FileReader();
    reader.onload = (e: ProgressEvent<FileReader>) => {
      if (e.target?.result) {
        emit('handlePhotoUpload', e.target.result as string);
      }
    };
    reader.readAsDataURL(file);
    return;
  }

  // GIF - передаём без кропа
  if (file.type === 'image/gif') {
    const reader = new FileReader();
    reader.onload = (e: ProgressEvent<FileReader>) => {
      if (e.target?.result) {
        emit('handlePhotoUpload', e.target.result as string);
      }
    };
    reader.readAsDataURL(file);
  } else {
    // Остальные изображения - открываем кроппер
    const reader = new FileReader();
    reader.onload = (e: ProgressEvent<FileReader>) => {
      if (e.target?.result) {
        imageUrl.value = e.target.result as string;
        cropDialog.value = true;
      }
    };
    reader.readAsDataURL(file);
  }
};

const onFileChange = (event: Event) => {
  const input = event.target as HTMLInputElement;
  if (input?.files && input.files.length > 0) {
    processFile(input.files[0]);
  }
};

// Cancel crop - fix the bug
const cancelCrop = () => {
  cropDialog.value = false;
  files.value = [];
  imageUrl.value = null;
  if (cropper.value) {
    cropper.value.destroy();
    cropper.value = null;
  }
};

watch(imageUrl, async (newValue) => {
  if (newValue) {
    await nextTick();

    const imageElement = document.querySelector('.editable-image') as HTMLImageElement;
    if (imageElement) {
      if (cropper.value) {
        cropper.value.destroy();
      }
      cropper.value = new Cropper(imageElement, {
        autoCropArea: 1,
        responsive: true,
        aspectRatio: props.aspectRatio,
      });
    }
  }
});

const cropImage = () => {
  if (cropper.value) {
    const canvas = cropper.value.getCroppedCanvas();
    croppedImage.value = canvas.toDataURL();
    emit('handlePhotoUpload', croppedImage.value);
    cropDialog.value = false;
    
    // Cleanup
    if (cropper.value) {
      cropper.value.destroy();
      cropper.value = null;
    }
  }
};
</script>

<style scoped>
/* Wrapper */
.file-input-wrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  border-radius: 0.75rem;
  border: 2px dashed var(--color-border);
  background: var(--color-bg-tertiary);
  transition: all 0.25s ease;
  overflow: hidden;
}

.file-input-wrapper--hover {
  border-color: var(--color-accent);
  background: var(--color-bg-hover);
  transform: scale(1.01);
}

.file-input-wrapper--dragging {
  border-color: var(--color-accent);
  border-style: solid;
  background: var(--color-accent-light);
  transform: scale(1.02);
  box-shadow: 0 0 20px var(--color-shadow);
}

/* Drag overlay */
.file-input-overlay {
  position: absolute;
  inset: 0;
  z-index: 20;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  background: var(--color-accent-light);
  backdrop-filter: blur(2px);
  border-radius: 0.625rem;
  animation: pulse-overlay 1.5s ease-in-out infinite;
}

@keyframes pulse-overlay {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.8; }
}

.file-input-overlay__icon {
  font-size: 3rem;
  color: var(--color-accent);
  animation: bounce-icon 0.6s ease-in-out infinite;
}

@keyframes bounce-icon {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.file-input-overlay__text {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-accent);
}

/* Content */
.file-input-content {
  position: absolute;
  inset: 0;
  z-index: 10;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  padding: 1rem;
  gap: 0;
}


/* Dialog */
.file-input-dialog {
  border-radius: 1rem !important;
  background-color: var(--color-bg-card) !important;
  color: var(--color-text-primary) !important;
}

.file-input-dialog__title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
  padding: 1.25rem 1.5rem;
  color: var(--color-text-primary);
}

.file-input-dialog__title .iconify {
  font-size: 1.5rem;
  color: var(--color-accent);
}

.file-input-dialog__loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 2rem;
  color: var(--color-text-secondary);
}

.file-input-dialog__actions {
  padding: 1rem 1.5rem;
  justify-content: flex-end;
  gap: 0.5rem;
  background-color: var(--color-bg-card);
}

.file-input-dialog__actions .v-btn .iconify {
  margin-right: 0.25rem;
}
</style>

<style>
/* Global styles for file input */
.admin-file-input .v-input__control {
  width: 100% !important;
  height: 100% !important;
  flex-grow: 1 !important;
}

.admin-file-input .v-input__details {
  position: absolute;
  bottom: -20px;
  left: -15px;
}

.admin-file-input .v-field {
  background: transparent !important;
}

.admin-file-input .v-field__input {
  opacity: 0;
  cursor: pointer;
}

.crop-container {
  max-width: 100%;
  max-height: 500px;
  overflow: hidden;
  border-radius: 0.5rem;
}

.editable-image {
  max-width: 100%;
}

/* Clipboard button - global styles for theme support */
.file-input-clipboard-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.5rem;
  padding: 0.5rem 1rem;
  font-size: 0.8rem;
  font-weight: 500;
  color: #34460C;
  background-color: #F4F7FE;
  border: 1px solid #34460C;
  border-radius: 0.5rem;
  cursor: pointer;
  pointer-events: auto;
  transition: all 0.2s ease;
}

.dark .file-input-clipboard-btn {
  color: #98B35D;
  background-color: #262626;
  border-color: #98B35D;
}

.file-input-clipboard-btn:hover {
  background-color: #34460C;
  color: #FFFFFF;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.dark .file-input-clipboard-btn:hover {
  background-color: #98B35D;
  color: #171717;
}

.file-input-clipboard-btn:active {
  transform: translateY(0);
}

.file-input-clipboard-btn .iconify {
  font-size: 1.1rem;
}
</style>
