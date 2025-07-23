
import 'package:agcare_plus/core/models/cycle_event.dart';


class CycleEvent {
  String? id; // MongoDB will generate this
  DateTime date;
  final CycleEventType type;
  int intensity;
  String? description;
  bool isSynced; // Make this final since it's part of the constructor

  CycleEvent({
    this.id,
    required this.date,
    required this.type,
    this.intensity = 1,
    this.description,
    this.isSynced = true, // Add to constructor with default value
  });

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'date': date.toIso8601String(),
    'type': type.index,
    'intensity': intensity,
    'description': description,
    'isSynced': isSynced,
  };

  factory CycleEvent.fromJson(Map<String, dynamic> json) => CycleEvent(
    id: json['_id']?.toString(),
    date: DateTime.parse(json['date']),
    type: CycleEventType.values[json['type']],
    intensity: json['intensity'] ?? 1,
    description: json['description'],
    isSynced: json['isSynced'] ?? true, // Add this line
  );
}