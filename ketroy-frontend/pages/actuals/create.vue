<template>
  <div class="actuals-create">
    <div class="actuals-create__header">
      <v-breadcrumbs :items="brItems" class="actuals-create__breadcrumbs">
        <template v-slot:divider>
          <icon name="bi:caret-right-fill" :color="styles.greySemiDark"/>
        </template>
      </v-breadcrumbs>
      <btn text="Сохранить" prepend-icon="mdi-plus" :loading="loading" @click="save"/>
    </div>
    <v-form ref="form" class="actuals-create__form">
      <fade>
        <section class="actuals-create__content">
          <div class="actuals-create__image-section">
            <card-form class="actuals-create__image-card">
              <p class="actuals-create__section-title">
                Фото
                <fade>
                  <v-btn
                      v-if="category.img"
                      variant="plain"
                      icon="mdi-close"
                      density="compact"
                      @click="category.img = undefined;"
                      class="actuals-create__remove-btn"
                  >
                    <icon class="actuals-create__remove-icon" name="mage:trash-square-fill" :color="styles.greyDark"/>
                  </v-btn>
                </fade>
              </p>
              <div class="actuals-create__image-content">
                <fade>
                  <file-input v-if="!category.img" v-model="category.img" class="actuals-create__file-input"
                              accept="image/*" @change="onFileChange($event, 0)">
                    <svg width="44" height="45" viewBox="0 0 44 45" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <rect y="0.5" width="44" height="44" rx="8" :fill="styles.primary"/>
                      <g clip-path="url(#clip0_0_7857)">
                        <path
                            d="M21.3416 22.9017C21.1326 22.6926 20.8845 22.5268 20.6115 22.4136C20.3384 22.3004 20.0457 22.2422 19.7501 22.2422C19.4545 22.2422 19.1618 22.3004 18.8887 22.4136C18.6156 22.5268 18.3675 22.6926 18.1586 22.9017L13.0286 28.0317C13.0979 28.9723 13.5198 29.852 14.2097 30.495C14.8997 31.138 15.807 31.4968 16.7501 31.4997H27.2501C27.9849 31.4996 28.7032 31.2822 29.3148 30.875L21.3416 22.9017Z"
                            fill="white"
                        />
                        <path
                            d="M26.4999 19.5C27.3283 19.5 27.9999 18.8284 27.9999 18C27.9999 17.1716 27.3283 16.5 26.4999 16.5C25.6715 16.5 24.9999 17.1716 24.9999 18C24.9999 18.8284 25.6715 19.5 26.4999 19.5Z"
                            fill="white"
                        />
                        <path
                            d="M27.25 13.5H16.75C15.7558 13.5012 14.8027 13.8967 14.0997 14.5997C13.3967 15.3027 13.0012 16.2558 13 17.25L13 25.9395L17.098 21.8415C17.4462 21.4932 17.8597 21.2169 18.3147 21.0283C18.7697 20.8398 19.2575 20.7428 19.75 20.7428C20.2425 20.7428 20.7303 20.8398 21.1853 21.0283C21.6403 21.2169 22.0538 21.4932 22.402 21.8415L30.3752 29.8148C30.7825 29.2031 30.9999 28.4848 31 27.75V17.25C30.9988 16.2558 30.6033 15.3027 29.9003 14.5997C29.1973 13.8967 28.2442 13.5012 27.25 13.5V13.5ZM26.5 21C25.9067 21 25.3266 20.8241 24.8333 20.4944C24.3399 20.1648 23.9554 19.6962 23.7284 19.1481C23.5013 18.5999 23.4419 17.9967 23.5576 17.4147C23.6734 16.8328 23.9591 16.2982 24.3787 15.8787C24.7982 15.4591 25.3328 15.1734 25.9147 15.0576C26.4967 14.9419 27.0999 15.0013 27.648 15.2284C28.1962 15.4554 28.6648 15.8399 28.9944 16.3333C29.3241 16.8266 29.5 17.4067 29.5 18C29.5 18.7956 29.1839 19.5587 28.6213 20.1213C28.0587 20.6839 27.2956 21 26.5 21Z"
                            fill="white"
                        />
                      </g>
                      <defs>
                        <clipPath id="clip0_0_7857">
                          <rect width="18" height="18" fill="white" transform="translate(13 13.5)"/>
                        </clipPath>
                      </defs>
                    </svg>
                    <span class="actuals-create__upload-text">Перетащите изображение сюда или нажмите «Добавить изображение».</span>
                  </file-input>
                </fade>
                <fade>
                  <div v-if="category.img" class="actuals-create__image-preview">
                    <img :src="category.img" alt="Hospital Image" class="actuals-create__image" draggable="false"/>
                  </div>
                </fade>
              </div>
            </card-form>
          </div>
          <div class="actuals-create__form-section">
            <div class="actuals-create__form-card">
              <p class="actuals-create__section-title">Актуальное</p>
              <v-text-field
                  v-model="category.name"
                  density="compact"
                  variant="outlined"
                  :bg-color="styles.greyLight"
                  placeholder="Введите актульное . . ."
                  rounded="lg"
                  :rules="[rules.requiredText]"
              />
            </div>
          </div>
        </section>
      </fade>
    </v-form>
  </div>
</template>

<script setup lang="ts">
import {computed, onMounted, ref} from 'vue';
import {useRoute, useRouter} from 'vue-router';
import {useDebounceFn} from '@vueuse/core';
import {AdminEnums} from '~/types/enums';

const route = useRoute();
const router = useRouter();
const loading = ref<boolean>(false);
const category = ref<{ name: string, img: string }>({name: '', img: ''}); // Category object
const existingCategories = ref<{ name: string }[]>([]); // Store existing categories
const which = computed(() => String(route.params.tab) as keyof typeof AdminEnums.CategoriesItems);
const id = computed<number | 'new'>(() => (route.params.id === 'new' ? 'new' : Number(route.params.id)));

const brItems: Types.Crumb[] = [
  {title: t(`admin.nav.categories`), to: {name: 'categories', query: {tab: which.value}}, disabled: false},
  {
    title: (id.value === 'new' ? 'Добавить ' : 'Редактировать ') + t(`admin.categories.categories`),
    to: {...route},
    disabled: false
  },
];

function convertToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = (error) => reject(error);
  });
}

async function onFileChange(event: Event, index: number) {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file) return;

  category.value.img = await convertToBase64(file);
}

const save = useDebounceFn(
    async () => {
      loading.value = true;

      const title = route.query.title || ''; // Get the title from the query
      let formData;

      // Ensure category.value is defined before accessing its properties
      const categoryName = category.value ? category.value.name : '';
      const img = category.value ? category.value.img : '';

      if (title) {
        // If a title is passed, substitute the first category's name with the title
        formData = existingCategories.value.map((existingCategory) =>
            existingCategory.name === title ? {...existingCategory, name: categoryName} : existingCategory
        );
      } else {
        // If no title is passed, add a new category
        formData = [...existingCategories.value, {name: categoryName, image: img}];
      }

      try {
        const response = await api.actuals.add(formData);
        if (response) {
          await router.push({name: 'actuals'});
          await getData();
        }
        if (response.message) showToaster('success', String(response.message));
      } catch (err) {
        console.log(err);
      } finally {
        loading.value = false;
      }
    },
    500,
    {maxWait: 3000}
);


const getData = async () => {
  try {
    const response = await api.actuals.getAll();
    existingCategories.value = response; // Store the fetched categories
  } catch (err) {
    console.log(err);
  }
};

onMounted(() => {
  getData();
  const title = route.query.title || ''; // Get the title from the query
  if (title) {
    category.value.name = title; // Set the first city's name to the passed title
  }
});
const handlePhotoUpload = (imageUrl: string) => {
  category.value.img = imageUrl;
};

</script>

<style scoped>
/* ===== ОСНОВНОЙ КОНТЕЙНЕР ===== */
.actuals-create {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* ===== ШАПКА ===== */
.actuals-create__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 6px;
  flex-wrap: wrap;
  gap: 0.75rem;
}

@media (max-width: 599px) {
  .actuals-create__header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .actuals-create__header > :last-child {
    align-self: flex-end;
  }
}

.actuals-create__breadcrumbs {
  color: var(--color-text-secondary);
}

:root.dark .actuals-create__breadcrumbs {
  color: white;
}

/* ===== ФОРМА ===== */
.actuals-create__form {
  color: var(--color-text-primary);
}

:root.dark .actuals-create__form {
  color: white;
}

/* ===== КОНТЕНТ ===== */
.actuals-create__content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  min-height: auto;
}

@media (min-width: 960px) {
  .actuals-create__content {
    flex-direction: row;
    gap: 1.5rem;
    min-height: 300px;
  }
}

/* ===== СЕКЦИЯ ИЗОБРАЖЕНИЯ ===== */
.actuals-create__image-section {
  width: 100%;
}

@media (min-width: 960px) {
  .actuals-create__image-section {
    width: 30%;
    min-width: 250px;
    max-width: 350px;
  }
}

.actuals-create__image-card {
  height: fit-content;
  width: 100%;
}

.actuals-create__section-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

.actuals-create__remove-btn {
  margin-left: auto;
}

.actuals-create__remove-icon {
  cursor: pointer;
  font-size: 1.875rem;
}

.actuals-create__image-content {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}

.actuals-create__file-input {
  min-height: 180px;
  flex-grow: 1;
}

@media (min-width: 600px) {
  .actuals-create__file-input {
    min-height: 200px;
  }
}

@media (min-width: 960px) {
  .actuals-create__file-input {
    min-height: 230px;
  }
}

.actuals-create__upload-text {
  margin-top: 1rem;
  text-align: center;
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.actuals-create__image-preview {
  display: flex;
  flex-grow: 1;
  align-items: center;
  justify-content: center;
}

.actuals-create__image {
  border-radius: 0.5rem;
  max-width: 100%;
  max-height: 300px;
  object-fit: contain;
}

/* ===== СЕКЦИЯ ФОРМЫ ===== */
.actuals-create__form-section {
  width: 100%;
}

@media (min-width: 960px) {
  .actuals-create__form-section {
    flex: 1;
    width: auto;
  }
}

.actuals-create__form-card {
  border-radius: 0.75rem;
  background-color: var(--color-bg-card, white);
  padding: 1rem 1.5rem;
  box-shadow: 0 1px 3px var(--color-shadow, rgba(0, 0, 0, 0.1));
  height: fit-content;
}

:root.dark .actuals-create__form-card {
  background-color: rgba(82, 82, 82, 0.6);
}

@media (max-width: 599px) {
  .actuals-create__form-card {
    padding: 1rem;
  }
}
</style>
