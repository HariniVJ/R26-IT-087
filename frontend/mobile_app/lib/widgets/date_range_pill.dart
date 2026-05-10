// lib/widgets/date_range_pill.dart
// UI redesigned to match pomegranate app style (white bg, red accents)
// All logic preserved exactly.

import 'package:flutter/material.dart';

enum DateRange { today, week, month, year, all }

extension DateRangeLabel on DateRange {
  String get label {
    switch (this) {
      case DateRange.today:
        return 'Today';
      case DateRange.week:
        return 'This Week';
      case DateRange.month:
        return 'This Month';
      case DateRange.year:
        return 'This Year';
      case DateRange.all:
        return 'All Time';
    }
  }

  bool contains(DateTime date) {
    final now = DateTime.now();
    switch (this) {
      case DateRange.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case DateRange.week:
        return now.difference(date).inDays <= 7;
      case DateRange.month:
        return now.difference(date).inDays <= 30;
      case DateRange.year:
        return now.difference(date).inDays <= 365;
      case DateRange.all:
        return true;
    }
  }
}

class DateRangePill extends StatelessWidget {
  final DateRange selected;
  final ValueChanged<DateRange> onChanged;

  static const _red = Color(0xFFC1121F);
  static const _redLight = Color(0xFFFFEEEE);
  static const _textDark = Color(0xFF1F2937);
  static const _border = Color(0xFFE5E7EB);

  const DateRangePill({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _redLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _red.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 11, color: _red),
            const SizedBox(width: 5),
            Text(
              selected.label,
              style: const TextStyle(
                color: _red,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: _red,
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Period',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...DateRange.values.map(
                (r) => ListTile(
                  leading: Icon(
                    _iconFor(r),
                    color: selected == r ? _red : const Color(0xFF9CA3AF),
                  ),
                  title: Text(
                    r.label,
                    style: TextStyle(
                      color: selected == r ? _red : _textDark,
                      fontWeight: selected == r
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: selected == r
                      ? const Icon(Icons.check_rounded, color: _red)
                      : null,
                  onTap: () {
                    onChanged(r);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(DateRange r) {
    switch (r) {
      case DateRange.today:
        return Icons.today_rounded;
      case DateRange.week:
        return Icons.view_week_rounded;
      case DateRange.month:
        return Icons.calendar_month_rounded;
      case DateRange.year:
        return Icons.event_rounded;
      case DateRange.all:
        return Icons.all_inclusive_rounded;
    }
  }
}
