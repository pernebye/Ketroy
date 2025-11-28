part of 'discount_bloc.dart';

enum DiscountStatus { initial, loading, success, failure }

class DiscountState extends Equatable {
  final DiscountStatus status;
  final String? promoCode;
  final String? message;
  final bool isReferralAvailable;
  final ReferralInfo? referralInfo;

  const DiscountState({
    this.status = DiscountStatus.initial,
    this.promoCode,
    this.message,
    this.isReferralAvailable = true, // По умолчанию показываем, пока не получим ответ
    this.referralInfo,
  });

  @override
  List<Object?> get props => [status, promoCode, message, isReferralAvailable, referralInfo];

  bool get isInitial => status == DiscountStatus.initial;
  bool get isLoading => status == DiscountStatus.loading;
  bool get isSuccess => status == DiscountStatus.success;
  bool get isFailure => status == DiscountStatus.failure;

  DiscountState copyWith({
    DiscountStatus? status,
    String? promoCode,
    String? message,
    bool? isReferralAvailable,
    ReferralInfo? referralInfo,
  }) {
    return DiscountState(
      status: status ?? this.status,
      promoCode: promoCode ?? this.promoCode,
      message: message ?? this.message,
      isReferralAvailable: isReferralAvailable ?? this.isReferralAvailable,
      referralInfo: referralInfo ?? this.referralInfo,
    );
  }
}
