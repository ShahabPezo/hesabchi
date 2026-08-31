import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/employee_salary_calculator.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/ui_components.dart';

class EmployeeSalaryScreen extends StatefulWidget {
  const EmployeeSalaryScreen({super.key});

  @override
  State<EmployeeSalaryScreen> createState() => _EmployeeSalaryScreenState();
}

class _EmployeeSalaryScreenState extends State<EmployeeSalaryScreen> {
  EmployeeSalary? _employee;
  Jalali? _start;
  Jalali? _end;

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<AppController>().dataset!.employeeSalaries;
    if (employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyListNotice(
          text: 'داده‌ای برای حقوق افراد در این فایل موجود نیست.',
        ),
      );
    }
    final selected = _employee;
    final summary = selected == null
        ? const EmployeeSalarySummary.empty()
        : EmployeeSalaryCalculator.calculate(
            employee: selected,
            start: _start,
            end: _end,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'وضعیت حقوق',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'کارمند و بازه زمانی را انتخاب کنید.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<EmployeeSalary>(
                  key: ValueKey(selected?.name ?? 'employee'),
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'نام کارمند',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee,
                          child: Text(employee.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _employee = value),
                ),
                if (selected?.phone.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'شماره تماس: ${toPersianDigits(selected!.phone)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'از تاریخ',
                        value: _start,
                        onTap: () => _selectDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'تا تاریخ',
                        value: _end,
                        onTap: () => _selectDate(isStart: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'محاسبه حقوق'),
        const SizedBox(height: 8),
        _SalaryCard(
          children: [
            _SalaryRow(
              label: 'حقوق ماهیانه',
              value: formatDirectToman(summary.baseSalary),
            ),
            _SalaryRow(
              label: 'حقوق روزانه',
              value: formatDirectToman(summary.dailySalaryDisplay),
            ),
            _SalaryRow(
              label: 'روزهای تعطیل',
              value: '${formatNumber(summary.holidays)} روز',
            ),
            _SalaryRow(
              label: 'روزهای سرویس اضافه',
              value: '${formatNumber(summary.extraDays)} روز',
            ),
            _SalaryRow(
              label: 'روزهای کاری',
              value: '${formatNumber(summary.workDays)} روز',
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'وضعیت حساب'),
        const SizedBox(height: 8),
        _SalaryCard(
          children: [
            _SalaryRow(
              label: 'حقوق برای تسویه',
              value: formatDirectToman(summary.currentSalary),
            ),
            _SalaryRow(
              label: 'جمع واریزی',
              value: formatDirectToman(summary.deposits),
            ),
            _SalaryRow(
              label: 'حساب آخرین تسویه',
              value: formatDirectToman(summary.lastSettleBalance),
            ),
            _SalaryRow(
              label: 'حساب قبلی',
              value: formatDirectToman(summary.previousBalance),
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _FinalSettlementCard(summary: summary, employeeName: selected?.name),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final chosen = await showDialog<Jalali>(
      context: context,
      builder: (context) => _JalaliDatePickerDialog(initial: current),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = chosen;
      } else {
        _end = chosen;
      }
    });
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
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

class _JalaliDatePickerDialog extends StatefulWidget {
  const _JalaliDatePickerDialog({this.initial});

  final Jalali? initial;

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
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

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    ),
  );
}

class _SalaryRow extends StatelessWidget {
  const _SalaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      if (!isLast) const Divider(height: 1),
    ],
  );
}

class _FinalSettlementCard extends StatelessWidget {
  const _FinalSettlementCard({
    required this.summary,
    required this.employeeName,
  });

  final EmployeeSalarySummary summary;
  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (summary.settlementKind) {
      EmployeeSettlementKind.settled => (Colors.black87, 'تسویه'),
      EmployeeSettlementKind.payable => (
        AppColors.danger,
        'بدهی به ${employeeName ?? 'کارمند'}',
      ),
      EmployeeSettlementKind.receivable => (
        AppColors.success,
        'طلب از ${employeeName ?? 'کارمند'}',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'وضعیت نهایی',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            formatDirectToman(summary.settlement),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
