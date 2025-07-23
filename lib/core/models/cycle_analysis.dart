// lib/core/models/cycle_analysis.dart
import 'package:agcare_plus/core/models/cycle_event.dart';
import 'package:flutter/material.dart';

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
    avgCycleLength: 28, // Default average cycle length
    avgPeriodLength: 5,  // Default average period length
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

      final severeSymptoms = symptomAnalysis.entries
          .where((e) => e.value.averageSeverity >= 2)
          .map((e) => e.key);
      if (severeSymptoms.isNotEmpty) {
        insights.add('Severe symptoms: ${severeSymptoms.join(', ')}');
      }
    }
    
    // Add fertility window information
    if (isFertile) {
      insights.add('You\'re currently in your fertile window');
    } else {
      final daysToFertile = 10 - currentDayInCycle;
      if (daysToFertile > 0) {
        insights.add('Your fertile window starts in $daysToFertile days');
      }
    }
    
    return insights;
  }
}

class SymptomAnalysis {
  int count = 0;
  int totalSeverity = 0;
  
  double get averageSeverity => count > 0 ? totalSeverity / count : 0;
}