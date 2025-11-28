<template>
  <div class="topbar">
    <div class="topbar__search">
      <v-text-field 
        placeholder="Поиск" 
        class="topbar__search-input" 
        variant="plain" 
        density="compact"
        hide-details 
        prepend-inner-icon="mdi-magnify"
      />
    </div>

    <v-divider class="topbar__divider topbar__divider--desktop" :vertical="true" />

    <!-- Переключатель темы -->
    <div class="topbar__theme">
      <v-btn
        icon
        variant="text"
        size="small"
        @click="toggleColorMode"
        class="topbar__theme-btn"
        :title="colorMode.value === 'dark' ? 'Светлая тема' : 'Тёмная тема'"
      >
        <v-icon>{{ colorMode.value === 'dark' ? 'mdi-weather-sunny' : 'mdi-weather-night' }}</v-icon>
      </v-btn>
    </div>

    <v-divider class="topbar__divider topbar__divider--desktop" :vertical="true" />

    <div class="topbar__user">
      <v-menu offset-y :close-on-content-click="false" activator="parent">
        <template v-slot:activator="{ props: menuProps }">
          <div class="topbar__user-info" v-bind="menuProps" v-if="store.auser">
            <img 
              v-if="store.auser.image && store.auser.image.path" 
              class="topbar__avatar"
              :src="fileUrlValidator(store.auser.image.path)" 
              alt="Admin image" 
              draggable="false"
            />
            <v-avatar v-else size="32" class="topbar__avatar topbar__avatar--placeholder">
              <v-icon>mdi-account</v-icon>
            </v-avatar>
            <div class="topbar__user-details">
              <span class="topbar__user-name">{{ `${store.auser.name ?? ''} ${store.auser.surname ?? ''}` }}</span>
              <span class="topbar__user-role">{{ hasRole('super-admin') ? "Админ" : "Маркетолог" }}</span>
            </div>
          </div>
        </template>
        <v-list>
          <v-list-item @click="logout">
            <v-list-item-title>Выйти</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-menu>
    </div>
  </div>
</template>

<script setup lang="ts">
const store = useStore();
const stayIn = ref<boolean>(true);
const {hasRole} = useAccess();
const colorMode = useColorMode();

const toggleColorMode = () => {
  colorMode.preference = colorMode.value === 'dark' ? 'light' : 'dark';
};

const logout = useDebounceFn(
    async () => {
      try {
        const response = await api.auth.logout();
        console.log(response);

        if (response) {
          store.atoken = null;
          store.auser = null;
          localStorage.removeItem("roles");
          if (stayIn.value) {
            const atoken = useCookie('atoken');
            const auser = useCookie('auser');
            atoken.value = null;
            auser.value = null;
          }

          if (response.message) showToaster('success', String(response.message));

          navigateTo({name: 'auth'});
        }
      } catch (err) {
        console.log('Error logging out:', err);
      } finally {
      }
    },
    500,
    {maxWait: 3000},
);
</script>

<style scoped>
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 52px;
  width: 100%;
  padding: 0 0.5rem;
  border-radius: 1rem;
  background-color: var(--color-bg-secondary);
  transition: background-color 0.3s ease;
  gap: 0.25rem;
}

@media (min-width: 600px) {
  .topbar {
    height: 56px;
    padding: 0 0.75rem;
    border-radius: 1.5rem;
    gap: 0.5rem;
  }
}

@media (min-width: 960px) {
  .topbar {
    height: 64px;
    padding: 0 0.5rem;
    border-radius: 9999px;
  }
}


.topbar__search {
  flex: 1;
  min-width: 0;
  padding: 0 0.5rem;
}

@media (min-width: 600px) {
  .topbar__search {
    padding: 0 1rem;
  }
}

@media (min-width: 960px) {
  .topbar__search {
    padding: 0 2rem;
  }
}

.topbar__search-input {
  width: 100%;
}

:deep(.topbar__search-input .v-field) {
  background-color: transparent !important;
}

:deep(.topbar__search-input .v-field__input) {
  color: var(--color-text-primary) !important;
  background-color: transparent !important;
  font-size: 0.875rem;
}

@media (min-width: 600px) {
  :deep(.topbar__search-input .v-field__input) {
    font-size: 1rem;
  }
}

:deep(.topbar__search-input .v-field__input::placeholder) {
  color: var(--color-text-muted) !important;
  opacity: 1;
}

:deep(.topbar__search-input .v-field__prepend-inner .v-icon) {
  color: var(--color-text-muted) !important;
}

:deep(.topbar__search-input .v-field--variant-plain) {
  --v-field-padding-start: 0;
  --v-field-padding-end: 0;
}

.topbar__divider {
  height: 60%;
  align-self: center;
  opacity: 0.5;
  border-color: var(--color-border-light) !important;
}

.topbar__divider--desktop {
  display: none;
}

@media (min-width: 600px) {
  .topbar__divider {
    height: 70%;
  }
  
  .topbar__divider--desktop {
    display: block;
  }
}

@media (min-width: 960px) {
  .topbar__divider {
    height: 80%;
  }
}

.topbar__theme {
  display: flex;
  align-items: center;
  padding: 0 0.25rem;
}

@media (min-width: 600px) {
  .topbar__theme {
    padding: 0 0.5rem;
  }
}

@media (min-width: 960px) {
  .topbar__theme {
    padding: 0 1rem;
  }
}

.topbar__theme-btn {
  color: var(--color-text-secondary) !important;
}

.topbar__theme-btn:hover {
  color: var(--color-accent) !important;
}

.topbar__user {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 0 0.5rem;
}

@media (min-width: 600px) {
  .topbar__user {
    padding: 0 0.75rem;
  }
}

@media (min-width: 960px) {
  .topbar__user {
    padding: 0 1.25rem;
  }
}

.topbar__user-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.topbar__avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

@media (min-width: 600px) {
  .topbar__avatar {
    width: 32px;
    height: 32px;
  }
}

.topbar__avatar--placeholder {
  background-color: var(--color-bg-tertiary);
  color: var(--color-text-muted);
}

.topbar__user-details {
  display: none;
  flex-direction: column;
  line-height: 1.3;
}

@media (min-width: 768px) {
  .topbar__user-details {
    display: flex;
  }
}

.topbar__user-name {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text-primary);
  white-space: nowrap;
}

.topbar__user-role {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}
</style>
