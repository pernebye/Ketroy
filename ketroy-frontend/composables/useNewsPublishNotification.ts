/**
 * Composable для управления модальным окном уведомления при публикации новостей
 * Запоминает выбор пользователя "Не спрашивать 5 минут" и применяет его ко всем активациям
 * 
 * ⚠️ ВАЖНО: Уведомления должны отправляться только целевой аудитории согласно фильтрам новости:
 * - города (city)
 * - категории (category)
 * - размер обуви (shoe_size)
 * - размер одежды (clothing_size)
 * 
 * При отправке уведомления на бэкенд необходимо передавать эти параметры:
 * target_cities, target_categories, target_shoe_size, target_clothing_size
 */

interface NotificationState {
  isActive: boolean;
  skipUntil: number | null;
  lastUserChoice: 'yes' | 'no' | null;
  newsItemId: number | null;
}

const STORAGE_KEY = 'news_publish_notification_state';
const SKIP_DURATION_MS = 5 * 60 * 1000; // 5 минут

/**
 * Получить сохранённое состояние из localStorage
 */
const getStoredState = (): NotificationState => {
  if (typeof window === 'undefined') {
    return {
      isActive: false,
      skipUntil: null,
      lastUserChoice: null,
      newsItemId: null,
    };
  }

  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const state = JSON.parse(stored);
      // Проверяем, не истекло ли время пропуска
      if (state.skipUntil && Date.now() > state.skipUntil) {
        // Время истекло, сбрасываем
        return {
          isActive: false,
          skipUntil: null,
          lastUserChoice: null,
          newsItemId: null,
        };
      }
      return state;
    }
  } catch (e) {
    console.error('Error reading notification state:', e);
  }

  return {
    isActive: false,
    skipUntil: null,
    lastUserChoice: null,
    newsItemId: null,
  };
};

/**
 * Сохранить состояние в localStorage
 */
const saveState = (state: NotificationState) => {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (e) {
    console.error('Error saving notification state:', e);
  }
};

/**
 * Основной composable
 */
export const useNewsPublishNotification = () => {
  const state = ref<NotificationState>(getStoredState());
  const isDialogOpen = ref(false);

  /**
   * Проверить, нужно ли показывать модальное окно
   * @param newsItemId - ID новости
   * @param wasInactiveBeforeArchive - была ли новость неактивной перед архивацией
   * @returns true если нужно показать модальное окно
   */
  const shouldShowNotification = (newsItemId: number, wasInactiveBeforeArchive?: boolean): boolean => {
    // Если архивировалась неактивная новость, при разархивации она будет неактивной,
    // поэтому модальное окно не нужно
    if (wasInactiveBeforeArchive) {
      return false;
    }

    // Проверяем, не в режиме ли "не спрашивать"
    const currentState = getStoredState();
    if (currentState.skipUntil && Date.now() <= currentState.skipUntil) {
      // Режим "не спрашивать" активен, используем последний выбор пользователя
      return currentState.lastUserChoice === 'yes';
    }

    return true;
  };

  /**
   * Открыть модальное окно для подтверждения публикации
   */
  const openNotification = (newsItemId: number) => {
    state.value.newsItemId = newsItemId;
    isDialogOpen.value = true;
  };

  /**
   * Закрыть модальное окно
   */
  const closeNotification = () => {
    isDialogOpen.value = false;
  };

  /**
   * Пользователь подтвердил публикацию с уведомлением
   * @param dontAskAgain - если true, не спрашивать 5 минут
   */
  const confirmPublish = (dontAskAgain: boolean = false) => {
    if (dontAskAgain) {
      state.value.skipUntil = Date.now() + SKIP_DURATION_MS;
      state.value.lastUserChoice = 'yes';
      saveState(state.value);
    }
    closeNotification();
    return true;
  };

  /**
   * Пользователь отклонил публикацию с уведомлением
   * @param dontAskAgain - если true, не спрашивать 5 минут
   */
  const rejectPublish = (dontAskAgain: boolean = false) => {
    if (dontAskAgain) {
      state.value.skipUntil = Date.now() + SKIP_DURATION_MS;
      state.value.lastUserChoice = 'no';
      saveState(state.value);
    }
    closeNotification();
    return false;
  };

  /**
   * Сбросить состояние (например, при выходе или явном требовании)
   */
  const resetState = () => {
    state.value = {
      isActive: false,
      skipUntil: null,
      lastUserChoice: null,
      newsItemId: null,
    };
    isDialogOpen.value = false;
    if (typeof window !== 'undefined') {
      localStorage.removeItem(STORAGE_KEY);
    }
  };

  return {
    state: readonly(state),
    isDialogOpen: readonly(isDialogOpen),
    shouldShowNotification,
    openNotification,
    closeNotification,
    confirmPublish,
    rejectPublish,
    resetState,
  };
};

