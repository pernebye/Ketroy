import 'package:ketroy_app/features/ai/domain/entities/ai_entity.dart';

class AiModel extends AiEntity {
  AiModel(
      {required super.success,
      required super.analysis,
      required super.processingTime,
      required super.timestamp});

  factory AiModel.fromjson(Map<String, dynamic> json) {
    DateTime parseTimestamp() {
      try {
        final timestamp = json['timestamp'];
        if (timestamp == null) return DateTime.now();
        if (timestamp is String) return DateTime.parse(timestamp);
        if (timestamp is DateTime) return timestamp;
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    return AiModel(
      success: json['success'] ?? false,
      analysis: json['analysis'] ?? '',
      processingTime: (json['processing_time'] as num?)?.toDouble() ?? 0.0,
      timestamp: parseTimestamp(),
    );
  }
}
