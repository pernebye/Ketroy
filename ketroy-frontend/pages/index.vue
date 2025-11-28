<template>
  <section></section>
</template>

<script setup lang="ts">
useHead({
  title: null,
});
const layoutStore = useLayoutStore();

onMounted(async () => {
  await onInit();
});

const onInit = async () => {
  layoutStore.navItem = {
    title: () => t('admin.nav.admin'),
    icon: '',
    route: 'index',
  };
};
</script>
