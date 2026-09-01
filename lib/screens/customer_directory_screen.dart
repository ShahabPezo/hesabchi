import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/invoice_detail_sheet.dart';
import '../widgets/ui_components.dart';

class _DirectoryEntry {
  const _DirectoryEntry({required this.customer, this.lastInvoice});

  final Customer customer;
  final Invoice? lastInvoice;
}

class CustomerDirectoryScreen extends StatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  State<CustomerDirectoryScreen> createState() =>
      _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataset = context.watch<AppController>().dataset!;
    final entries = _buildEntries(dataset.customers, dataset.invoices);
    final query = _query.text.trim().toLowerCase();
    final visible = entries.where((entry) {
      return query.isEmpty ||
          entry.customer.name.toLowerCase().contains(query) ||
          entry.customer.phone.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'همه‌ی مشتریانی که حتی یک‌بار فعالیت داشته‌اند (${formatNumber(entries.length)} نفر)',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.mutedText),
            ),
          ),
        ),
        const SizedBox(height: 10),
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
                      _DirectoryCard(entry: visible[index]),
                ),
        ),
      ],
    );
  }

  List<_DirectoryEntry> _buildEntries(
    List<Customer> customers,
    List<Invoice> invoices,
  ) {
    final lastInvoiceByCustomerId = <String, Invoice>{};
    for (final invoice in invoices) {
      final current = lastInvoiceByCustomerId[invoice.customerId];
      if (current == null || invoice.issuedAt.isAfter(current.issuedAt)) {
        lastInvoiceByCustomerId[invoice.customerId] = invoice;
      }
    }
    final entries = customers
        .map(
          (customer) => _DirectoryEntry(
            customer: customer,
            lastInvoice: lastInvoiceByCustomerId[customer.id],
          ),
        )
        .toList();
    entries.sort(
      (first, second) =>
          first.customer.name.compareTo(second.customer.name),
    );
    return entries;
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.entry});

  final _DirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final customer = entry.customer;
    final lastInvoice = entry.lastInvoice;
    return Card(
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
                  const SizedBox(height: 4),
                  if (lastInvoice == null)
                    Text(
                      'بدون فاکتور ثبت‌شده',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.mutedText),
                    )
                  else
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => showInvoiceDetailSheet(context, lastInvoice),
                      child: Text(
                        'آخرین فاکتور: ${formatJalaliDate(lastInvoice.issuedAt)} (${lastInvoice.id})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (customer.phone.isNotEmpty)
              IconButton(
                tooltip: 'تماس با ${customer.name}',
                icon: const Icon(Icons.call_outlined, color: AppColors.primary),
                onPressed: () => _openDirectoryDialer(context, customer.phone),
              )
            else
              const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

Future<void> _openDirectoryDialer(BuildContext context, String phone) async {
  final dialableNumber = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (dialableNumber.isEmpty) return;

  final opened = await launchUrl(Uri(scheme: 'tel', path: dialableNumber));
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('بازکردن برنامه تماس ممکن نشد.')),
    );
  }
}
