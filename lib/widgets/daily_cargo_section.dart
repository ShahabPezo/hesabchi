import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/daily_cargo_status.dart';
import '../data/models.dart';
import 'ui_components.dart';

/// بخش «وضعیت روزانه کارتن» در بالای تب آمار.
/// با تغییر روز/ماه/سال، اعداد بلافاصله از داده‌ی ذخیره‌شده دوباره حساب می‌شوند.
class DailyCargoSection extends StatelessWidget {
  const DailyCargoSection({
    super.key,
    required this.dataset,
    required this.day,
    required this.onDayChanged,
  });

  final BusinessDataset dataset;
  final Jalali day;
  final ValueChanged<Jalali> onDayChanged;

  static String _dateText(Jalali day) =>
      '${day.year.toString().padLeft(4, '0')}/'
      '${day.month.toString().padLeft(2, '0')}/'
      '${day.day.toString().padLeft(2, '0')}';

  /// فاکتورهای مشتری فقط تا بازه‌ی فایل HCH در دسترس‌اند.
  static bool _isOutOfScope(InvoiceScope scope, Jalali day) {
    if (scope.type != InvoiceScopeType.range) return false;
    final text = _dateText(day);
    final start = scope.startDate;
    final end = scope.endDate;
    return (start != null && text.compareTo(start) < 0) ||
        (end != null && text.compareTo(end) > 0);
  }

  void _change({int? year, int? month, int? dayOfMonth}) {
    final newYear = year ?? day.year;
    final newMonth = month ?? day.month;
    final maxDay = Jalali(newYear, newMonth, 1).monthLength;
    final wanted = dayOfMonth ?? day.day;
    onDayChanged(Jalali(newYear, newMonth, wanted > maxDay ? maxDay : wanted));
  }

  Widget _dropdown({
    required String label,
    required int value,
    required List<int> options,
    required String Function(int) text,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey('daily_${label}_$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((item) => DropdownMenuItem(value: item, child: Text(text(item))))
          .toList(growable: false),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = computeDailyCargoStatus(
      day: day,
      invoices: dataset.invoices,
      storeEntries: dataset.storeStatus.cargoEntries,
    );
    final currentYear = Jalali.now().year;
    final years = List<int>.generate(
      currentYear - 1379,
      (index) => 1380 + index,
    );
    final monthLength = Jalali(day.year, day.month, 1).monthLength;
    final mutedStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'وضعیت روزانه کارتن'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'روز',
                        value: day.day,
                        options: List<int>.generate(
                          monthLength,
                          (index) => index + 1,
                        ),
                        text: (value) => toPersianDigits(value.toString()),
                        onChanged: (value) => _change(dayOfMonth: value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _dropdown(
                        label: 'ماه',
                        value: day.month,
                        options: List<int>.generate(12, (index) => index + 1),
                        text: (value) => persianMonthNames[value - 1],
                        onChanged: (value) => _change(month: value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _dropdown(
                        label: 'سال',
                        value: day.year,
                        options: years,
                        text: (value) => toPersianDigits(value.toString()),
                        onChanged: (value) => _change(year: value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  toPersianDigits(_dateText(day)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isOutOfScope(dataset.scope, day)) ...[
                  const SizedBox(height: 8),
                  Text(
                    'این تاریخ خارج از بازه‌ی فاکتورهای فایل است؛ '
                    'فاکتورهای مشتریِ آن روز در فایل نیست.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                ],
                const Divider(height: 28),
                if (!status.hasData)
                  Text(
                    'داده‌ای ثبت نشده',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  )
                else ...[
                  _DailyLine(
                    label: 'وزن بار فروشگاه',
                    value: formatWeight(status.storeWeight),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  _DailyLine(
                    label: 'وزن ناخالص مشتری',
                    value: formatWeight(status.customerGross),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  _DailyLine(
                    label: 'وزن خالص مشتری',
                    value: formatWeight(status.customerNet),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  _DailyLine(
                    label: 'جمع رطوبت کسرشده',
                    value: formatWeight(status.moisture),
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 10),
                  _DailyLine(
                    label: 'مبلغ بار',
                    value: formatMoney(status.cargoAmount),
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 10),
                  _DailyLine(
                    label: 'فی میانگین مشتری (هر کیلو)',
                    value: formatMoney(status.avgPrice.round()),
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 10),
                  _DailyLine(
                    label: 'مجموع وزن روز',
                    value: formatWeight(status.totalWeight),
                    color: AppColors.primary,
                    emphasized: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'محاسبه از '
                    '${toPersianDigits(status.customerInvoiceCount.toString())} '
                    'فاکتور ورود کارتن مشتری و '
                    '${toPersianDigits(status.storeEntryCount.toString())} '
                    'ورود کارتن فروشگاه',
                    style: mutedStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyLine extends StatelessWidget {
  const _DailyLine({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
