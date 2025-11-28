<template>
  <div class="admin-layout">
    <!-- Sidebar Navigation -->
    <Navigation 
      :items="navItems"
    />
    
    <div class="admin-content">
      <TopBar />
      <v-expand-transition>
        <NuxtLink v-if="layoutStore.navItem" :to="{ name: layoutStore.navItem.route }">
          <h3 class="admin-page-title">
            {{ layoutStore.navItem.title() }}
          </h3>
        </NuxtLink>
      </v-expand-transition>
      <main class="admin-main"><slot></slot></main>
    </div>
    
    <!-- Bottom Navigation (Mobile) -->
    <BottomNav />
  </div>
</template>

<script setup lang="ts">
const layoutStore = useLayoutStore();
const route = useRoute();


const navItems = [
  {
    title: () => t('admin.nav.analytics'),
    icon: 'ic:round-home',
    route: 'analytics',
  },
  {
    title: () => t('admin.nav.content'),
    icon: 'tabler:layout-dashboard-filled',
    route: 'content',
  },
  {
    title: () => t('admin.nav.adds'),
    icon: 'solar:gift-outline',
    route: 'adds',
  },
  {
    title: () => t('admin.nav.pushNotifications'),
    icon: 'mdi:bell-ring-outline',
    route: 'push-notifications',
  },
  {
    title: () => t('admin.nav.users'),
    icon: 'basil:user-solid',
    route: 'users',
  },
  {
    title: () => t('admin.nav.reviews'),
    icon: 'mdi:star-outline',
    route: 'reviews',
  },
  {
    title: () => t('admin.nav.qr'),
    icon: 'mdi:qrcode',
    route: 'qr'
  }
];
</script>

<style scoped>
.admin-layout {
  display: flex;
  min-height: 100vh;
  background-color: var(--color-bg-primary);
  transition: background-color 0.3s ease;
}


.admin-content {
  position: relative;
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
  gap: 1rem;
  padding: 1rem;
  overflow-x: hidden;
}

/* Tablet */
@media (min-width: 600px) {
  .admin-content {
    gap: 1.25rem;
    padding: 1.25rem;
  }
}

/* Desktop */
@media (min-width: 960px) {
  .admin-content {
    gap: 1.5rem;
    padding: 1.5rem;
  }
}

/* Large Desktop */
@media (min-width: 1280px) {
  .admin-content {
    padding: 2rem;
  }
}

/* Extra Large */
@media (min-width: 1920px) {
  .admin-content {
    padding: 2rem 2.5rem;
  }
}

.admin-page-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text-primary);
  transition: color 0.3s ease;
}

@media (min-width: 600px) {
  .admin-page-title {
    font-size: 1.5rem;
  }
}

.admin-main {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  gap: 1rem;
  padding-bottom: calc(64px + 1rem + env(safe-area-inset-bottom, 0px));
}

@media (min-width: 600px) {
  .admin-main {
    gap: 1.25rem;
    padding-bottom: calc(64px + 1.25rem + env(safe-area-inset-bottom, 0px));
  }
}

@media (min-width: 960px) {
  .admin-main {
    gap: 1.5rem;
    padding-bottom: 1.5rem;
  }
}
</style>
