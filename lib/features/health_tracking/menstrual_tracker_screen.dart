// menstrual_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agcare_plus/core/models/cycle_event.dart';
import 'package:agcare_plus/features/menstrual_tracker/presentation/providers/menstrual_provider.dart';
import 'package:intl/intl.dart';

class MenstrualTrackerScreen extends ConsumerStatefulWidget {
  const MenstrualTrackerScreen({super.key});
  
  @override 
  ConsumerState<MenstrualTrackerScreen> createState() => _MenstrualTrackerScreenState();
}

class _MenstrualTrackerScreenState extends ConsumerState<MenstrualTrackerScreen> 
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;

  @override 
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(menstrualProvider.notifier).loadEvents();
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _loadData,
          textColor: Colors.white,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(menstrualProvider);
    final analysis = ref.read(menstrualProvider.notifier).analyzeCycle();
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Your Current Cycle', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showInsightsDialog(analysis),
            tooltip: 'View Insights',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTodayHeader(analysis),
                      const SizedBox(height: 16),
                      _buildCycleOverview(analysis),
                      const SizedBox(height: 24),
                      _buildCycleVisualization(analysis),
                      const SizedBox(height: 24),
                      if (analysis.getInsights().isNotEmpty) ...[
                        _buildInsightsSection(analysis),
                        const SizedBox(height: 24),
                      ],
                      _buildCalendarSection(events, analysis),
                      const SizedBox(height: 24),
                      _buildQuickTrackSection(),
                      const SizedBox(height: 100), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddDialog(),
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }

  Widget _buildTodayHeader(CycleAnalysis analysis) {
    final daysUntilNextPeriod = analysis.predictedNextPeriod.difference(DateTime.now()).inDays;
    final progressValue = analysis.currentDayInCycle / analysis.avgCycleLength;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              analysis.getPhaseColor().withOpacity(0.1),
              analysis.getPhaseColor().withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: analysis.getPhaseColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${analysis.currentDayInCycle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Cycle Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cycle Progress', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('${(progressValue * 100).toInt()}%', 
                         style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressValue.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(analysis.getPhaseColor()),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Text(
              daysUntilNextPeriod > 0 
                ? '$daysUntilNextPeriod days until your next period'
                : daysUntilNextPeriod == 0
                  ? 'Your period is due today'
                  : 'Your period is ${daysUntilNextPeriod.abs()} days late',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: daysUntilNextPeriod < 0 ? Colors.red : Colors.black87,
              ),
            ),
            
            if (analysis.isFertile) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Potential fertile window',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: analysis.getPhaseColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Current phase: ${analysis.getCurrentPhase()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: analysis.getPhaseColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleOverview(CycleAnalysis analysis) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Period Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showHistoryDialog(),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Track your period and its flow to get accurate cycle predictions.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFlowButton('Light', Colors.pink.shade100, FlowIntensity.light),
                _buildFlowButton('Medium', Colors.pink.shade300, FlowIntensity.medium),
                _buildFlowButton('Heavy', Colors.pink.shade500, FlowIntensity.heavy),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openTrackDialog(CycleEventType.period),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Log Period', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowButton(String label, Color color, FlowIntensity intensity) {
    return InkWell(
      onTap: () => _logPeriod(intensity),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleVisualization(CycleAnalysis analysis) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cycle Visualization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Day ${value.toInt()}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: analysis.avgCycleLength.toDouble(),
                  minY: 0,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateCycleSpots(analysis),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.pink.shade400,
                          Colors.orange.shade400,
                          Colors.green.shade400,
                          Colors.blue.shade400,
                        ],
                      ),
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.pink.shade100.withOpacity(0.3),
                            Colors.orange.shade100.withOpacity(0.3),
                            Colors.green.shade100.withOpacity(0.3),
                            Colors.blue.shade100.withOpacity(0.3),
                          ],
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: barData.gradient?.colors.first ?? Colors.pink,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildPhaseIndicator('Menstruation', Colors.red.shade400),
                _buildPhaseIndicator('Follicular', Colors.green.shade400),
                _buildPhaseIndicator('Ovulation', Colors.orange.shade400),
                _buildPhaseIndicator('Luteal', Colors.blue.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(CycleAnalysis analysis) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cycle Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showInsightsDialog(analysis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...analysis.getInsights().take(3).map((insight) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
            if (analysis.getInsights().length > 3) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showInsightsDialog(analysis),
                child: const Text('View all insights'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection(Map<DateTime, List<CycleEvent>> events, CycleAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar<CycleEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: (day) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                return events[normalizedDay] ?? [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                _showDayEvents(selectedDay, events[normalizedDay]);
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red.shade400),
                todayDecoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Colors.pink.shade400,
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(3).map((event) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getEventColor(event as CycleEvent),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getEventColor(CycleEvent event) {
    switch (event.type) {
      case CycleEventType.period:
        return Colors.red;
      case CycleEventType.ovulation:
        return Colors.orange;
      case CycleEventType.symptom:
        return Colors.blue;
      case CycleEventType.mood:
        return Colors.purple;
      case CycleEventType.medication:
        return Colors.green;
    }
  }

  Widget _buildQuickTrackSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Track',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllTrackingOptions(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildQuickTrackItem(Icons.water_drop, 'Period', Colors.pink, 
                  () => _openTrackDialog(CycleEventType.period)),
                _buildQuickTrackItem(Icons.egg, 'Ovulation', Colors.orange, 
                  () => _openTrackDialog(CycleEventType.ovulation)),
                _buildQuickTrackItem(Icons.sick, 'Symptoms', Colors.blue, 
                  () => _openTrackDialog(CycleEventType.symptom)),
                _buildQuickTrackItem(Icons.mood, 'Mood', Colors.purple, 
                  () => _openTrackDialog(CycleEventType.mood)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTrackItem(IconData icon, String label, Color color, VoidCallback onTap) {
  // Handle both MaterialColor and regular Color
  final textColor = color is MaterialColor ? color.shade700 : color;
  
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor, // Use the safe color here
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPhaseIndicator(String phase, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          phase,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateCycleSpots(CycleAnalysis analysis) {
    List<FlSpot> spots = [];
    
    // Menstruation phase (days 1-5)
    for (int i = 1; i <= analysis.avgPeriodLength; i++) {
      spots.add(FlSpot(i.toDouble(), 1.5 - (i * 0.1)));
    }
    
    // Follicular phase (days 6-13)
    for (int i = analysis.avgPeriodLength + 1; i <= 13; i++) {
      final progress = (i - analysis.avgPeriodLength) / (13 - analysis.avgPeriodLength);
      spots.add(FlSpot(i.toDouble(), 1.0 + progress * 2.5));
    }
    
    // Ovulation peak (day 14)
    spots.add(FlSpot(14.0, 4.5));
    
    // Luteal phase decline (days 15-28)
    for (int i = 15; i <= analysis.avgCycleLength; i++) {
      final progress = (i - 14) / (analysis.avgCycleLength - 14);
      spots.add(FlSpot(i.toDouble(), 4.5 - progress * 3.0));
    }
    
    return spots;
  }

  Future<void> _logPeriod(FlowIntensity intensity) async {
    try {
      final event = CycleEvent.period(
        eventDate: DateTime.now(),
        flowIntensity: intensity,
      );
      await ref.read(menstrualProvider.notifier).addEvent(DateTime.now(), event);
      _showSuccessSnackBar('Period logged successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to log period: ${e.toString()}');
    }
  }

  void _openTrackDialog(CycleEventType type) {
    String? symptomType;
    FlowIntensity? flowIntensity;
    MoodType? moodType;
    SymptomSeverity? symptomSeverity;
    String notes = '';
    final selectedSymptoms = <String>[];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Log ${type.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == CycleEventType.period) ...[
                    const Text('Flow Intensity', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<FlowIntensity>(
                      value: flowIntensity,
                      items: FlowIntensity.values.map((intensity) =>
                        DropdownMenuItem(
                          value: intensity,
                          child: Text(
                            intensity.name[0].toUpperCase() + intensity.name.substring(1),
                          ),
                        ),
                      ).toList(),
                      onChanged: (value) => setDialogState(() => flowIntensity = value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      isExpanded: true,
                    ),
                  ],
                  
                  if (type == CycleEventType.symptom) ...[
                    const Text('Symptom Type', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) => symptomType = value,
                      decoration: const InputDecoration(
                        hintText: 'E.g. cramps, headache',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Severity', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Mild'),
                            selected: symptomSeverity == SymptomSeverity.mild,
                            onSelected: (selected) => setDialogState(() {
                              symptomSeverity = selected ? SymptomSeverity.mild : null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Moderate'),
                            selected: symptomSeverity == SymptomSeverity.moderate,
                            onSelected: (selected) => setDialogState(() {
                              symptomSeverity = selected ? SymptomSeverity.moderate : null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Severe'),
                            selected: symptomSeverity == SymptomSeverity.severe,
                            onSelected: (selected) => setDialogState(() {
                              symptomSeverity = selected ? SymptomSeverity.severe : null;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (type == CycleEventType.mood) ...[
                    const Text('Select Mood', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MoodType.values.map((mood) =>
                        ChoiceChip(
                          label: Text(
                            mood.name[0].toUpperCase() + mood.name.substring(1),
                            style: TextStyle(
                              color: moodType == mood ? Colors.white : null,
                            ),
                          ),
                          selected: moodType == mood,
                          selectedColor: Colors.purple,
                          onSelected: (selected) => setDialogState(() => moodType = mood),
                        ),
                      ).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => notes = value,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add any additional notes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if ((type == CycleEventType.period && flowIntensity == null) ||
                      (type == CycleEventType.symptom && (symptomType == null || symptomSeverity == null)) ||
                      (type == CycleEventType.mood && moodType == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final now = DateTime.now();
                    CycleEvent event;
                    
                    switch (type) {
                      case CycleEventType.period:
                        event = CycleEvent.period(
                          eventDate: now,
                          flowIntensity: flowIntensity!,
                          description: notes.isNotEmpty ? notes : null,
                        );
                        break;
                      case CycleEventType.symptom:
                        event = CycleEvent.symptom(
                          eventDate: now,
                          symptomType: symptomType!,
                          severity: symptomSeverity!,
                          description: notes.isNotEmpty ? notes : null,
                        );
                        break;
                      case CycleEventType.mood:
                        event = CycleEvent.mood(
                          eventDate: now,
                          moodType: moodType!,
                          description: notes.isNotEmpty ? notes : null,
                        );
                        break;
                      case CycleEventType.ovulation:
                        event = CycleEvent.ovulation(
                          eventDate: now,
                          description: notes.isNotEmpty ? notes : null,
                        );
                        break;
                      case CycleEventType.medication:
                        event = CycleEvent.medication(
                          eventDate: now,
                          medicationName: 'Unknown',
                          description: notes.isNotEmpty ? notes : null,
                        );
                        break;
                    }
                    
                    await ref.read(menstrualProvider.notifier).addEvent(now, event);
                    if (mounted) {
                      Navigator.pop(context);
                      _showSuccessSnackBar('${type.name.capitalize()} logged successfully');
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorSnackBar('Failed to log ${type.name}: ${e.toString()}');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getTypeColor(type),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getTypeColor(CycleEventType type) {
    switch (type) {
      case CycleEventType.period:
        return Colors.pink;
      case CycleEventType.ovulation:
        return Colors.orange;
      case CycleEventType.symptom:
        return Colors.blue;
      case CycleEventType.mood:
        return Colors.purple;
      case CycleEventType.medication:
        return Colors.green;
    }
  }

  IconData _getTypeIcon(CycleEventType type) {
    switch (type) {
      case CycleEventType.period:
        return Icons.water_drop;
      case CycleEventType.ovulation:
        return Icons.egg;
      case CycleEventType.symptom:
        return Icons.sick;
      case CycleEventType.mood:
        return Icons.mood;
      case CycleEventType.medication:
        return Icons.medication;
    }
  }

  void _showQuickAddDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildQuickAddOption(Icons.water_drop, 'Period', Colors.pink, 
                  () => _openTrackDialog(CycleEventType.period)),
                _buildQuickAddOption(Icons.egg, 'Ovulation', Colors.orange, 
                  () => _openTrackDialog(CycleEventType.ovulation)),
                _buildQuickAddOption(Icons.sick, 'Symptoms', Colors.blue, 
                  () => _openTrackDialog(CycleEventType.symptom)),
                _buildQuickAddOption(Icons.mood, 'Mood', Colors.purple, 
                  () => _openTrackDialog(CycleEventType.mood)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInsightsDialog(CycleAnalysis analysis) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cycle Insights'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (analysis.getInsights().isEmpty)
                const Text('Track more data to get personalized insights')
              else
                ...analysis.getInsights().map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.pink),
                      const SizedBox(width: 12),
                      Expanded(child: Text(insight)),
                    ],
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Settings'),
            Text('Data Export'),
            Text('Privacy Settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    final periodEvents = ref.read(menstrualProvider.notifier).getPeriodEvents();
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Period History'),
        content: SizedBox(
          width: double.maxFinite,
          child: periodEvents.isEmpty
              ? const Text('No period history yet')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: periodEvents.length,
                  itemBuilder: (context, index) {
                    final event = periodEvents[index];
                    return ListTile(
                      title: Text(DateFormat('MMM dd, yyyy').format(event.eventDate)),
                      subtitle: Text('Flow: ${event.flowIntensity?.name ?? 'medium'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await ref.read(menstrualProvider.notifier).deleteEvent(event);
                          if (mounted) {
                            Navigator.pop(context);
                            _showSuccessSnackBar('Period deleted');
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAllTrackingOptions() {
    Navigator.pop(context); // Close any open dialogs first
    _showQuickAddDialog();
  }

  void _showDayEvents(DateTime day, List<CycleEvent>? events) {
    if (events == null || events.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(day),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...events.map((event) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getEventColor(event).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(event.type),
                    color: _getEventColor(event),
                  ),
                ),
                title: Text(event.displayDescription),
                subtitle: Text(
                  DateFormat('h:mm a').format(event.eventDate),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await ref.read(menstrualProvider.notifier).deleteEvent(event);
                    if (mounted) {
                      Navigator.pop(context);
                      _showSuccessSnackBar('Event deleted');
                    }
                  },
                ),
              ),
            )).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}