<template>
  <div class="card-form"><slot></slot></div>
</template>

<style scoped>
.card-form {
  display: flex;
  flex-direction: column;
  padding: 1.5rem;
  border-radius: 12px;
  background-color: var(--color-bg-card);
  box-shadow: 0 4px 6px -1px var(--color-shadow);
  transition: background-color 0.3s ease, box-shadow 0.3s ease;
}
</style>
