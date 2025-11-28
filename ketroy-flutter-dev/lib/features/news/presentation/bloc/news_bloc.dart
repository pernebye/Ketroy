import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/news/domain/entities/actuals_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/banners_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/categories_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/news_entity.dart';
import 'package:ketroy_app/features/news/domain/entities/news_list_entity.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_actuals.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_banners_list.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_categories.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_news_list.dart';
import 'package:ketroy_app/features/news/domain/usecases/get_news_list_by_id.dart';
import 'package:ketroy_app/features/news/domain/usecases/post_device_token.dart';
import 'package:ketroy_app/init_dependencies.dart';
import 'package:ketroy_app/services/local_storage/user_data_manager.dart';
import 'package:ketroy_app/services/notification_services.dart';
import 'package:ketroy_app/services/shared_preferences_service.dart';

part 'news_events.dart';
part 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final GetBannersList _getBannersList;
  final GetNewsList _getNewsList;
  final GetNewsListById _getNewsListById;
  final GetCategories _getCategories;
  final GetActuals _getActuals;
  final PostDeviceToken _postDeviceToken;
  final sharedService = serviceLocator<SharedPreferencesService>();
  NewsBloc(
      {required GetBannersList getBannersList,
      required GetNewsList getNewsList,
      required GetCategories getCategories,
      required GetActuals getActuals,
      required PostDeviceToken postDeviceToken,
      required GetNewsListById getNewsListById})
      : _getBannersList = getBannersList,
        _getNewsList = getNewsList,
        _getCategories = getCategories,
        _getActuals = getActuals,
        _postDeviceToken = postDeviceToken,
        _getNewsListById = getNewsListById,
        super(const NewsState()) {
    // on<NewsEvent>(
    //     (_, emit) => emit(state.copyWith(status: NewsStatus.loading)));
    on<GetBannersListFetch>(_onFetchGetBannerList);
    on<GetNewsListFetch>(_getNewsListFetch);
    on<GetCategoriesListFetch>(_getCategoriesListFetch);
    on<GetActualsFetch>(_getActualsFetch);
    on<PostDeviceTokenFetch>(_postDeviceTokenFetch);
    on<GetNewsByIdFetch>(_getNewsByIdFetch);
    on<ResetNewsStateFetch>(_resetNewsState);
  }

  // ✅ Добавить метод сброса состояния
  void _resetNewsState(ResetNewsStateFetch event, Emitter<NewsState> emit) {
    emit(const NewsState());
  }

  void _getActualsFetch(GetActualsFetch event, Emitter<NewsState> emit) async {
    // Устанавливаем статус загрузки
    final userData = await UserDataManager.getUser();

    try {
      emit(state.copyWith(status: NewsStatus.loading));
      final res =
          await _getActuals(GetActualsParams(city: userData?.city ?? ''), null);
      res.fold(
          (failure) => emit(state.copyWith(
              status: NewsStatus.failure, error: failure.message)), (actuals) {
        emit(state.copyWith(actuals: actuals, status: NewsStatus.success));
      });
    } catch (e) {
      // Обрабатываем неожиданные ошибки
      emit(state.copyWith(
          status: NewsStatus.failure,
          error: 'Unexpected error: ${e.toString()}'));
    }
  }

  void _getCategoriesListFetch(
      GetCategoriesListFetch event, Emitter<NewsState> emit) async {
    try {
      final res = await _getCategories(NoParams(), null);
      res.fold((failure) => emit(state.copyWith()), (categoriesList) {
        emit(state.copyWith(categoriesList: categoriesList));
      });
    } catch (e) {
      emit(state.copyWith(
        status: NewsStatus.failure,
        error: 'Failed to load categories: ${e.toString()}',
      ));
    }
  }

  void _onFetchGetBannerList(
      GetBannersListFetch event, Emitter<NewsState> emit) async {
    try {
      // ✅ Получаем город пользователя для фильтрации баннеров
      final userData = await UserDataManager.getUser();
      
      // ✅ Устанавливаем loading только если это первая загрузка
      if (state.banners == null) {
        emit(state.copyWith(status: NewsStatus.loading));
      }
      final res = await _getBannersList(BannersParams(city: userData?.city), null);
      res.fold((failure) {
        emit(
            state.copyWith(status: NewsStatus.failure, error: failure.message));
      }, (banners) {
        emit(state.copyWith(
            status: NewsStatus.success, banners: banners, error: null));
      });
    } catch (e) {
      emit(state.copyWith(
        status: NewsStatus.failure,
        error: 'Failed to load banners: ${e.toString()}',
      ));
    }
  }

  void _getNewsListFetch(
      GetNewsListFetch event, Emitter<NewsState> emit) async {
    try {
      // ✅ Получаем данные пользователя для фильтрации новостей
      final userData = await UserDataManager.getUser();
      
      // ✅ При смене категории используем isCategoryChanging вместо loading
      // чтобы не сбрасывать UI и сохранить плавную анимацию
      if (event.isCategoryChange) {
        emit(state.copyWith(isCategoryChanging: true));
      } else if (!event.isLoadMore) {
        emit(state.copyWith(status: NewsStatus.loading));
      }

      final res = await _getNewsList(
        CategoryParams(
          category: event.category,
          page: event.page,
          city: userData?.city,
          clothingSize: userData?.clothingSize,
          shoeSize: userData?.shoeSize,
        ),
        null,
      );

      res.fold(
        (failure) => emit(state.copyWith(
          status: NewsStatus.failure,
          error: failure.message,
          isCategoryChanging: false,
        )),
        (newsList) {
          // ✅ Если это подгрузка, добавляем к существующим новостям
          if (event.isLoadMore && state.newsEntity != null) {
            final existingNews = state.newsEntity!.data;
            final newNews = newsList.data;

            // Объединяем списки
            final combinedNews = [...existingNews, ...newNews];

            final updatedNewsEntity = NewsEntity(
              currentPage: newsList.currentPage,
              data: combinedNews,
              firstPageUrl: newsList.firstPageUrl,
              from: state.newsEntity!.from,
              lastPage: newsList.lastPage,
              lastPageUrl: newsList.lastPageUrl,
              links: newsList.links,
              nextPageUrl: newsList.nextPageUrl,
              path: newsList.path,
              perPage: newsList.perPage,
              prevPageUrl: newsList.prevPageUrl,
              to: newsList.to,
              total: newsList.total,
            );

            emit(state.copyWith(
              status: NewsStatus.success,
              newsEntity: updatedNewsEntity,
              error: null,
              isCategoryChanging: false,
            ));
          } else {
            // ✅ Для первой загрузки или смены категории - заменяем данные
            emit(state.copyWith(
              status: NewsStatus.success,
              newsEntity: newsList,
              error: null,
              isCategoryChanging: false,
            ));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: NewsStatus.failure,
        error: 'Failed to load news: ${e.toString()}',
        isCategoryChanging: false,
      ));
    }
  }

  void _getNewsByIdFetch(
      GetNewsByIdFetch event, Emitter<NewsState> emit) async {
    try {
      // ✅ Устанавливаем loading для деталей новости
      emit(state.copyWith(status: NewsStatus.loading, newsDetail: null));

      final res = await _getNewsListById(NewsIdParams(id: event.id), null);
      res.fold(
        (failure) => emit(state.copyWith(
          status: NewsStatus.failure,
          error: failure.message,
        )),
        (news) => emit(state.copyWith(
          status: NewsStatus.success,
          newsDetail: news,
          error: null,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: NewsStatus.failure,
        error: 'Failed to load news details: ${e.toString()}',
      ));
    }
  }

  void _postDeviceTokenFetch(
      PostDeviceTokenFetch event, Emitter<NewsState> emit) async {
    try {
      final token = NotificationServices.instance.fcmToken;

      // ✅ Проверка токена
      if (token == null || token.isEmpty) {
        emit(state.copyWith(
          message: 'FCM token is not available',
        ));
        return;
      }

      final res = await _postDeviceToken(
        PostDeviceTokenParams(token: token),
        null,
      );

      res.fold(
        (failure) {
          emit(state.copyWith(message: failure.message));
          // ✅ Используем debugPrint вместо print
          debugPrint('Device token error: ${failure.message}');
        },
        (successMessage) {
          emit(state.copyWith(message: successMessage));
          sharedService.deviceTokenPassed = true;
          debugPrint('Device token sent successfully');
        },
      );
    } catch (e) {
      emit(state.copyWith(
        message: 'Failed to send device token: ${e.toString()}',
      ));
      debugPrint('Device token exception: $e');
    }
  }
}
