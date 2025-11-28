<template>

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
.admin-table .v-data-table-header__content {
  font-size: 14px !important;
  font-weight: 500;
  @apply tw-text-typo;
}
.admin-table .v-data-table__td {
  font-weight: 700;
  @apply tw-text-typo;
}
</style>
