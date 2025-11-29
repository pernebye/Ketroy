// Composable для использования LiquidGL эффекта
// Предоставляет реактивное API для создания Liquid Glass эффекта

interface LiquidGlassOptions {
  target: string | HTMLElement;
  refraction?: number;      // Степень преломления (0-1), default: 0.5
  bevelDepth?: number;      // Глубина фаски, default: 8
  bevelWidth?: number;      // Ширина фаски, default: 8
  frost?: number;           // Степень матовости (0-1), default: 0.2
  magnify?: number;         // Увеличение, default: 1
  shadow?: boolean;         // Тень, default: true
  specular?: boolean;       // Зеркальное отражение, default: true
  tilt?: boolean;           // Интерактивный наклон при hover, default: false
  tiltFactor?: number;      // Фактор наклона, default: 0.1
  reveal?: 'none' | 'fade'; // Анимация появления
  borderRadius?: number;    // Радиус скругления
  on?: {
    init?: () => void;
  };
}

declare global {
  interface Window {
    liquidGL: new (options: LiquidGlassOptions) => {
      destroy: () => void;
      update: () => void;
      setOption: (key: string, value: any) => void;
    };
  }
}

export function useLiquidGlass() {
  const isReady = ref(false);
  const instance = ref<any>(null);

  // Ждём загрузки библиотеки
  const waitForLibrary = (): Promise<void> => {
    return new Promise((resolve) => {
      if (typeof window !== 'undefined' && window.liquidGL) {
        resolve();
        return;
      }

      const checkInterval = setInterval(() => {
        if (typeof window !== 'undefined' && window.liquidGL) {
          clearInterval(checkInterval);
          resolve();
        }
      }, 100);

      // Также слушаем событие ready
      if (typeof window !== 'undefined') {
        window.addEventListener('liquidgl:ready', () => {
          clearInterval(checkInterval);
          resolve();
        }, { once: true });
      }

      // Таймаут через 10 секунд
      setTimeout(() => {
        clearInterval(checkInterval);
        console.warn('LiquidGL library loading timeout');
        resolve();
      }, 10000);
    });
  };

  // Создание эффекта
  const createGlass = async (options: LiquidGlassOptions) => {
    await waitForLibrary();

    if (typeof window === 'undefined' || !window.liquidGL) {
      console.error('LiquidGL library not available');
      return null;
    }

    try {
      // Уничтожаем предыдущий инстанс если есть
      if (instance.value) {
        instance.value.destroy();
      }

      // Создаём новый инстанс
      instance.value = new window.liquidGL({
        refraction: 0.5,
        bevelDepth: 8,
        bevelWidth: 8,
        frost: 0.15,
        shadow: true,
        specular: true,
        tilt: false,
        ...options,
      });

      isReady.value = true;
      return instance.value;
    } catch (error) {
      console.error('Error creating LiquidGL instance:', error);
      return null;
    }
  };

  // Уничтожение эффекта
  const destroyGlass = () => {
    if (instance.value) {
      try {
        instance.value.destroy();
      } catch (e) {
        // Ignore errors on destroy
      }
      instance.value = null;
      isReady.value = false;
    }
  };

  // Обновление эффекта
  const updateGlass = () => {
    if (instance.value) {
      instance.value.update();
    }
  };

  // Очистка при размонтировании компонента
  onUnmounted(() => {
    destroyGlass();
  });

  return {
    isReady,
    instance,
    createGlass,
    destroyGlass,
    updateGlass,
    waitForLibrary,
  };
}





