import axios from './axios';
import type { AxiosRequestConfig } from 'axios';

export class ApiClass {
  private async axiosCall<T>(config: AxiosRequestConfig): Promise<Api.AxiosResponse<T>> {
    const { data } = await axios.request<Api.AxiosResponse<T>>(config);
    return data;
  }

  auth = {
    link: '/admin',
    login: async (data: Api.Auth.Login) => {
      return await this.axiosCall<Api.Auth.Response>({
        url: `${this.auth.link}/login`,
        method: 'POST',
        data: data,
      });
    },
    register: async (data: Api.Auth.Register) => {
      return await this.axiosCall<Api.Auth.Response>({
        url: `${this.auth.link}/register`,
        method: 'POST',
        data: data,
      });
    },
    verify: async (data: Api.Auth.Verify) => {
      return await this.axiosCall<Api.Auth.Response>({
        url: `${this.auth.link}/verify`,
        method: 'POST',
        data: data,
      });
    },
    logout: async (data: any) => {
      return await this.axiosCall<void>({
        url: `/admin/logout`,
        method: 'POST',
        data: data,
      });
    },
  };
  analytics = {
    link: '/analytics',
    get: async (category?: Api.Analytics.Types | 'clicks', click_type?: Api.Analytics.Types) => {
      return await this.axiosCall<Api.Analytics.Response>({
        url: `${this.analytics.link}`,
        params: { category, click_type },
      });
    },
    // Статистика событий по дням
    getEventStatistics: async (type: string, startDate: string, endDate: string) => {
      return await this.axiosCall<any[]>({
        url: '/admin/event-statistics',
        params: { type, start_date: startDate, end_date: endDate },
      });
    },
    // Детальная статистика по конкретным объектам (постам, сторис, баннерам)
    getDetailedEventStatistics: async (type: string, startDate: string, endDate: string) => {
      return await this.axiosCall<any[]>({
        url: '/admin/event-statistics-detailed',
        params: { type, start_date: startDate, end_date: endDate },
      });
    },
    // Статистика кликов по социальным сетям
    getSocialClickStatistics: async (startDate: string, endDate: string, socialType?: string, sourcePage?: string) => {
      return await this.axiosCall<Api.Analytics.SocialClickResponse>({
        url: '/admin/social-click-statistics',
        params: { 
          start_date: startDate, 
          end_date: endDate,
          ...(socialType && { social_type: socialType }),
          ...(sourcePage && { source_page: sourcePage }),
        },
      });
    },
    // Статистика реферальной программы "Подари скидку другу"
    getReferralStatistics: async (startDate: string, endDate: string) => {
      return await this.axiosCall<Api.Analytics.ReferralStatisticsResponse>({
        url: '/admin/referral-statistics',
        params: { 
          start_date: startDate, 
          end_date: endDate,
        },
      });
    },
  };
  cities = {
    link: '/cities',
    getAll: async () => {
      return await this.axiosCall<Api.City[]>({
        url: `${this.cities.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.City>({
        url: `${this.cities.link}/${id}`,
      });
    },
    add: async (data: Api.City) => {
      return await this.axiosCall<Api.City[]>({
        url: `/admin/cities`,
        method: 'POST',
        data: data,
      });
    },
  };
  categories = {
    link: '/categories',
    adminLink: '/admin/categories',
    getAll: async () => {
      // Для админки получаем ВСЕ категории
      return await this.axiosCall<Api.Category[]>({
        url: `${this.categories.adminLink}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Category>({
        url: `${this.categories.link}/${id}`,
      });
    },
    add: async (data: { id?: number; name: string }[]) => {
      return await this.axiosCall<{ message?: string }>({
        url: this.categories.adminLink,
        method: 'POST',
        data: data,
      });
    },
  };
  actuals = {
    link: '/actuals',
    adminLink: '/admin/actuals',
    getAll: async () => {
      return await this.axiosCall<Api.Actuals[]>({
        url: `${this.actuals.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Actuals>({
        url: `${this.actuals.link}/${id}`,
      });
    },
    add: async (data: { name: string; image?: string | null; is_welcome?: boolean }[]) => {
      return await this.axiosCall<Api.Actuals[]>({
        url: `${this.actuals.adminLink}`,
        method: 'POST',
        data: data,
      });
    },
    reorder: async (groups: { id: number; sort_order: number }[]) => {
      return await this.axiosCall<{ message: string; groups: Api.Actuals[] }>({
        url: `${this.actuals.adminLink}/reorder`,
        method: 'POST',
        data: { groups },
      });
    },
  };

  entertainments = {
    link: '/entertainments',
    getAll: async () => {
      return await this.axiosCall<Api.Entertainment.Self[]>({
        url: `${this.entertainments.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Entertainment.Self>({
        url: `${this.entertainments.link}/${id}`,
      });
    },
    add: async (data: Api.Entertainment.New) => {
      return await this.axiosCall<Api.Entertainment.Self>({
        url: `${this.entertainments.link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.entertainments.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Entertainment.New) => {
      return await this.axiosCall<Api.Entertainment.Self>({
        url: `${this.entertainments.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
    getTypes: async () => {
      return await this.axiosCall<Api.Dict[]>({
        url: `${this.entertainments.link}/types`,
      });
    },
  };
  musics = {
    link: '/musics',
    getAll: async () => {
      return await this.axiosCall<Api.Music.Self[]>({
        url: `${this.musics.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Music.Self>({
        url: `${this.musics.link}/${id}`,
      });
    },
    add: async (data: Api.Music.New) => {
      return await this.axiosCall<Api.Music.Self>({
        url: `${this.musics.link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.musics.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Music.New) => {
      return await this.axiosCall<Api.Music.Self>({
        url: `${this.musics.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
    getGenres: async () => {
      return await this.axiosCall<Api.Music.Genre[]>({
        url: `${this.musics.link}/genres`,
      });
    },
  };
  partners = {
    link: '/partners',
    getAll: async () => {
      return await this.axiosCall<Api.Partners.Self[]>({
        url: `${this.partners.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Partners.Self>({
        url: `${this.partners.link}/${id}`,
      });
    },
    add: async (data: Api.Partners.New) => {
      return await this.axiosCall<Api.Partners.Self>({
        url: `${this.partners.link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.partners.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Partners.New) => {
      return await this.axiosCall<Api.Partners.Self>({
        url: `${this.partners.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
  };
  'hospitality-venues' = {
    link: '/hospitality-venues',
    getAll: async () => {
      return await this.axiosCall<Api.Hospitality.Self[]>({
        url: `${this['hospitality-venues'].link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Hospitality.Self>({
        url: `${this['hospitality-venues'].link}/${id}`,
      });
    },
    add: async (data: Api.Hospitality.New) => {
      return await this.axiosCall<Api.Hospitality.Self>({
        url: `${this['hospitality-venues'].link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this['hospitality-venues'].link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Hospitality.New) => {
      return await this.axiosCall<Api.Hospitality.Self>({
        url: `${this['hospitality-venues'].link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
    getTypes: async () => {
      return await this.axiosCall<Api.Hospitalities[]>({
        url: `${this['hospitality-venues'].link}/types`,
      });
    },
  };
  offers = {
    link: '/offers',
    getAll: async () => {
      return await this.axiosCall<Api.Offers.Self[]>({
        url: `${this.offers.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Offers.Self>({
        url: `${this.offers.link}/${id}`,
      });
    },
    add: async (data: Api.Offers.New) => {
      return await this.axiosCall<Api.Offers.Self>({
        url: `${this.offers.link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.offers.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Offers.New) => {
      return await this.axiosCall<Api.Offers.Self>({
        url: `${this.offers.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
  };

  discounts = {
    link: '/admin/promotions',
    getAll: async () => {
      return await this.axiosCall<Api.Discounts.Self[]>({
        url: `${this.discounts.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Discounts.Self>({
        url: `${this.discounts.link}/${id}`,
      });
    },
    add: async (data: Api.Discounts.New) => {
      return await this.axiosCall<Api.Discounts.Self>({
        url: `${this.discounts.link}`,
        method: 'POST',
        data: data,
      });
    },
    update: async (id: number, data: Api.Discounts.New) => {
      return await this.axiosCall<Api.Discounts.Self>({
        url: `${this.discounts.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.discounts.link}/${id}`,
        method: 'DELETE',
      });
    },
    toggleActive: async (id: number, is_active: boolean) => {
      return await this.axiosCall<Api.Discounts.Self>({
        url: `${this.discounts.link}/${id}/toggle-active`,
        method: 'PATCH',
        data: { is_active },
      });
    },
    getArchived: async () => {
      return await this.axiosCall<Api.Discounts.Self[]>({
        url: `${this.discounts.link}/archived`,
      });
    },
    archive: async (id: number) => {
      return await this.axiosCall({
        url: `${this.discounts.link}/${id}/archive`,
        method: 'POST',
      });
    },
  };

  // Каталог подарков
  prizes = {
    link: '/admin/gift-catalog',
    getAll: async (params?: any) => {
      return await this.axiosCall<Api.GiftCatalog.PaginatedResponse>({
        url: `${this.prizes.link}/all`,
        params: params,
      });
    },
    getActive: async () => {
      return await this.axiosCall<Api.GiftCatalog.Self[]>({
        url: `${this.prizes.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.GiftCatalog.Self>({
        url: `${this.prizes.link}/${id}`,
      });
    },
    add: async (data: Api.GiftCatalog.New) => {
      return await this.axiosCall<{ message: string; gift: Api.GiftCatalog.Self }>({
        url: `${this.prizes.link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.prizes.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.GiftCatalog.New) => {
      return await this.axiosCall<{ message: string; gift: Api.GiftCatalog.Self }>({
        url: `${this.prizes.link}/${id}`,
        method: 'PUT',
        data: data,
      });
    },
  };

  // Система геймификации / Уровни лояльности
  gamification = {
    link: '/admin/loyalty-levels',
    publicLink: '/loyalty-levels',
    getAll: async () => {
      return await this.axiosCall<Api.LoyaltyLevel.Self[]>({
        url: `${this.gamification.link}`,
      });
    },
    // Публичный endpoint для страницы пользователя
    getPublicLevels: async () => {
      return await this.axiosCall<Api.LoyaltyLevel.Self[]>({
        url: `${this.gamification.publicLink}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.LoyaltyLevel.Self>({
        url: `${this.gamification.link}/${id}`,
      });
    },
    add: async (data: Api.LoyaltyLevel.New) => {
      return await this.axiosCall<{ message: string; level: Api.LoyaltyLevel.Self }>({
        url: `${this.gamification.link}`,
        method: 'POST',
        data: data,
      });
    },
    update: async (id: number, data: Api.LoyaltyLevel.New) => {
      return await this.axiosCall<{ message: string; level: Api.LoyaltyLevel.Self }>({
        url: `${this.gamification.link}/${id}`,
        method: 'PUT',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.gamification.link}/${id}`,
        method: 'DELETE',
      });
    },
    reorder: async (levels: { id: number; order: number }[]) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.gamification.link}/reorder`,
        method: 'POST',
        data: { levels },
      });
    },
    getGifts: async () => {
      return await this.axiosCall<Api.GiftCatalog.Self[]>({
        url: `${this.gamification.link}/gifts`,
      });
    },
  };
  advertisings = {
    link: '/advertisings',
    getAll: async () => {
      return await this.axiosCall<Api.Advertisings.Self[]>({
        url: `${this.advertisings.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Advertisings.Self>({
        url: `${this.advertisings.link}/${id}`,
      });
    },
    add: async (data: Api.Advertisings.New) => {
      return await this.axiosCall<Api.Advertisings.Self>({
        url: `${this.advertisings.link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.advertisings.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Advertisings.New) => {
      return await this.axiosCall<Api.Advertisings.Self>({
        url: `${this.advertisings.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
    getTypes: async () => {
      return await this.axiosCall<Api.Dict[]>({
        url: `${this.advertisings.link}/types`,
      });
    },
  };
  banners = {
    link: '/banners',
    adminLink: '/admin/banners',
    getAll: async () => {
      return await this.axiosCall<Api.Banners.Self[]>({
        url: this.banners.adminLink,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Banners.Self>({
        url: `${this.banners.link}/${id}`,
      });
    },
    add: async (data: Api.Banners.New) => {
      return await this.axiosCall<Api.Banners.Self>({
        url: this.banners.adminLink,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.banners.adminLink}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Banners.New) => {
      return await this.axiosCall<Api.Banners.Self>({
        url: `${this.banners.adminLink}/${id}`,
        method: 'PUT',
        data: data,
      });
    },
    quickUpdate: async (id: number, data: { name?: string; cities?: string[]; is_active?: boolean; start_date?: string | null; expired_at?: string | null; sort_order?: number; file_path?: string }) => {
      return await this.axiosCall<Api.Banners.Self>({
        url: `${this.banners.adminLink}/${id}`,
        method: 'PATCH',
        data: data,
      });
    },
    reorder: async (banners: { id: number; sort_order: number }[]) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.banners.adminLink}/reorder`,
        method: 'POST',
        data: { banners },
      });
    },
  };
  reviews = {
    link: '/reviews',
    adminLink: '/admin/reviews',
    getAll: async () => {
      return await this.axiosCall<Api.Reviews.Self[]>({
        url: `${this.reviews.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Reviews.Self>({
        url: `${this.reviews.link}/${id}`,
      });
    },
    add: async (data: Api.Reviews.New) => {
      return await this.axiosCall<Api.Reviews.Self>({
        url: `${this.reviews.link}`,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.reviews.adminLink}/${id}`,
        method: 'DELETE',
      });
    },
  };
  histories = {
    link: '/stories',
    adminLink: '/admin/stories',
    getAll: async () => {
      return await this.axiosCall<Api.Histories.Self[]>({
        url: this.histories.adminLink,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Histories.Self>({
        url: `${this.histories.link}/${id}`,
      });
    },
    add: async (data: { name?: string; cities?: string[]; actual_group?: string; type?: string; is_active?: number; file_path?: string }) => {
      return await this.axiosCall<Api.Histories.Self>({
        url: this.histories.adminLink,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.histories.adminLink}/${id}`,
        method: 'DELETE',
      });
    },
    deleteMany: async (ids: number[]) => {
      return await this.axiosCall({
        url: `${this.histories.adminLink}/bulk-delete`,
        method: 'POST',
        data: { ids },
      });
    },
    update: async (id: number, data: { name?: string; cities?: string[]; actual_group?: string; type?: string; is_active?: number; file?: string }) => {
      return await this.axiosCall<Api.Histories.Self>({
        url: `${this.histories.adminLink}/${id}`,
        method: 'PUT',
        data: data,
      });
    },
    reorder: async (stories: { id: number; sort_order: number }[]) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.histories.adminLink}/reorder`,
        method: 'POST',
        data: { stories },
      });
    },
  };
  news = {
    link: '/news',
    adminLink: '/admin/news',
    getAll: async () => {
      return await this.axiosCall<Api.News.Self[]>({
        url: this.news.adminLink,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.News.Self>({
        url: `${this.news.link}/${id}`,
      });
    },
    add: async (data: any) => {
      return await this.axiosCall<Api.News.Self>({
        url: this.news.adminLink,
        method: 'POST',
        data: JSON.stringify(data),
        headers: { 'Content-Type': 'application/json' },
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.news.adminLink}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.News.New) => {
      return await this.axiosCall<Api.News.Self>({
        url: `${this.news.adminLink}/${id}`,
        method: 'PUT',
        data: data,
      });
    },
    quickUpdate: async (id: number, data: { 
      is_active?: boolean; 
      send_notification?: boolean;
      target_cities?: string[];
      target_categories?: string[];
      target_shoe_size?: string | number | null;
      target_clothing_size?: string | number | null;
    }) => {
      return await this.axiosCall<Api.News.Self>({
        url: `${this.news.adminLink}/${id}`,
        method: 'PATCH',
        data: data,
      });
    },
    deleteMany: async (ids: number[]) => {
      return await Promise.all(ids.map(id => this.news.delete(id)));
    },
    reorder: async (news: { id: number; sort_order: number }[]) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.news.adminLink}/reorder`,
        method: 'POST',
        data: { news },
      });
    },
    // Архив
    getArchived: async () => {
      return await this.axiosCall<Api.News.Self[]>({
        url: `${this.news.adminLink}/archived`,
      });
    },
    archive: async (id: number) => {
      return await this.axiosCall<Api.News.Self>({
        url: `${this.news.adminLink}/${id}/archive`,
        method: 'POST',
      });
    },
    archiveMany: async (ids: number[]) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.news.adminLink}/archive-many`,
        method: 'POST',
        data: { ids },
      });
    },
    restore: async (id: number) => {
      return await this.axiosCall<Api.News.Self>({
        url: `${this.news.adminLink}/${id}/restore`,
        method: 'POST',
      });
    },
  };
  shops = {
    link: '/shop',
    adminLink: '/admin/shop',
    getAll: async () => {
      return await this.axiosCall<Api.Shops.Self[]>({
        url: `${this.shops.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Shops.Self>({
        url: `${this.shops.link}/${id}`,
      });
    },
    add: async (data: Api.Shops.New) => {
      return await this.axiosCall<Api.Shops.Self>({
        url: this.shops.adminLink,
        method: 'POST',
        data: data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.shops.adminLink}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Shops.New) => {
      return await this.axiosCall<Api.Shops.Self>({
        url: `${this.shops.adminLink}/${id}`,
        method: 'PUT',
        data: data,
      });
    },
  };
  users = {
    link: '/users',
    getAll: async (params:any) => {
      return await this.axiosCall<Api.User.Self[]>({
        url: `${this.users.link}`,
        params: params,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.User.Self>({
        url: `${this.users.link}/${id}`,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.users.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.User.New) => {
      return await this.axiosCall<Api.User.Self>({
        url: `${this.users.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
    trade: async (userId: number, data: { prize_id: number; city_id: number; address: string }) => {
      return await this.axiosCall<Api.User.Self>({ url: `${this.users.link}/${userId}/trade`, method: 'POST', data: data });
    },
    getPurchases: async (id: number) => {
      return await this.axiosCall<Api.User.PurchaseHistory>({
        url: `${this.users.link}/${id}/purchases`,
      });
    },
    // Управление пользователем
    updateDiscount: async (id: number, discount: number) => {
      return await this.axiosCall<{ message: string; discount: number }>({
        url: `${this.users.link}/${id}/discount`,
        method: 'POST',
        data: { discount },
      });
    },
    addBonuses: async (id: number, amount: number, comment?: string, withDelay: boolean = true) => {
      return await this.axiosCall<{ message: string; bonus_amount: number }>({
        url: `${this.users.link}/${id}/bonuses/add`,
        method: 'POST',
        data: { amount, comment, withDelay },
      });
    },
    deductBonuses: async (id: number, amount: number, comment?: string, withDelay: boolean = true) => {
      return await this.axiosCall<{ message: string; bonus_amount: number }>({
        url: `${this.users.link}/${id}/bonuses/deduct`,
        method: 'POST',
        data: { amount, comment, withDelay },
      });
    },
    sendGift: async (id: number, giftCatalogId: number) => {
      return await this.axiosCall<{ message: string; gift: any }>({
        url: `${this.users.link}/${id}/gift`,
        method: 'POST',
        data: { gift_catalog_ids: [giftCatalogId] },
      });
    },
    sendGifts: async (id: number, giftCatalogIds: number[]) => {
      return await this.axiosCall<{ message: string; gifts: any[]; gift_group_id: string }>({
        url: `${this.users.link}/${id}/gift`,
        method: 'POST',
        data: { gift_catalog_ids: giftCatalogIds },
      });
    },
    sendTestNotification: async (id: number) => {
      return await this.axiosCall<{ success: boolean; message: string }>({
        url: `${this.users.link}/${id}/test-notification`,
        method: 'POST',
      });
    },
  };
  admins = {
    link: '/admins',
    getAll: async (params:any) => {
      return await this.axiosCall<Api.User.Self[]>({
        url: `${this.admins.link}`,
        params: params,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.User.Self>({
        url: `${this.admins.link}/${id}`,
      });
    },
    add: async (data: any) => {
      return await this.axiosCall<any>({
        url: `${this.admins.link}/register`,
        method: 'POST',
        data: data,
      });
    },
    changeRole: async (data: any) => {
      return await this.axiosCall<any>({
        url: `${this.admins.link}/change-role`,
        method: 'POST',
        data: data,
      });
    },
  };

  winners = {
    link: '/users?has_prizes=true',
    getAll: async () => {
      return await this.axiosCall<Api.User.Self[]>({
        url: `${this.winners.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.User.Self>({
        url: `${this.users.link}/${id}`,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.users.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.User.New) => {
      return await this.axiosCall<Api.User.Self>({
        url: `${this.users.link}/${id}`,
        method: 'POST',
        data: data,
      });
    },
  };
  quiz = {
    link: '/quiz-questions',
    getAll: async () => {
      return await this.axiosCall<Api.Quiz.Self[]>({
        url: `${this.quiz.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Quiz.Self>({
        url: `${this.quiz.link}/${id}`,
      });
    },
    add: async (data: Api.Quiz.New) => {
      return await this.axiosCall<Api.Quiz.Self>({
        url: `${this.quiz.link}`,
        method: 'POST',
        data: data,
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.quiz.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Quiz.New) => {
      return await this.axiosCall<Api.Quiz.Self>({
        url: `${this.quiz.link}/${id}`,
        method: 'POST',
        data: data,
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
  };
  differences = {
    link: '/differences',
    getAll: async () => {
      return await this.axiosCall<Api.Difference.Self[]>({
        url: `${this.differences.link}`,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.Difference.Self>({
        url: `${this.differences.link}/${id}`,
      });
    },
    add: async (data: Api.Difference.New) => {
      return await this.axiosCall<Api.Difference.Self>({
        url: `${this.differences.link}`,
        method: 'POST',
        data: data,
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall({
        url: `${this.differences.link}/${id}`,
        method: 'DELETE',
      });
    },
    update: async (id: number, data: Api.Difference.New) => {
      return await this.axiosCall<Api.Difference.Self>({
        url: `${this.differences.link}/${id}`,
        method: 'POST',
        data: data,
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
  };
  leaderboard = {
    link: '/leaderboard',
    get: async () => {
      return await this.axiosCall<Api.Leaderboard.Self[]>({ url: this.leaderboard.link });
    },
  };
  qr = {
    link: '/static-discount-qrcode',
    get: async () => {
      return await this.axiosCall({ url: this.qr.link });
    },
  };

  // Универсальная загрузка файлов
  upload = {
    link: '/admin/upload',
    post: async (formData: FormData) => {
      return await this.axiosCall<string[]>({
        url: '/admin/upload',
        method: 'POST',
        data: formData,
        // axios автоматически добавит Content-Type с boundary для FormData
      });
    },
  };

  // Конвертация видео в GIF
  videoToGif = {
    link: '/admin/video-to-gif',
    convert: async (file: File) => {
      const formData = new FormData();
      formData.append('video', file);
      // НЕ устанавливаем Content-Type вручную - axios сам добавит boundary для FormData
      return await this.axiosCall<{
        success: boolean;
        url: string;
        duration: number;
        original_size: string;
        gif_size: string;
        file_size: number;
      }>({
        url: this.videoToGif.link,
        method: 'POST',
        data: formData,
      });
    },
    convertBase64: async (base64: string) => {
      return await this.axiosCall<{
        success: boolean;
        url: string;
        duration: number;
        original_size: string;
        gif_size: string;
        file_size: number;
      }>({
        url: `${this.videoToGif.link}/base64`,
        method: 'POST',
        data: { video: base64 },
      });
    },
    info: async () => {
      return await this.axiosCall<{
        max_duration: number;
        supported_formats: string[];
        max_file_size_mb: number;
      }>({
        url: `${this.videoToGif.link}/info`,
      });
    },
  };

  // API для управления подарками (выдача)
  giftIssuance = {
    link: '/admin/gifts',
    getAll: async (params?: { status?: string; search?: string; per_page?: number; page?: number }) => {
      return await this.axiosCall<{
        data: Api.GiftIssuance.Self[];
        total: number;
        current_page: number;
        last_page: number;
      }>({
        url: this.giftIssuance.link,
        params,
      });
    },
    getStats: async () => {
      return await this.axiosCall<Api.GiftIssuance.Stats>({
        url: `${this.giftIssuance.link}/stats`,
      });
    },
    issue: async (id: number) => {
      return await this.axiosCall<{ message: string; gift: any }>({
        url: `${this.giftIssuance.link}/${id}/issue`,
        method: 'POST',
      });
    },
    updateStatus: async (id: number, data: { status: string; auto_select_gift?: boolean }) => {
      return await this.axiosCall<{ message: string; data: Api.GiftIssuance.Self }>({
        url: `${this.giftIssuance.link}/${id}/status`,
        method: 'PUT',
        data,
      });
    },
    sendNotification: async (id: number, data: { title: string; message: string }) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.giftIssuance.link}/${id}/notify`,
        method: 'POST',
        data,
      });
    },
  };

  // Push-уведомления (кастомные)
  pushNotifications = {
    link: '/admin/push-notifications',
    getAll: async (params?: { 
      per_page?: number; 
      page?: number; 
      status?: string; 
      search?: string;
    }) => {
      return await this.axiosCall<Api.PushNotification.PaginatedResponse>({
        url: this.pushNotifications.link,
        params,
      });
    },
    get: async (id: number) => {
      return await this.axiosCall<Api.PushNotification.Self>({
        url: `${this.pushNotifications.link}/${id}`,
      });
    },
    create: async (data: Api.PushNotification.New) => {
      return await this.axiosCall<{ message: string; notification: Api.PushNotification.Self }>({
        url: this.pushNotifications.link,
        method: 'POST',
        data,
      });
    },
    update: async (id: number, data: Api.PushNotification.New) => {
      return await this.axiosCall<{ message: string; notification: Api.PushNotification.Self }>({
        url: `${this.pushNotifications.link}/${id}`,
        method: 'PUT',
        data,
      });
    },
    delete: async (id: number) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.pushNotifications.link}/${id}`,
        method: 'DELETE',
      });
    },
    sendNow: async (id: number) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.pushNotifications.link}/${id}/send`,
        method: 'POST',
      });
    },
    cancel: async (id: number) => {
      return await this.axiosCall<{ message: string }>({
        url: `${this.pushNotifications.link}/${id}/cancel`,
        method: 'POST',
      });
    },
    duplicate: async (id: number) => {
      return await this.axiosCall<{ message: string; notification: Api.PushNotification.Self }>({
        url: `${this.pushNotifications.link}/${id}/duplicate`,
        method: 'POST',
      });
    },
    getStats: async () => {
      return await this.axiosCall<Api.PushNotification.Stats>({
        url: `${this.pushNotifications.link}/stats`,
      });
    },
    getTargetingOptions: async () => {
      return await this.axiosCall<Api.PushNotification.TargetingOptions>({
        url: `${this.pushNotifications.link}/targeting-options`,
      });
    },
    previewRecipients: async (data: {
      target_cities?: string[];
      target_clothing_sizes?: string[];
      target_shoe_sizes?: string[];
    }) => {
      return await this.axiosCall<{ recipients_count: number }>({
        url: `${this.pushNotifications.link}/preview-recipients`,
        method: 'POST',
        data,
      });
    },
  };
}
