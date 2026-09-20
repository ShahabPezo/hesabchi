import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/ui_components.dart';

enum InvoiceSearchScope {
  all('همه'),
  customer('نام مشتری'),
  invoiceNumber('شماره فاکتور');

  const InvoiceSearchScope(this.label);

  final String label;
}

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _query = TextEditingController();
  InvoiceSearchScope _searchScope = InvoiceSearchScope.all;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.text.trim().toLowerCase();
    final invoices = context.watch<AppController>().dataset!.invoices.where((
      invoice,
    ) {
      if (query.isEmpty) return true;
      return switch (_searchScope) {
        InvoiceSearchScope.all =>
          invoice.id.toLowerCase().contains(query) ||
              invoice.customerName.toLowerCase().contains(query),
        InvoiceSearchScope.customer =>
          invoice.customerName.toLowerCase().contains(query),
        InvoiceSearchScope.invoiceNumber => invoice.id.toLowerCase().contains(
          query,
        ),
      };
    }).toList()..sort(_compareInvoicesByNumberDescending);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _searchScope == InvoiceSearchScope.customer
                  ? 'جست‌وجوی نام مشتری'
                  : _searchScope == InvoiceSearchScope.invoiceNumber
                  ? 'جست‌وجوی شماره فاکتور'
                  : 'جست‌وجوی نام مشتری یا شماره فاکتور',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'پاک کردن',
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: InvoiceSearchScope.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final scope = InvoiceSearchScope.values[index];
              return FilterChip(
                label: Text(scope.label),
                selected: _searchScope == scope,
                showCheckmark: false,
                onSelected: (_) => setState(() => _searchScope = scope),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _searchScope == scope
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : null,
                ),
                side: BorderSide(
                  color: _searchScope == scope
                      ? Colors.transparent
                      : AppColors.outline,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: invoices.isEmpty
              ? const EmptyListNotice(
                  text: 'فاکتوری مطابق جست‌وجوی شما پیدا نشد.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: invoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      InvoiceCard(invoice: invoices[index]),
                ),
        ),
      ],
    );
  }
}

int _invoiceSequence(String invoiceId) {
  final match = RegExp(r'(\d+)(?!.*\d)').firstMatch(invoiceId);
  return int.tryParse(match?.group(1) ?? '') ?? -1;
}

int _compareInvoicesByNumberDescending(Invoice first, Invoice second) {
  final byNumber = _invoiceSequence(second.id)
      .compareTo(_invoiceSequence(first.id));
  if (byNumber != 0) return byNumber;
  return second.issuedAt.compareTo(first.issuedAt);
}

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({super.key, required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InvoiceDetailScreen(invoice: invoice),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '${invoice.id} • ${formatJalaliDate(invoice.issuedAt)}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.mutedText),
              ),
              const Divider(height: 22),
              _AmountInfo(
                label: 'مبلغ فاکتور',
                value: formatMoney(invoice.total),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountInfo extends StatelessWidget {
  const _AmountInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final item = invoice.items.isEmpty ? null : invoice.items.first;
    final operationType = item?.title.trim().isNotEmpty == true
        ? item!.title
        : 'ثبت نشده';
    final grossWeight = item?.grossWeight;
    final netWeight = item == null ? 'ثبت نشده' : formatNumber(item.quantity);
    final unitPrice = item == null ? 'ثبت نشده' : formatMoney(item.unitPrice);

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات فاکتور')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'شماره فاکتور: ${invoice.id}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                  const Divider(height: 28),
                  _DetailLine(
                    label: 'تاریخ صدور',
                    value: formatJalaliDate(invoice.issuedAt),
                  ),
                  const SizedBox(height: 12),
                  _DetailLine(label: 'نوع عملیات', value: operationType),
                  if (grossWeight != null) ...[
                    const SizedBox(height: 12),
                    _DetailLine(
                      label: 'وزن ناخالص',
                      value: formatNumber(grossWeight),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailLine(label: 'وزن خالص', value: netWeight),
                  const SizedBox(height: 12),
                  _DetailLine(label: 'قیمت واحد', value: unitPrice),
                  const Divider(height: 28),
                  _DetailLine(
                    label: 'مبلغ کل',
                    value: formatMoney(invoice.total),
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.mutedText),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: emphasized ? FontWeight.w700 : null),
          ),
        ),
      ],
    );
  }
}
