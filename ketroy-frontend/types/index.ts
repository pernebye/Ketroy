import type { RouteLocationRaw } from 'vue-router';

export {};
declare global {
  export namespace Types {
    export namespace Nav {
      export type AdmItem = {
        title: () => string;
        icon: string;
        route: string;
      };
      export type Item = {
        title: () => string;
        hash: string;
      };
    }
    export namespace Text {
      export type Block = {
        title: () => string;
        text: () => string;
      };
    }
    export type Tab = {
      title: () => string;
      value: string;
    };
    export type List = {
      file_path: string | undefined;
      id: number;
      title: string;
      description?: string;
      image?: Api.Image.Self;
      name: string;
    }[];
    type InternalBreadcrumbItem = Partial<{
      href: string | undefined;
      replace: boolean | undefined;
      to: RouteLocationRaw | undefined;
      exact: boolean | undefined;
    }> & {
      title: string;
      disabled?: boolean;
    };
    export type Crumb = string | InternalBreadcrumbItem;
    export type VFormValidation = { valid: boolean; errors: { id: string; errorMessages: string[] }[] };
    export type TableHeader<T extends object> = { title: string; key?: NestedKeyOf<T>; value?: string };
    export type NestedKeyOf<ObjectType extends object> = {
      [Key in keyof ObjectType & (string | number)]: ObjectType[Key] extends object ? `${Key}` | `${Key}.${NestedKeyOf<ObjectType[Key]>}` : Key;
    }[keyof ObjectType & (string | number)];
    export type FinalNestedKeyOf<ObjectType extends object> = {
      [Key in keyof ObjectType & (string | number)]: ObjectType[Key] extends object ? `${Key}.${NestedKeyOf<ObjectType[Key]>}` : Key;
    }[keyof ObjectType & (string | number)];
  }
  export namespace Api {
    export type AxiosResponse<T> = {
      data: T;
      message?: string;
      links?: { first: string | null; last: string | null; next: string | null; prev: string | null };
      meta?: {
        current_page: number;
        from: number;
        last_page: number;
        links: [
          {
            url: string | null;
            label: string | number;
            active: boolean;
          },
          {
            url: string;
            label: string | number;
            active: boolean;
          },
          {
            url: string;
            label: string | number;
            active: boolean;
          },
        ];
        path: string;
        per_page: number;
        to: number;
        total: number;
      };
    };
    export type Dict = {
      id: number;
      name: string;
    };
    export type City = Api.Dict;
    export type Actuals = {
      id: number;
      name: string;
      image?: string | null;
      is_welcome?: boolean;
      is_system?: boolean;
      sort_order?: number;
    };
    export type Category = Api.Dict;
    export type Hospitalities = Api.Dict;
    export type Banners = Api.Dict;
    export type Histories = Api.Dict;
    export namespace Entertainment {
      export type Self = {
        id: number;
        type: string;
        title: string;
        address: string;
        description: string;
        city_id: number;
        image: Api.Image.Self;
      };

      export type New = {
        name: string;
        description: string;
        image: File;
        city_id: number;
      };
    }

    export namespace Music {
      export type Self = {
        id: number;
        title: string;
        genre: string;
        path: string;
        image: Api.Image.Self;
      };

      export type New = {
        title: string;
        genre: string;
        image: File;
        file: File;
      };

      export type Genre = Api.Dict;
    }

    export namespace Offers {
      export type Self = {
        id: number;
        text: string;
      };

      export type New = {
        id: number;
        text: string;
      };
    }

    export namespace Category {
      export type Self = {
        id: number;
        text: string;
      };

      export type New = {
        id: number;
        text: string;
      };
    }

    export namespace Prizes {
      export type Self = {
        id: number;
        title: string;
        description: string;
        point_amount: number;
        image: Api.Image.Self;
      };
      export type New = {
        title: string;
        description: string;
        image: string;
        point_amount: number;
      };
    }

    export namespace Advertisings {
      export type Self = {
        id: number;
        title: string;
        placement_area: string;
        play_time: number;
        description: string;
        video_path: string;
      };

      export type New = {
        title: string;
        placement_area: string;
        play_time: string;
        description: string;
        video: File;
        video_link: string;
      };
    }

    export namespace Partners {
      export type Self = {
        id: number;
        title: string;
        description: string;
        image: Api.Image.Self;
      };

      export type New = {
        title: string;
        description: string;
        image: File;
      };
    }



    export namespace Hospitality {
      export type Self = {
        id: number;
        title: string;
        type: string;
        address: string;
        description: string;
        city: Api.City;
        image: Api.Image.Self;
      };

      export type New = {
        title: string;
        type: string;
        address: string;
        description: string;
        city_id: number;
        image: File;
      };
    }

    export namespace Banners {
      export type Self = {
        id: number;
        title: string;
        description: string;
        image: Api.Image.Self;
        city: Api.City;

      };

      export type New = {
        title: string;
        description: string;
        image: File;
      };
    }

    export namespace Histories {
      export type Self = {
        id: number;
        title: string;
        description: string;
        image: Api.Image.Self;
      };

      export type New = {
        title: string;
        description: string;
        image: File;
      };
    }

    export namespace News {
      export type Self = {
        id: number;
        title: string;
        description: string;
        image: Api.Image.Self;
      };

      export type New = {
        title: string;
        description: string;
        image: File;
      };
    }

    export namespace Shops {
      export type Self = {
        id: number;
        title: string;
        description: string;
        image: Api.Image.Self;
      };

      export type New = {
        title: string;
        description: string;
        image: File;
      };
    }

    export namespace Discounts {
      export type Self = {
        id: number;
        title: string;
        description: string;
        image: Api.Image.Self;
      };

      export type New = {
        title: string;
        description: string;
        image: File;
        start_date: string;
        end_date: string;
      };
    }

    // Каталог подарков
    export namespace GiftCatalog {
      export type Self = {
        id: number;
        name: string;
        image: string | null;
        image_url: string | null;
        description: string | null;
        is_active: boolean;
        created_at: string;
        updated_at: string;
      };

      export type New = {
        name: string;
        image: string; // Base64
        description?: string;
        is_active?: boolean;
      };

      export type PaginatedResponse = {
        data: Self[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
      };
    }

    // Выдача подарков
    export namespace GiftIssuance {
      export type Status = 'pending' | 'selected' | 'activated' | 'issued';
      
      export type Self = {
        id: number;
        user_id: number;
        name: string;
        image: string | null;
        status: Status;
        gift_group_id: string | null;
        gift_catalog_id: number | null;
        is_viewed: boolean;
        is_activated: boolean;
        selected_at: string | null;
        issued_at: string | null;
        created_at: string;
        updated_at: string;
        user?: {
          id: number;
          name: string;
          surname: string;
          phone: string;
          city: string;
        };
        gift_catalog?: GiftCatalog.Self;
      };

      export type Stats = {
        total: number;
        pending: number;
        selected: number;
        activated: number;
        issued: number;
      };
    }

    // Система геймификации / Уровни лояльности
    export namespace LoyaltyLevel {
      export type RewardType = 'discount' | 'bonus' | 'gift_choice';

      export type Reward = {
        id?: number;
        loyalty_level_id?: number;
        reward_type: RewardType;
        discount_percent?: number | null;
        bonus_amount?: number | null;
        description?: string | null;
        is_active: boolean;
        gift_options?: GiftCatalog.Self[];
        gift_ids?: number[];
      };

      export type Self = {
        id: number;
        name: string;
        icon: string | null;
        color: string | null;
        min_purchase_amount: number;
        order: number;
        is_active: boolean;
        rewards: Reward[];
        created_at: string;
        updated_at: string;
      };

      export type New = {
        name: string;
        icon?: string;
        color?: string;
        min_purchase_amount: number;
        order?: number;
        is_active?: boolean;
        rewards?: Reward[];
      };
    }

    export namespace Reviews {
      export type Self = {
        id: number;
        title: string;
        description: string;
      };

      export type New = {
        title: string;
        description: string;
      };
    }

    export namespace Bonuses {
      export type Self = {
        id: number;
        title: string;
        description: string;
        // image: string;
      };

      export type New = {
        title: string;
        description: string;
        // image: string;
      };
    }

    export namespace Image {
      export type Self = {
        id: number;
        path: string;
        imageable_type: string;
        imageable_id: number;
        width: number;
        height: number;
      };
    }

    export namespace Auth {
      export type Login = {
        phone_number: string;
      };

      export type Response = {
        token: string;
        user: Api.User.Self;
      };

      export type Register = {
        first_name: string;
        last_name: string;
        email: string;
        phone_number: string;
        interests: string;
        teams: string;
        age: number | null;
        city_id: number;
      };

      export type Verify = {
        phone_number: string;
        code: string;
      };
    }

    export namespace User {
      export type Self = {
        id: number;
        first_name: string;
        last_name: string | null;
        email: string | null;
        age: number;
        interests: string | null;
        teams: string | null;
        points: number;
        is_active: boolean | null;
        is_admin: boolean | null;
        is_taxi_driver: boolean | null;
        image: Api.Image.Self;
        city: Api.City;
        prizes: Api.Prizes.Self[];
        created_at: string;
        phone_number: string;
        // Поля из бэкенда Ketroy
        name?: string;
        surname?: string;
        phone?: string;
        birthdate?: string;
        avatar_image?: string | null;
        height?: string;
        clothing_size?: string;
        shoe_size?: string;
        bonus_amount?: number;
        discount?: number;
        referrer_id?: number;
        referrer?: string;
        gifts_count?: number;
        purchases_sum?: number;
        purchases_count?: number;
        referrals_count?: number;
        loyalty_level?: {
          name: string;
          icon: string;
          color: string;
        } | null;
        last_activity?: string;
      };

      export type New = {
        first_name: string;
        last_name: string;
        email: string;
        age: number;
        interest: string;
        teams: string;
        city_id: number;
        password: string;
        image: File;
      };

      export type Purchase = {
        purchaseDate: string;
        purchaseAmount: number;
      };

      export type PurchaseHistory = {
        purchases: Purchase[];
      };
    }

    export namespace Quiz {
      export type Self = {
        id: number | null;
        text: string;
        quiz_id: number;
        image?: Api.Image.Self;
        options: {
          id: number;
          text: string;
          is_correct: boolean;
          quiz_question_id: number;
        }[];
      };

      export type New = {
        text: string;
        options: {
          text: string;
          is_correct: boolean;
          image: File;
        }[];
      };
    }

    export namespace Difference {
      export type Self = {
        id: number;
        game_level: string;
        game_id: number;
        coordinates: { x: number; y: number }[];
        images: Api.Image.Self[];
      };

      export type New = {
        game_level: string;
        coordinates: { x: number; y: number }[];
        first_image: File;
        second_image: File;
      };
    }

    export namespace Leaderboard {
      export type Self = {
        id: number;
        first_name: string;
        last_name: string;
        points: number;
      };
    }

    export namespace Analytics {
      export type Types = 'all' | 'age' | 'restaurant' | 'hotel' | 'entertainment' | 'adverting_plays';
      export type Age = { '18-25': number; '26-34': number; '34-45': number; '45+': number };
      export type Clicks = { hotel: Record<string, number>; restaurant: Record<string, number>; entertainment: Record<string, number> };
      export type Response =
        | { category: 'age'; users_by_age_range: Api.Analytics.Age }
        | { category: 'restaurant' | 'hotel' | 'entertainment'; clicks_by_field: Api.Analytics.Clicks }
        | { category: 'adverting_plays'; adverting_plays: Record<string, number> }
        | { category: 'all'; users_by_age_range: Api.Analytics.Age; clicks_by_field: Api.Analytics.Clicks; adverting_plays: Record<string, number> };

      // Статистика кликов по социальным сетям
      export type SocialClickItem = {
        social_type?: string;
        source_page?: string;
        city?: string;
        shop_id?: string;
        shop_name?: string;
        news_id?: string;
        news_name?: string;
        clicks: number;
        date?: string;
      };

      export type SocialClickResponse = {
        success: boolean;
        data: {
          total_clicks: number;
          by_social_type: SocialClickItem[];
          by_source_page: SocialClickItem[];
          by_city: SocialClickItem[];
          detailed: SocialClickItem[];
          by_date: SocialClickItem[];
          top_shops: SocialClickItem[];
          top_news: SocialClickItem[];
        };
        period: {
          start_date: string;
          end_date: string;
        };
      };

      // Статистика реферальной программы "Подари скидку другу"
      export type ReferralReferrer = {
        referrer_id: number;
        referrer_name: string;
        referrer_phone: string | null;
        referred_count: number;
      };

      export type ReferralApplication = {
        id: number;
        applied_at: string;
        user: {
          id: number | null;
          name: string;
          phone: string | null;
        };
        referrer: {
          id: number | null;
          name: string;
          phone: string | null;
        };
      };

      export type ReferralPromotion = {
        id: number;
        name: string;
        is_active: boolean;
        referrer_bonus_percent: number;
        referrer_max_purchases: number;
        new_user_discount_percent: number;
        new_user_bonus_percent: number;
      };

      export type ReferralDateItem = {
        date: string;
        applications: number;
      };

      export type ReferralStatisticsResponse = {
        success: boolean;
        data: {
          total_applied: number;
          total_applied_all_time: number;
          unique_referrers: number;
          new_referred_users: number;
          referred_with_purchases: number;
          conversion_rate: number;
          purchase_stats: {
            total_purchases: number;
            total_amount: number;
          };
          gifts_to_referrers: number;
          by_date: ReferralDateItem[];
          top_referrers: ReferralReferrer[];
          recent_applications: ReferralApplication[];
          promotion: ReferralPromotion | null;
        };
        period: {
          start_date: string;
          end_date: string;
        };
      };
    }

    // Push-уведомления (кастомные)
    export namespace PushNotification {
      export type Status = 'draft' | 'scheduled' | 'sending' | 'sent' | 'failed' | 'cancelled';

      export type Self = {
        id: number;
        title: string;
        body: string;
        status: Status;
        scheduled_at: string | null;
        sent_at: string | null;
        target_cities: string[] | null;
        target_clothing_sizes: string[] | null;
        target_shoe_sizes: string[] | null;
        recipients_count: number;
        sent_count: number;
        failed_count: number;
        created_by: number | null;
        error_message: string | null;
        created_at: string;
        updated_at: string;
        creator?: {
          id: number;
          name: string;
          email: string;
        };
        potential_recipients?: number;
        targeting_summary?: string;
      };

      export type New = {
        title: string;
        body: string;
        scheduled_at?: string | null;
        target_cities?: string[] | null;
        target_clothing_sizes?: string[] | null;
        target_shoe_sizes?: string[] | null;
        send_immediately?: boolean;
      };

      export type PaginatedResponse = {
        data: Self[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
      };

      export type Stats = {
        total: number;
        draft: number;
        scheduled: number;
        sent: number;
        failed: number;
        cancelled: number;
        total_sent_count: number;
        total_recipients: number;
      };

      export type TargetingOptions = {
        cities: string[];
        clothing_sizes: string[];
        shoe_sizes: string[];
      };
    }
  }
}
