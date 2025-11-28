<template>
  <div class="tw-flex tw-justify-between">
    <p v-if="title" class="tw-text-xl tw-font-medium dark:tw-text-white">{{ title }}</p>
    <span class="tw-text-sm tw-font-semibold tw-text-primary dark:tw-text-white">Всего {{ total }}</span>
  </div>
  <expand>
    <div v-if="data" class="tw-mt-4 tw-flex tw-max-h-[25svh] tw-flex-col tw-gap-6 tw-overflow-y-scroll tw-pr-2">
      <div v-for="([key, value], index) of Object.entries(data)" :key="index">
        <div class="tw-mb-1 tw-flex tw-justify-between dark:tw-text-white">
          <span class="tw-text-sm tw-font-medium">{{ key }}</span>
          <span>{{ value }}</span>
        </div>
        <v-progress-linear :model-value="value" height="8" rounded :buffer-color="ageBgColors[index % ageBgColors.length]" :color="ageColors[index % ageColors.length]" :max="total" />
      </div>
    </div>
  </expand>
</template>

<script setup lang="ts">
const props = defineProps({
  title: {
    type: String,
    default: undefined,
  },
  data: {
    type: Object as PropType<Record<string, number>>,
    default: undefined,
  },
});

const ageColors = ['#FFB200', '#4339F2', '#02A0FC', '#FF3A29'];
const ageBgColors = ['#FFEABA', '#DAD7FE', '#B9E5FF', '#FFCBC6'];

const total = computed(() => (props.data ? Object.values(props.data).reduce((acc, curr) => acc + curr, 0) : 0));
</script>
