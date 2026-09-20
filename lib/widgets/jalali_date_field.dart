import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../core/formatters.dart';

class JalaliDateField extends StatelessWidget {
  const JalaliDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final Jalali? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? label
        : toPersianDigits(
            '${value!.year.toString().padLeft(4, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.day.toString().padLeft(2, '0')}',
          );
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined, size: 19),
      label: Text(text, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerRight,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 8, 0),
      ),
    );
  }
}

class JalaliDatePickerDialog extends StatefulWidget {
  const JalaliDatePickerDialog({super.key, this.initial});

  final Jalali? initial;

  @override
  State<JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<JalaliDatePickerDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? Jalali.now();
    _year = initial.year;
    _month = initial.month;
    _day = initial.day;
  }

  int get _monthLength => Jalali(_year, _month, 1).monthLength;

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(
      Jalali.now().year - 1379,
      (index) => 1380 + index,
    );
    return AlertDialog(
      title: const Text('انتخاب تاریخ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey('year_$_year'),
            initialValue: _year,
            decoration: const InputDecoration(labelText: 'سال'),
            items: years
                .map(
                  (year) => DropdownMenuItem(
                    value: year,
                    child: Text(toPersianDigits(year.toString())),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _year = value;
                _day = _day.clamp(1, _monthLength).toInt();
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('month_$_year$_month'),
            initialValue: _month,
            decoration: const InputDecoration(labelText: 'ماه'),
            items: List<int>.generate(12, (index) => index + 1)
                .map(
                  (month) => DropdownMenuItem(
                    value: month,
                    child: Text(toPersianDigits(month.toString())),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _month = value;
                _day = _day.clamp(1, _monthLength).toInt();
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('day_$_year$_month$_day'),
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'روز'),
            items: List<int>.generate(_monthLength, (index) => index + 1)
                .map(
                  (day) => DropdownMenuItem(
                    value: day,
                    child: Text(toPersianDigits(day.toString())),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) setState(() => _day = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(Jalali(_year, _month, _day)),
          child: const Text('تأیید'),
        ),
      ],
    );
  }
}
