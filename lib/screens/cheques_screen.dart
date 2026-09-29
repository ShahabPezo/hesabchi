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

class _ChequesScreenState extends State<ChequesScreen>
    with SingleTickerProviderStateMixin {
  _ChequeFilter _filter = _ChequeFilter.all;
  final _search = TextEditingController();
  late final TabController _tabController;

  // وضعیت‌های تسویه‌شده
  static const _settledStatuses = {
    'پاس شده',
    'برگشت خورده',
    'تنزیل شده',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _search.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCheques = context.watch<AppController>().dataset!.cheques;
    final query = _search.text.trim();

    final filtered = allCheques.where((c) {
      final matchesFilter = switch (_filter) {
        _ChequeFilter.all => true,
        _ChequeFilter.incoming => c.isIncoming,
        _ChequeFilter.outgoing => !c.isIncoming,
      };
      final matchesSearch = query.isEmpty ||
          c.partyName.contains(query) ||
          c.checkNumber.contains(query) ||
          c.description.contains(query);
      return matchesFilter && matchesSearch;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final active =
        filtered.where((c) => !_settledStatuses.contains(c.status)).toList();
    final settled =
        filtered.where((c) => _settledStatuses.contains(c.status)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'جست‌وجو بر اساس نام یا شماره چک',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'پاک کردن',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('فعال'),
                  const SizedBox(width: 6),
                  _CountBadge(count: active.length, color: AppColors.primary),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('سررسید گذشته'),
                  const SizedBox(width: 6),
                  _CountBadge(
                    count: settled.length,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ChequeList(cheques: active, emptyText: 'چک فعالی وجود ندارد.'),
              _ChequeList(
                cheques: settled,
                emptyText: 'چک سررسید گذشته‌ای وجود ندارد.',
                muted: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        toPersianDigits(count.toString()),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ChequeList extends StatelessWidget {
  const _ChequeList({
    required this.cheques,
    required this.emptyText,
    this.muted = false,
  });

  final List<Cheque> cheques;
  final String emptyText;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (cheques.isEmpty) {
      return EmptyListNotice(text: emptyText);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: cheques.length,
      itemBuilder: (context, index) =>
          _ChequeCard(cheque: cheques[index], muted: muted),
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
                        label: 'تاریخ فاکتور',
                        value: cheque.issueDate,
                      ),
                    if (cheque.checkNumber.isNotEmpty)
                      _InfoRow(
                        icon: Icons.tag_outlined,
                        label: 'شماره چک',
                        value: cheque.checkNumber,
                      )
                    else if (cheque.description.isNotEmpty)
                      _InfoRow(
                        icon: Icons.tag_outlined,
                        label: 'شماره چک',
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
                        cheque.status.isEmpty ? 'وضعیت نامشخص' : cheque.status,
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
