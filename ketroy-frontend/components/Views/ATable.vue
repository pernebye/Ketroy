<template>
  <div class="admin-table-container">
    <p v-if="title" class="admin-table-title">{{ title }}</p>
    <div v-if="loading" class="admin-table-loading">
      <div class="admin-table-loading__content">
        <v-progress-circular
          indeterminate
          color="var(--color-accent)"
          :size="48"
          :width="4"
        />
        <span>Загрузка данных...</span>
      </div>
    </div>
    <div v-else class="admin-table-wrapper">
      <!-- @vue-ignore -->
      <v-data-table
        class="admin-table"
        :items="items"
        :headers="headers"
        :items-per-page="10"
        :items-per-page-options="[5, 7, 10]"
        items-per-page-text=""
        no-data-text="Отсутствуют данные"
        :sticky="true"
        @click:row="onClickRow"
      >
        <template v-slot:item.prizes="{ item }">{{ item.prizes.map((prize: Api.Prizes.Self) => `${prize.title}`).join(', ') }}</template>
        <template v-slot:item.phone_number="{ item }">{{ formatPhone(item.phone_number, 'front') }}</template>
        <template v-slot:item.actions="{ item }">
          <v-icon v-if="hasDelete" color="red" @click.stop="onDelete(item)"> mdi-delete </v-icon>
        </template>
      </v-data-table>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps({
  hasDelete: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: '',
  },
  headers: {
    type: Array as PropType<Types.TableHeader<any>[]>,
    default: [],
  },
  items: {
    type: Array as PropType<any[]>,
    default: [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
});
const emit = defineEmits(['edit']);

const onClickRow = (event: any, row: any) => {
  emit('edit', row.item);
  emit('goToProfile', row.item);
};

const onDelete = (item: any) => {
  emit('delete', item.id);
};
</script>

<style>
.admin-table-container {
  display: flex;
  flex-direction: column;
  gap: 1.375rem;
  padding: 1.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-card);
  transition: background-color 0.3s ease;
}

@media (min-width: 1280px) {
  .admin-table-container {
    padding: 2rem;
    border-radius: 1.5rem;
  }
}

.admin-table-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--color-text-primary);
}

@media (min-width: 1280px) {
  .admin-table-title {
    font-size: 1.5rem;
  }
}

.admin-table-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 200px;
  padding: 24px;
}

.admin-table-loading__content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  color: var(--color-text-secondary);
}

.admin-table-loading__content span {
  font-size: 0.875rem;
  font-weight: 500;
}

@media (min-width: 600px) {
  .admin-table-loading__content span {
    font-size: 1rem;
  }
}

.admin-table-wrapper {
  display: flex;
  flex-direction: column;
  gap: 1.375rem;
  max-height: calc(100vh - 350px);
  min-height: 300px;
  overflow-y: auto;
}

@media (min-width: 1280px) {
  .admin-table-wrapper {
    max-height: calc(100vh - 300px);
  }
}

@media (min-width: 1920px) {
  .admin-table-wrapper {
    max-height: calc(100vh - 280px);
    min-height: 400px;
  }
}

.admin-table .v-data-table-header__content {
  font-size: 0.875rem !important;
  font-weight: 500;
  color: var(--color-text-secondary) !important;
}

.admin-table .v-data-table__td {
  font-weight: 700;
  color: var(--color-text-primary) !important;
}

.admin-table .v-data-table__tr {
  background-color: transparent !important;
  transition: background-color 0.2s ease;
}

.admin-table .v-data-table__tr:hover {
  background-color: var(--color-bg-hover) !important;
}
</style>
