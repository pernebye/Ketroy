class GiftsEntities {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int isViewed;
  final String? image;
  final int? promotionId;
  final String? status; // pending, selected, activated, issued

  GiftsEntities({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.isViewed,
    required this.image,
    required this.promotionId,
    this.status,
  });
  
  /// Статусы подарка
  static const String statusPending = 'pending';
  static const String statusSelected = 'selected';
  static const String statusActivated = 'activated';
  static const String statusIssued = 'issued';
  
  bool get isPending => status == statusPending;
  bool get isSelected => status == statusSelected;
  bool get isActivated => status == statusActivated;
  bool get isIssued => status == statusIssued;
}
