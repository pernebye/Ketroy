// LiquidGL Plugin - Client-side only
// Подключает библиотеку liquidGL для эффекта Liquid Glass

export default defineNuxtPlugin(async () => {
  // Загружаем скрипты только на клиенте
  if (typeof window !== 'undefined') {
    // Импортируем html2canvas из npm пакета
    const html2canvas = await import('html2canvas');
    (window as any).html2canvas = html2canvas.default || html2canvas;

    // Загружаем liquidGL из статических файлов (обходим Vite обработку)
    const loadScript = (src: string): Promise<void> => {
      return new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = src;
        script.async = true;
        script.onload = () => resolve();
        script.onerror = reject;
        document.head.appendChild(script);
      });
    };

    try {
      await loadScript('/libs/liquidGL.iife.js');
      console.log('✨ LiquidGL loaded successfully');
      window.dispatchEvent(new CustomEvent('liquidgl:ready'));
    } catch (e) {
      console.error('Failed to load LiquidGL:', e);
    }
  }
});

