import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_metadata.dart';
import '../app_theme.dart';
import '../core/formatters.dart';
import '../state/app_controller.dart';
import '../widgets/ui_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onImport,
    required this.onDataCleared,
    required this.onSync,
  });

  final VoidCallback onImport;
  final VoidCallback onDataCleared;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final data = controller.dataset;
    if (data == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اطلاعات دیتابیس',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                _InfoRow(label: 'کسب‌وکار', value: data.business.displayName),
                const Divider(height: 22),
                _InfoRow(
                  label: 'زمان خروجی فایل',
                  value: formatJalaliDate(data.exportedAt, withTime: true),
                ),
                const Divider(height: 22),
                _InfoRow(
                  label: 'نوع دیتابیس',
                  value: toPersianDigits(data.scope.displayText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'نمایش'),
        const SizedBox(height: 8),
        RadioGroup<ThemeMode>(
          groupValue: controller.themeMode,
          onChanged: (value) {
            if (value != null) {
              context.read<AppController>().setThemeMode(value);
            }
          },
          child: Card(
            child: Column(
              children: const [
                _ThemeOption(
                  label: 'براساس تنظیمات دستگاه',
                  mode: ThemeMode.system,
                ),
                Divider(indent: 16, endIndent: 16),
                _ThemeOption(label: 'روشن', mode: ThemeMode.light),
                Divider(indent: 16, endIndent: 16),
                _ThemeOption(label: 'تیره', mode: ThemeMode.dark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'داده‌ها'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.cloud_download_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('دریافت به‌روزرسانی'),
                subtitle: Text(
                  controller.isSyncing
                      ? 'در حال دریافت اطلاعات…'
                      : 'دریافت آخرین اطلاعات از حسابچی',
                ),
                trailing: controller.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_left),
                onTap: controller.isSyncing ? null : onSync,
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.upload_file_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('ورود فایل جدید'),
                subtitle: const Text('جایگزین‌کردن اطلاعات با فایل HCH معتبر'),
                trailing: const Icon(Icons.chevron_left),
                onTap: onImport,
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
                title: const Text('پاک‌کردن اطلاعات دستگاه'),
                subtitle: const Text('فایل اصلی شما حذف نمی‌شود'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _confirmClear(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'حسابچی نسخه $hesabchiDisplayVersion\nطراح و سازنده: شهاب\nتمام اطلاعات فقط روی همین دستگاه نگهداری می‌شود.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.mutedText, height: 1.8),
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('پاک‌کردن اطلاعات؟'),
        content: const Text(
          'تمام داده‌های واردشده از داخل برنامه پاک می‌شوند. فایل JSON اصلی در دستگاه شما باقی می‌ماند.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('پاک‌کردن'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final controller = context.read<AppController>();
    // صفحه تنظیمات به dataset نیاز دارد؛ پیش از پاک‌سازی آن را می‌بندیم تا دوباره
    // با dataset=null ساخته نشود. DataIntakePage سپس صفحه انتخاب HCH را نمایش می‌دهد.
    Navigator.of(context).pop();
    await controller.clearData();
    onDataCleared();
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.label, required this.mode});

  final String label;
  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: mode,
      title: Text(label),
      contentPadding: const EdgeInsetsDirectional.only(start: 8, end: 12),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

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
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}
