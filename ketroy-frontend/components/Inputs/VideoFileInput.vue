<template>
  <div 
    class="video-file-input"
    :class="{ 
      'video-file-input--dragging': isDragging,
      'video-file-input--hover': isHovering,
      'video-file-input--converting': isConverting,
      'video-file-input--has-preview': hasPreview,
    }"
    @dragenter.prevent="onDragEnter"
    @dragover.prevent="onDragOver"
    @dragleave.prevent="onDragLeave"
    @drop.prevent="onDrop"
    @mouseenter="isHovering = true"
    @mouseleave="isHovering = false"
  >
    <!-- Overlay для drag -->
    <div v-if="isDragging" class="video-file-input__overlay">
      <Icon name="mdi:cloud-upload" class="video-file-input__overlay-icon" />
      <span class="video-file-input__overlay-text">Отпустите для загрузки</span>
    </div>

    <!-- Overlay для конвертации -->
    <div v-if="isConverting" class="video-file-input__converting">
      <v-progress-circular indeterminate :size="48" :width="4" color="primary" />
      <span class="video-file-input__converting-text">Конвертация видео в GIF...</span>
      <span class="video-file-input__converting-hint">Это может занять некоторое время</span>
    </div>

    <!-- Превью загруженного изображения -->
    <div v-if="hasPreview && !isConverting" class="video-file-input__preview">
      <img :src="previewUrl!" alt="Preview" class="video-file-input__preview-image" />
      <div class="video-file-input__preview-overlay">
        <Icon name="solar:pen-bold" class="video-file-input__preview-icon" />
        <span>Нажмите для замены</span>
      </div>
    </div>

    <!-- Контент по умолчанию -->
    <div v-if="!hasPreview && !isConverting" class="video-file-input__content">
      <slot>
        <div class="video-file-input__placeholder">
          <Icon name="solar:gallery-add-bold" class="video-file-input__placeholder-icon" />
          <span class="video-file-input__placeholder-title">Загрузить изображение или видео</span>
          <span class="video-file-input__placeholder-subtitle">
            JPG, PNG, GIF или видео (MP4, MOV, HEVC)
          </span>
          <span class="video-file-input__placeholder-hint">
            Видео автоматически конвертируется в GIF (макс. {{ maxDuration }} сек)
          </span>
        </div>
      </slot>
      
      <!-- Кнопка загрузки из буфера -->
      <button 
        type="button"
        class="video-file-input__clipboard-btn"
        @click.stop="pasteFromClipboard"
      >
        <Icon name="mdi:clipboard-arrow-down" />
        Вставить из буфера
      </button>
    </div>

    <!-- Скрытый input -->
    <input
      ref="fileInput"
      type="file"
      :accept="acceptFormats"
      class="video-file-input__hidden"
      @change="onFileChange"
    />

    <!-- Кликабельная область -->
    <div v-if="!isConverting" class="video-file-input__clickable" @click="triggerFileInput"></div>

    <!-- Диалог кроппера для изображений -->
    <v-dialog v-model="cropDialog" max-width="800px" persistent>
      <v-card class="video-file-input__dialog">
        <v-card-title class="video-file-input__dialog-title">
          <Icon name="mdi:crop" />
          Редактирование изображения
        </v-card-title>
        <v-card-text>
          <div v-if="imageUrl" class="video-file-input__crop-container">
            <img ref="cropImageRef" class="video-file-input__crop-image" :src="imageUrl" alt="Editable Image" />
          </div>
          <div v-else class="video-file-input__dialog-loading">
            <v-progress-circular indeterminate />
            <p>Загрузка изображения...</p>
          </div>
        </v-card-text>
        <v-card-actions class="video-file-input__dialog-actions">
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
import { api } from '~/composables';

const emit = defineEmits<{
  (e: 'update:modelValue', url: string | null): void;
  (e: 'handlePhotoUpload', url: string): void;
  (e: 'error', message: string): void;
}>();

const props = defineProps({
  modelValue: {
    type: String as () => string | null,
    default: null,
  },
  aspectRatio: {
    type: Number,
    default: undefined,
  },
  maxDuration: {
    type: Number,
    default: 15,
  },
});

// Поддерживаемые форматы
const videoFormats = ['video/mp4', 'video/quicktime', 'video/x-m4v', 'video/webm', 'video/x-matroska', 'video/hevc', 'video/3gpp'];
const videoExtensions = ['mp4', 'mov', 'avi', 'm4v', 'webm', 'mkv', 'hevc', '3gp', 'mts'];
const imageFormats = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

const acceptFormats = computed(() => {
  return [...imageFormats, ...videoFormats, ...videoExtensions.map(ext => `.${ext}`)].join(',');
});

// State
const fileInput = ref<HTMLInputElement | null>(null);
const cropImageRef = ref<HTMLImageElement | null>(null);
const isDragging = ref(false);
const isHovering = ref(false);
const isConverting = ref(false);
const dragCounter = ref(0);
const cropDialog = ref(false);
const cropper = ref<Cropper | null>(null);
const imageUrl = ref<string | null>(null);

// Внутреннее состояние превью (для случаев когда modelValue не используется)
const internalPreviewUrl = ref<string | null>(null);

// URL для превью - берём из modelValue или из internal state
const previewUrl = computed(() => props.modelValue || internalPreviewUrl.value);
const hasPreview = computed(() => !!previewUrl.value);

// Функция обновления значения
const updateValue = (url: string) => {
  internalPreviewUrl.value = url;
  emit('update:modelValue', url);
  emit('handlePhotoUpload', url);
};

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

// Trigger file input
const triggerFileInput = () => {
  fileInput.value?.click();
};

// File change handler
const onFileChange = (event: Event) => {
  const input = event.target as HTMLInputElement;
  if (input?.files && input.files.length > 0) {
    processFile(input.files[0]);
  }
  // Reset input
  if (fileInput.value) {
    fileInput.value.value = '';
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
    
    showToaster('warning', 'В буфере обмена нет изображения');
  } catch (err) {
    console.error('Clipboard error:', err);
    showToaster('error', 'Не удалось прочитать буфер обмена');
  }
};

// Check if file is video
const isVideoFile = (file: File): boolean => {
  const mimeType = file.type.toLowerCase();
  const extension = file.name.split('.').pop()?.toLowerCase() || '';
  
  return videoFormats.includes(mimeType) || 
         videoExtensions.includes(extension) ||
         mimeType === 'application/octet-stream' && videoExtensions.includes(extension);
};

// Process uploaded file
const processFile = async (file: File) => {
  console.log('[VideoFileInput] Processing file:', {
    name: file.name,
    type: file.type,
    size: file.size,
  });

  // Check if it's a video
  if (isVideoFile(file)) {
    await processVideo(file);
    return;
  }

  // Check if it's an image
  if (!file.type.startsWith('image/')) {
    showToaster('error', 'Пожалуйста, выберите изображение или видео');
    emit('error', 'Неподдерживаемый формат файла');
    return;
  }

  // GIF - no cropping
  if (file.type === 'image/gif') {
    const reader = new FileReader();
    reader.onload = (e) => {
      if (e.target?.result) {
        updateValue(e.target.result as string);
      }
    };
    reader.readAsDataURL(file);
    return;
  }

  // Other images - open cropper
  const reader = new FileReader();
  reader.onload = (e) => {
    if (e.target?.result) {
      imageUrl.value = e.target.result as string;
      cropDialog.value = true;
    }
  };
  reader.readAsDataURL(file);
};

// Check if FFMpeg is available
const checkFFMpegAvailability = async (): Promise<boolean> => {
  try {
    const info = await api.videoToGif.info();
    if (!info.ffmpeg_installed) {
      showToaster('error', 'FFMpeg не установлен на сервере. Загрузите изображение вместо видео.');
      return false;
    }
    return true;
  } catch (err) {
    console.error('[VideoFileInput] Failed to check FFMpeg:', err);
    return true; // Если не удалось проверить, пробуем конвертировать
  }
};

// Process video file
const processVideo = async (file: File) => {
  console.log('[VideoFileInput] Processing video:', file.name);
  
  // Сначала проверяем доступность FFMpeg
  const ffmpegAvailable = await checkFFMpegAvailability();
  if (!ffmpegAvailable) {
    emit('error', 'FFMpeg не установлен на сервере');
    return;
  }
  
  isConverting.value = true;
  
  try {
    // Convert video to GIF via API
    const result = await api.videoToGif.convert(file);
    
    if (result.success && result.url) {
      console.log('[VideoFileInput] Video converted successfully:', result);
      showToaster('success', `Видео конвертировано в GIF (${result.duration.toFixed(1)} сек)`);
      updateValue(result.url);
    } else {
      throw new Error('Не удалось получить URL конвертированного GIF');
    }
  } catch (err: any) {
    console.error('[VideoFileInput] Video conversion failed:', err);
    
    const errorMessage = err?.response?.data?.error || 
                         err?.message || 
                         'Ошибка конвертации видео';
    
    showToaster('error', errorMessage);
    emit('error', errorMessage);
  } finally {
    isConverting.value = false;
  }
};

// Cropper setup
watch(imageUrl, async (newValue) => {
  if (newValue) {
    await nextTick();
    
    const imageElement = document.querySelector('.video-file-input__crop-image') as HTMLImageElement;
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

// Cancel crop
const cancelCrop = () => {
  cropDialog.value = false;
  imageUrl.value = null;
  if (cropper.value) {
    cropper.value.destroy();
    cropper.value = null;
  }
};

// Crop image
const cropImage = () => {
  if (cropper.value) {
    const canvas = cropper.value.getCroppedCanvas();
    const croppedImage = canvas.toDataURL();
    updateValue(croppedImage);
    cropDialog.value = false;
    imageUrl.value = null;
    
    if (cropper.value) {
      cropper.value.destroy();
      cropper.value = null;
    }
  }
};
</script>

<style scoped>
.video-file-input {
  position: relative;
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-height: 200px;
  border-radius: 0.75rem;
  border: 2px dashed var(--color-border);
  background: var(--color-bg-tertiary);
  transition: all 0.25s ease;
  overflow: hidden;
}

.video-file-input--hover {
  border-color: var(--color-accent);
  background: var(--color-bg-hover);
  transform: scale(1.01);
}

.video-file-input--dragging {
  border-color: var(--color-accent);
  border-style: solid;
  background: var(--color-accent-light);
  transform: scale(1.02);
  box-shadow: 0 0 20px var(--color-shadow);
}

.video-file-input--converting {
  pointer-events: none;
}

.video-file-input--has-preview {
  border-style: solid;
  border-color: var(--color-accent);
}

/* Preview */
.video-file-input__preview {
  position: absolute;
  inset: 0;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  border-radius: 0.625rem;
}

.video-file-input__preview-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.video-file-input__preview-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  background: rgba(0, 0, 0, 0.6);
  color: white;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.video-file-input__preview:hover .video-file-input__preview-overlay {
  opacity: 1;
}

.video-file-input__preview-icon {
  font-size: 2rem;
}

.video-file-input__preview-overlay span {
  font-size: 0.875rem;
  font-weight: 500;
}

/* Overlay */
.video-file-input__overlay {
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

.video-file-input__overlay-icon {
  font-size: 3rem;
  color: var(--color-accent);
  animation: bounce-icon 0.6s ease-in-out infinite;
}

@keyframes bounce-icon {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.video-file-input__overlay-text {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-accent);
}

/* Converting overlay */
.video-file-input__converting {
  position: absolute;
  inset: 0;
  z-index: 25;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  background: rgba(var(--color-bg-card-rgb), 0.95);
  backdrop-filter: blur(4px);
}

.video-file-input__converting-text {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.video-file-input__converting-hint {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

/* Content */
.video-file-input__content {
  position: absolute;
  inset: 0;
  z-index: 10;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  padding: 1.5rem;
  gap: 0.75rem;
}

.video-file-input__placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 0.5rem;
}

.video-file-input__placeholder-icon {
  font-size: 3rem;
  color: var(--color-text-muted);
  opacity: 0.5;
}

.video-file-input__placeholder-title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.video-file-input__placeholder-subtitle {
  font-size: 0.8125rem;
  color: var(--color-text-secondary);
}

.video-file-input__placeholder-hint {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  padding: 0.25rem 0.75rem;
  background: var(--color-bg-secondary);
  border-radius: 1rem;
  margin-top: 0.25rem;
}

/* Hidden input */
.video-file-input__hidden {
  display: none;
}

/* Clickable area */
.video-file-input__clickable {
  position: absolute;
  inset: 0;
  z-index: 5;
  cursor: pointer;
}

/* Clipboard button */
.video-file-input__clipboard-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.5rem;
  padding: 0.5rem 1rem;
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--color-accent);
  background-color: transparent;
  border: 1px solid var(--color-accent);
  border-radius: 0.5rem;
  cursor: pointer;
  pointer-events: auto;
  transition: all 0.2s ease;
}

.video-file-input__clipboard-btn:hover {
  background-color: var(--color-accent);
  color: white;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.video-file-input__clipboard-btn:active {
  transform: translateY(0);
}

.video-file-input__clipboard-btn .iconify {
  font-size: 1.1rem;
}

/* Dialog */
.video-file-input__dialog {
  border-radius: 1rem !important;
  background-color: var(--color-bg-card) !important;
  color: var(--color-text-primary) !important;
}

.video-file-input__dialog-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
  padding: 1.25rem 1.5rem;
  color: var(--color-text-primary);
}

.video-file-input__dialog-title .iconify {
  font-size: 1.5rem;
  color: var(--color-accent);
}

.video-file-input__dialog-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 2rem;
  color: var(--color-text-secondary);
}

.video-file-input__dialog-actions {
  padding: 1rem 1.5rem;
  justify-content: flex-end;
  gap: 0.5rem;
  background-color: var(--color-bg-card);
}

.video-file-input__dialog-actions .v-btn .iconify {
  margin-right: 0.25rem;
}

.video-file-input__crop-container {
  max-width: 100%;
  max-height: 500px;
  overflow: hidden;
  border-radius: 0.5rem;
}

.video-file-input__crop-image {
  max-width: 100%;
}
</style>

