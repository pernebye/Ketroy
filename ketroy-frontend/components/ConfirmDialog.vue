<template>
  <Teleport to="body">
    <Transition name="confirm-fade">
      <div v-if="state.isOpen" class="confirm-overlay" @click.self="handleCancel">
        <Transition name="confirm-scale" appear>
          <div v-if="state.isOpen" class="confirm-dialog" :class="[themeClass, `confirm-dialog--${state.type}`]">
            <!-- Icon -->
            <div class="confirm-icon" :class="`confirm-icon--${state.type}`">
              <svg v-if="state.type === 'danger'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 6h18M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>
                <line x1="10" y1="11" x2="10" y2="17"/>
                <line x1="14" y1="11" x2="14" y2="17"/>
              </svg>
              <svg v-else-if="state.type === 'warning'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                <line x1="12" y1="9" x2="12" y2="13"/>
                <line x1="12" y1="17" x2="12.01" y2="17"/>
              </svg>
              <svg v-else width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"/>
                <line x1="12" y1="16" x2="12" y2="12"/>
                <line x1="12" y1="8" x2="12.01" y2="8"/>
              </svg>
            </div>
            
            <!-- Content -->
            <div class="confirm-content">
              <h3 class="confirm-title">{{ state.title }}</h3>
              <p class="confirm-message">{{ state.message }}</p>
            </div>
            
            <!-- Actions -->
            <div class="confirm-actions">
              <button 
                v-if="state.showCancel" 
                class="confirm-btn confirm-btn--cancel"
                @click="handleCancel"
              >
                {{ state.cancelText }}
              </button>
              <button 
                class="confirm-btn confirm-btn--confirm"
                :class="`confirm-btn--${state.type}`"
                @click="handleConfirm"
              >
                {{ state.confirmText }}
              </button>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { useConfirm } from '~/composables/useConfirm';

const colorMode = useColorMode();
const themeClass = computed(() => colorMode.value === 'dark' ? 'confirm-dialog--dark' : 'confirm-dialog--light');

const { state, handleConfirm, handleCancel } = useConfirm();

// Close on Escape key
onMounted(() => {
  const handleKeydown = (e: KeyboardEvent) => {
    if (e.key === 'Escape' && state.isOpen) {
      handleCancel();
    }
  };
  window.addEventListener('keydown', handleKeydown);
  onUnmounted(() => window.removeEventListener('keydown', handleKeydown));
});
</script>

<style scoped>
.confirm-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
}

.confirm-dialog {
  position: relative;
  width: 100%;
  max-width: 400px;
  padding: 28px;
  border-radius: 20px;
  box-shadow: 
    0 25px 50px -12px rgba(0, 0, 0, 0.25),
    0 0 0 1px rgba(255, 255, 255, 0.1);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

/* Light Theme */
.confirm-dialog--light {
  background: linear-gradient(145deg, #ffffff, #f8f9fa);
  border: 1px solid rgba(52, 70, 12, 0.1);
}

.confirm-dialog--light .confirm-title {
  color: #1a1a1a;
}

.confirm-dialog--light .confirm-message {
  color: #4a5568;
}

.confirm-dialog--light .confirm-btn--cancel {
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #e2e8f0;
}

.confirm-dialog--light .confirm-btn--cancel:hover {
  background: #e2e8f0;
}

/* Dark Theme */
.confirm-dialog--dark {
  background: linear-gradient(145deg, #262626, #1a1a1a);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.confirm-dialog--dark .confirm-title {
  color: #ffffff;
}

.confirm-dialog--dark .confirm-message {
  color: #a1a1aa;
}

.confirm-dialog--dark .confirm-btn--cancel {
  background: #3f3f46;
  color: #e4e4e7;
  border: 1px solid #52525b;
}

.confirm-dialog--dark .confirm-btn--cancel:hover {
  background: #52525b;
}

/* Icon */
.confirm-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.confirm-icon--danger {
  background: linear-gradient(135deg, #fef2f2, #fee2e2);
  color: #dc2626;
  box-shadow: 0 8px 16px -4px rgba(220, 38, 38, 0.2);
}

.confirm-dialog--dark .confirm-icon--danger {
  background: linear-gradient(135deg, #450a0a, #7f1d1d);
  color: #f87171;
}

.confirm-icon--warning {
  background: linear-gradient(135deg, #fffbeb, #fef3c7);
  color: #d97706;
  box-shadow: 0 8px 16px -4px rgba(217, 119, 6, 0.2);
}

.confirm-dialog--dark .confirm-icon--warning {
  background: linear-gradient(135deg, #451a03, #78350f);
  color: #fbbf24;
}

.confirm-icon--info {
  background: linear-gradient(135deg, #ebf3da, #d4e4b3);
  color: #34460C;
  box-shadow: 0 8px 16px -4px rgba(52, 70, 12, 0.2);
}

.confirm-dialog--dark .confirm-icon--info {
  background: linear-gradient(135deg, #1d2b05, #34460C);
  color: #98B35D;
}

/* Content */
.confirm-content {
  text-align: center;
}

.confirm-title {
  font-family: 'Gilroy', sans-serif;
  font-size: 1.25rem;
  font-weight: 700;
  margin: 0 0 8px 0;
  line-height: 1.3;
}

.confirm-message {
  font-family: 'Gilroy', sans-serif;
  font-size: 0.95rem;
  font-weight: 500;
  margin: 0;
  line-height: 1.5;
}

/* Actions */
.confirm-actions {
  display: flex;
  gap: 12px;
  width: 100%;
  margin-top: 4px;
}

.confirm-btn {
  flex: 1;
  padding: 14px 24px;
  border-radius: 12px;
  font-family: 'Gilroy', sans-serif;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  border: none;
  outline: none;
}

.confirm-btn:focus-visible {
  box-shadow: 0 0 0 3px rgba(152, 179, 93, 0.4);
}

.confirm-btn--cancel:active {
  transform: scale(0.98);
}

.confirm-btn--confirm {
  color: white;
  box-shadow: 0 4px 12px -2px rgba(0, 0, 0, 0.15);
}

.confirm-btn--confirm:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px -2px rgba(0, 0, 0, 0.2);
}

.confirm-btn--confirm:active {
  transform: translateY(0) scale(0.98);
}

.confirm-btn--danger {
  background: linear-gradient(135deg, #ef4444, #dc2626);
}

.confirm-btn--danger:hover {
  background: linear-gradient(135deg, #f87171, #ef4444);
}

.confirm-btn--warning {
  background: linear-gradient(135deg, #f59e0b, #d97706);
}

.confirm-btn--warning:hover {
  background: linear-gradient(135deg, #fbbf24, #f59e0b);
}

.confirm-btn--info {
  background: linear-gradient(135deg, #98B35D, #7a9a3d);
}

.confirm-btn--info:hover {
  background: linear-gradient(135deg, #a8c36d, #98B35D);
}

/* Animations */
.confirm-fade-enter-active,
.confirm-fade-leave-active {
  transition: opacity 0.25s ease;
}

.confirm-fade-enter-from,
.confirm-fade-leave-to {
  opacity: 0;
}

.confirm-scale-enter-active {
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.confirm-scale-leave-active {
  transition: all 0.2s ease-in;
}

.confirm-scale-enter-from {
  opacity: 0;
  transform: scale(0.9) translateY(10px);
}

.confirm-scale-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>




