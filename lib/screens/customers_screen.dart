import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/invoice_detail_sheet.dart';
import '../widgets/ui_components.dart';

enum CustomerSortMode {
  balanceAscending('مبلغ ↑', 'کمترین تا بیشترین'),
  balanceDescending('مبلغ ↓', 'بیشترین تا کمترین'),
  nameAscending('الف ↑', 'الفبا صعودی'),
  nameDescending('الف ↓', 'الفبا نزولی');

  const CustomerSortMode(this.shortLabel, this.description);

  final String shortLabel;
  final String description;
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _query = TextEditingController();
  CustomerSortMode _sortMode = CustomerSortMode.balanceDescending;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<AppController>().dataset!.customers;
    final query = _query.text.trim().toLowerCase();
    final visible = customers.where((customer) {
      return query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query);
    }).toList()..sort(_compareCustomers);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'نام، شماره تلفن مشتری',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'پاک کردن',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _query.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: _sortMode.description,
                child: PopupMenuButton<CustomerSortMode>(
                  tooltip: 'مرتب‌سازی',
                  onSelected: (sortMode) =>
                      setState(() => _sortMode = sortMode),
                  itemBuilder: (context) => CustomerSortMode.values
                      .map(
                        (sortMode) => PopupMenuItem(
                          value: sortMode,
                          child: Row(
                            children: [
                              Icon(
                                sortMode == _sortMode
                                    ? Icons.check_circle
                                    : Icons.sort,
                                size: 18,
                                color: sortMode == _sortMode
                                    ? AppColors.primary
                                    : AppColors.mutedText,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${sortMode.shortLabel} — ${sortMode.description}',
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 8, 0),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 19),
                        const SizedBox(width: 5),
                        Text(_sortMode.shortLabel),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const EmptyListNotice(
                  text: 'مشتری مطابق جست‌وجوی شما پیدا نشد.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 32),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      CustomerCard(customer: visible[index]),
                ),
        ),
      ],
    );
  }

  int _compareCustomers(Customer first, Customer second) {
    switch (_sortMode) {
      case CustomerSortMode.balanceAscending:
        return first.balance.compareTo(second.balance);
      case CustomerSortMode.balanceDescending:
        return second.balance.compareTo(first.balance);
      case CustomerSortMode.nameAscending:
        return first.name.compareTo(second.name);
      case CustomerSortMode.nameDescending:
        return second.name.compareTo(first.name);
    }
  }
}

class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CustomerDetailScreen(customer: customer),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (customer.phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        customer.phone,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'مانده حساب',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(customer.balance, compact: true),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: _balanceColor(customer.balance)),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_left, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final invoices =
        context
            .watch<AppController>()
            .dataset!
            .invoices
            .where((invoice) => invoice.customerId == customer.id)
            .toList()
          ..sort(_compareCustomerInvoicesByNumberDescending);
    final balanceLabel = _balanceLabel(customer.balance);
    final balanceColor = _balanceColor(customer.balance);

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات مشتری')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  if (customer.phone.isEmpty)
                    Text(
                      'شماره تماس ثبت نشده',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.mutedText),
                    )
                  else
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            _openCustomerDialer(context, customer.phone),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 17,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                customer.phone,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 28),
                  Text(
                    'مانده حساب',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        formatMoney(customer.balance),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: balanceColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        balanceLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: balanceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'آخرین به‌روزرسانی: ${formatJalaliDate(customer.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'فاکتورها (${formatNumber(invoices.length)})'),
          const SizedBox(height: 10),
          if (invoices.isEmpty)
            const EmptyListNotice(text: 'فاکتوری برای این مشتری ثبت نشده است.')
          else
            ...invoices.map(
              (invoice) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () => showInvoiceDetailSheet(context, invoice),
                    title: Text(
                      invoice.id,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'تاریخ صدور: ${formatJalaliDate(invoice.issuedAt)}',
                    ),
                    trailing: Text(
                      formatMoney(invoice.total),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _openCustomerDialer(BuildContext context, String phone) async {
  final dialableNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (dialableNumber.isEmpty) return;

  final opened = await launchUrl(Uri(scheme: 'tel', path: dialableNumber));
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('بازکردن برنامه تماس ممکن نشد.')),
    );
  }
}

int _customerInvoiceSequence(String invoiceId) {
  final match = RegExp(r'(\d+)(?!.*\d)').firstMatch(invoiceId);
  return int.tryParse(match?.group(1) ?? '') ?? -1;
}

int _compareCustomerInvoicesByNumberDescending(Invoice first, Invoice second) {
  final byNumber = _customerInvoiceSequence(second.id)
      .compareTo(_customerInvoiceSequence(first.id));
  if (byNumber != 0) return byNumber;
  return second.issuedAt.compareTo(first.issuedAt);
}

String _balanceLabel(int balance) {
  if (balance > 0) return 'بدهی به مشتری';
  if (balance < 0) return 'طلب از مشتری';
  return 'تسویه';
}

Color _balanceColor(int balance) {
  if (balance > 0) return AppColors.danger;
  if (balance < 0) return AppColors.success;
  return AppColors.mutedText;
}
