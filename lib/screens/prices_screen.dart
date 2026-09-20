import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/ui_components.dart';

class PricesScreen extends StatefulWidget {
  const PricesScreen({super.key});

  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.text.trim().toLowerCase();
    final prices = context.watch<AppController>().dataset!.prices.where((item) {
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'جست‌وجوی مشتری یا نوع کالا',
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
        Expanded(
          child: prices.isEmpty
              ? const EmptyListNotice(
                  text: 'کالایی مطابق جست‌وجوی شما پیدا نشد.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 32),
                  itemCount: prices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      PriceCard(item: prices[index]),
                ),
        ),
      ],
    );
  }
}

class PriceCard extends StatelessWidget {
  const PriceCard({super.key, required this.item});

  final PriceItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.sell_outlined, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.sku.isEmpty ? item.id : item.sku,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'به‌روزرسانی: ${formatJalaliDate(item.updatedAt)}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatMoney(item.price, compact: true),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
