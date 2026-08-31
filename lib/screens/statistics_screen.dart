import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/ui_components.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? _selectedMonthKey;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppController>().dataset!;
    final statuses = data.monthlyStatuses;
    if (statuses.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'داده‌ای برای آمار ماهانه موجود نیست',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'برای مشاهده وضعیت ماهانه، فایل HCH جدیدی را که شامل داده آمار ماهانه است وارد کنید.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: widget.onImport,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('ورود فایل HCH جدید'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final selected = _selectedStatus(statuses);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _MonthSelector(
          statuses: statuses,
          selected: selected,
          onChanged: (key) => setState(() => _selectedMonthKey = key),
        ),
        const SizedBox(height: 10),
        Text(
          'بر پایه خروجی: ${toPersianDigits(data.scope.displayText)}',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'وضعیت ماهانه بار تفکیکی'),
        const SizedBox(height: 10),
        _StatisticsDetailCard(
          title: 'وضعیت بار مشتری',
          icon: Icons.local_shipping_outlined,
          color: AppColors.primary,
          rows: [
            _StatisticsRow(
              'مجموع وزن ناخالص مشتری',
              formatWeight(selected.cargoCustomer.customerGrossWeight),
            ),
            _StatisticsRow(
              'مجموع وزن خالص مشتری',
              formatWeight(selected.cargoCustomer.customerNetWeight),
            ),
            _StatisticsRow(
              'مجموع مبلغ بار مشتری',
              formatDirectToman(selected.cargoCustomer.cargoAmount),
            ),
            _StatisticsRow(
              'درصد کسر بار',
              formatPercent(selected.cargoCustomer.moisturePercent),
            ),
            _StatisticsRow(
              'مجموع وزن کاغذ خروجی',
              formatWeight(selected.cargoCustomer.paperWeight),
            ),
            _StatisticsRow(
              'مجموع وزن مشتری',
              formatWeight(selected.cargoCustomer.customerWeight),
            ),
            _StatisticsRow(
              'فی کارتن مشتری',
              _priceOrDash(
                selected.cargoCustomer.customerPrice,
                selected.cargoCustomer.customerWeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatisticsDetailCard(
          title: 'وضعیت بار فروشگاه',
          icon: Icons.storefront_outlined,
          color: AppColors.warning,
          rows: [
            _StatisticsRow(
              'مجموع وزن خالص فروشگاهی',
              formatWeight(selected.cargoStore.storeNetWeight),
            ),
            _StatisticsRow(
              'مجموع اجاره فروشگاه‌ها',
              formatDirectToman(selected.cargoStore.storeRentTotal),
            ),
            _StatisticsRow(
              'مجموع وزن نایلون خروجی',
              formatWeight(selected.cargoStore.nylonWeight),
            ),
            _StatisticsRow(
              'مجموع وزن پلاستیک خروجی',
              formatWeight(selected.cargoStore.plasticWeight),
            ),
            _StatisticsRow(
              'مجموع وزن گونی خروجی',
              formatWeight(selected.cargoStore.guniWeight),
            ),
            _StatisticsRow(
              'مجموع وزن کارتن فروشگاهی',
              formatWeight(selected.cargoStore.storeCartonWeight),
            ),
            _StatisticsRow(
              'فی کارتن فروشگاهی',
              _priceOrDash(
                selected.cargoStore.storeCartonPrice,
                selected.cargoStore.storeCartonWeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'وضعیت کلی ماهانه'),
        const SizedBox(height: 10),
        _OverallSummaryCard(status: selected),
        const SizedBox(height: 24),
        SectionHeader(
          title: '۵ مشتری برتر ${toPersianDigits(selected.monthLabel)}',
        ),
        const SizedBox(height: 10),
        _TopCustomersCard(customers: selected.topCustomers),
        const SizedBox(height: 22),
        Text(
          'این آمار یک تصویر از لحظه خروجی‌گرفتن فایل HCH است: ${formatJalaliDate(data.exportedAt, withTime: true)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }

  MonthlyStatus _selectedStatus(List<MonthlyStatus> statuses) {
    final key = _selectedMonthKey;
    if (key != null) {
      for (final status in statuses) {
        if (_monthKey(status) == key) return status;
      }
    }
    return statuses.last;
  }
}

String _monthKey(MonthlyStatus status) => '${status.year}-${status.month}';

String _priceOrDash(num price, num baseWeight) =>
    baseWeight > 0 ? '${formatDirectToman(price.round())} / کیلو' : '—';

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.statuses,
    required this.selected,
    required this.onChanged,
  });

  final List<MonthlyStatus> statuses;
  final MonthlyStatus selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وضعیت ماهانه',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'انتخاب ماه گزارش',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 112,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _monthKey(selected),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: _monthKey(status),
                          child: Text(
                            toPersianDigits(status.monthLabel),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsDetailCard extends StatelessWidget {
  const _StatisticsDetailCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_StatisticsRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.expand(
              (row) => [
                _StatisticsValueRow(row: row),
                if (row != rows.last) const Divider(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsRow {
  const _StatisticsRow(this.label, this.value);

  final String label;
  final String value;
}

class _StatisticsValueRow extends StatelessWidget {
  const _StatisticsValueRow({required this.row});

  final _StatisticsRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            row.label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            row.value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _OverallSummaryCard extends StatelessWidget {
  const _OverallSummaryCard({required this.status});

  final MonthlyStatus status;

  @override
  Widget build(BuildContext context) {
    final overall = status.overallTotals;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryMetric(
                  width: itemWidth,
                  label: 'مجموع وزن مشتری',
                  value: formatWeight(overall.customerWeight),
                  icon: Icons.groups_2_outlined,
                  color: AppColors.primary,
                ),
                _SummaryMetric(
                  width: itemWidth,
                  label: 'وزن کارتن فروشگاهی',
                  value: formatWeight(overall.storeCartonWeight),
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.warning,
                ),
                _SummaryMetric(
                  width: itemWidth,
                  label: 'خالص کارتن ورودی',
                  value: formatWeight(overall.netInputCarton),
                  icon: Icons.move_to_inbox_outlined,
                  color: AppColors.success,
                ),
                _SummaryMetric(
                  width: itemWidth,
                  label: 'فی کارتن ورودی',
                  value: _priceOrDash(
                    overall.inputCartonPrice,
                    overall.netInputCarton,
                  ),
                  icon: Icons.sell_outlined,
                  color: AppColors.navy,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _TopCustomersCard extends StatelessWidget {
  const _TopCustomersCard({required this.customers});

  final List<MonthlyTopCustomer> customers;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const EmptyListNotice(
        text: 'مشتری برتری برای این ماه ثبت نشده است.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: customers
              .map(
                (customer) => _TopCustomerRow(
                  customer: customer,
                  isLast: customer == customers.last,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _TopCustomerRow extends StatelessWidget {
  const _TopCustomerRow({required this.customer, required this.isLast});

  final MonthlyTopCustomer customer;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final progress = (customer.percent / 100).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formatNumber(customer.rank),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatWeight(customer.netWeight),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatPercent(customer.percent),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Divider(height: 1),
            ),
        ],
      ),
    );
  }
}
