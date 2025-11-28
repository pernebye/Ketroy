<template>
  <v-tabs v-if="items && items.length" v-model="model" class="admin-tabs" hide-slider height="auto">
    <nuxt-link v-for="tab of items" :key="tab.value" :to="{ name: String($route.name), query: { tab: tab.value } }">
      <v-tab :value="tab.value" color="" variant="tonal" height="32">{{ tab.title() }} </v-tab>
    </nuxt-link>
  </v-tabs>
</template>

<script setup lang="ts">
defineProps({
  items: {
    type: Array as PropType<Types.Tab[]>,
    default: [],
  },
});
const model = defineModel();
</script>

<style>
.admin-tabs {
  width: 100%;
  max-width: 100%;
  padding: 3px;
  border-radius: 8px;
  border: 1px solid var(--color-border);
  background-color: var(--color-bg-secondary);
  transition: background-color 0.3s ease, border-color 0.3s ease;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}

@media (min-width: 600px) {
  .admin-tabs {
    width: fit-content;
    max-width: 100%;
    padding: 4px;
  }
}

.admin-tabs::-webkit-scrollbar {
  display: none;
}

.admin-tabs .v-btn__underlay {
  display: none !important;
}

.admin-tabs .v-tab {
  border-radius: 6px !important;
  color: var(--color-text-secondary) !important;
  transition: all 0.2s ease;
  min-width: auto !important;
  padding: 0 10px !important;
  height: 28px !important;
}

@media (min-width: 600px) {
  .admin-tabs .v-tab {
    padding: 0 12px !important;
    height: 32px !important;
  }
}

.admin-tabs .v-tab--selected,
.admin-tabs .v-tab:hover {
  background-color: var(--color-accent-light) !important;
}

.admin-tabs .v-tab--selected .v-btn__content,
.admin-tabs .v-tab:hover .v-btn__content {
  color: var(--color-accent) !important;
}

.admin-tabs .v-btn__content {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-text-secondary);
  transition: color 0.2s ease;
  white-space: nowrap;
}

@media (min-width: 600px) {
  .admin-tabs .v-btn__content {
    font-size: 14px;
  }
}

.admin-tabs .v-slide-group__content {
  gap: 2px;
}

@media (min-width: 600px) {
  .admin-tabs .v-slide-group__content {
    gap: 4px;
  }
}
</style>
