import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import 'customers_screen.dart';
import 'employee_salary_screen.dart';
import 'home_screen.dart';
import 'invoices_screen.dart';
import 'prices_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'store_status_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.onImport,
    required this.onDataCleared,
    required this.onSync,
  });

  final VoidCallback onImport;
  final VoidCallback onDataCleared;
  final Future<void> Function() onSync;

  @override
  State<MainShell> createState() => _MainShellState();
}

enum _MoreDestination { employeeSalary, invoices, storeStatus, settings }

class _MainShellState extends State<MainShell> {
  var _index = 0;
  var _exitDialogOpen = false;

  static const _titles = ['خانه', 'مشتری‌ها', 'قیمت‌ها', 'آمار'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onImport: widget.onImport),
      const CustomersScreen(),
      const PricesScreen(),
      StatisticsScreen(onImport: widget.onImport),
    ];
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: [
            if (_index != 3)
              IconButton(
                tooltip: 'ورود فایل جدید',
                onPressed: widget.onImport,
                icon: const Icon(Icons.file_upload_outlined),
              ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            if (value == 4) {
              _openMoreMenu();
              return;
            }
            setState(() => _index = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'مشتری‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.sell_outlined),
              selectedIcon: Icon(Icons.sell),
              label: 'قیمت‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'آمار',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_rounded),
              selectedIcon: Icon(Icons.menu_open_rounded),
              label: 'بیشتر',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMoreMenu() async {
    final destination = await showModalBottomSheet<_MoreDestination>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('بیشتر', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              _MoreMenuTile(
                icon: Icons.badge_outlined,
                title: 'حقوق افراد',
                subtitle: 'وضعیت حقوق و تسویه کارکنان',
                onTap: () =>
                    Navigator.of(sheetContext)
                        .pop(_MoreDestination.employeeSalary),
              ),
              const Divider(height: 1),
              _MoreMenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'فاکتورهای مشتری',
                subtitle: 'فهرست و جزئیات فاکتورهای ثبت‌شده',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_MoreDestination.invoices),
              ),
              const Divider(height: 1),
              _MoreMenuTile(
                icon: Icons.storefront_outlined,
                title: 'وضعیت فروشگاه‌ها',
                subtitle: 'بار، اجاره و فاکتورهای ورود کارتن فروشگاهی',
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_MoreDestination.storeStatus),
              ),
              const Divider(height: 1),
              _MoreMenuTile(
                icon: Icons.settings_outlined,
                title: 'تنظیمات',
                subtitle: 'نمایش، داده‌ها و به‌روزرسانی',
                onTap: () =>
                    Navigator.of(sheetContext).pop(_MoreDestination.settings),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || destination == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (destination) {
          _MoreDestination.employeeSalary => Scaffold(
            appBar: AppBar(title: const Text('حقوق افراد')),
            body: const EmployeeSalaryScreen(),
          ),
          _MoreDestination.invoices => Scaffold(
            appBar: AppBar(title: const Text('فاکتورهای مشتری')),
            body: const InvoicesScreen(),
          ),
          _MoreDestination.storeStatus => Scaffold(
            appBar: AppBar(title: const Text('وضعیت فروشگاه‌ها')),
            body: const StoreStatusScreen(),
          ),
          _MoreDestination.settings => Scaffold(
            appBar: AppBar(title: const Text('تنظیمات')),
            body: SettingsScreen(
              onImport: widget.onImport,
              onDataCleared: widget.onDataCleared,
              onSync: widget.onSync,
            ),
          ),
        },
      ),
    );
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop || _exitDialogOpen) return;

    _exitDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ببندم؟ کارت تموم شد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('نه!'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('آره تمومه'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (confirmed != true || !mounted) return;

    await SystemNavigator.pop();
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 5),
    leading: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.primary),
    ),
    title: Text(title, style: Theme.of(context).textTheme.titleMedium),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_left),
    onTap: onTap,
  );
}
