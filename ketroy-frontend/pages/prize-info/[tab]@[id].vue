<template>
  <div class="prize-info-page">
    <h1 class="prize-info-page__title">Пользователь</h1>
    <p class="prize-info-page__user-name">{{ user?.name }}</p>

    <div class="prize-info-page__grid">
      <card-form v-for="(photo, index) in prizes" :key="index" class="prize-info-page__card">
        <p class="prize-info-page__card-title">Подарок {{ index + 1 }}</p>
        <div class="prize-info-page__card-content">
          <file-input class="prize-info-page__file-input" accept="image/*" :rules="[rules.requiredFile]">
            <svg width="44" height="45" viewBox="0 0 44 45" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect y="0.5" width="44" height="44" rx="8" :fill="styles.primary" />
              <g clip-path="url(#clip0_0_7857)">
                <path
                  d="M21.3416 22.9017C21.1326 22.6926 20.8845 22.5268 20.6115 22.4136C20.3384 22.3004 20.0457 22.2422 19.7501 22.2422C19.4545 22.2422 19.1618 22.3004 18.8887 22.4136C18.6156 22.5268 18.3675 22.6926 18.1586 22.9017L13.0286 28.0317C13.0979 28.9723 13.5198 29.852 14.2097 30.495C14.8997 31.138 15.807 31.4968 16.7501 31.4997H27.2501C27.9849 31.4996 28.7032 31.2822 29.3148 30.875L21.3416 22.9017Z"
                  fill="white"
                />
                <path
                  d="M26.4999 19.5C27.3283 19.5 27.9999 18.8284 27.9999 18C27.9999 17.1716 27.3283 16.5 26.4999 16.5C25.6715 16.5 24.9999 17.1716 24.9999 18C24.9999 18.8284 25.6715 19.5 26.4999 19.5Z"
                  fill="white"
                />
                <path
                  d="M27.25 13.5H16.75C15.7558 13.5012 14.8027 13.8967 14.0997 14.5997C13.3967 15.3027 13.0012 16.2558 13 17.25L13 25.9395L17.098 21.8415C17.4462 21.4932 17.8597 21.2169 18.3147 21.0283C18.7697 20.8398 19.2575 20.7428 19.75 20.7428C20.2425 20.7428 20.7303 20.8398 21.1853 21.0283C21.6403 21.2169 22.0538 21.4932 22.402 21.8415L30.3752 29.8148C30.7825 29.2031 30.9999 28.4848 31 27.75V17.25C30.9988 16.2558 30.6033 15.3027 29.9003 14.5997C29.1973 13.8967 28.2442 13.5012 27.25 13.5V13.5ZM26.5 21C25.9067 21 25.3266 20.8241 24.8333 20.4944C24.3399 20.1648 23.9554 19.6962 23.7284 19.1481C23.5013 18.5999 23.4419 17.9967 23.5576 17.4147C23.6734 16.8328 23.9591 16.2982 24.3787 15.8787C24.7982 15.4591 25.3328 15.1734 25.9147 15.0576C26.4967 14.9419 27.0999 15.0013 27.648 15.2284C28.1962 15.4554 28.6648 15.8399 28.9944 16.3333C29.3241 16.8266 29.5 17.4067 29.5 18C29.5 18.7956 29.1839 19.5587 28.6213 20.1213C28.0587 20.6839 27.2956 21 26.5 21Z"
                  fill="white"
                />
              </g>
              <defs>
                <clipPath id="clip0_0_7857">
                  <rect width="18" height="18" fill="white" transform="translate(13 13.5)" />
                </clipPath>
              </defs>
            </svg>
            <span class="prize-info-page__upload-text">Перетащите изображение сюда или нажмите «Добавить изображение».</span>
          </file-input>
        </div>
      </card-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
const user = ref<Api.User.Self | null>(null);
const id = computed<number>(() => Number(route.params.id));
const route = useRoute();
const router = useRouter();
const prizes = ref([
]);


onMounted(async () => {
  await get();
});
const get = async () => {
  try {
    const response = await api.prizes.get(id.value);
    if (response){
      user.value = response?.user
      prizes.value = response?.prizes.gifts || [];
    }
  } catch (err) {
    console.log(err);
  }
};

</script>

<style scoped>
/* ===== ОСНОВНОЙ КОНТЕЙНЕР ===== */
.prize-info-page {
  background-color: var(--color-bg-secondary, #f7f8fa);
  padding: 1rem;
  border-radius: 0.75rem;
}

@media (min-width: 600px) {
  .prize-info-page {
    padding: 1.5rem;
  }
}

@media (min-width: 960px) {
  .prize-info-page {
    padding: 2rem;
  }
}

/* ===== ЗАГОЛОВОК ===== */
.prize-info-page__title {
  margin-bottom: 1rem;
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .prize-info-page__title {
    margin-bottom: 1.5rem;
    font-size: 1.75rem;
  }
}

/* ===== ИМЯ ПОЛЬЗОВАТЕЛЯ ===== */
.prize-info-page__user-name {
  margin: 1rem 0 1.5rem;
  font-size: 1rem;
  font-weight: 700;
  color: var(--color-text-primary, #2B3674);
}

@media (min-width: 600px) {
  .prize-info-page__user-name {
    margin: 1.25rem 0 2rem;
    font-size: 1.125rem;
  }
}

/* ===== СЕТКА ПОДАРКОВ ===== */
.prize-info-page__grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

@media (min-width: 480px) {
  .prize-info-page__grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 768px) {
  .prize-info-page__grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 1.25rem;
  }
}

@media (min-width: 1200px) {
  .prize-info-page__grid {
    grid-template-columns: repeat(4, 1fr);
    gap: 1rem;
  }
}

/* ===== КАРТОЧКА ПОДАРКА ===== */
.prize-info-page__card {
  height: fit-content;
  width: 100%;
}

.prize-info-page__card-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text-primary);
}

@media (min-width: 600px) {
  .prize-info-page__card-title {
    font-size: 1.125rem;
  }
}

/* ===== КОНТЕНТ КАРТОЧКИ ===== */
.prize-info-page__card-content {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}

.prize-info-page__file-input {
  min-height: 180px;
  flex-grow: 1;
}

@media (min-width: 600px) {
  .prize-info-page__file-input {
    min-height: 200px;
  }
}

@media (min-width: 960px) {
  .prize-info-page__file-input {
    min-height: 230px;
  }
}

.prize-info-page__upload-text {
  margin-top: 1rem;
  text-align: center;
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

@media (min-width: 600px) {
  .prize-info-page__upload-text {
    font-size: 0.875rem;
  }
}
</style>
