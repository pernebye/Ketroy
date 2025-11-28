<template>
    <VueDatePicker 
      v-model="internalValue" 
      :format="dateFormat"
      :close-on-select="!enableTime"
      :hide-input-icon="true"
      :enable-time-picker="enableTime"
      :action-row="enableTime"
      :auto-apply="!enableTime"
      :dark="isDark"
      :placeholder="placeholder"
      :range="range"
      :minutes-increment="5"
      rounded
      class="date-picker"
    />
</template>

<script setup lang="ts">
import { computed } from 'vue';
import VueDatePicker from '@vuepic/vue-datepicker';
import '@vuepic/vue-datepicker/dist/main.css';

const props = defineProps<{
  modelValue?: string | string[] | Date | Date[] | null;
  placeholder?: string;
  range?: boolean;
  enableTime?: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: string | string[] | Date | Date[] | null | undefined): void;
}>();

const colorMode = useColorMode();
const isDark = computed(() => colorMode.value === 'dark');

const internalValue = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value),
});

// Формат даты: если включено время - добавляем часы и минуты
const dateFormat = computed(() => {
  return props.enableTime ? 'dd.MM.yyyy HH:mm' : 'dd.MM.yyyy';
});
</script>

<style scoped>
:deep(.dp__pointer) {
  border-radius: 8px;
}

/* Шрифт Gilroy для всех элементов */
:deep(.dp__input) {
  font-family: 'Gilroy', sans-serif;
  background-color: var(--color-bg-input);
  color: var(--color-text-primary);
  border-color: var(--color-border);
}

:deep(.dp__input::placeholder) {
  font-family: 'Gilroy', sans-serif;
  color: var(--color-text-muted);
}

:deep(.dp__input:hover) {
  border-color: var(--color-accent);
}

:deep(.dp__input:focus) {
  border-color: var(--color-accent);
}

/* Шрифт для календаря */
:deep(.dp__menu) {
  font-family: 'Gilroy', sans-serif;
}

:deep(.dp__calendar_header_item),
:deep(.dp__cell_inner),
:deep(.dp__month_year_select),
:deep(.dp__button) {
  font-family: 'Gilroy', sans-serif;
}

/* Стили для выбора времени */
:deep(.dp__time_display),
:deep(.dp__time_col) {
  font-family: 'Gilroy', sans-serif;
}

:deep(.dp__time_picker_inline_container) {
  font-family: 'Gilroy', sans-serif;
}

:deep(.dp__action_row) {
  font-family: 'Gilroy', sans-serif;
}

:deep(.dp__action_button) {
  font-family: 'Gilroy', sans-serif;
}

:deep(.dp__selection_preview) {
  font-family: 'Gilroy', sans-serif;
}
</style>

