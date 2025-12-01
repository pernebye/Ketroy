<template>
  <v-dialog
    v-model="isOpen"
    :width="400"
    persistent
    @update:model-value="onDialogClose"
  >
    <v-card class="news-notification-modal">
      <div class="news-notification-modal__content">
        <div class="news-notification-modal__header">
          <icon name="mdi:bell-outline" size="28" class="news-notification-modal__icon" />
          <h3 class="news-notification-modal__title">Опубликовать с уведомлением?</h3>
        </div>

        <p class="news-notification-modal__description">
          Хотите отправить уведомление пользователям при публикации этой новости?
        </p>

        <div class="news-notification-modal__checkbox">
          <v-checkbox
            v-model="dontAskAgain"
            label="Не спрашивать следующие 5 минут"
            density="compact"
            hide-details
          />
        </div>

        <div class="news-notification-modal__actions">
          <v-btn
            variant="outlined"
            color="error"
            @click="onReject"
            class="news-notification-modal__btn"
          >
            Нет
          </v-btn>
          <v-btn
            variant="flat"
            color="success"
            @click="onConfirm"
            class="news-notification-modal__btn"
          >
            Да
          </v-btn>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits<{
  'update:modelValue': [value: boolean];
  'confirm': [value: { sendNotification: boolean; dontAskAgain: boolean }];
}>();

const dontAskAgain = ref(false);

const isOpen = computed({
  get: () => props.modelValue,
  set: (value: boolean) => {
    emit('update:modelValue', value);
  },
});

const onConfirm = () => {
  emit('confirm', {
    sendNotification: true,
    dontAskAgain: dontAskAgain.value,
  });
  dontAskAgain.value = false;
};

const onReject = () => {
  emit('confirm', {
    sendNotification: false,
    dontAskAgain: dontAskAgain.value,
  });
  dontAskAgain.value = false;
};

const onDialogClose = (newValue: boolean) => {
  if (!newValue) {
    dontAskAgain.value = false;
  }
};
</script>

<style scoped>
.news-notification-modal {
  background-color: var(--color-bg-card) !important;
}

.news-notification-modal__content {
  padding: 28px 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.news-notification-modal__header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.news-notification-modal__icon {
  color: var(--color-accent);
  flex-shrink: 0;
  margin-top: 2px;
}

.news-notification-modal__title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--color-text-primary);
  line-height: 1.4;
}

.news-notification-modal__description {
  margin: 0;
  font-size: 14px;
  color: var(--color-text-secondary);
  line-height: 1.6;
}

.news-notification-modal__checkbox {
  margin: 8px 0;
}

.news-notification-modal__checkbox :deep(.v-checkbox) {
  min-height: auto;
}

.news-notification-modal__checkbox :deep(.v-label) {
  font-size: 13px;
  color: var(--color-text-secondary);
}

.news-notification-modal__actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 8px;
}

.news-notification-modal__btn {
  min-width: 100px;
  text-transform: none;
  font-weight: 500;
}

.news-notification-modal__btn :deep(.v-btn__content) {
  letter-spacing: normal;
}

/* Dark theme adjustments */
:root.dark .news-notification-modal {
  background-color: var(--color-bg-card) !important;
}

:root.dark .news-notification-modal__title {
  color: var(--color-text-primary);
}

:root.dark .news-notification-modal__description {
  color: var(--color-text-secondary);
}

:root.dark .news-notification-modal__checkbox :deep(.v-label) {
  color: var(--color-text-secondary);
}
</style>



