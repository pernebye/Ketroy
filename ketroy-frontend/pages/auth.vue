<template>
  <div class="auth-page">
    <!-- Background image -->
    <div class="auth-page__bg"></div>
    
    <!-- Overlay gradient -->
    <div class="auth-page__overlay"></div>
    
    <!-- Liquid Glass Container - изолирует позиционирование от эффектов библиотеки -->
    <div v-if="isFormVisible" class="liquid-glass-container">
      <div class="shape liquidGL"></div>
    </div>
    
    <div class="auth-page__content" :class="{ 'auth-page__content--hidden': !isFormVisible }">
      <!-- Logo -->
      <div class="auth-page__logo-wrapper">
        <img src="../public/logo.png" alt="Ketroy" draggable="false" class="auth-page__logo" />
      </div>
      
      <!-- Form Card - контент поверх стекла -->
      <div v-if="isFormVisible" class="auth-page__card">
        <fade>
          <div class="auth-page__header">
            <h1 class="auth-page__title">Добро пожаловать</h1>
            <p class="auth-page__subtitle">Войдите в панель управления</p>
          </div>
        </fade>
        
        <v-form ref="form" @submit.prevent="auth" class="auth-page__form">
          <fade>
            <div class="auth-page__fields">
              <div class="auth-page__field">
                <label class="auth-page__label">
                  <svg class="auth-page__label-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                    <polyline points="22,6 12,13 2,6"/>
                  </svg>
                  Email
                </label>
                <v-text-field 
                  v-model.trim="email" 
                  variant="outlined" 
                  color="#98B35D" 
                  placeholder="admin@ketroy.com" 
                  rounded="xl"
                  class="auth-page__input"
                  :rules="[rules.requiredText, rules.email]" 
                />
              </div>
              
              <div class="auth-page__field">
                <label class="auth-page__label">
                  <svg class="auth-page__label-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                  </svg>
                  Пароль
                </label>
                <v-text-field 
                  v-model.trim="password" 
                  :type="showPassword ? 'text' : 'password'"
                  variant="outlined" 
                  color="#98B35D" 
                  placeholder="••••••••" 
                  rounded="xl"
                  class="auth-page__input"
                  :rules="[rules.requiredText]"
                  :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
                  @click:append-inner="showPassword = !showPassword"
                />
              </div>
              
              <div class="auth-page__options">
                <v-checkbox 
                  v-model="stayIn" 
                  class="auth-checkbox" 
                  density="compact" 
                  color="#98B35D" 
                  :hide-details="true" 
                  label="Запомнить меня" 
                />
              </div>
              
              <btn 
                class="auth-page__submit" 
                text="Войти в систему" 
                :loading="loading" 
                type="submit" 
              />
            </div>
          </fade>
        </v-form>
        
        <div class="auth-page__footer">
          <span>Ketroy Admin Panel</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
declare const liquidGL: any;

const store = useStore();
const form = ref();
const email = ref<string>('');
const password = ref<string>('');
const stayIn = ref<boolean>(true);
const loading = ref<boolean>(false);
const showPassword = ref<boolean>(false);
const isFormVisible = ref<boolean>(true);

let glassEffect: any = null;

const destroyGlassEffect = () => {
  if (glassEffect && typeof glassEffect.destroy === 'function') {
    try {
      glassEffect.destroy();
      glassEffect = null;
    } catch (e) {
      console.error('Error destroying glass effect:', e);
    }
  }
};

const hideFormAndNavigate = () => {
  // Сразу скрываем жидкое стекло и форму
  destroyGlassEffect();
  isFormVisible.value = false;
  loading.value = false;
  
  // Даем время на CSS анимацию
  setTimeout(() => {
    navigateTo({ name: 'content' });
  }, 300);
};

const auth = async () => {
  if (loading.value) return; // Предотвращаем двойной клик
  
  try {
    await form.value.validate().then(async (v: Types.VFormValidation) => {
      if (v.valid) {
        loading.value = true;
        const response = await api.auth.login({
          email: email.value,
          password: password.value,
        });
        console.log(response);
        
        if (response) {
          store.atoken = response.token;
          store.auser = response.user;
          localStorage.setItem("roles", JSON.stringify(response.user.roles));

          if (stayIn.value) {
            const atoken = useCookie('atoken');
            const auser = useCookie('auser');
            atoken.value = response.token;
            auser.value = JSON.stringify(response.user);
          }
          if (response.message) showToaster('success', String(response.message));
          
          // Скрыть форму и перейти
          hideFormAndNavigate();
        } else {
          loading.value = false;
        }
      }
    });
  } catch (err) {
    console.log(err);
    loading.value = false;
  }
};

// Инициализация Liquid Glass эффекта
const initLiquidGlass = async () => {
  await nextTick();
  
  // Ждём загрузки библиотеки
  const waitForLib = () => new Promise<void>((resolve) => {
    const check = setInterval(() => {
      if (typeof liquidGL !== 'undefined') {
        clearInterval(check);
        resolve();
      }
    }, 100);
    setTimeout(() => {
      clearInterval(check);
      resolve();
    }, 5000);
  });
  
  await waitForLib();
  
  // Небольшая задержка для отрисовки
  setTimeout(() => {
    if (typeof liquidGL !== 'undefined') {
      try {
        glassEffect = liquidGL({
          target: '.liquidGL',
          snapshot: 'body',          // Захватывать весь body для преломления
          resolution: 2,             // Разрешение рендеринга
          refraction: 0.15,           // Степень преломления
          bevelDepth: 0.12,          // Глубина фаски (0-1)
          bevelWidth: 0.03,          // Ширина фаски (0-1)
          frost: 2,                  // Матовость (0 = прозрачное стекло)
          magnify: 1,                // Увеличение
          shadow: true,              // Тень
          specular: true,            // Блики
          tilt: true,                // Интерактивный наклон
          tiltFactor: 1,             // Сила наклона
          reveal: 'fade',            // Анимация появления
          on: {
            init: () => {
              console.log('✨ Liquid Glass ready!');
            }
          }
        });
      } catch (e) {
        console.error('LiquidGL init error:', e);
      }
    }
  }, 400);
};

definePageMeta({
  layout: 'clear',
});

useHead({
  title: 'Авторизация',
});

onMounted(() => {
  // Принудительно отключаем темную тему для страницы авторизации
  document.documentElement.classList.remove('dark');
  setPageLayout('clear');
  initLiquidGlass();
});

onUnmounted(() => {
  destroyGlassEffect();
});
</script>

<style scoped>
.auth-page {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  width: 100%;
  padding: 1rem;
  overflow: hidden;
}

.auth-page__bg {
  position: absolute;
  inset: 0;
  background: url('~/assets/img/bg.jpeg') no-repeat center center;
  background-size: cover;
  z-index: 0;
}

.auth-page__overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    rgba(52, 70, 12, 0.70) 0%,
    rgba(58, 69, 16, 0.58) 50%,
    rgba(34, 46, 8, 0.75) 100%
  );
  z-index: 1;
}

/* Контейнер для позиционирования стекла */
.liquid-glass-container {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -47%); /* Подняли выше */
  width: min(460px, calc(100vw - 2rem));
  height: 605px;
  z-index: 5;
  pointer-events: none;
  opacity: 1;
  transition: opacity 0.3s cubic-bezier(0.4, 0, 1, 1), transform 0.3s cubic-bezier(0.4, 0, 1, 1);
}

.liquid-glass-container.v-leave-active {
  opacity: 0;
  transform: translate(-50%, -47%) scale(0.95);
}

/* Само стекло - заполняет контейнер, без трансформаций позиционирования */
.shape {
  width: 100%;
  height: 100%;
  border-radius: 28px;
  will-change: transform;
}

@media (max-height: 700px) {
  .liquid-glass-container {
    height: 540px;
    transform: translate(-50%, -42%); /* Подняли выше */
  }
}

@media (min-width: 600px) {
  .liquid-glass-container {
    width: 460px;
    height: 605px; /* Вернул высоту */
  }
}

/* Стиль для canvas, созданного liquidGL - должен быть внутри контейнера */
:deep(canvas) {
  border-radius: 28px !important;
}

.auth-page__content {
  position: relative;
  z-index: 10;
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  max-width: 460px;
  animation: slideUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  transition: opacity 0.4s cubic-bezier(0.4, 0, 1, 1);
}

.auth-page__content--hidden {
  opacity: 0;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(40px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.auth-page__logo-wrapper {
  margin-bottom: 0.5rem;
  margin-top: -4.5rem; /* Поднимаем логотип выше */
  animation: fadeIn 1s ease-out 0.3s backwards;
  transition: all 0.4s cubic-bezier(0.4, 0, 1, 1);
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: scale(0.9);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.auth-page__logo {
  height: 80px;
  filter: drop-shadow(0 4px 20px rgba(0, 0, 0, 0.3));
  transition: transform 0.3s ease;
}

.auth-page__logo:hover {
  transform: scale(1.05);
}

@media (min-width: 600px) {
  .auth-page__logo {
    height: 90px;
  }
}

/* Form Card - прозрачный, контент поверх стекла */
.auth-page__card {
  position: relative;
  width: 100%;
  padding: 1.5rem; /* Уменьшил с 2rem */
  border-radius: 28px;
  animation: cardAppear 0.6s cubic-bezier(0.16, 1, 0.3, 1) 0.2s backwards;
  background: transparent;
  transition: all 0.4s cubic-bezier(0.4, 0, 1, 1);
}

.auth-page__card.v-leave-active {
  opacity: 0;
  transform: scale(0.95) translateY(-20px);
}

@keyframes cardAppear {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@media (min-width: 600px) {
  .auth-page__card {
    padding: 2rem; /* Уменьшил с 2.5rem */
  }
}

.auth-page__header {
  text-align: center;
  margin-bottom: 1.25rem;
}

.auth-page__title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #fff;
  margin: 0 0 0.5rem 0;
  letter-spacing: -0.02em;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
}

@media (min-width: 600px) {
  .auth-page__title {
    font-size: 2rem;
  }
}

.auth-page__subtitle {
  font-size: 0.95rem;
  color: rgba(255, 255, 255, 0.75);
  margin: 0;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.2);
}

.auth-page__form {
  width: 100%;
}

.auth-page__fields {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.auth-page__field {
  display: flex;
  flex-direction: column;
}

.auth-page__label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.92);
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.auth-page__label-icon {
  width: 16px;
  height: 16px;
  opacity: 0.75;
}

/* Исправление белого фона при автозаполнении */
.auth-page__input :deep(input:-webkit-autofill),
.auth-page__input :deep(input:-webkit-autofill:hover),
.auth-page__input :deep(input:-webkit-autofill:focus),
.auth-page__input :deep(input:-webkit-autofill:active) {
  transition: background-color 5000s ease-in-out 0s;
  -webkit-text-fill-color: #fff !important;
  caret-color: #fff !important;
}

.auth-page__input :deep(.v-field) {
  background: rgba(255, 255, 255, 0.1) !important;
  border: 1px solid rgba(255, 255, 255, 0.18) !important;
  transition: all 0.3s ease !important;
}

.auth-page__input :deep(.v-field:hover) {
  background: rgba(255, 255, 255, 0.14) !important;
  border-color: rgba(255, 255, 255, 0.25) !important;
}

.auth-page__input :deep(.v-field--focused) {
  background: rgba(255, 255, 255, 0.12) !important;
  border-color: rgba(152, 179, 93, 0.6) !important;
  box-shadow: 0 0 0 3px rgba(152, 179, 93, 0.18) !important;
}

.auth-page__input :deep(.v-field__outline) {
  display: none !important;
}

.auth-page__input :deep(input) {
  color: #fff !important;
}

.auth-page__input :deep(input::placeholder) {
  color: rgba(255, 255, 255, 0.45) !important;
}

.auth-page__input :deep(.v-icon) {
  color: rgba(255, 255, 255, 0.55) !important;
  opacity: 1 !important;
}

.auth-page__options {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.auth-checkbox :deep(.v-label) {
  color: rgba(255, 255, 255, 0.85) !important;
  opacity: 1 !important;
  font-size: 0.875rem;
}

.auth-checkbox :deep(.v-selection-control__input > .mdi-checkbox-marked) {
  color: #98B35D !important;
}

.auth-checkbox :deep(.v-selection-control--dirty .v-selection-control__input) {
  color: #98B35D !important;
}

.auth-page__submit {
  width: 100%;
  height: 52px !important;
  margin-top: 0.5rem;
  font-size: 1rem !important;
  font-weight: 600 !important;
  border-radius: 14px !important;
  background: linear-gradient(135deg, #98B35D 0%, #7a9248 100%) !important;
  box-shadow: 0 4px 15px rgba(152, 179, 93, 0.38) !important;
  transition: all 0.3s ease !important;
}

.auth-page__submit:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 22px rgba(152, 179, 93, 0.48) !important;
}

.auth-page__submit:active {
  transform: translateY(0);
}

.auth-page__footer {
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.12);
  text-align: center;
}

.auth-page__footer span {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.5);
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

/* Dark mode - удаляем или меняем стили если они зависят от .dark */
/* Так как мы принудительно убираем класс dark, эти стили не должны применяться, но на всякий случай оставляем их для совместимости */
.dark .auth-page__overlay {
  background: linear-gradient(
    135deg,
    rgba(20, 25, 10, 0.82) 0%,
    rgba(30, 35, 15, 0.72) 50%,
    rgba(15, 20, 8, 0.85) 100%
  );
}
</style>
