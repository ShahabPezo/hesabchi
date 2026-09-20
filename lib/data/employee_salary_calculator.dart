import 'package:shamsi_date/shamsi_date.dart';

import 'models.dart';

enum EmployeeSettlementKind { settled, payable, receivable }

class EmployeeSalarySummary {
  const EmployeeSalarySummary({
    required this.baseSalary,
    required this.dailySalaryDisplay,
    required this.holidays,
    required this.extraDays,
    required this.workDays,
    required this.currentSalary,
    required this.deposits,
    required this.lastSettleBalance,
    required this.previousBalance,
    required this.settlement,
  });

  const EmployeeSalarySummary.empty()
    : baseSalary = 0,
      dailySalaryDisplay = 0,
      holidays = 0,
      extraDays = 0,
      workDays = 0,
      currentSalary = 0,
      deposits = 0,
      lastSettleBalance = 0,
      previousBalance = 0,
      settlement = 0;

  final int baseSalary;
  final int dailySalaryDisplay;
  final int holidays;
  final double extraDays;
  final double workDays;
  final int currentSalary;
  final int deposits;
  final int lastSettleBalance;
  final int previousBalance;
  final int settlement;

  EmployeeSettlementKind get settlementKind => switch (settlement) {
    0 => EmployeeSettlementKind.settled,
    > 0 => EmployeeSettlementKind.payable,
    _ => EmployeeSettlementKind.receivable,
  };
}

class EmployeeEmploymentClampResult {
  const EmployeeEmploymentClampResult({
    required this.start,
    required this.end,
    this.message,
  });

  final Jalali? start;
  final Jalali? end;
  final String? message;
}

class EmployeeSalaryCalculator {
  const EmployeeSalaryCalculator._();

  static Jalali? parseJalaliOrNull(String? text) {
    if (text == null) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    try {
      return Jalali(year, month, day);
    } on Object {
      return null;
    }
  }

  /// اگر بازه‌ی انتخابی از محدوده‌ی همکاری کارمند (تاریخ شروع/پایان کار) بیرون بزند،
  /// آن را به مرز مجاز محدود می‌کند و پیام توضیحی برمی‌گرداند؛ در غیر این صورت بازه
  /// را بدون تغییر برمی‌گرداند (message خالی).
  static EmployeeEmploymentClampResult clampToEmployment({
    required EmployeeSalary employee,
    required Jalali? start,
    required Jalali? end,
  }) {
    final hireDate = parseJalaliOrNull(employee.hireDate);
    final terminationDate = parseJalaliOrNull(employee.terminationDate);
    var clampedStart = start;
    var clampedEnd = end;
    final messages = <String>[];

    if (clampedStart != null &&
        hireDate != null &&
        clampedStart.julianDayNumber < hireDate.julianDayNumber) {
      clampedStart = hireDate;
      messages.add(
        'شروع همکاری ${employee.name} از تاریخ ${employee.hireDate} بوده؛ '
        'تاریخ ابتدا به همان روز تنظیم شد.',
      );
    }
    if (clampedEnd != null &&
        terminationDate != null &&
        clampedEnd.julianDayNumber > terminationDate.julianDayNumber) {
      clampedEnd = terminationDate;
      messages.add(
        'همکاری ${employee.name} در تاریخ ${employee.terminationDate} '
        'پایان یافته؛ تاریخ انتها به همان روز تنظیم شد.',
      );
    }

    return EmployeeEmploymentClampResult(
      start: clampedStart,
      end: clampedEnd,
      message: messages.isEmpty ? null : messages.join(' '),
    );
  }

  static EmployeeSalarySummary calculate({
    required EmployeeSalary employee,
    required Jalali? start,
    required Jalali? end,
  }) {
    if (start == null ||
        end == null ||
        end.julianDayNumber < start.julianDayNumber) {
      return const EmployeeSalarySummary.empty();
    }

    final profile = _latestProfile(
      employee.profileHistory,
      start: start,
      end: end,
      dateOf: (item) => item.actionDate,
      hasValue: (item) => item.baseSalary != null,
    );
    final baseSalary = profile?.baseSalary ?? 0;
    final dailySalaryExact = baseSalary / 30;
    final dailySalaryDisplay = ((dailySalaryExact / 1000).round()) * 1000;

    final holidays = _countInRange(employee.offdays, start, end);
    final extraCount = _countInRange(employee.extraServices, start, end);
    final extraDays = ((extraCount / 2) * 10).round() / 10;
    final totalDays = end.julianDayNumber - start.julianDayNumber + 1;
    final workDays = totalDays - holidays + extraDays;
    final currentSalary = (workDays * dailySalaryExact).round();

    final deposits = employee.deposits
        .where((item) {
          final key = item.billingYear * 12 + item.billingMonth;
          final startKey = start.year * 12 + start.month;
          final endKey = end.year * 12 + end.month;
          return key >= startKey && key <= endKey;
        })
        .fold<int>(0, (sum, item) => sum + item.amount);

    final lastSettleProfile = _latestProfile(
      employee.profileHistory,
      start: start,
      end: end,
      dateOf: (item) => item.lastSettleDate ?? '',
      hasValue: (item) =>
          item.lastBalance != null &&
          item.lastSettleDate != null &&
          item.lastSettleDate!.isNotEmpty,
    );
    final lastSettleBalance = lastSettleProfile?.lastBalance ?? 0;
    final previousBalance = employee.previousAccountEntries
        .where((item) => _isInRange(_parse(item.date), start, end))
        .fold<int>(0, (sum, item) => sum + item.amount);
    final settlement =
        currentSalary - deposits + previousBalance + lastSettleBalance;

    return EmployeeSalarySummary(
      baseSalary: baseSalary,
      dailySalaryDisplay: dailySalaryDisplay,
      holidays: holidays,
      extraDays: extraDays,
      workDays: workDays,
      currentSalary: currentSalary,
      deposits: deposits,
      lastSettleBalance: lastSettleBalance,
      previousBalance: previousBalance,
      settlement: settlement,
    );
  }

  static EmployeeProfileHistory? _latestProfile(
    List<EmployeeProfileHistory> profiles, {
    required Jalali start,
    required Jalali end,
    required String Function(EmployeeProfileHistory item) dateOf,
    required bool Function(EmployeeProfileHistory item) hasValue,
  }) {
    final previousStartDay = start - 1;
    EmployeeProfileHistory? selected;
    var selectedDay = -1;
    for (final profile in profiles) {
      if (!hasValue(profile)) continue;
      final date = _parse(dateOf(profile));
      final day = date.julianDayNumber;
      final eligible =
          _isInRange(date, start, end) ||
          day == previousStartDay.julianDayNumber;
      if (eligible && day >= selectedDay) {
        selected = profile;
        selectedDay = day;
      }
    }
    return selected;
  }

  static int _countInRange(
    List<EmployeeSalaryDatedEntry> values,
    Jalali start,
    Jalali end,
  ) => values.where((item) => _isInRange(_parse(item.date), start, end)).length;

  static bool _isInRange(Jalali date, Jalali start, Jalali end) =>
      date.julianDayNumber >= start.julianDayNumber &&
      date.julianDayNumber <= end.julianDayNumber;

  static Jalali _parse(String text) {
    final parts = text.split('/');
    return Jalali(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
