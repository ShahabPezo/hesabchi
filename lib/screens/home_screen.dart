import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/invoice_detail_sheet.dart';
import '../widgets/ui_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final data = controller.dataset!;
    final lastSync = controller.lastGitHubSyncExportedAt;
    final scopeLabel = _homeScopeLabel(data);
    final recent = [...data.invoices]..sort(compareInvoicesByNumberDescending);
    final totalDebt = data.customers
        .where((customer) => customer.balance > 0)
        .fold(0, (sum, customer) => sum + customer.balance);
    final totalCredit = data.customers
        .where((customer) => customer.balance < 0)
        .fold(0, (sum, customer) => sum + customer.balance.abs());
    final debtCreditBalance = totalCredit - totalDebt;
    final largestDebtor = _largestDebtor(data.customers);
    final largestCreditor = _largestCreditor(data.customers);
    return RefreshIndicator(
      onRefresh: () async => onImport(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'سلام، خوش آمدید',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            data.business.displayName,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 2),
          Text(
            scopeLabel,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
          if (lastSync != null) ...[
            const SizedBox(height: 2),
            Text(
              'آخرین به‌روزرسانی: ${formatJalaliDate(lastSync, withTime: true)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.mutedText),
            ),
          ],
          const SizedBox(height: 20),
          _BalanceBanner(
            value: debtCreditBalance,
            totalDebt: totalDebt,
            totalCredit: totalCredit,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CustomerHighlightCard(
                  title: 'بزرگترین بدهکارمون',
                  customer: largestDebtor,
                  color: AppColors.success,
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CustomerHighlightCard(
                  title: 'بزرگترین طلبکارمون',
                  customer: largestCreditor,
                  color: AppColors.danger,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: '۱۰ فاکتور اخیر مشتری‌ها'),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const EmptyListNotice(text: 'فاکتوری برای نمایش وجود ندارد.')
          else
            ...recent
                .take(10)
                .map(
                  (invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentInvoiceCard(invoice: invoice),
                  ),
                ),
        ],
      ),
    );
  }
}

String _homeScopeLabel(BusinessDataset data) {
  try {
    final scope = data.scope;
    if (scope.type == InvoiceScopeType.range) {
      final startDate = scope.startDate?.trim() ?? '';
      final endDate = scope.endDate?.trim() ?? '';
      if (startDate.isNotEmpty && endDate.isNotEmpty) {
        return toPersianDigits('از $startDate تا $endDate');
      }
    }
  } catch (_) {
    // نمایش خانه نباید به‌خاطر متادیتای افزوده‌شده در فایل HCH متوقف شود.
  }
  return 'کل فاکتورها';
}

int invoiceSequence(String invoiceId) {
  final match = RegExp(r'(\d+)(?!.*\d)').firstMatch(invoiceId);
  return int.tryParse(match?.group(1) ?? '') ?? -1;
}

int compareInvoicesByNumberDescending(Invoice first, Invoice second) {
  final byNumber = invoiceSequence(second.id)
      .compareTo(invoiceSequence(first.id));
  if (byNumber != 0) return byNumber;
  return second.issuedAt.compareTo(first.issuedAt);
}

Customer? _largestDebtor(List<Customer> customers) {
  Customer? result;
  for (final customer in customers) {
    if (customer.balance < 0 &&
        (result == null || customer.balance < result.balance)) {
      result = customer;
    }
  }
  return result;
}

Customer? _largestCreditor(List<Customer> customers) {
  Customer? result;
  for (final customer in customers) {
    if (customer.balance > 0 &&
        (result == null || customer.balance > result.balance)) {
      result = customer;
    }
  }
  return result;
}

class _CustomerHighlightCard extends StatelessWidget {
  const _CustomerHighlightCard({
    required this.title,
    required this.customer,
    required this.color,
    required this.icon,
  });

  final String title;
  final Customer? customer;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasCustomer = customer != null;
    return Container(
      height: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            hasCustomer ? customer!.name : 'موردی ثبت نشده',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            hasCustomer ? formatMoney(customer!.balance.abs()) : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({
    required this.value,
    required this.totalDebt,
    required this.totalCredit,
  });

  final int value;
  final int totalDebt;
  final int totalCredit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showBalanceDetails(context),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تراز بدهی/طلب',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                formatMoney(value),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برای مشاهده جزئیات، لمس کنید',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBalanceDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جزئیات بدهی و طلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BalanceDetailRow(
              label: 'جمع بدهی به مشتری‌ها',
              amount: totalDebt,
              color: AppColors.danger,
            ),
            const Divider(height: 28),
            _BalanceDetailRow(
              label: 'جمع طلب از مشتری‌ها',
              amount: totalCredit,
              color: AppColors.success,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}

class _BalanceDetailRow extends StatelessWidget {
  const _BalanceDetailRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(
          formatMoney(amount),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RecentInvoiceCard extends StatelessWidget {
  const _RecentInvoiceCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => showInvoiceDetailSheet(context, invoice),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
        leading: Container(
          height: 42,
          width: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.receipt_outlined, color: AppColors.primary),
        ),
        title: Text(
          invoice.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${invoice.id} • ${formatJalaliDate(invoice.issuedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          formatMoney(invoice.total),
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
