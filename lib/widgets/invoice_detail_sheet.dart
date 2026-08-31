import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';

Future<void> showInvoiceDetailSheet(BuildContext context, Invoice invoice) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _InvoiceDetailSheet(invoice: invoice),
  );
}

class _InvoiceDetailSheet extends StatelessWidget {
  const _InvoiceDetailSheet({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final item = invoice.items.first;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              'شماره فاکتور: ${invoice.id}',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.mutedText),
            ),
            const Divider(height: 28),
            _InfoLine(
              label: 'تاریخ صدور',
              value: formatJalaliDate(invoice.issuedAt),
            ),
            const SizedBox(height: 12),
            _InfoLine(label: 'نوع عملیات', value: item.title),
            const SizedBox(height: 12),
            _InfoLine(label: 'وزن خالص', value: formatNumber(item.quantity)),
            const SizedBox(height: 12),
            _InfoLine(label: 'قیمت واحد', value: formatMoney(item.unitPrice)),
            const Divider(height: 28),
            _InfoLine(
              label: 'مبلغ کل',
              value: formatMoney(invoice.total),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: emphasized ? AppColors.primary : null,
              fontWeight: emphasized ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    );
  }
}
