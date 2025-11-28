import { i18n } from '~/configs';
import { jwtDecode } from 'jwt-decode';
import { Toast, ToastOptions } from './toast';
import { ApiClass } from '~/api/api';
import type { JwtPayload } from 'jwt-decode';

export const api = new ApiClass();
export const t = i18n.t;

export const decodeJwt = (token?: string | null) => {
  if (token) return jwtDecode<JwtPayload>(token);
  else return null;
};

export const isValidToken = (token: string) => {
  const decoded = decodeJwt(token);
  return !!decoded && (new Date(Number(decoded.exp) * 1000).getTime() - Date.now()) / 1000 > 0;
};

export const showToaster = (type: 'success' | 'error' | 'warning' | 'info' | 'default', msg: string) =>
  Toast.useToast()(msg, {
    ...ToastOptions,
    // @ts-ignore
    type: type,
    timeout: ToastOptions.timeout,
  });

// Статические стили (не реактивные - избегаем проблем с DevTools)
export const styles = {
  primary: '#34460C',
  primaryLight: '#EBF3DA',
  primaryDark: '#34460C2e',

  typo: '#34460C',
  typoLight: '#98B35D',
  typoDark: '#1D1F2C',
  typoSmoke: '#A3AED0',

  grey: '#e2e8f0',
  greyLight: '#F9F9FC',
  greySemiDark: '#667085',
  greyDark: '#858D9D',

  danger: '#ef4444',
};

// Если нужна реактивность на тему, используй эту функцию внутри компонента
export const useStyles = () => {
  const mode = useColorMode();
  return computed(() => ({
    ...styles,
    // Добавь динамические стили здесь если нужно
    // primary: mode.value === 'light' ? '#34460C' : '#EBF3DA',
  }));
};

export const rules = {
  requiredText: (v: any) => !!v || t('rules.requiredText'),
  requiredNumber: (v: any) => typeof v === 'number' || t('rules.requiredText'),
  requiredFile: (v: any[]) => (!!v && Array.isArray(v) && !!v.length) || t('rules.requiredFile'),
  age: (v: any) => (Number(v) > 0 && Number(v) < 100) || t('rules.age'),
  email: (v: any) => /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(String(v)) || t('rules.email'),
  url: (v: any) => /^https:\/\/[^\s/$.?#].[^\s]*$/.test(String(v)) || 'Введите корректную ссылку',
  youtube: (v: any) => /^(https:\/\/(www\.)?youtube\.com\/watch\?v=|https:\/\/youtu\.be\/)[\w-]+$/.test(String(v)) || 'Некорректная ссылка YouTube',
  maxLength255: (v: any) => !v || String(v).length <= 255 || t('rules.maxLength255'),
  minLength8: (v: any) => !v || String(v).length >= 8 || t('rules.minLength8'),
};

export const masks = {
  otp: '#####',
  numbers: '#*',
  date: '##.##.####',
  phone: '+7 (7##) ### ## ##',
};

export const formatPhone = (phone: string, to: 'back' | 'front') => {
  if (!!phone) {
    if (to === 'back') return phone.replace(/(\(|\)|\+| )/g, '');
    if (to === 'front' && phone.includes('(') === false) return `+7 (${phone.slice(1, 4)}) ${phone.slice(4, 7)} ${phone.slice(7, 9)} ${phone.slice(9)}`;
  }
  return phone;
};

export const fileUrlValidator = (url: string | null | undefined): string => {
  if (!url) return '';
  if (url.includes('path')) url = JSON.parse(url).path;
  if (url) {
    if (url.startsWith('http://')) url = url.replace('http://', 'https://');
    if (url.startsWith('http') === false && url.startsWith('/')) url = String(import.meta.env.VITE_API_URL).replace('/api', '') + url;
  }
  return url;
};

export const imagePreview = (image: File[]) => {
  if (image && image.length) return (window.URL ? URL : webkitURL).createObjectURL(image[0]);
};
