<template>
  <v-menu activator="parent">
    <div class="admin-confirm" :class="isDark ? 'admin-confirm--dark' : 'admin-confirm--light'">
      <p class="admin-confirm__title">Удалить?</p>
      <div class="admin-confirm__actions">
        <v-btn class="admin-confirm__btn-cancel" text="Отменить" variant="outlined" rounded="lg" @click="$emit('cancel')" />
        <v-btn text="Удалить" variant="flat" rounded="lg" :color="styles.danger" @click="$emit('delete')" />
      </div>
    </div>
  </v-menu>
</template>

<script setup lang="ts">
const colorMode = useColorMode();
const isDark = computed(() => colorMode.value === 'dark');
</script>

<style>
.admin-confirm {
  padding: 12px;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  border: 1px solid;
}

.admin-confirm--light {
  background-color: #ffffff;
  border-color: #e5e7eb;
}

.admin-confirm--dark {
  background-color: #374151;
  border-color: #4b5563;
}

.admin-confirm__title {
  padding-bottom: 8px;
  padding-left: 4px;
  font-size: 1.125rem;
  font-weight: 600;
}

.admin-confirm--light .admin-confirm__title {
  color: #1f2937;
}

.admin-confirm--dark .admin-confirm__title {
  color: #ffffff;
}

.admin-confirm__actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
}

.admin-confirm__btn-cancel {
  border-color: #9ca3af !important;
}

.admin-confirm--light .admin-confirm__btn-cancel .v-btn__content {
  color: #1f2937 !important;
}

.admin-confirm--dark .admin-confirm__btn-cancel {
  border-color: #6b7280 !important;
}

.admin-confirm--dark .admin-confirm__btn-cancel .v-btn__content {
  color: #ffffff !important;
}
</style>
