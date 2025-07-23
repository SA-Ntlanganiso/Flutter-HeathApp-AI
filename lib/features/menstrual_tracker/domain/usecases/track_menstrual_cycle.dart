// lib/features/menstrual_tracker/domain/usecases/track_menstrual_cycle.dart
import 'package:agcare_plus/core/models/cycle_event.dart';
import 'package:agcare_plus/features/menstrual_tracker/domain/repositories/menstrual_repository.dart';

class TrackMenstrualCycle {
  final MenstrualRepository repository;

  TrackMenstrualCycle(this.repository);

  Future<void> call(CycleEvent event) async {
    return await repository.trackCycleEvent(event);
  }
}