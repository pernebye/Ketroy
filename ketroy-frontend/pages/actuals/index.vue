<template>
  <section class="tw-flex tw-flex-col tw-gap-6">
    <div class="tw-flex tw-items-center tw-justify-between">
      <expand>
        <NuxtLink v-if="showAddButton" class="tw-self-end tw-ml-auto" to="/actuals/create">
          <btn text="Добавить" prepend-icon="mdi-plus" />
        </NuxtLink>
      </expand>
    </div>
    <b-list :title="$t(`admin.actuals.actuals`)" :list="list" :loading="loading" @delete="onDelete" />
  </section>
</template>

<script setup lang="ts">
import { AdminEnums } from '~/types/enums';

const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();

const list = ref<Types.List>([]);
const loading = ref(true);
const existingActuals = ref<{ name: string }[]>([]);

const showAddButton = computed(() => {
  return true;
});


const getList = async () => {
  loading.value = true;
  try {
    const response = await api[layoutStore.actualsTab].getAll();
    if (response && Array.isArray(response)) {
      existingActuals.value = response;
      list.value = response.map((i: any) => {
        return { id: i.id, title: i.name ?? i.name, description: i.description, image: i.image ?? { path: i.video_path } };
      });
    }
  } catch (err) {
    list.value = [];
    console.log(err);
  } finally {
    loading.value = false;
  }
};

const onDelete = async (obj: any) => {
  const updatedArray = existingActuals.value.filter(item => item.name !== obj.title);
  
  try {
    const response = await api.actuals.add(updatedArray);

    if (response.message) showToaster('success', String(response.message));
    await getList();
  } catch (err) {
    console.log(err);
  }
};

useHead({
  title: () => (layoutStore.actualsTab ? `${t('admin.nav.actuals')} - ${t(`admin.actuals.${layoutStore.actualsTab}`)}` : t('admin.nav.actuals')),
});

onMounted(async () => {
  const tab = String(route.query.tab) as AdminEnums.ActualItems;
  if (tab && tab in AdminEnums.ActualItems) {
    if (tab !== layoutStore.actualsTab) {
      layoutStore.actualsTab = tab;
      await router.replace({ query: { tab: tab } });
    }
  } else {
    await router.replace({ query: { tab: layoutStore.actualsTab } });
  }
  await getList();
});

watch(
  () => layoutStore.actualsTab,
  async (tab) => {
    if (tab && tab in AdminEnums.ActualItems) {
      router.replace({ query: { tab: tab } });
      await getList();
    }
  },
);
</script>
