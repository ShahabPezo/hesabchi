import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_handler/share_handler.dart';

import 'app_metadata.dart';
import 'app_theme.dart';
import 'screens/main_shell.dart';
import 'state/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppController()..initialize(),
      child: const HesabchiApp(),
    ),
  );
}

class HesabchiApp extends StatelessWidget {
  const HesabchiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'حسابچی',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: controller.themeMode,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const DataIntakePage(),
      ),
    );
  }
}

class DataIntakePage extends StatefulWidget {
  const DataIntakePage({super.key});

  @override
  State<DataIntakePage> createState() => _DataIntakePageState();
}

class _DataIntakePageState extends State<DataIntakePage> {
  static const _openFileChannel = MethodChannel('ir.hesabchi/open_json');
  static const _brandSplashDuration = Duration(seconds: 5);

  StreamSubscription<SharedMedia>? _shareSubscription;
  bool _showBrandSplash = true;

  @override
  void initState() {
    super.initState();
    _openFileChannel.setMethodCallHandler(_handleNativeOpenFile);
    _listenForSharedFiles();
    Future<void>.delayed(_brandSplashDuration, () {
      if (mounted) setState(() => _showBrandSplash = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_readInitialNativeOpenFile());
    });
  }

  Future<void> _listenForSharedFiles() async {
    try {
      final initial = await ShareHandler.instance.getInitialSharedMedia();
      if (initial != null) {
        await _processSharedMedia(initial);
        await ShareHandler.instance.resetInitialSharedMedia();
      }
      _shareSubscription = ShareHandler.instance.sharedMediaStream.listen(
        _processSharedMedia,
      );
    } catch (_) {
      // ورود دستی فایل همچنان مسیر جایگزین امن است.
    }
  }

  Future<void> _waitUntilReady() async {
    while (mounted && context.read<AppController>().isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  Future<void> _processSharedMedia(SharedMedia media) async {
    await _waitUntilReady();
    if (!mounted) return;
    final result = await context.read<AppController>().importSharedMedia(media);
    if (!mounted || result.ok) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _readInitialNativeOpenFile() async {
    try {
      final data = await _openFileChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getInitialOpenFile',
      );
      if (data != null) await _importNativeOpenFile(data);
    } on PlatformException {
      // کاربر همچنان می‌تواند از انتخاب فایل یا اشتراک‌گذاری استفاده کند.
    }
  }

  Future<void> _handleNativeOpenFile(MethodCall call) async {
    if (call.method == 'openFile' && call.arguments is Map) {
      await _importNativeOpenFile(call.arguments as Map<dynamic, dynamic>);
    }
  }

  Future<void> _importNativeOpenFile(Map<dynamic, dynamic> data) async {
    final uri = data['uri'] as String?;
    if (uri == null || uri.isEmpty) return;
    try {
      await _waitUntilReady();
      if (!mounted) return;
      final bytes = await _openFileChannel.invokeMethod<Uint8List>(
        'readOpenFile',
        {'uri': uri},
      );
      if (bytes == null) throw PlatformException(code: 'empty_file');
      if (!mounted) return;
      final source = (data['name'] as String?)?.trim();
      final result = await context.read<AppController>().importBytes(
        bytes,
        source: source?.isNotEmpty == true ? source! : 'فایل JSON',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.ok ? AppColors.success : null,
          content: Text(result.message),
        ),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فایل JSON قابل خواندن نیست.')),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await context.read<AppController>().pickAndImport();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.ok ? AppColors.success : null,
        content: Text(result.message),
      ),
    );
  }

  Future<void> _syncFromGitHub() async {
    if (context.read<AppController>().isSyncing) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('در حال به‌روزرسانی اطلاعات…')),
            ],
          ),
        ),
      ),
    );
    final result = await context.read<AppController>().syncFromGitHub();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.ok ? AppColors.success : null,
        content: Text(result.message),
      ),
    );
  }

  void _onDataCleared() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اطلاعات واردشده از دستگاه پاک شد.')),
    );
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _openFileChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        if (controller.isLoading || _showBrandSplash) {
          return const _HesabchiSplash();
        }
        if (controller.dataset != null) {
          return MainShell(
            onImport: _pickFile,
            onDataCleared: _onDataCleared,
            onSync: _syncFromGitHub,
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('حسابچی'),
            actions: [
              IconButton(
                tooltip: 'ورود فایل جدید',
                onPressed: controller.isImporting ? null : _pickFile,
                icon: const Icon(Icons.file_upload_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _EmptyDataState(
                onImport: _pickFile,
                onSync: _syncFromGitHub,
                isImporting: controller.isImporting,
                isSyncing: controller.isSyncing,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HesabchiSplash extends StatelessWidget {
  const _HesabchiSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0A2145), Color(0xFF155FC1), Color(0xFF2082D8)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -55,
                child: _GlowCircle(size: 210, color: Color(0x30F4BA62)),
              ),
              Positioned(
                bottom: 90,
                right: -60,
                child: _GlowCircle(size: 230, color: Color(0x24FFFFFF)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 158,
                      height: 158,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/hesabchi_logo.png'),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'حسابچی',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'مدیریت همراه حساب‌های کارتن',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'نسخه $hesabchiDisplayVersion',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Color(0xFFF4BA62),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 26,
                child: Text(
                  'طراحی و ساخت: شهاب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _EmptyDataState extends StatelessWidget {
  const _EmptyDataState({
    required this.onImport,
    required this.onSync,
    required this.isImporting,
    required this.isSyncing,
  });

  final VoidCallback onImport;
  final Future<void> Function() onSync;
  final bool isImporting;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset('assets/images/hesabchi_logo.png', height: 112),
        const SizedBox(height: 26),
        Text(
          'هنوز اطلاعاتی وارد نشده است',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'فایل HCH خروجی برنامه ویندوزی را انتخاب کنید؛ آخرین نسخه معتبر فقط روی همین دستگاه نگهداری می‌شود.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: isImporting ? null : onImport,
          icon: isImporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.upload_file_outlined),
          label: Text(isImporting ? 'در حال ورود...' : 'انتخاب فایل HCH'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isSyncing ? null : onSync,
          icon: isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_download_outlined),
          label: Text(
            isSyncing ? 'در حال دریافت اطلاعات...' : 'دریافت به‌روزرسانی',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'فایل HCH را از فایل‌منیجر با گزینه «باز کردن با حسابچی» یا از تلگرام با «اشتراک‌گذاری» وارد کنید.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}
