<template>
  <nav class="bottom-nav">
    <!-- Left items -->
    <NuxtLink
      v-for="item in leftItems"
      :key="item.route"
      :to="{ name: item.route }"
      class="bottom-nav__item"
      :class="{ 'bottom-nav__item--active': isActive(item.route) }"
    >
      <Icon class="bottom-nav__icon" :name="item.icon" />
      <span class="bottom-nav__label">{{ item.title() }}</span>
    </NuxtLink>
    
    <!-- Center QR Button -->
    <NuxtLink
      :to="{ name: 'qr' }"
      class="bottom-nav__qr-btn"
      :class="{ 'bottom-nav__qr-btn--active': isActive('qr') }"
    >
      <div class="bottom-nav__qr-circle">
        <Icon class="bottom-nav__qr-icon" name="mdi:qrcode-scan" />
      </div>
      <span class="bottom-nav__qr-label">QR</span>
    </NuxtLink>
    
    <!-- Right items -->
    <NuxtLink
      v-for="item in rightItems"
      :key="item.route"
      :to="{ name: item.route }"
      class="bottom-nav__item"
      :class="{ 'bottom-nav__item--active': isActive(item.route) }"
    >
      <Icon class="bottom-nav__icon" :name="item.icon" />
      <span class="bottom-nav__label">{{ item.title() }}</span>
    </NuxtLink>
  </nav>
</template>

<script setup lang="ts">
const route = useRoute();

const leftItems = [
  {
    title: () => 'Аналит.',
    icon: 'mdi:chart-line',
    route: 'analytics',
  },
  {
    title: () => 'Контент',
    icon: 'tabler:layout-dashboard-filled',
    route: 'content',
  },
];

const rightItems = [
  {
    title: () => 'Польз.',
    icon: 'basil:user-solid',
    route: 'users',
  },
  {
    title: () => 'Акции',
    icon: 'solar:gift-outline',
    route: 'adds',
  },
];

const isActive = (routeName: string) => {
  return String(route.name).startsWith(routeName);
};
</script>

<style scoped>
.bottom-nav {
  display: flex;
  align-items: flex-end;
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 100;
  height: 64px;
  background-color: var(--color-bg-secondary);
  border-top: 1px solid var(--color-border);
  box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
  padding: 0 0.5rem;
  padding-bottom: env(safe-area-inset-bottom, 0);
}

@media (min-width: 960px) {
  .bottom-nav {
    display: none;
  }
}

.bottom-nav__item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  gap: 0.25rem;
  padding: 0.5rem 0.25rem;
  text-decoration: none;
  color: var(--color-text-muted);
  transition: all 0.2s ease;
  position: relative;
  height: 100%;
}

.bottom-nav__item::before {
  content: '';
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 3px;
  background-color: var(--color-accent);
  border-radius: 0 0 4px 4px;
  transition: width 0.2s ease;
}

.bottom-nav__item--active::before {
  width: 32px;
}

.bottom-nav__item--active {
  color: var(--color-accent);
}

.bottom-nav__item:active {
  transform: scale(0.95);
}

.bottom-nav__icon {
  font-size: 1.375rem;
  transition: transform 0.2s ease;
}

.bottom-nav__item--active .bottom-nav__icon {
  transform: scale(1.1);
}

.bottom-nav__label {
  font-size: 0.6875rem;
  font-weight: 600;
  text-align: center;
  white-space: nowrap;
}

/* === QR Button === */
.bottom-nav__qr-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-end;
  flex: 1;
  gap: 0.25rem;
  padding-bottom: 0.5rem;
  text-decoration: none;
  position: relative;
  height: 100%;
}

.bottom-nav__qr-circle {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: linear-gradient(135deg, #5A6F2B 0%, #3C4B1B 100%);
  box-shadow: 
    0 4px 14px rgba(60, 75, 27, 0.4),
    0 2px 6px rgba(60, 75, 27, 0.2);
  position: absolute;
  top: -20px;
  left: 50%;
  transform: translateX(-50%);
  transition: all 0.25s ease;
}

.bottom-nav__qr-btn:hover .bottom-nav__qr-circle {
  transform: translateX(-50%) scale(1.05);
  box-shadow: 
    0 6px 18px rgba(60, 75, 27, 0.5),
    0 3px 8px rgba(60, 75, 27, 0.3);
}

.bottom-nav__qr-btn:active .bottom-nav__qr-circle {
  transform: translateX(-50%) scale(0.95);
}

.bottom-nav__qr-btn--active .bottom-nav__qr-circle {
  background: linear-gradient(135deg, #6A8030 0%, #4A5A22 100%);
  box-shadow: 
    0 6px 20px rgba(60, 75, 27, 0.5),
    0 3px 10px rgba(60, 75, 27, 0.3),
    0 0 0 3px rgba(60, 75, 27, 0.15);
}

.bottom-nav__qr-icon {
  font-size: 1.5rem;
  color: white;
}

.bottom-nav__qr-label {
  font-size: 0.6875rem;
  font-weight: 600;
  text-align: center;
  white-space: nowrap;
  color: var(--color-text-muted);
  transition: color 0.2s ease;
}

.bottom-nav__qr-btn--active .bottom-nav__qr-label {
  color: var(--color-accent);
}

@media (min-width: 400px) {
  .bottom-nav__label,
  .bottom-nav__qr-label {
    font-size: 0.75rem;
  }
}

@media (min-width: 480px) {
  .bottom-nav {
    padding: 0 1rem;
  }
  
  .bottom-nav__item {
    gap: 0.375rem;
  }
  
  .bottom-nav__icon {
    font-size: 1.5rem;
  }
  
  .bottom-nav__label,
  .bottom-nav__qr-label {
    font-size: 0.8125rem;
  }
  
  .bottom-nav__qr-circle {
    width: 56px;
    height: 56px;
    top: -22px;
  }
  
  .bottom-nav__qr-icon {
    font-size: 1.625rem;
  }
}
</style>
