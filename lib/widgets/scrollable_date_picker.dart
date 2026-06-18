import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<DateTime?> showScrollableDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _ScrollableDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now(),
    ),
  );
}

class _ScrollableDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _ScrollableDatePickerDialog({
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_ScrollableDatePickerDialog> createState() => _ScrollableDatePickerDialogState();
}

class _ScrollableDatePickerDialogState extends State<_ScrollableDatePickerDialog> {
  DateTime? _pickedDate;

  void _onDateSelected(DateTime date) {
    _pickedDate = date;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Date',
            style: AppTheme.subHeading.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.textHint.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScrollableDatePicker(
            initialDate: widget.initialDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onDateSelected: _onDateSelected,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context, _pickedDate),
                child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollableDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const ScrollableDatePicker({
    super.key,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  State<ScrollableDatePicker> createState() => _ScrollableDatePickerState();
}

class _ScrollableDatePickerState extends State<ScrollableDatePicker> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int get daysInMonth {
    return DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDay = initial.day.clamp(1, 31);
    _selectedMonth = initial.month;
    _selectedYear = initial.year;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: _selectedYear - widget.firstDate.year);
    widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yearCount = widget.lastDate.year - widget.firstDate.year + 1;

    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildColumn(
              controller: _dayController,
              items: List.generate(31, (i) => '${i + 1}'),
              onChanged: (i) {
                final day = i + 1;
                final maxDay = daysInMonth;
                setState(() {
                  _selectedDay = day.clamp(1, maxDay);
                });
                _dayController.jumpToItem(_selectedDay - 1);
                widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
              },
            ),
          ),
          Expanded(
            child: _buildColumn(
              controller: _monthController,
              items: monthNames,
              onChanged: (i) {
                setState(() {
                  _selectedMonth = i + 1;
                  _selectedDay = _selectedDay.clamp(1, daysInMonth);
                });
                _dayController.jumpToItem(_selectedDay - 1);
                widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
              },
            ),
          ),
          Expanded(
            child: _buildColumn(
              controller: _yearController,
              items: List.generate(yearCount, (i) => '${widget.firstDate.year + i}'),
              onChanged: (i) {
                setState(() {
                  _selectedYear = widget.firstDate.year + i;
                  final maxDay = daysInMonth;
                  if (_selectedDay > maxDay) {
                    _selectedDay = maxDay;
                    _dayController.jumpToItem(_selectedDay - 1);
                  }
                });
                widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required FixedExtentScrollController controller,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return Stack(
      children: [
        ListWheelScrollView(
          controller: controller,
          itemExtent: 40,
          diameterRatio: 1.5,
          useMagnifier: true,
          magnification: 1.1,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onChanged,
          children: items.map((item) {
            return Center(
              child: Text(
                item,
                style: AppTheme.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 90,
          child: IgnorePointer(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
                  bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
