<template>
  <v-btn :elevation="0" variant="flat" class="admin-btn" />
</template>

<style>
.admin-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: fit-content;
  padding: 10px 14px;
  border-radius: 8px;
  background-color: var(--color-accent) !important;
  color: #FFFFFF !important;
  transition: background-color 0.2s ease, transform 0.2s ease;
}

.admin-btn .v-btn__content,
.admin-btn .v-icon {
  color: #FFFFFF !important;
}

.admin-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
}

.admin-btn .v-btn__content {
  font-weight: 600 !important;
  font-size: 16px !important;
}

.admin-btn .v-btn__prepend {
  margin-inline: unset !important;
  margin-right: 4px !important;
}

.admin-btn .v-btn__append {
  margin-inline: unset !important;
  margin-left: 4px !important;
}

.admin-btn.v-btn .v-icon {
  --v-icon-size-multiplier: 1;
}
</style>
