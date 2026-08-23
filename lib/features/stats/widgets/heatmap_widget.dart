import 'package:flutter/material.dart';

class HeatmapWidget extends StatefulWidget {
  final Map<DateTime, int> data;

  const HeatmapWidget({
    super.key,
    required this.data,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to the end (today) after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Normalizes dates to strip time
  DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    final today = _normalizeDate(DateTime.now());
    // 364 days ago represents 52 full weeks + current week
    final startDate = today.subtract(const Duration(days: 364));
    // Find the Monday before or on startDate
    final firstMonday = startDate.subtract(Duration(days: startDate.weekday - 1));

    // Generate days in columns of 7 (Monday to Sunday)
    final List<List<DateTime>> weeks = [];
    DateTime currentDay = firstMonday;

    while (currentDay.isBefore(today.add(const Duration(days: 1)))) {
      final List<DateTime> week = [];
      for (int i = 0; i < 7; i++) {
        week.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STUDY ACTIVITY (365 DAYS)',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: onSurfaceVariant,
              ),
            ),
            Text(
              '${widget.data.values.fold(0, (sum, val) => sum + val)} total reviews',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: onSurface.withOpacity(0.05)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday labels column
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  SizedBox(height: 16), // space for month labels
                  _WeekdayLabel('M'),
                  SizedBox(height: 12),
                  _WeekdayLabel('W'),
                  SizedBox(height: 12),
                  _WeekdayLabel('F'),
                ],
              ),
              const SizedBox(width: 8),
              // Heatmap grid scroll view
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month labels row
                      Row(
                        children: weeks.asMap().entries.map((entry) {
                          final i = entry.key;
                          final week = entry.value;
                          final firstDay = week.first;
                          // Show month label if it's the start of a month or first week
                          final isFirstOfNewMonth = i == 0 ||
                              (i > 0 && firstDay.month != weeks[i - 1].first.month && firstDay.day <= 7);

                          return SizedBox(
                            width: 14.0, // 10px box + 4px margin
                            child: isFirstOfNewMonth
                                ? Transform.translate(
                                    offset: const Offset(0, -2),
                                    child: Text(
                                      _getMonthAbbr(firstDay.month),
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface.withOpacity(0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      // Heatmap blocks
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: weeks.map((week) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Column(
                              children: week.map((date) {
                                final isAfterToday = date.isAfter(today);
                                final count = widget.data[_normalizeDate(date)] ?? 0;

                                Color cellColor = surfaceContainer;
                                if (isAfterToday) {
                                  cellColor = Colors.transparent;
                                } else if (count > 0) {
                                  if (count <= 3) {
                                    cellColor = primaryGold.withOpacity(0.25);
                                  } else if (count <= 8) {
                                    cellColor = primaryGold.withOpacity(0.50);
                                  } else if (count <= 15) {
                                    cellColor = primaryGold.withOpacity(0.75);
                                  } else {
                                    cellColor = primaryGold;
                                  }
                                }

                                return Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(bottom: 4.0),
                                  decoration: BoxDecoration(
                                    color: cellColor,
                                    borderRadius: BorderRadius.circular(2),
                                    border: isAfterToday
                                        ? null
                                        : Border.all(
                                            color: count > 0
                                                ? Colors.transparent
                                                : onSurface.withOpacity(0.03),
                                          ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String char;

  const _WeekdayLabel(this.char, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 9,
            color: const Color(0xFFE7E2DA).withOpacity(0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
