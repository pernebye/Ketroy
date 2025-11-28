<template>
  <nav class="admin-nav">
    <NuxtLink class="admin-nav__logo" :to="{ name: 'index' }">
      <svg class="admin-nav__logo-icon" width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M6.63478 12.8303L13.7931 0H15.4627L2.07974 23.9998H0.407227" fill="currentColor"/>
        <path d="M10.2096 23.9998L23.5926 0H21.9201L8.53711 23.9998" fill="currentColor"/>
        <path d="M13.8765 23.4996H13.3481L12.2036 21.4459L12.4673 20.9733L13.8765 23.4996Z" fill="currentColor"/>
        <path d="M22.002 23.4996H21.4775L16.2676 14.1598L16.5322 13.6871L22.002 23.4996Z" fill="currentColor"/>
        <path d="M0.407227 23.9998V0H1.87613V21.3674" fill="currentColor"/>
        <path d="M7.54785 11.1956V0H9.01675V8.56325" fill="currentColor"/>
      </svg>
      <span class="admin-nav__brand">KETROY</span>
    </NuxtLink>
    
    <div class="admin-nav__menu">
      <template v-for="(item, index) of items" :key="item.title">
        <NuxtLink 
          :to="{ name: item.route }" 
          class="admin-nav__item" 
          :class="{ 'admin-nav__item--active': isCurrentNav(item) }"
        >
          <Icon class="admin-nav__icon" :name="item.icon" />
          <span class="admin-nav__text">{{ item.title() }}</span>
          <v-scale-transition>
            <div v-if="isCurrentNav(item)" class="admin-nav__indicator"></div>
          </v-scale-transition>
        </NuxtLink>
      </template>
    </div>
  </nav>
</template>

<script setup lang="ts">
const route = useRoute();
const layoutStore = useLayoutStore();

defineProps({
  items: {
    type: Array as PropType<Types.Nav.AdmItem[]>,
    default: [],
  },
});

const isCurrentNav = (item: Types.Nav.AdmItem) => {
  const isCurrent = String(route.name).startsWith(item.route);
  if (isCurrent) layoutStore.navItem = item;
  return isCurrent;
};
</script>

<style scoped>
.admin-nav {
  display: none;
  flex-direction: column;
  align-items: center;
  min-height: 100vh;
  width: 280px;
  flex-shrink: 0;
  background-color: var(--color-bg-secondary);
  transition: background-color 0.3s ease;
}

/* Desktop: always visible */
@media (min-width: 960px) {
  .admin-nav {
    display: flex;
    position: relative;
    transform: none;
    width: 260px;
  }
}

@media (min-width: 1280px) {
  .admin-nav {
    width: 280px;
  }
}

@media (min-width: 1920px) {
  .admin-nav {
    width: 300px;
  }
}


.admin-nav__logo {
  display: flex;
  align-items: center;
  align-self: flex-start;
  gap: 0.625rem;
  margin: 2rem 0 1.5rem 1.25rem;
  text-decoration: none;
  color: var(--color-accent);
  transition: color 0.3s ease, opacity 0.2s ease;
}

.admin-nav__logo:hover {
  opacity: 0.85;
}

.admin-nav__logo-icon {
  flex-shrink: 0;
  width: 24px;
  height: 24px;
}

.admin-nav__brand {
  font-family: 'Gilroy', sans-serif;
  font-weight: 700;
  font-size: 1.25rem;
  letter-spacing: 0.15em;
  color: inherit;
}

@media (min-width: 960px) {
  .admin-nav__logo {
    gap: 0.75rem;
    margin: 2.5rem 0 2.5rem 1.5rem;
  }
  
  .admin-nav__logo-icon {
    width: 26px;
    height: 26px;
  }
  
  .admin-nav__brand {
    font-size: 1.375rem;
  }
}

@media (min-width: 1280px) {
  .admin-nav__logo {
    margin: 3rem 0 3rem 1.75rem;
  }
  
  .admin-nav__logo-icon {
    width: 28px;
    height: 28px;
  }
  
  .admin-nav__brand {
    font-size: 1.5rem;
  }
}

.admin-nav__menu {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 100%;
  gap: 0.75rem;
  padding: 1rem 1.25rem 2rem;
}

@media (min-width: 600px) {
  .admin-nav__menu {
    gap: 1rem;
    padding: 1.5rem 1.5rem 2rem;
  }
}

@media (min-width: 1280px) {
  .admin-nav__menu {
    gap: 1.25rem;
    padding: 2rem 1.75rem;
  }
}

.admin-nav__item {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  padding: 0.5rem 0;
  text-decoration: none;
  transition: all 0.2s ease;
}

@media (min-width: 600px) {
  .admin-nav__item {
    padding: 0.375rem 0;
  }
}

.admin-nav__icon {
  margin-right: 0.75rem;
  font-size: 1.375rem;
  color: var(--color-text-muted);
  transition: color 0.2s ease;
}

@media (min-width: 600px) {
  .admin-nav__icon {
    font-size: 1.5rem;
  }
}

.admin-nav__text {
  font-size: 0.875rem;
  font-weight: 700;
  color: var(--color-text-muted);
  transition: color 0.2s ease;
}

@media (min-width: 600px) {
  .admin-nav__text {
    font-size: 0.9375rem;
  }
}

@media (min-width: 1280px) {
  .admin-nav__text {
    font-size: 1rem;
  }
}

.admin-nav__item--active .admin-nav__icon,
.admin-nav__item--active .admin-nav__text {
  color: var(--color-accent);
}

.admin-nav__item:hover .admin-nav__icon,
.admin-nav__item:hover .admin-nav__text {
  color: var(--color-text-primary);
}

.admin-nav__indicator {
  position: absolute;
  right: 0;
  top: 50%;
  transform: translateY(-50%);
  height: 28px;
  width: 4px;
  border-radius: 24px;
  background-color: var(--color-accent);
}

@media (min-width: 600px) {
  .admin-nav__indicator {
    height: 32px;
  }
}
</style>
