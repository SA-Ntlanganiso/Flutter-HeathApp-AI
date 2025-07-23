// lib/core/models/health_models.dart
enum CycleEventType { period, ovulation, symptom }

class CycleEvent {
  final CycleEventType type;
  final int intensity;
  final String? description;

  CycleEvent({
    required this.type,
    required this.intensity,
    this.description,
  });

  factory CycleEvent.fromJson(Map<String, dynamic> json) {
    return CycleEvent(
      type: CycleEventType.values[json['type']],
      intensity: json['intensity'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'intensity': intensity,
      'description': description,
    };
  }
}