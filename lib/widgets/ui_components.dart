import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/models.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (action case final Widget action) action,
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) {},
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close),
                tooltip: 'پاک کردن',
              ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == InvoiceStatus.overdue) {
      return const SizedBox.shrink();
    }
    final data = switch (status) {
      InvoiceStatus.paid => (
        'تسویه‌شده',
        AppColors.success,
        Icons.check_circle_outline,
      ),
      InvoiceStatus.partial => (
        'پرداخت جزئی',
        AppColors.warning,
        Icons.timelapse_outlined,
      ),
      InvoiceStatus.unpaid => (
        'پرداخت‌نشده',
        AppColors.danger,
        Icons.error_outline,
      ),
      InvoiceStatus.overdue => throw StateError(
        'وضعیت سررسید گذشته نباید نمایش داده شود.',
      ),
    };
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.$3, size: 15, color: data.$2),
          const SizedBox(width: 4),
          Text(
            data.$1,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: data.$2, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class EmptyListNotice extends StatelessWidget {
  const EmptyListNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
