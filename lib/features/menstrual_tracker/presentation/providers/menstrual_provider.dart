import 'package:agcare_plus/core/models/cycle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agcare_plus/features/menstrual_tracker/domain/repositories/menstrual_repository.dart';
import 'package:agcare_plus/features/menstrual_tracker/data/repositories/menstrual_repository_impl.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final mongoDbProvider = Provider<Db>((ref) {
  throw UnimplementedError('mongoDbProvider must be overridden');
});

final mongoCollectionProvider = Provider<DbCollection>((ref) {
  return ref.watch(mongoDbProvider).collection('cycle_events');
});

final menstrualRepositoryProvider = Provider<MenstrualRepository>((ref) {
  return MenstrualRepositoryImpl(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
    mongoCollection: ref.watch(mongoCollectionProvider),
  );
});

final menstrualProvider = StateNotifierProvider<MenstrualNotifier, Map<DateTime, List<CycleEvent>>>((ref) {
  return MenstrualNotifier(ref.watch(menstrualRepositoryProvider));
});

class MenstrualNotifier extends StateNotifier<Map<DateTime, List<CycleEvent>>> {
  final MenstrualRepository _repository;

  MenstrualNotifier(this._repository) : super({});

  Future<void> loadEvents() async {
    state = await _repository.getCycleEvents();
  }

  Future<void> addEvent(DateTime date, CycleEvent event) async {
  try {
    final eventWithDate = event.copyWith(eventDate: date);
    await _repository.trackCycleEvent(eventWithDate);
    await loadEvents();
  } catch (e) {
    debugPrint('Error adding event: $e');
    rethrow; // Or handle the error as appropriate for your app
  }
}

  Future<void> updateEvent(CycleEvent oldEvent, CycleEvent newEvent) async {
    await _repository.updateCycleEvent(oldEvent, newEvent);
    await loadEvents();
  }

  Future<void> deleteEvent(CycleEvent event) async {
    await _repository.deleteCycleEvent(event);
    await loadEvents();
  }

  List<CycleEvent> getPeriodEvents() {
    return state.values
        .expand((events) => events)
        .where((event) => event.type == CycleEventType.period)
        .toList();
  }

  CycleAnalysis analyzeCycle() {
    final periodEvents = getPeriodEvents();
    if (periodEvents.isEmpty) return CycleAnalysis.empty();

    periodEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final cycleLengths = <int>[];
    for (var i = 1; i < periodEvents.length; i++) {
      final diff = periodEvents[i].eventDate.difference(periodEvents[i-1].eventDate).inDays;
      cycleLengths.add(diff);
    }

    final avgCycleLength = cycleLengths.isNotEmpty 
        ? (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length).round()
        : 28;

    var currentPeriodStart = periodEvents.first.eventDate;
    var periodLengths = <int>[];
    var currentLength = 1;

    for (var i = 1; i < periodEvents.length; i++) {
      if (periodEvents[i].eventDate.difference(periodEvents[i-1].eventDate).inDays == 1) {
        currentLength++;
      } else {
        periodLengths.add(currentLength);
        currentLength = 1;
        currentPeriodStart = periodEvents[i].eventDate;
      }
    }
    periodLengths.add(currentLength);

    final avgPeriodLength = periodLengths.isNotEmpty
        ? (periodLengths.reduce((a, b) => a + b) / periodLengths.length).round()
        : 5;

    final lastPeriodStart = periodEvents.last.eventDate;
    final predictedNextPeriod = lastPeriodStart.add(Duration(days: avgCycleLength));

    final currentDayInCycle = DateTime.now().difference(lastPeriodStart).inDays + 1;
    final isFertile = currentDayInCycle >= 10 && currentDayInCycle <= 17;

    final symptomEvents = state.values
        .expand((events) => events)
        .where((event) => event.type == CycleEventType.symptom)
        .toList();

    final symptomAnalysis = <String, SymptomAnalysis>{};
    for (var event in symptomEvents) {
      if (event.symptomType != null) {
        final analysis = symptomAnalysis[event.symptomType!] ?? SymptomAnalysis();
        analysis.count++;
        analysis.totalSeverity += event.symptomSeverity?.index ?? 0;
        symptomAnalysis[event.symptomType!] = analysis;
      }
    }

    return CycleAnalysis(
      avgCycleLength: avgCycleLength,
      avgPeriodLength: avgPeriodLength,
      lastPeriodStart: lastPeriodStart,
      predictedNextPeriod: predictedNextPeriod,
      isFertile: isFertile,
      currentDayInCycle: currentDayInCycle,
      symptomAnalysis: symptomAnalysis,
    );
  }
}

class CycleAnalysis {
  final int avgCycleLength;
  final int avgPeriodLength;
  final DateTime lastPeriodStart;
  final DateTime predictedNextPeriod;
  final bool isFertile;
  final int currentDayInCycle;
  final Map<String, SymptomAnalysis> symptomAnalysis;

  CycleAnalysis({
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.lastPeriodStart,
    required this.predictedNextPeriod,
    required this.isFertile,
    required this.currentDayInCycle,
    required this.symptomAnalysis,
  });

  factory CycleAnalysis.empty() => CycleAnalysis(
    avgCycleLength: 28,
    avgPeriodLength: 5,
    lastPeriodStart: DateTime.now(),
    predictedNextPeriod: DateTime.now(),
    isFertile: false,
    currentDayInCycle: 1,
    symptomAnalysis: {},
  );

  String getCurrentPhase() {
    if (currentDayInCycle <= avgPeriodLength) return 'Menstruation';
    if (currentDayInCycle <= 13) return 'Follicular Phase';
    if (currentDayInCycle <= 16) return 'Ovulation';
    return 'Luteal Phase';
  }

  Color getPhaseColor() {
    if (currentDayInCycle <= avgPeriodLength) return Colors.red.shade400;
    if (currentDayInCycle <= 13) return Colors.green.shade400;
    if (currentDayInCycle <= 16) return Colors.orange.shade400;
    return Colors.blue.shade400;
  }

  List<String> getInsights() {
    final insights = <String>[];
    
    insights.add('Your average cycle is $avgCycleLength days');
    insights.add('Your average period lasts $avgPeriodLength days');
    
    if (symptomAnalysis.isNotEmpty) {
      final mostCommonSymptom = symptomAnalysis.entries.reduce(
        (a, b) => a.value.count > b.value.count ? a : b
      ).key;
      
      insights.add('You most frequently report $mostCommonSymptom symptoms');
    }
    
    return insights;
  }
}

class SymptomAnalysis {
  int count = 0;
  int totalSeverity = 0;
  
  double get averageSeverity => count > 0 ? totalSeverity / count : 0;
}