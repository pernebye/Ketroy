<template>
  <div class="users-create">
    <div class="users-create__header">
      <v-breadcrumbs :items="brItems" class="users-create__breadcrumbs">
        <template v-slot:divider>
          <icon name="bi:caret-right-fill" :color="styles.greySemiDark"/>
        </template>
      </v-breadcrumbs>
      <btn text="Сохранить" prepend-icon="mdi-plus" :loading="loading" @click="save"/>
    </div>
    <v-form ref="form" class="users-create__form">
      <fade>
        <div class="users-create__content">
          <card-form class="users-create__card">
            <div class="users-create__fields">
              <div class="users-create__field-group">
                <span class="users-create__label">Фамилия</span>
                <v-text-field
                    v-model.trim="adminUser.surname"
                    density="compact"
                    variant="outlined"
                    :bg-color="styles.greyLight"
                    placeholder="Введите фамилию"
                    rounded="lg"
                    :rules="[rules.requiredText]"
                />
              </div>
              <div class="users-create__field-group">
                <span class="users-create__label">Имя</span>
                <v-text-field
                    v-model.trim="adminUser.name"
                    density="compact"
                    variant="outlined"
                    :bg-color="styles.greyLight"
                    placeholder="Введите имя"
                    rounded="lg"
                    :rules="[rules.requiredText]"
                />
              </div>
              <div class="users-create__field-group">
                <span class="users-create__label">Email</span>
                <v-text-field
                    v-model.trim="adminUser.email"
                    density="compact"
                    variant="outlined"
                    type="email"
                    :bg-color="styles.greyLight"
                    placeholder="Введите email"
                    rounded="lg"
                    :rules="[rules.requiredText, rules.email]"
                />
              </div>
              <div class="users-create__field-group">
                <span class="users-create__label">Роль</span>
                <v-select
                    v-model="adminUser.role"
                    placeholder="Выберите роль"
                    :items="options"
                    density="compact"
                    variant="outlined"
                    :bg-color="styles.greyLight"
                    :persistent-placeholder="true"
                    rounded="lg"
                    item-value="key"
                    item-title="value"
                />
              </div>
              <div class="users-create__field-group">
                <span class="users-create__label">Пароль</span>
                <v-text-field
                    v-model.trim="adminUser.password"
                    density="compact"
                    variant="outlined"
                    :bg-color="styles.greyLight"
                    placeholder="Мин. 8 символов"
                    rounded="lg"
                    :rules="[rules.requiredText, rules.minLength8, () =>
        adminUser.password === adminUser.password_confirmation || 'Пароли не совпадают']"
                />
              </div>
              <div class="users-create__field-group">
                <span class="users-create__label">Повторите пароль</span>
                <v-text-field
                    v-model.trim="adminUser.password_confirmation"
                    density="compact"
                    variant="outlined"
                    :bg-color="styles.greyLight"
                    placeholder="Мин. 8 символов"
                    rounded="lg"
                    :rules="[rules.requiredText, rules.minLength8, () =>
        adminUser.password === adminUser.password_confirmation || 'Пароли не совпадают']"
                />
              </div>
            </div>
          </card-form>
        </div>
      </fade>
    </v-form>
  </div>
</template>

<script setup lang="ts">
import {computed, ref} from 'vue';
import {useRoute, useRouter} from 'vue-router';
import {useDebounceFn} from '@vueuse/core';

const route = useRoute();
const router = useRouter();
const loading = ref<boolean>(false);
const id = computed<number | 'new'>(() => (route.params.id === 'new' ? 'new' : Number(route.params.id)));
const adminUser = ref<{ name: string; surname: string; email: string; role: string; password: string, password_confirmation: string }>({
  name: '',
  surname: '',
  email: '',
  role: '',
  password: '',
  password_confirmation: ''
});

const options = ref([
  {key: "super-admin", value: 'Супер-админ'},
  {key: "marketer", value: 'Маркетолог'},
]);

const brItems: Types.Crumb[] = [
  {title: t(`admin.nav.users`), to: {name: 'users'}, disabled: false},
  {
    title: 'Добавить роль',
    to: {...route},
    disabled: false
  },
];

const save = useDebounceFn(
    async () => {
      loading.value = true;
      const formData = {
        name: adminUser.value.name,
        surname: adminUser.value.surname,
        email: adminUser.value.email,
        role: adminUser.value.role,
        password: adminUser.value.password,
        password_confirmation: adminUser.value.password_confirmation
      };

      try {
        const response = await api.admins.add(formData);
        if (response) {
          await router.push({name: 'users', query: {tab: 'admins'}});
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

</script>

<style scoped>
/* ===== ОСНОВНОЙ КОНТЕЙНЕР ===== */
.users-create {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* ===== ШАПКА ===== */
.users-create__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 6px;
  flex-wrap: wrap;
  gap: 0.75rem;
}

@media (max-width: 599px) {
  .users-create__header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .users-create__header > :last-child {
    align-self: flex-end;
  }
}

.users-create__breadcrumbs {
  color: var(--color-text-secondary);
}

:root.dark .users-create__breadcrumbs {
  color: white;
}

/* ===== ФОРМА ===== */
.users-create__form {
  color: var(--color-text-primary);
}

:root.dark .users-create__form {
  color: white;
}

/* ===== КОНТЕНТ ===== */
.users-create__content {
  width: 100%;
}

.users-create__card {
  width: 100%;
  max-width: 600px;
}

@media (min-width: 960px) {
  .users-create__card {
    max-width: 700px;
  }
}

/* ===== ПОЛЯ ФОРМЫ ===== */
.users-create__fields {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  gap: 0.25rem;
}

.users-create__field-group {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.users-create__label {
  font-size: 0.8125rem;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .users-create__label {
    font-size: 0.875rem;
  }
}
</style>
