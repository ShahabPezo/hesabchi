import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/ui_components.dart';

class ChequesScreen extends StatefulWidget {
  const ChequesScreen({super.key});

  @override
  State<ChequesScreen> createState() => _ChequesScreenState();
}

enum _ChequeFilter { all, incoming, outgoing }

class _ChequesScreenState extends State<ChequesScreen> {
  _ChequeFilter _filter = _ChequeFilter.all;

  static const _settledStatuses = {'پاس شده', 'برگشت خورده', 'تنزیل شده'};

  @override
  Widget build(BuildContext context) {
    final allCheques = context.watch<AppController>().dataset!.cheques;

    final filtered = allCheques.where((c) {
      return switch (_filter) {
        _ChequeFilter.all => true,
        _ChequeFilter.incoming => c.isIncoming,
        _ChequeFilter.outgoing => !c.isIncoming,
      };
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final active = filtered.where((c) => !_settledStatuses.contains(c.status)).toList();
    final settled = filtered.where((c) => _settledStatuses.contains(c.status)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: SegmentedButton<_ChequeFilter>(
            segments: const [
              ButtonSegment(
                value: _ChequeFilter.all,
                label: Text('همه'),
                icon: Icon(Icons.checklist_outlined),
              ),
              ButtonSegment(
                value: _ChequeFilter.incoming,
                label: Text('دریافتی'),
                icon: Icon(Icons.arrow_downward),
              ),
              ButtonSegment(
                value: _ChequeFilter.outgoing,
                label: Text('پرداختی'),
                icon: Icon(Icons.arrow_upward),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyListNotice(text: 'چکی برای نمایش وجود ندارد.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (active.isNotEmpty) ...[
                      _SectionLabel(
                        label: 'فعال',
                        count: active.length,
                      ),
                      const SizedBox(height: 8),
                      ...active.map((c) => _ChequeCard(cheque: c)),
                    ],
                    if (settled.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionLabel(
                        label: 'تسویه‌شده',
                        count: settled.length,
                        muted: true,
                      ),
                      const SizedBox(height: 8),
                      ...settled.map((c) => _ChequeCard(cheque: c, muted: true)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.count,
    this.muted = false,
  });

  final String label;
  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: muted ? AppColors.mutedText : AppColors.primary,
          fontWeight: FontWeight.w700,
        );
    return Row(
      children: [
        Text(label, style: style),
        const SizedBox(width: 6),
        Text('(${toPersianDigits(count.toString())})', style: style),
      ],
    );
  }
}

class _ChequeCard extends StatelessWidget {
  const _ChequeCard({required this.cheque, this.muted = false});

  final Cheque cheque;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final isIn = cheque.isIncoming;
    final color = muted
        ? AppColors.mutedText
        : isIn
            ? AppColors.success
            : AppColors.danger;
    final icon = isIn ? Icons.arrow_downward : Icons.arrow_upward;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cheque.partyName.isEmpty ? '—' : cheque.partyName,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatMoney(cheque.amount ~/ 10, compact: false),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'سررسید',
                      value: cheque.dueDate.isEmpty ? '—' : cheque.dueDate,
                    ),
                    if (cheque.issueDate.isNotEmpty)
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'ثبت',
                        value: cheque.issueDate,
                      ),
                    if (cheque.description.isNotEmpty)
                      _InfoRow(
                        icon: Icons.notes_outlined,
                        label: 'توضیحات',
                        value: cheque.description,
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cheque.status.isEmpty ? '—' : cheque.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.mutedText),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
