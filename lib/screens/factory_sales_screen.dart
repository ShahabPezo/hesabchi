import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/factory_sales_calculator.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/jalali_date_field.dart';
import '../widgets/ui_components.dart';

const String _allFactoriesOption = 'همه کارخانه‌ها';
const String _allDriversOption = 'همه راننده‌ها';

List<String> _driverNamesFor(FactorySales factorySales, String factory) {
  final names = <String>{
    for (final entry in factorySales.entries)
      if (entry.driverName.trim().isNotEmpty &&
          (factory == _allFactoriesOption || entry.factoryName == factory))
        entry.driverName,
  }.toList();
  names.sort();
  return names;
}

class FactorySalesScreen extends StatefulWidget {
  const FactorySalesScreen({super.key});

  @override
  State<FactorySalesScreen> createState() => _FactorySalesScreenState();
}

class _FactorySalesScreenState extends State<FactorySalesScreen> {
  String _factory = _allFactoriesOption;
  String _driver = _allDriversOption;
  Jalali? _start;
  Jalali? _end;

  @override
  Widget build(BuildContext context) {
    final factorySales = context.watch<AppController>().dataset!.factorySales;
    if (factorySales.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyListNotice(
          text: 'داده‌ای برای فروش به کارخانه‌ها در این فایل موجود نیست.',
        ),
      );
    }

    final factoryNames = [
      ...{for (final f in factorySales.factories) f.name}..removeWhere(
        (name) => name.trim().isEmpty,
      ),
    ]..sort();
    final driverNamesForFactory = _driverNamesFor(factorySales, _factory);

    final startText = _padDate(_start);
    final endText = _padDate(_end);
    final rows = factorySales.entries.where((entry) {
      final matchesFactory =
          _factory == _allFactoriesOption || entry.factoryName == _factory;
      final matchesDriver =
          _driver == _allDriversOption || entry.driverName == _driver;
      final matchesStart = startText == null || entry.opDate.compareTo(startText) >= 0;
      final matchesEnd = endText == null || entry.opDate.compareTo(endText) <= 0;
      return matchesFactory && matchesDriver && matchesStart && matchesEnd;
    }).toList();

    final factoryStatus = FactoryStatusResult.compute(rows);
    final trailerStatus = TrailerStatusResult.compute(
      rows: rows,
      allEntries: factorySales.entries,
      driverFilter: _driver,
      allDriversOption: _allDriversOption,
      startText: startText,
      endText: endText,
    );
    final invoiceEligible = rows.where((entry) => entry.trailerRent > 0).toList();
    final factoryGroups = <String, List<FactorySalesEntry>>{};
    for (final entry in invoiceEligible) {
      final key = entry.factoryName.trim().isEmpty ? 'نامشخص' : entry.factoryName;
      factoryGroups.putIfAbsent(key, () => []).add(entry);
    }
    final factoryGroupNames = factoryGroups.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'فروش به کارخانه‌ها',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'کارخانه، راننده/کارفرما و بازه‌ی تاریخ را انتخاب کنید.',
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
                DropdownButtonFormField<String>(
                  key: ValueKey('factory_$_factory'),
                  initialValue: _factory,
                  decoration: const InputDecoration(
                    labelText: 'نام کارخانه',
                    prefixIcon: Icon(Icons.factory_outlined),
                  ),
                  items: [_allFactoriesOption, ...factoryNames]
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() {
                    final newFactory = value ?? _allFactoriesOption;
                    _factory = newFactory;
                    final allowedDrivers = _driverNamesFor(
                      factorySales,
                      newFactory,
                    );
                    if (_driver != _allDriversOption &&
                        !allowedDrivers.contains(_driver)) {
                      _driver = _allDriversOption;
                    }
                  }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey('driver_$_factory$_driver'),
                  initialValue: _driver,
                  decoration: const InputDecoration(
                    labelText: 'نام راننده/کارفرما',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [_allDriversOption, ...driverNamesForFactory]
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => _driver = value ?? _allDriversOption),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: JalaliDateField(
                        label: 'از تاریخ',
                        value: _start,
                        onTap: () => _selectDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: JalaliDateField(
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
        const SectionHeader(title: 'وضعیت کارخانه'),
        const SizedBox(height: 8),
        _KeyValueCard(
          rows: [
            _KeyValueRow('جمع وزن ناخالص', formatWeight(factoryStatus.totalGross)),
            _KeyValueRow('جمع وزن خالص', formatWeight(factoryStatus.totalNet)),
            _KeyValueRow(
              'درصد کسر از بار',
              '${toPersianDigits(factoryStatus.moistureLossPct.toStringAsFixed(1))}٪',
            ),
            _KeyValueRow('جمع مبلغ بار', formatMoney(factoryStatus.totalCargo)),
            _KeyValueRow(
              'جمع کرایه تریلی‌ها',
              formatMoney(trailerStatus.balance),
            ),
            _KeyValueRow(
              'فی میانگین اولیه',
              formatMoney(factoryStatus.initialPrice.round()),
            ),
            _KeyValueRow(
              'فی میانگین نهایی بعد از کرایه',
              formatMoney(factoryStatus.finalPrice.round()),
            ),
            _KeyValueRow(
              'جمع واریزی‌های کارخانه',
              formatMoney(factoryStatus.totalDeposits),
            ),
            _KeyValueRow(
              'جمع پرداختی به کارخانه',
              formatMoney(factoryStatus.totalPaid),
            ),
            _KeyValueRow(
              'جمع حساب قبلی کارخانه',
              formatMoney(factoryStatus.totalPrev),
            ),
            _KeyValueRow(
              'حساب جاری کارخانه',
              formatMoney(factoryStatus.currentBalance),
              emphasized: true,
              color: _balanceColor(factoryStatus.currentBalance),
              label: factoryStatus.currentBalance > 0
                  ? 'بدهی به کارخانه'
                  : factoryStatus.currentBalance < 0
                      ? 'طلب از کارخانه'
                      : 'تسویه',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'وضعیت تریلی‌ها'),
        const SizedBox(height: 8),
        _KeyValueCard(
          rows: [
            _KeyValueRow('تعداد تریلی', '${formatNumber(trailerStatus.count)} مورد'),
            _KeyValueRow('جمع کرایه تعیین‌شده', formatMoney(trailerStatus.due)),
            _KeyValueRow(
              'جمع پرداختی به راننده/کارفرما',
              formatMoney(trailerStatus.paid),
            ),
            _KeyValueRow(
              'جمع حساب قبلی',
              formatMoney(trailerStatus.prevBalance),
            ),
            _KeyValueRow(
              'مانده (حساب نهایی)',
              formatMoney(trailerStatus.balance),
              emphasized: true,
              color: _balanceColor(trailerStatus.balance),
              label: trailerStatus.balance > 0
                  ? 'بدهی به راننده‌ها'
                  : trailerStatus.balance < 0
                      ? 'طلب از راننده‌ها'
                      : 'تسویه',
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'لیست فاکتورها (${formatNumber(factoryGroupNames.length)})',
        ),
        const SizedBox(height: 10),
        if (factoryGroupNames.isEmpty)
          const EmptyListNotice(
            text: 'فاکتوری با کرایه‌ی تریلی برای این انتخاب ثبت نشده است.',
          )
        else
          ...factoryGroupNames.map((factoryName) {
            final entries = factoryGroups[factoryName]!
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () =>
                      _openDriverInvoicesScreen(context, factoryName, entries),
                  title: Text(
                    factoryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text('${formatNumber(entries.length)} فاکتور'),
                  trailing: const Icon(Icons.chevron_left),
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final chosen = await showDialog<Jalali>(
      context: context,
      builder: (context) => JalaliDatePickerDialog(initial: current),
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

  static String? _padDate(Jalali? date) {
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static Color _balanceColor(int amount) {
    if (amount > 0) return AppColors.danger;
    if (amount < 0) return AppColors.success;
    return Colors.black87;
  }

  void _openDriverInvoicesScreen(
    BuildContext context,
    String driverName,
    List<FactorySalesEntry> entries,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _DriverInvoicesScreen(driverName: driverName, entries: entries),
      ),
    );
  }
}


class _KeyValueRow {
  const _KeyValueRow(
    this.label,
    this.value, {
    this.emphasized = false,
    this.color,
    this.label2,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? color;
  /// لیبل وضعیت زیر مقدار (مثلاً بدهی / طلب / تسویه)
  final String? label2;
}

class _KeyValueCard extends StatelessWidget {
  const _KeyValueCard({required this.rows});

  final List<_KeyValueRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rows[i].label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                rows[i].value,
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: rows[i].color,
                                    ),
                              ),
                              if (rows[i].label2 != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (rows[i].color ?? Colors.black87)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    rows[i].label2!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: rows[i].color ?? Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != rows.length - 1) const Divider(height: 1),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DriverInvoicesScreen extends StatelessWidget {
  const _DriverInvoicesScreen({
    required this.driverName,
    required this.entries,
  });

  final String driverName;
  final List<FactorySalesEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final factoryNames = {
      for (final entry in entries)
        if (entry.factoryName.trim().isNotEmpty) entry.factoryName,
    }.toList();
    final factoryLabel = factoryNames.isEmpty
        ? 'نامشخص'
        : factoryNames.join('، ');

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات فاکتورها')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کارخانه: $factoryLabel',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'راننده/کارفرما: $driverName',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatNumber(sortedEntries.length)} فاکتور',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: sortedEntries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                return Card(
                  child: ListTile(
                    onTap: () => _showInvoiceDetailSheet(context, entry),
                    title: Text(
                      toPersianDigits(entry.opDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text('شماره فاکتور: ${entry.id}'),
                    trailing: const Icon(Icons.chevron_left),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetailSheet(BuildContext context, FactorySalesEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: SingleChildScrollView(
            child: _DriverInvoiceDetail(entry: entry),
          ),
        ),
      ),
    );
  }
}

class _DriverInvoiceDetail extends StatelessWidget {
  const _DriverInvoiceDetail({required this.entry});

  final FactorySalesEntry entry;

  @override
  Widget build(BuildContext context) {
    final rows = <_KeyValueRow>[
      _KeyValueRow('تاریخ صدور', toPersianDigits(entry.opDate)),
      _KeyValueRow('نوع عملیات', entry.operationType),
      if (entry.plateOrHelper.isNotEmpty)
        _KeyValueRow('پلاک', entry.plateOrHelper),
      _KeyValueRow('وزن ناخالص', formatWeight(entry.grossWeightKg)),
      _KeyValueRow('وزن خالص', formatWeight(entry.netWeightKg)),
      if (entry.packageCount.isNotEmpty)
        _KeyValueRow('تعداد بسته', toPersianDigits(entry.packageCount)),
      _KeyValueRow('قیمت واحد', formatMoney(entry.unitPrice)),
      _KeyValueRow('کرایه', formatMoney(entry.trailerRent)),
      _KeyValueRow(
        'مبلغ کل بعد از کرایه',
        formatMoney(entry.cargoAmount + entry.trailerRent),
        emphasized: true,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.mutedText),
                ),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: row.emphasized
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: row.emphasized ? AppColors.primary : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
