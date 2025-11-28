<template>
  <div class="tw-flex tw-justify-between tw-pt-[6px]">
    <v-breadcrumbs :items="brItems" class="dark:tw-text-white">
      <template v-slot:divider>
        <icon name="bi:caret-right-fill" :color="styles.greySemiDark" />
      </template>
    </v-breadcrumbs>
  </div>
  <v-form v-if="user" ref="form" class="tw-flex tw-flex-col tw-gap-6">
    <section class="tw-flex tw-w-1/3 tw-flex-col tw-rounded-xl tw-bg-white tw-p-2 tw-shadow-md dark:tw-bg-neutral-800">
      <div class="tw-relative tw-flex tw-flex-col tw-items-center tw-gap-2">
        <img class="tw-absolute tw-w-full" src="~/assets/img/profile-bg.png" alt="Profile bg" draggable="false" />
        <div class="tw-z-10 tw-mt-20 tw-h-[150px] tw-w-[150px]">
          <img v-if="image && image.length" :src="imagePreview(image)" alt="User image" class="tw-h-[150px] tw-rounded-full" draggable="false" />
          <img v-else-if="user.image && user.image.path" :src="fileUrlValidator(user.image.path)" alt="User image" class="tw-h-[150px] tw-rounded-full" draggable="false" />
          <v-btn v-else icon="mdi-camera-enhance-outline" width="150" height="150" @click="imageInput.click()" />
          <svg
            class="tw-absolute tw-right-28 tw-top-20 tw-cursor-pointer"
            @click="
              image = [];
              // @ts-ignore
              user.image = undefined;
            "
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M16.19 2H7.81C4.17 2 2 4.17 2 7.81V16.18C2 19.83 4.17 22 7.81 22H16.18C19.82 22 21.99 19.83 21.99 16.19V7.81C22 4.17 19.83 2 16.19 2ZM10.95 17.51C10.66 17.8 10.11 18.08 9.71 18.14L7.25 18.49C7.16 18.5 7.07 18.51 6.98 18.51C6.57 18.51 6.19 18.37 5.92 18.1C5.59 17.77 5.45 17.29 5.53 16.76L5.88 14.3C5.94 13.89 6.21 13.35 6.51 13.06L10.97 8.6C11.05 8.81 11.13 9.02 11.24 9.26C11.34 9.47 11.45 9.69 11.57 9.89C11.67 10.06 11.78 10.22 11.87 10.34C11.98 10.51 12.11 10.67 12.19 10.76C12.24 10.83 12.28 10.88 12.3 10.9C12.55 11.2 12.84 11.48 13.09 11.69C13.16 11.76 13.2 11.8 13.22 11.81C13.37 11.93 13.52 12.05 13.65 12.14C13.81 12.26 13.97 12.37 14.14 12.46C14.34 12.58 14.56 12.69 14.78 12.8C15.01 12.9 15.22 12.99 15.43 13.06L10.95 17.51ZM17.37 11.09L16.45 12.02C16.39 12.08 16.31 12.11 16.23 12.11C16.2 12.11 16.16 12.11 16.14 12.1C14.11 11.52 12.49 9.9 11.91 7.87C11.88 7.76 11.91 7.64 11.99 7.57L12.92 6.64C14.44 5.12 15.89 5.15 17.38 6.64C18.14 7.4 18.51 8.13 18.51 8.89C18.5 9.61 18.13 10.33 17.37 11.09Z"
              fill="white"
            />
          </svg>
          <v-file-input v-model="image" ref="imageInput" class="tw-invisible" accept="image/*" />
        </div>
      </div>
      <v-divider class="tw-mt-6 tw-w-full tw-opacity-50" color="#F4F7FE" />
      <div class="tw-flex tw-flex-col tw-gap-4 tw-p-6 tw-text-sm tw-font-semibold">
        <div class="tw-flex tw-w-full tw-items-center tw-justify-between tw-gap-2">
          <div class="tw-flex tw-w-full tw-gap-2">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect width="40" height="40" rx="20" fill="#F0F1F3" />
              <path
                d="M23.4917 11.666H16.5083C13.475 11.666 11.6667 13.4743 11.6667 16.5077V23.491C11.6667 25.8327 12.7417 27.441 14.6333 28.0493C15.1833 28.241 15.8167 28.3327 16.5083 28.3327H23.4917C24.1833 28.3327 24.8167 28.241 25.3667 28.0493C27.2583 27.441 28.3333 25.8327 28.3333 23.491V16.5077C28.3333 13.4743 26.525 11.666 23.4917 11.666ZM27.0833 23.491C27.0833 25.2743 26.3833 26.3993 24.975 26.866C24.1667 25.2743 22.25 24.141 20 24.141C17.75 24.141 15.8417 25.266 15.025 26.866H15.0167C13.625 26.416 12.9167 25.2827 12.9167 23.4993V16.5077C12.9167 14.1577 14.1583 12.916 16.5083 12.916H23.4917C25.8417 12.916 27.0833 14.1577 27.0833 16.5077V23.491Z"
                :fill="styles.greySemiDark"
              />
              <path
                d="M20 16.666C18.35 16.666 17.0167 17.9993 17.0167 19.6493C17.0167 21.2993 18.35 22.641 20 22.641C21.65 22.641 22.9833 21.2993 22.9833 19.6493C22.9833 17.9993 21.65 16.666 20 16.666Z"
                :fill="styles.greySemiDark"
              />
            </svg>
            <div class="tw-flex tw-w-full tw-flex-col tw-justify-between">
              <span class="tw-text-grey-semidark dark:tw-text-white">Имя</span>
              <v-text-field
                v-model.trim="user.first_name"
                class="profile-input"
                :disabled="isNameDisabled"
                density="compact"
                variant="plain"
                placeholder="Имя"
                hide-details
                :rules="[rules.requiredText]"
              />
            </div>
          </div>
          <fade>
            <svg v-if="isNameDisabled" @click="isNameDisabled = false" class="tw-cursor-pointer" width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path
                d="M16.19 2H7.81C4.17 2 2 4.17 2 7.81V16.18C2 19.83 4.17 22 7.81 22H16.18C19.82 22 21.99 19.83 21.99 16.19V7.81C22 4.17 19.83 2 16.19 2ZM10.95 17.51C10.66 17.8 10.11 18.08 9.71 18.14L7.25 18.49C7.16 18.5 7.07 18.51 6.98 18.51C6.57 18.51 6.19 18.37 5.92 18.1C5.59 17.77 5.45 17.29 5.53 16.76L5.88 14.3C5.94 13.89 6.21 13.35 6.51 13.06L10.97 8.6C11.05 8.81 11.13 9.02 11.24 9.26C11.34 9.47 11.45 9.69 11.57 9.89C11.67 10.06 11.78 10.22 11.87 10.34C11.98 10.51 12.11 10.67 12.19 10.76C12.24 10.83 12.28 10.88 12.3 10.9C12.55 11.2 12.84 11.48 13.09 11.69C13.16 11.76 13.2 11.8 13.22 11.81C13.37 11.93 13.52 12.05 13.65 12.14C13.81 12.26 13.97 12.37 14.14 12.46C14.34 12.58 14.56 12.69 14.78 12.8C15.01 12.9 15.22 12.99 15.43 13.06L10.95 17.51ZM17.37 11.09L16.45 12.02C16.39 12.08 16.31 12.11 16.23 12.11C16.2 12.11 16.16 12.11 16.14 12.1C14.11 11.52 12.49 9.9 11.91 7.87C11.88 7.76 11.91 7.64 11.99 7.57L12.92 6.64C14.44 5.12 15.89 5.15 17.38 6.64C18.14 7.4 18.51 8.13 18.51 8.89C18.5 9.61 18.13 10.33 17.37 11.09Z"
                :fill="styles.primary"
              />
            </svg>
          </fade>
          <fade>
            <icon v-if="!isNameDisabled" @click="isNameDisabled = true" class="tw-cursor-pointer tw-text-[25px]" name="mdi:close-box" :color="styles.primary" />
          </fade>
        </div>
        <div class="tw-flex tw-w-full tw-items-center tw-justify-between tw-gap-2">
          <div class="tw-flex tw-w-full tw-gap-2">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect width="40" height="40" rx="20" fill="#F0F1F3" />
              <path
                d="M27.75 20.1914H24.85C24.0333 20.1914 23.3083 20.6414 22.9416 21.3747L22.2416 22.7581C22.075 23.0914 21.7416 23.2997 21.375 23.2997H18.6416C18.3833 23.2997 18.0166 23.2414 17.775 22.7581L17.075 21.3831C16.7083 20.6581 15.975 20.1997 15.1666 20.1997H12.25C11.925 20.1997 11.6666 20.4581 11.6666 20.7831V23.4997C11.6666 26.5247 13.4833 28.3331 16.5166 28.3331H23.5C26.3583 28.3331 28.1166 26.7664 28.3333 23.9831V20.7747C28.3333 20.4581 28.075 20.1914 27.75 20.1914Z"
                :fill="styles.greySemiDark"
              />
              <path
                d="M23.4916 11.666H16.5083C13.475 11.666 11.6666 13.4743 11.6666 16.5077V19.041C11.85 18.9743 12.05 18.941 12.25 18.941H15.1666C16.4583 18.941 17.6166 19.6577 18.1916 20.816L18.8166 22.041H21.2L21.825 20.8077C22.4 19.6577 23.5583 18.941 24.85 18.941H27.75C27.95 18.941 28.15 18.9743 28.3333 19.041V16.5077C28.3333 13.4743 26.525 11.666 23.4916 11.666ZM18.7083 14.5077H21.2916C21.6083 14.5077 21.875 14.766 21.875 15.0827C21.875 15.4077 21.6083 15.666 21.2916 15.666H18.7083C18.3916 15.666 18.125 15.4077 18.125 15.0827C18.125 14.766 18.3916 14.5077 18.7083 14.5077ZM21.9416 17.991H18.0583C17.7416 17.991 17.4833 17.7327 17.4833 17.416C17.4833 17.091 17.7416 16.8327 18.0583 16.8327H21.9416C22.2583 16.8327 22.5166 17.091 22.5166 17.416C22.5166 17.7327 22.2583 17.991 21.9416 17.991Z"
                :fill="styles.greySemiDark"
              />
            </svg>
            <div class="tw-flex tw-w-full tw-flex-col tw-justify-between">
              <span class="tw-text-grey-semidark dark:tw-text-white">Почта</span>
              <v-text-field
                v-model.trim="user.email"
                class="profile-input"
                :disabled="isEmailDisabled"
                density="compact"
                variant="plain"
                placeholder="Почта"
                hide-details
                :rules="[rules.requiredText]"
              />
            </div>
          </div>
          <fade>
            <svg v-if="isEmailDisabled" @click="isEmailDisabled = false" class="tw-cursor-pointer" width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path
                d="M16.19 2H7.81C4.17 2 2 4.17 2 7.81V16.18C2 19.83 4.17 22 7.81 22H16.18C19.82 22 21.99 19.83 21.99 16.19V7.81C22 4.17 19.83 2 16.19 2ZM10.95 17.51C10.66 17.8 10.11 18.08 9.71 18.14L7.25 18.49C7.16 18.5 7.07 18.51 6.98 18.51C6.57 18.51 6.19 18.37 5.92 18.1C5.59 17.77 5.45 17.29 5.53 16.76L5.88 14.3C5.94 13.89 6.21 13.35 6.51 13.06L10.97 8.6C11.05 8.81 11.13 9.02 11.24 9.26C11.34 9.47 11.45 9.69 11.57 9.89C11.67 10.06 11.78 10.22 11.87 10.34C11.98 10.51 12.11 10.67 12.19 10.76C12.24 10.83 12.28 10.88 12.3 10.9C12.55 11.2 12.84 11.48 13.09 11.69C13.16 11.76 13.2 11.8 13.22 11.81C13.37 11.93 13.52 12.05 13.65 12.14C13.81 12.26 13.97 12.37 14.14 12.46C14.34 12.58 14.56 12.69 14.78 12.8C15.01 12.9 15.22 12.99 15.43 13.06L10.95 17.51ZM17.37 11.09L16.45 12.02C16.39 12.08 16.31 12.11 16.23 12.11C16.2 12.11 16.16 12.11 16.14 12.1C14.11 11.52 12.49 9.9 11.91 7.87C11.88 7.76 11.91 7.64 11.99 7.57L12.92 6.64C14.44 5.12 15.89 5.15 17.38 6.64C18.14 7.4 18.51 8.13 18.51 8.89C18.5 9.61 18.13 10.33 17.37 11.09Z"
                :fill="styles.primary"
              />
            </svg>
          </fade>
          <fade>
            <icon v-if="!isEmailDisabled" @click="isEmailDisabled = true" class="tw-cursor-pointer tw-text-[25px]" name="mdi:close-box" :color="styles.primary" />
          </fade>
        </div>
      </div>
      <btn class="tw-self-end" text="Сохранить" :loading="loading" @click="save" />
    </section>
  </v-form>
</template>

<script setup lang="ts">
const store = useStore();
const route = useRoute();
const router = useRouter();
const layoutStore = useLayoutStore();

const form = ref();
const imageInput = ref();
const image = ref<File[]>([]);
const loading = ref<boolean>(false);
const isNameDisabled = ref<boolean>(true);
const isEmailDisabled = ref<boolean>(true);
const user = ref<Api.User.Self | null>(null);

const id = computed(() => (store.auser ? store.auser.id : useCookie<Api.User.Self>('auser').value.id ?? 0));
const brItems: Types.Crumb[] = [{ title: 'Личный кабинет администратора', to: { ...route }, disabled: false }];

const save = useDebounceFn(
  async () => {
    await form.value.validate().then(async (v: Types.VFormValidation) => {
      if (v.valid && user.value) {
        const formData = new FormData();
        formData.append('_method', 'PATCH');
        const img = image.value ? image.value[0] : undefined;
        if (img) formData.append('image', img);
        formData.append('first_name', user.value.first_name);
        if (user.value.email) formData.append('email', String(user.value.email ?? ''));
        formData.append('age', String(user.value.age ?? ''));
        formData.append('city_id', String(user.value.city.id));
        try {
          // @ts-ignore
          const response = await api.users.update(id.value, formData);
          await get();
        } catch (err) {
          console.log(err);
        }
      }
    });
  },
  500,
  { maxWait: 3000 },
);

const get = async () => {
  if (id.value === 0) return;
  try {
    const response = await api.users.get(id.value);
    if (response && response.data) {
      const auser = useCookie('auser');
      user.value = structuredClone(response.data);
      store.auser = response.data;
      auser.value = JSON.stringify(response.data);
    }
  } catch (err) {
    console.log(err);
  }
};

useHead({
  title: () => 'Личный кабинет',
});

onBeforeMount(() => {
  layoutStore.navItem = null;
});

onMounted(async () => {
  await get();
});
</script>

<style>
.profile-input .v-field__input {
  padding: 0 !important;
  font-weight: 600 !important;
  font-size: 14px !important;
  @apply dark:tw-text-white;
}
</style>
