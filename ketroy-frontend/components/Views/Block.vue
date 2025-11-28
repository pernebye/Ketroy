<template>
  <section class="admin-block">
    <slot></slot>
  </section>
</template>

<style scoped>
.admin-block {
  display: flex;
  flex-direction: column;
  width: 100%;
  gap: 0.5rem;
  padding: 1.5rem;
  border-radius: 0.75rem;
  background-color: var(--color-bg-card);
  transition: background-color 0.3s ease;
}

@media (min-width: 1280px) {
  .admin-block {
    padding: 2rem;
    border-radius: 0.625rem;
  }
}

@media (min-width: 1920px) {
  .admin-block {
    padding: 2.5rem;
  }
}
</style>
