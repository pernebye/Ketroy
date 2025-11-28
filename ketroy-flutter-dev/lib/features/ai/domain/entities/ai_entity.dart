class AiEntity {
  final bool success;
  final String analysis;
  final double processingTime;
  final DateTime timestamp;

  AiEntity(
      {required this.success,
      required this.analysis,
      required this.processingTime,
      required this.timestamp});
}
