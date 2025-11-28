import axios from 'axios';
import interceptor from './interceptor';

const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
});
interceptor(axiosInstance);

export default axiosInstance;
