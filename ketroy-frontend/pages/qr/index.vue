<template>
  <div class="qr-page">
    <!-- Кнопки действий -->
    <div class="qr-page__actions">
      <button class="qr-page__action-btn" @click="downloadQR" title="Скачать QR-код">
        <Icon name="mdi:download" class="qr-page__action-icon" />
        <span class="qr-page__action-text">Скачать</span>
      </button>
      <button class="qr-page__action-btn qr-page__action-btn--primary" @click="printQR" title="Распечатать QR-код">
        <Icon name="mdi:printer" class="qr-page__action-icon" />
        <span class="qr-page__action-text">Печать</span>
      </button>
    </div>

    <!-- QR-код контейнер -->
    <div class="qr-page__card">
      <div class="qr-page__qr-wrapper" ref="qrWrapper">
        <div class="qr-page__content" v-html="qr"></div>
      </div>
      <p class="qr-page__hint">Отсканируйте QR-код для получения скидки</p>
    </div>

    <!-- Скрытый контейнер для печати -->
    <div ref="printContainer" class="qr-page__print-container">
      <div class="print-page">
        <div class="print-page__header">
          <img src="/nav_logo_dark.svg" alt="Ketroy" class="print-page__logo" />
          <h1 class="print-page__title">KETROY</h1>
        </div>
        
        <div class="print-page__qr-section">
          <div class="print-page__qr-wrapper">
            <div class="print-page__qr" v-html="qr"></div>
          </div>
        </div>
        
        <div class="print-page__info">
          <h2 class="print-page__subtitle">Получите персональную скидку!</h2>
          <p class="print-page__description">
            Отсканируйте QR-код камерой вашего смартфона
            <br>для активации скидки
          </p>
        </div>
        
        <div class="print-page__footer">
          <div class="print-page__footer-line"></div>
          <p class="print-page__footer-text">ketroy-shop.kz</p>
        </div>
      </div>
    </div>

  </div>
</template>

<script lang="ts" setup>
import html2pdf from 'html2pdf.js';
import { useConfirm } from '~/composables/useConfirm';

const { alert } = useConfirm();
const qr = ref<string>();
const qrWrapper = ref<HTMLElement>();
const printContainer = ref<HTMLElement>();
const isDownloading = ref(false);

const get = async () => {
  try {
    const response = await api.qr.get();
    qr.value = response;
  } catch (error) {
    console.log(error);
  }
};

const downloadQR = async () => {
  if (isDownloading.value || !qr.value) return;
  
  isDownloading.value = true;
  
  try {
    // A4: 210mm x 297mm
    // При масштабе 2 для html2canvas: 595 x 842 px (72 DPI базовый)
    const A4_WIDTH = 595;
    const A4_HEIGHT = 842;
    
    // Создаём временный контейнер
    const container = document.createElement('div');
    container.style.cssText = 'position: fixed; left: 0; top: 0; z-index: 99999; background: white;';
    
    container.innerHTML = `
      <div id="pdf-content" style="
        width: ${A4_WIDTH}px;
        height: ${A4_HEIGHT}px;
        padding: 80px 60px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: space-between;
        background: #fafbf7;
        font-family: Gilroy, Segoe UI, system-ui, sans-serif;
        box-sizing: border-box;
        overflow: hidden;
      ">
        <div style="display: flex; flex-direction: column; align-items: center; gap: 12px;">
          <img src="/nav_logo_dark.svg" alt="Ketroy" style="width: 60px; height: 60px; object-fit: contain;" />
          <h1 style="font-size: 28px; font-weight: 700; color: #34460C; letter-spacing: 8px; text-transform: uppercase; margin: 0;">KETROY</h1>
        </div>
        
        <div style="display: flex; align-items: center; justify-content: center;">
          <div style="
            padding: 20px;
            background: #FFFFFF;
            border-radius: 20px;
            box-shadow: 0 6px 24px rgba(52, 70, 12, 0.12);
          ">
            <div style="width: 180px; height: 180px;">${qr.value}</div>
          </div>
        </div>
        
        <div style="text-align: center;">
          <h2 style="font-size: 20px; font-weight: 600; color: #34460C; margin: 0 0 12px 0;">Получите персональную скидку!</h2>
          <p style="font-size: 14px; font-weight: 400; color: #5a6b3a; line-height: 1.6; margin: 0;">
            Отсканируйте QR-код камерой смартфона<br>для активации скидки
          </p>
        </div>
        
        <div style="text-align: center;">
          <div style="width: 60px; height: 2px; background: linear-gradient(90deg, #98B35D 0%, #34460C 100%); border-radius: 2px; margin: 0 auto 12px;"></div>
          <p style="font-size: 12px; color: #98B35D; font-weight: 500; letter-spacing: 2px; margin: 0;">ketroy-shop.kz</p>
        </div>
      </div>
    `;
    
    document.body.appendChild(container);
    
    // Ждём загрузки изображений
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Находим SVG в QR-коде и устанавливаем размеры
    const qrSvg = container.querySelector('#pdf-content svg');
    if (qrSvg) {
      qrSvg.setAttribute('width', '180');
      qrSvg.setAttribute('height', '180');
      qrSvg.style.width = '180px';
      qrSvg.style.height = '180px';
      qrSvg.style.display = 'block';
    }
    
    const element = container.querySelector('#pdf-content');
    
    const opt = {
      margin: 0,
      filename: 'ketroy-qr-code.pdf',
      image: { type: 'jpeg', quality: 1 },
      html2canvas: { 
        scale: 2,
        useCORS: true,
        logging: false,
        backgroundColor: '#fafbf7',
        width: A4_WIDTH,
        height: A4_HEIGHT
      },
      jsPDF: { 
        unit: 'pt', 
        format: [A4_WIDTH, A4_HEIGHT], 
        orientation: 'portrait'
      },
      pagebreak: { mode: 'avoid-all' }
    };
    
    await html2pdf().set(opt).from(element).save();
    
    // Удаляем временный контейнер
    document.body.removeChild(container);
  } catch (error) {
    console.error('Ошибка при создании PDF:', error);
    alert({
      title: 'Ошибка',
      message: 'Не удалось создать PDF. Попробуйте ещё раз.',
      type: 'warning',
    });
  } finally {
    isDownloading.value = false;
  }
};

const printQR = () => {
  if (!printContainer.value) return;
  
  const printContent = printContainer.value.innerHTML;
  const printWindow = window.open('', '_blank', 'width=800,height=600');
  
  if (!printWindow) {
    alert({
      title: 'Всплывающие окна заблокированы',
      message: 'Пожалуйста, разрешите всплывающие окна для печати',
      type: 'warning',
    });
    return;
  }
  
  // Получаем базовый URL для загрузки шрифтов
  const baseUrl = window.location.origin;
  
  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Ketroy QR-код</title>
      <style>
        @font-face {
          font-family: 'Gilroy';
          src: url('${baseUrl}/fonts/Gilroy-Regular.ttf') format('truetype');
          font-weight: 400;
          font-style: normal;
        }
        
        @font-face {
          font-family: 'Gilroy';
          src: url('${baseUrl}/fonts/Gilroy-Medium.ttf') format('truetype');
          font-weight: 500;
          font-style: normal;
        }
        
        @font-face {
          font-family: 'Gilroy';
          src: url('${baseUrl}/fonts/Gilroy-Semibold.ttf') format('truetype');
          font-weight: 600;
          font-style: normal;
        }
        
        @font-face {
          font-family: 'Gilroy';
          src: url('${baseUrl}/fonts/Gilroy-Bold.ttf') format('truetype');
          font-weight: 700;
          font-style: normal;
        }
        
        @page {
          size: A4;
          margin: 0;
        }
        
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        html, body {
          width: 100%;
          height: 100%;
          font-family: 'Gilroy', 'Segoe UI', system-ui, -apple-system, sans-serif;
        }
        
        .print-page {
          width: 210mm;
          height: 297mm;
          padding: 40mm 30mm;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: space-between;
          background: linear-gradient(180deg, #fafbf7 0%, #f5f7f0 100%);
        }
        
        .print-page__header {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 16px;
        }
        
        .print-page__logo {
          width: 80px;
          height: 80px;
          object-fit: contain;
        }
        
        .print-page__title {
          font-family: 'Gilroy', sans-serif;
          font-size: 36px;
          font-weight: 700;
          color: #34460C;
          letter-spacing: 10px;
          text-transform: uppercase;
        }
        
        .print-page__qr-section {
          flex: 1;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20mm 0;
        }
        
        .print-page__qr-wrapper {
          padding: 28px;
          background: #FFFFFF;
          border-radius: 24px;
          box-shadow: 0 8px 32px rgba(52, 70, 12, 0.12);
          border: 3px solid #FFFFFF;
          outline: 2px solid rgba(152, 179, 93, 0.3);
        }
        
        .print-page__qr svg {
          width: 200px;
          height: 200px;
          display: block;
        }
        
        .print-page__info {
          text-align: center;
        }
        
        .print-page__subtitle {
          font-family: 'Gilroy', sans-serif;
          font-size: 26px;
          font-weight: 600;
          color: #34460C;
          margin-bottom: 16px;
        }
        
        .print-page__description {
          font-family: 'Gilroy', sans-serif;
          font-size: 16px;
          font-weight: 400;
          color: #5a6b3a;
          line-height: 1.7;
        }
        
        .print-page__footer {
          width: 100%;
          text-align: center;
        }
        
        .print-page__footer-line {
          width: 80px;
          height: 3px;
          background: linear-gradient(90deg, #98B35D 0%, #34460C 100%);
          border-radius: 2px;
          margin: 0 auto 16px;
        }
        
        .print-page__footer-text {
          font-family: 'Gilroy', sans-serif;
          font-size: 14px;
          color: #98B35D;
          font-weight: 500;
          letter-spacing: 3px;
        }
        
        @media print {
          body {
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
          }
        }
      </style>
    </head>
    <body>
      ${printContent}
    </body>
    </html>
  `);
  
  printWindow.document.close();
  
  printWindow.onload = () => {
    printWindow.focus();
    printWindow.print();
  };
};

onMounted(async () => {
  await get();

  const interval = setInterval(() => {
    get();
  }, 60000);

  onUnmounted(() => {
    clearInterval(interval);
  });
});
</script>

<style scoped>
.qr-page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.qr-page__actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

.qr-page__action-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.625rem 1rem;
  border: 2px solid var(--color-border);
  border-radius: 12px;
  background-color: var(--color-bg-secondary);
  color: var(--color-text-secondary);
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.qr-page__action-btn:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px var(--color-shadow);
}

.qr-page__action-btn--primary {
  background-color: var(--color-accent);
  border-color: var(--color-accent);
  color: var(--color-text-inverse);
}

.qr-page__action-btn--primary:hover {
  background-color: var(--color-accent-secondary);
  border-color: var(--color-accent-secondary);
  color: var(--color-text-inverse);
}

.qr-page__action-icon {
  font-size: 1.25rem;
}

.qr-page__action-text {
  display: none;
}

@media (min-width: 480px) {
  .qr-page__action-text {
    display: inline;
  }
}

.qr-page__card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  padding: 2rem;
  border-radius: 1.5rem;
  background-color: var(--color-bg-secondary);
  box-shadow: 0 4px 20px var(--color-shadow);
}

@media (min-width: 600px) {
  .qr-page__card {
    padding: 3rem;
    gap: 2rem;
  }
}

@media (min-width: 960px) {
  .qr-page__card {
    padding: 4rem;
  }
}

.qr-page__qr-wrapper {
  padding: 1.5rem;
  background: #FFFFFF;
  border-radius: 20px;
  box-shadow: 
    0 0 0 4px #FFFFFF,
    0 0 0 6px var(--color-accent-light),
    0 8px 32px rgba(52, 70, 12, 0.15);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.qr-page__qr-wrapper:hover {
  transform: scale(1.02);
  box-shadow: 
    0 0 0 4px #FFFFFF,
    0 0 0 6px var(--color-accent),
    0 12px 40px rgba(52, 70, 12, 0.2);
}

@media (min-width: 600px) {
  .qr-page__qr-wrapper {
    padding: 2rem;
    border-radius: 24px;
  }
}

.qr-page__content {
  display: flex;
  justify-content: center;
  align-items: center;
}

.qr-page__content :deep(svg) {
  width: 200px;
  height: 200px;
  display: block;
}

@media (min-width: 600px) {
  .qr-page__content :deep(svg) {
    width: 280px;
    height: 280px;
  }
}

@media (min-width: 960px) {
  .qr-page__content :deep(svg) {
    width: 320px;
    height: 320px;
  }
}

.qr-page__hint {
  font-size: 0.9375rem;
  color: var(--color-text-secondary);
  text-align: center;
  font-weight: 500;
}

@media (min-width: 600px) {
  .qr-page__hint {
    font-size: 1rem;
  }
}

/* Скрытый контейнер для печати */
.qr-page__print-container {
  position: absolute;
  left: -9999px;
  top: -9999px;
  visibility: hidden;
}

/* Стили для предпросмотра (не используются напрямую) */
.print-page {
  width: 210mm;
  height: 297mm;
  padding: 40mm 30mm;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(180deg, #fafbf7 0%, #f5f7f0 100%);
}

.print-page__header {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.print-page__logo {
  width: 80px;
  height: 80px;
  object-fit: contain;
}

.print-page__title {
  font-size: 32px;
  font-weight: 700;
  color: #34460C;
  letter-spacing: 8px;
  text-transform: uppercase;
}

.print-page__qr-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.print-page__qr-wrapper {
  padding: 24px;
  background: #FFFFFF;
  border-radius: 24px;
  box-shadow: 0 8px 32px rgba(52, 70, 12, 0.12);
  border: 3px solid #FFFFFF;
  outline: 2px solid rgba(152, 179, 93, 0.3);
}

.print-page__qr :deep(svg) {
  width: 200px;
  height: 200px;
  display: block;
}

.print-page__info {
  text-align: center;
}

.print-page__subtitle {
  font-size: 24px;
  font-weight: 600;
  color: #34460C;
  margin-bottom: 16px;
}

.print-page__description {
  font-size: 16px;
  color: #5a6b3a;
  line-height: 1.6;
}

.print-page__footer {
  width: 100%;
  text-align: center;
}

.print-page__footer-line {
  width: 80px;
  height: 3px;
  background: linear-gradient(90deg, #98B35D 0%, #34460C 100%);
  border-radius: 2px;
  margin: 0 auto 16px;
}

.print-page__footer-text {
  font-size: 14px;
  color: #98B35D;
  font-weight: 500;
  letter-spacing: 2px;
}

</style>
