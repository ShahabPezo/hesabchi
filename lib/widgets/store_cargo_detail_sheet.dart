import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../core/formatters.dart';
import '../data/models.dart';

Future<void> showStoreCargoDetailSheet(
  BuildContext context,
  StoreCargoEntry entry,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _StoreCargoDetailSheet(entry: entry),
  );
}

class _StoreCargoDetailSheet extends StatelessWidget {
  const _StoreCargoDetailSheet({required this.entry});

  final StoreCargoEntry entry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              'شماره ثبت: ${entry.id}',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.mutedText),
            ),
            const Divider(height: 28),
            _InfoLine(label: 'تاریخ', value: formatJalaliDate(entry.date)),
            const SizedBox(height: 12),
            _InfoLine(
              label: 'وزن ناخالص',
              value: formatWeight(entry.grossWeightKg),
            ),
            const SizedBox(height: 12),
            _InfoLine(
              label: 'وزن خالص',
              value: formatWeight(entry.netWeightKg),
              emphasized: true,
            ),
            if (entry.plateOrHelper.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoLine(label: 'پلاک یا نام کارگر', value: entry.plateOrHelper),
            ],
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoLine(label: 'توضیحات', value: entry.description),
            ],
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
