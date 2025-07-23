import 'package:mongo_dart/mongo_dart.dart';
import 'package:agcare_plus/core/models/cycle_event.dart';

class CycleEventRepository {
  final DbCollection collection;

  CycleEventRepository(this.collection);

  // Add a new cycle event
  Future<void> addEvent(CycleEvent event) async {
    await collection.insert(event.toJson());
  }

  // Get events for a specific date range
  Future<List<CycleEvent>> getEvents(DateTime startDate, DateTime endDate) async {
    final events = await collection.find({
      'date': {
        '\$gte': startDate,
        '\$lte': endDate,
      }
    }).toList();
    
    return events.map((e) => CycleEvent.fromJson(e)).toList();
  }

  // Update an existing event
  Future<void> updateEvent(CycleEvent event) async {
    await collection.update(
      where.eq('_id', event.id),
      event.toJson(),
    );
  }

  // Delete an event
  Future<void> deleteEvent(ObjectId id) async {
    await collection.remove(where.eq('_id', id));
  }

  // Get all unsynced events (for offline sync)
  Future<List<CycleEvent>> getUnsyncedEvents() async {
    final events = await collection.find({
      'isSynced': false,
    }).toList();
    
    return events.map((e) => CycleEvent.fromJson(e)).toList();
  }

  // Mark events as synced
  Future<void> markAsSynced(List<ObjectId> ids) async {
    await collection.update(
      where.oneFrom('_id', ids),
      modify.set('isSynced', true),
      multiUpdate: true,
    );
  }
}