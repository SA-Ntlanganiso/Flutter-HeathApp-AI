import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

enum CycleEventType { period, ovulation, symptom, mood, medication }

enum FlowIntensity { spotting, light, medium, heavy, veryHeavy }

enum SymptomSeverity { mild, moderate, severe }

enum MoodType { happy, sad, anxious, irritable, energetic, tired, emotional }

class CycleEvent {
  final ObjectId? id;
  final DateTime eventDate;
  final String? description;
  final bool isSynced;
  final CycleEventType type;
  
  // Type-specific fields
  final FlowIntensity? flowIntensity;
  final SymptomSeverity? symptomSeverity;
  final String? symptomType;
  final MoodType? moodType;
  final String? medicationName;
  final String? medicationDosage;
  final int? intensity;

  CycleEvent({
    this.id,
    required this.eventDate,
    this.description,
    this.isSynced = false,
    required this.type,
    this.flowIntensity,
    this.symptomSeverity,
    this.symptomType,
    this.moodType,
    this.medicationName,
    this.medicationDosage,
    this.intensity,
  }) {
    _validateEventData();
  }

  void _validateEventData() {
    switch (type) {
      case CycleEventType.period:
        if (flowIntensity == null && intensity == null) {
          throw ArgumentError('Period events must have either flowIntensity or intensity');
        }
        break;
      case CycleEventType.symptom:
        if (symptomType == null || symptomType!.isEmpty) {
          throw ArgumentError('Symptom events must have a symptom type');
        }
        if (symptomSeverity == null && intensity == null) {
          throw ArgumentError('Symptom events must have either severity or intensity');
        }
        break;
      case CycleEventType.mood:
        if (moodType == null) {
          throw ArgumentError('Mood events must have a mood type');
        }
        break;
      case CycleEventType.medication:
        if (medicationName == null || medicationName!.isEmpty) {
          throw ArgumentError('Medication events must have a medication name');
        }
        break;
      case CycleEventType.ovulation:
        // No validation needed
        break;
    }
  }

  CycleEvent copyWith({
    ObjectId? id,
    DateTime? eventDate,
    String? description,
    bool? isSynced,
    CycleEventType? type,
    FlowIntensity? flowIntensity,
    SymptomSeverity? symptomSeverity,
    String? symptomType,
    MoodType? moodType,
    String? medicationName,
    String? medicationDosage,
    int? intensity,
  }) {
    return CycleEvent(
      id: id ?? this.id,
      eventDate: eventDate ?? this.eventDate,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      type: type ?? this.type,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      symptomSeverity: symptomSeverity ?? this.symptomSeverity,
      symptomType: symptomType ?? this.symptomType,
      moodType: moodType ?? this.moodType,
      medicationName: medicationName ?? this.medicationName,
      medicationDosage: medicationDosage ?? this.medicationDosage,
      intensity: intensity ?? this.intensity,
    );
  }

  String get displayDescription {
    switch (type) {
      case CycleEventType.period:
        return description ?? 'Period - ${flowIntensity?.name ?? intensity?.toString() ?? 'medium'} flow';
      case CycleEventType.symptom:
        return description ?? '${symptomType ?? 'Symptom'} - ${symptomSeverity?.name ?? intensity?.toString() ?? 'mild'}';
      case CycleEventType.mood:
        return description ?? moodType?.name ?? 'Mood';
      case CycleEventType.medication:
        return description ?? '${medicationName ?? 'Medication'} ${medicationDosage ?? ''}'.trim();
      case CycleEventType.ovulation:
        return description ?? 'Ovulation';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'eventDate': eventDate.toIso8601String(),
      'description': description,
      'isSynced': isSynced,
      'type': type.name,
      'flowIntensity': flowIntensity?.name,
      'symptomSeverity': symptomSeverity?.name,
      'symptomType': symptomType,
      'moodType': moodType?.name,
      'medicationName': medicationName,
      'medicationDosage': medicationDosage,
      'intensity': intensity,
    };
  }

  factory CycleEvent.fromJson(Map<String, dynamic> json) {
    try {
      // Handle ID conversion safely
      ObjectId? id;
      if (json['_id'] != null) {
        if (json['_id'] is ObjectId) {
          id = json['_id'];
        } else if (json['_id'] is String) {
          try {
            id = ObjectId.fromHexString(json['_id']);
          } catch (e) {
            debugPrint('Invalid ObjectId format: ${json['_id']}');
          }
        }
      }

      // Helper function to parse enums safely
      T? parseEnum<T>(List<T> values, String? value) {
        if (value == null) return null;
        try {
          return values.firstWhere((e) => e.toString().split('.').last == value);
        } catch (_) {
          return null;
        }
      }

      return CycleEvent(
        id: id,
        eventDate: DateTime.parse(json['eventDate'] as String),
        description: json['description'] as String?,
        isSynced: json['isSynced'] as bool? ?? false,
        type: parseEnum(CycleEventType.values, json['type'] as String?) ?? CycleEventType.period,
        flowIntensity: parseEnum(FlowIntensity.values, json['flowIntensity'] as String?),
        symptomSeverity: parseEnum(SymptomSeverity.values, json['symptomSeverity'] as String?),
        symptomType: json['symptomType'] as String?,
        moodType: parseEnum(MoodType.values, json['moodType'] as String?),
        medicationName: json['medicationName'] as String?,
        medicationDosage: json['medicationDosage'] as String?,
        intensity: (json['intensity'] as num?)?.toInt(),
      );
    } catch (e, stack) {
      debugPrint('Error parsing CycleEvent: $e\n$stack');
      rethrow;
    }
  }

  // Factory constructors
  factory CycleEvent.period({
    ObjectId? id,
    DateTime? eventDate,
    FlowIntensity? flowIntensity,
    int? intensity,
    String? description,
  }) => CycleEvent(
    id: id,
    eventDate: eventDate ?? DateTime.now(),
    type: CycleEventType.period,
    flowIntensity: flowIntensity,
    intensity: intensity,
    description: description,
  );

  factory CycleEvent.symptom({
    ObjectId? id,
    DateTime? eventDate,
    required String symptomType,
    SymptomSeverity? severity,
    int? intensity,
    String? description,
  }) => CycleEvent(
    id: id,
    eventDate: eventDate ?? DateTime.now(),
    type: CycleEventType.symptom,
    symptomType: symptomType,
    symptomSeverity: severity,
    intensity: intensity,
    description: description,
  );

  factory CycleEvent.mood({
    ObjectId? id,
    DateTime? eventDate,
    required MoodType moodType,
    String? description,
  }) => CycleEvent(
    id: id,
    eventDate: eventDate ?? DateTime.now(),
    type: CycleEventType.mood,
    moodType: moodType,
    description: description,
  );

  factory CycleEvent.medication({
    ObjectId? id,
    DateTime? eventDate,
    required String medicationName,
    String? dosage,
    String? description,
  }) => CycleEvent(
    id: id,
    eventDate: eventDate ?? DateTime.now(),
    type: CycleEventType.medication,
    medicationName: medicationName,
    medicationDosage: dosage,
    description: description,
  );

  factory CycleEvent.ovulation({
    ObjectId? id,
    DateTime? eventDate,
    String? description,
  }) => CycleEvent(
    id: id,
    eventDate: eventDate ?? DateTime.now(),
    type: CycleEventType.ovulation,
    description: description,
  );
}