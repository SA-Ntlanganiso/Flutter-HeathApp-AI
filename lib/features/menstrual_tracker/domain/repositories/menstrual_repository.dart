// lib/features/menstrual_tracker/domain/repositories/menstrual_repository.dart
// lib/features/menstrual_tracker/domain/repositories/menstrual_repository.dart
import 'package:agcare_plus/core/models/cycle_event.dart';

abstract class MenstrualRepository {
  Future<Map<DateTime, List<CycleEvent>>> getCycleEvents();
  Future<void> trackCycleEvent(CycleEvent event);
  Future<void> updateCycleEvent(CycleEvent oldEvent, CycleEvent newEvent);
  Future<void> deleteCycleEvent(CycleEvent event);
}