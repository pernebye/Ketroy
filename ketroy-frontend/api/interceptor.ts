import { AxiosError, type AxiosInstance } from 'axios';

export default function (axios: AxiosInstance) {
  axios.interceptors.request.use(
    (request) => {
      if (request.url && request.url.startsWith('/auth') === false) {
        const atoken = useStore().atoken ?? useCookie('atoken').value;
        if (atoken) request.headers.Authorization = `Bearer ${atoken}`;
      }
      return request;
    },
    (error: AxiosError) => {
      return Promise.reject(error);
    },
  );
  axios.interceptors.response.use(
    (response) => {
      return response;
    },
    (error: AxiosError) => {
      // @ts-ignore
      if (error.response && error.response.data && 'message' in error.response.data && typeof error.response.data.message === 'string') {
        const message = (() => {
          switch (error.response.data.message) {
            case 'Пользователь с таким номером телефона не найден':
              return t('error.notFoundUser');
            case 'Неверный код подтверждения':
              return t('error.notCorrectOtp');
            case 'Points traded successfully.':
              return t('text.auth.traded');
            case 'Пользователь с таким номером телефона уже существует':
              return t('error.userExists');
            default:
              return error.response.data.message;
          }
        })();
        showToaster('error', message);
      }
      if (error.response && error.response.status) {
        if (error.response.status === 401) {
          const store = useStore();
          const atoken = useCookie('atoken');
          atoken.value = undefined;
          store.atoken = undefined;
          store.auser = null;
          navigateTo({ name: 'auth' });
        }
      }
      return Promise.reject(error);
    },
  );
}
