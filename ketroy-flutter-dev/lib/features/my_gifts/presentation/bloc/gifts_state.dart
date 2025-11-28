part of 'gifts_bloc.dart';

enum GiftsStatus { initial, loading, success, failure }

class GiftsState extends Equatable {
  final GiftsStatus status;
  final List<GiftsEntities> savedGiftsList;
  final List<GiftsEntities> gifts;
  final List<GiftGroup> pendingGroups;
  final bool hasPending;
  final bool isActivate;
  final bool isSaved;
  final String? name;
  final String? surname;
  final String? avaImage;
  final String? message;

  const GiftsState({
    this.status = GiftsStatus.initial,
    this.savedGiftsList = const [],
    this.gifts = const [],
    this.pendingGroups = const [],
    this.hasPending = false,
    this.isActivate = false,
    this.isSaved = false,
    this.name,
    this.surname,
    this.avaImage,
    this.message,
  });

  @override
  List<Object?> get props => [
        status,
        savedGiftsList,
        isActivate,
        isSaved,
        gifts,
        pendingGroups,
        hasPending,
        name,
        surname,
        avaImage,
        message
      ];

  bool get isInitial => status == GiftsStatus.initial;
  bool get isLoading => status == GiftsStatus.loading;
  bool get isSuccess => status == GiftsStatus.success;
  bool get isFailure => status == GiftsStatus.failure;

  GiftsState copyWith({
    GiftsStatus? status,
    List<GiftsEntities>? giftsList,
    List<GiftsEntities>? gifts,
    List<GiftGroup>? pendingGroups,
    bool? hasPending,
    bool? isActivate,
    bool? isSaved,
    String? name,
    String? surname,
    String? avaImage,
    String? message,
  }) {
    return GiftsState(
      status: status ?? this.status,
      savedGiftsList: giftsList ?? savedGiftsList,
      gifts: gifts ?? this.gifts,
      pendingGroups: pendingGroups ?? this.pendingGroups,
      hasPending: hasPending ?? this.hasPending,
      name: name ?? this.name,
      isActivate: isActivate ?? this.isActivate,
      isSaved: isSaved ?? this.isSaved,
      surname: surname ?? this.surname,
      avaImage: avaImage ?? this.avaImage,
      message: message ?? this.message,
    );
  }
}
