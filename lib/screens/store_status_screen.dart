import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/store_cargo_detail_sheet.dart';
import '../widgets/ui_components.dart';

class StoreStatusScreen extends StatefulWidget {
  const StoreStatusScreen({super.key});

  @override
  State<StoreStatusScreen> createState() => _StoreStatusScreenState();
}

class _StoreStatusScreenState extends State<StoreStatusScreen> {
  StoreStatusStore? _store;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final storeStatus = context.watch<AppController>().dataset!.storeStatus;
    final stores = [...storeStatus.stores]
      ..sort((first, second) => first.name.compareTo(second.name));

    if (stores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyListNotice(
          text: 'داده‌ای برای وضعیت فروشگاه‌ها در این فایل موجود نیست.',
        ),
      );
    }

    final selectedStore = _store ?? stores.first;
    final cargoEntries = storeStatus.cargoEntries
        .where((entry) => entry.storeId == selectedStore.id)
        .toList();
    final filteredEntries =
        cargoEntries.where((entry) {
            final jalali = Jalali.fromDateTime(entry.date);
            return jalali.year == _year && jalali.month == _month;
          }).toList()
          ..sort((first, second) => second.date.compareTo(first.date));
    final totalNetWeight = filteredEntries.fold<num>(
      0,
      (sum, entry) => sum + entry.netWeightKg,
    );
    StoreRentalStatus? rentalStatus;
    for (final status in storeStatus.rentalStatus) {
      if (status.storeId == selectedStore.id) {
        rentalStatus = status;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'وضعیت فروشگاه‌ها',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'فروشگاه و بازه ماهانه را انتخاب کنید.',
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
                DropdownButtonFormField<StoreStatusStore>(
                  key: ValueKey(selectedStore.id),
                  initialValue: selectedStore,
                  decoration: const InputDecoration(
                    labelText: 'نام فروشگاه',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  items: stores
                      .map(
                        (store) => DropdownMenuItem(
                          value: store,
                          child: Text(store.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _store = value),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('month_$_month'),
                        initialValue: _month,
                        decoration: const InputDecoration(labelText: 'ماه'),
                        items: List<int>.generate(12, (index) => index + 1)
                            .map(
                              (month) => DropdownMenuItem(
                                value: month,
                                child: Text(persianMonthNames[month - 1]),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) setState(() => _month = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('year_$_year'),
                        initialValue: _year,
                        decoration: const InputDecoration(labelText: 'سال'),
                        items: _yearOptions()
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(toPersianDigits(year.toString())),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) setState(() => _year = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'جمع کل کارتن'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatWeight(totalNetWeight),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'فاکتورها (${formatNumber(filteredEntries.length)})',
        ),
        const SizedBox(height: 10),
        if (filteredEntries.isEmpty)
          const EmptyListNotice(text: 'برای این ماه فاکتوری ثبت نشده است.')
        else
          ...filteredEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () => showStoreCargoDetailSheet(context, entry),
                  title: Text(
                    formatJalaliDate(entry.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text('وزن خالص: ${formatWeight(entry.netWeightKg)}'),
                  trailing: const Icon(Icons.chevron_left),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'وضعیت اجاره'),
        const SizedBox(height: 10),
        if (rentalStatus == null)
          const EmptyListNotice(
            text: 'این فروشگاه قرارداد اجاره‌ی فعالی ندارد.',
          )
        else
          _RentalStatusCard(rentalStatus: rentalStatus),
      ],
    );
  }

  List<int> _yearOptions() {
    final currentYear = Jalali.now().year;
    return List<int>.generate(currentYear - 1379, (index) => 1380 + index);
  }
}

class _RentalStatusCard extends StatelessWidget {
  const _RentalStatusCard({required this.rentalStatus});

  final StoreRentalStatus rentalStatus;

  @override
  Widget build(BuildContext context) {
    if (rentalStatus.months.isEmpty) {
      return const EmptyListNotice(
        text: 'برای این فروشگاه هنوز وضعیت ماهانه‌ای ثبت نشده است.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: rentalStatus.months
              .map(
                (month) => _RentalMonthRow(
                  month: month,
                  isLast: month == rentalStatus.months.last,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _RentalAmountLine extends StatelessWidget {
  const _RentalAmountLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.mutedText),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _RentalMonthRow extends StatelessWidget {
  const _RentalMonthRow({required this.month, required this.isLast});

  final StoreRentalMonth month;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                toPersianDigits(month.monthLabel),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                month.status,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _RentalAmountLine(
            label: 'اجاره',
            value: formatMoney(month.rentDue.round()),
          ),
          const SizedBox(height: 4),
          _RentalAmountLine(
            label: 'پرداختی',
            value: formatMoney(month.paid.round()),
          ),
          const SizedBox(height: 4),
          _RentalAmountLine(
            label: 'مانده',
            value: formatMoney(month.balance.round()),
            emphasized: true,
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
