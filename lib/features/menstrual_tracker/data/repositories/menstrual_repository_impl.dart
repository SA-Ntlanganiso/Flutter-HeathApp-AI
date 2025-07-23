import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agcare_plus/core/models/cycle_event.dart';
import 'package:agcare_plus/features/menstrual_tracker/domain/repositories/menstrual_repository.dart';
import 'package:collection/collection.dart';

class MenstrualRepositoryImpl implements MenstrualRepository {
  final SharedPreferences sharedPreferences;
  final DbCollection mongoCollection;

  MenstrualRepositoryImpl({
    required this.sharedPreferences,
    required this.mongoCollection,
  });

  @override
  Future<Map<DateTime, List<CycleEvent>>> getCycleEvents() async {
    try {
      final events = await mongoCollection.find().toList();
      final cycleEvents = events.map((e) => CycleEvent.fromJson(e)).toList();
      return groupBy(cycleEvents, (e) => 
        DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day));
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return {};
    }
  }

  @override
  Future<void> trackCycleEvent(CycleEvent event) async {
    try {
      await mongoCollection.insert(event.toJson());
    } catch (e) {
      debugPrint('Error saving event: $e');
      rethrow;
    }
  }

  @override
Future<void> updateCycleEvent(CycleEvent oldEvent, CycleEvent newEvent) async {
  try {
    if (oldEvent.id == null) {
      throw ArgumentError('Cannot update event without ID');
    }
    await mongoCollection.update(
      where.id(oldEvent.id!), // Add ! to assert non-null
      newEvent.copyWith(id: oldEvent.id).toJson(),
    );
  } catch (e) {
    debugPrint('Error updating event: $e');
    rethrow;
  }
}

@override
Future<void> deleteCycleEvent(CycleEvent event) async {
  try {
    if (event.id == null) {
      throw ArgumentError('Cannot delete event without ID');
    }
    await mongoCollection.remove(where.id(event.id!)); // Add ! to assert non-null
  } catch (e) {
    debugPrint('Error deleting event: $e');
    rethrow;
  }
}
}