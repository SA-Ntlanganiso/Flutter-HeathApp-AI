// lib/core/providers/cycle_event_providers.dart
import 'package:agcare_plus/core/models/cycle_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../repositories/cycle_event_repository.dart';

final cycleEventRepositoryProvider = Provider<CycleEventRepository>((ref) {
  throw UnimplementedError('cycleEventRepositoryProvider must be overridden');
});

final cycleEventsProvider = StateNotifierProvider<CycleEventsNotifier, List<CycleEvent>>((ref) {
  return CycleEventsNotifier(ref.watch(cycleEventRepositoryProvider));
});

class CycleEventsNotifier extends StateNotifier<List<CycleEvent>> {
  final CycleEventRepository _repository;

  CycleEventsNotifier(this._repository) : super([]);

  Future<void> loadEvents(DateTime startDate, DateTime endDate) async {
    final events = await _repository.getEvents(startDate, endDate);
    state = events;
  }

  Future<void> addEvent(CycleEvent event) async {
    await _repository.addEvent(event);
    state = [...state, event];
  }

  Future<void> updateEvent(CycleEvent event) async {
    await _repository.updateEvent(event);
    state = state.map((e) => e.id == event.id ? event : e).toList();
  }

  Future<void> deleteEvent(ObjectId id) async {
    await _repository.deleteEvent(id);
    state = state.where((e) => e.id != id).toList();
  }
}