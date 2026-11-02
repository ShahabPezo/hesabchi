import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';

/// تاریخچه‌ی یک چک بر اساس شماره‌ی چک (همه‌ی چک‌های هم‌شماره).
Future<void> showChequeHistorySheet(
  BuildContext context,
  Cheque cheque,
  List<Cheque> allCheques,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _ChequeHistorySheet(
      selected: cheque,
      rows: chequeHistory(cheque, allCheques),
    ),
  );
}

class _ChequeHistorySheet extends StatelessWidget {
  const _ChequeHistorySheet({required this.selected, required this.rows});

  final Cheque selected;
  final List<Cheque> rows;

  @override
  Widget build(BuildContext context) {
    final number = selected.checkNumber.trim();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تاریخچه‌ی چک', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              number.isEmpty ? 'شماره‌ی چک ثبت نشده' : number,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.mutedText),
            ),
            const Divider(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) => _HistoryRow(
                  index: index + 1,
                  cheque: rows[index],
                  highlighted: rows[index].id == selected.id,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.index,
    required this.cheque,
    required this.highlighted,
  });

  final int index;
  final Cheque cheque;
  final bool highlighted;

  static String _orDash(String value) => value.isEmpty ? '—' : value;

  @override
  Widget build(BuildContext context) {
    final color = cheque.isIncoming ? AppColors.success : AppColors.danger;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary.withValues(alpha: 0.07) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              toPersianDigits(index.toString()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _orDash(cheque.partyName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      cheque.isIncoming ? 'دریافتی' : 'صادره',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(cheque.amount),
                  style: textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تاریخ فاکتور: ${_orDash(cheque.issueDate)}    '
                  'سررسید: ${_orDash(cheque.dueDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cheque.status.isEmpty ? 'وضعیت نامشخص' : cheque.status,
                  style: textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
