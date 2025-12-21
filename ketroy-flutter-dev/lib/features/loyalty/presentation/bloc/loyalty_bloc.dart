import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ketroy_app/core/usecase/usecase.dart';
import 'package:ketroy_app/features/loyalty/data/models/loyalty_info_model.dart';
import 'package:ketroy_app/features/loyalty/domain/entities/loyalty_info_entity.dart';
import 'package:ketroy_app/features/loyalty/domain/usecases/get_loyalty_info.dart';
import 'package:ketroy_app/features/loyalty/domain/usecases/get_unviewed_achievements.dart';
import 'package:ketroy_app/features/loyalty/domain/usecases/mark_levels_viewed.dart';

part 'loyalty_event.dart';
part 'loyalty_state.dart';

/// BLoC для управления состоянием лояльности
class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final GetLoyaltyInfo _getLoyaltyInfo;
  final GetUnviewedAchievements _getUnviewedAchievements;
  final MarkLevelsViewed _markLevelsViewed;

  LoyaltyBloc({
    required GetLoyaltyInfo getLoyaltyInfo,
    required GetUnviewedAchievements getUnviewedAchievements,
    required MarkLevelsViewed markLevelsViewed,
  })  : _getLoyaltyInfo = getLoyaltyInfo,
        _getUnviewedAchievements = getUnviewedAchievements,
        _markLevelsViewed = markLevelsViewed,
        super(const LoyaltyState()) {
    on<LoadLoyaltyInfo>(_onLoadLoyaltyInfo);
    on<CheckUnviewedAchievements>(_onCheckUnviewedAchievements);
    on<MarkAchievementsViewed>(_onMarkAchievementsViewed);
    on<ShowLevelUpModal>(_onShowLevelUpModal);
    on<DismissLevelUpModal>(_onDismissLevelUpModal);
  }

  /// Загрузить информацию о лояльности
  Future<void> _onLoadLoyaltyInfo(
    LoadLoyaltyInfo event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(state.copyWith(status: LoyaltyStatus.loading));

    final result = await _getLoyaltyInfo(NoParams(), null);

    result.fold(
      (failure) {
        debugPrint('❌ Failed to load loyalty info: ${failure.message}');
        emit(state.copyWith(
          status: LoyaltyStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (loyaltyInfo) {
        debugPrint('✅ Loyalty info loaded: level=${loyaltyInfo.currentLevel?.name}');
        emit(state.copyWith(
          status: LoyaltyStatus.success,
          loyaltyInfo: loyaltyInfo,
        ));
      },
    );
  }

  /// Проверить непросмотренные достижения
  Future<void> _onCheckUnviewedAchievements(
    CheckUnviewedAchievements event,
    Emitter<LoyaltyState> emit,
  ) async {
    final result = await _getUnviewedAchievements(NoParams(), null);

    result.fold(
      (failure) {
        debugPrint('❌ Failed to check unviewed achievements: ${failure.message}');
      },
      (response) {
        debugPrint('✅ Unviewed achievements: ${response.newLevels.length}');
        if (response.hasNewLevels && response.newLevels.isNotEmpty) {
          emit(state.copyWith(
            unviewedAchievements: response.newLevels,
            showLevelUpModal: true,
          ));
        }
      },
    );
  }

  /// Отметить достижения как просмотренные
  Future<void> _onMarkAchievementsViewed(
    MarkAchievementsViewed event,
    Emitter<LoyaltyState> emit,
  ) async {
    final result = await _markLevelsViewed(NoParams(), null);

    result.fold(
      (failure) {
        debugPrint('❌ Failed to mark achievements viewed: ${failure.message}');
      },
      (count) {
        debugPrint('✅ Marked $count achievements as viewed');
        emit(state.copyWith(
          unviewedAchievements: [],
          showLevelUpModal: false,
        ));
      },
    );
  }

  /// Показать модальное окно повышения уровня
  void _onShowLevelUpModal(
    ShowLevelUpModal event,
    Emitter<LoyaltyState> emit,
  ) {
    emit(state.copyWith(showLevelUpModal: true));
  }

  /// Скрыть модальное окно повышения уровня
  void _onDismissLevelUpModal(
    DismissLevelUpModal event,
    Emitter<LoyaltyState> emit,
  ) {
    emit(state.copyWith(showLevelUpModal: false));
    // После закрытия модального окна отмечаем достижения как просмотренные
    add(const MarkAchievementsViewed());
  }
}
