import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_handler/share_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/github_sync_service.dart';
import '../data/import_service.dart';
import '../data/local_store.dart';
import '../data/models.dart';

class ImportResult {
  const ImportResult._({required this.ok, required this.message});

  const ImportResult.success(String message)
    : this._(ok: true, message: message);
  const ImportResult.failure(String message)
    : this._(ok: false, message: message);

  final bool ok;
  final String message;
}

class GitHubSyncResult {
  const GitHubSyncResult._({
    required this.ok,
    required this.updated,
    required this.message,
  });

  const GitHubSyncResult.success({
    required bool updated,
    required String message,
  }) : this._(ok: true, updated: updated, message: message);

  const GitHubSyncResult.failure(String message)
    : this._(ok: false, updated: false, message: message);

  final bool ok;
  final bool updated;
  final String message;
}

class AppController extends ChangeNotifier {
  AppController({
    LocalStore? store,
    ImportService? importer,
    GitHubSyncGateway? githubSync,
  }) : _store = store ?? LocalStore(),
       _importer = importer ?? const ImportService(),
       _githubSync = githubSync ?? GitHubSyncService();

  static const _themePreferenceKey = 'theme_mode';
  static const _githubLastSyncKey = 'github_last_sync_exported_at';
  static const _githubTokenKey = 'github_reader_token';

  final LocalStore _store;
  final ImportService _importer;
  final GitHubSyncGateway _githubSync;
  BusinessDataset? _dataset;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  bool _isImporting = false;
  bool _isSyncing = false;
  String? _lastImportSource;
  DateTime? _lastGitHubSyncExportedAt;
  String? _customGitHubToken;

  BusinessDataset? get dataset => _dataset;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  bool get isSyncing => _isSyncing;
  bool get hasData => _dataset != null;
  String? get lastImportSource => _lastImportSource;
  DateTime? get lastGitHubSyncExportedAt => _lastGitHubSyncExportedAt;
  String? get customGitHubToken => _customGitHubToken;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString(_themePreferenceKey);
    _themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _dataset = await _store.loadDataset();
    final rawLastSync = preferences.getString(_githubLastSyncKey);
    _lastGitHubSyncExportedAt = rawLastSync == null
        ? null
        : DateTime.tryParse(rawLastSync)?.toLocal();
    _customGitHubToken = preferences.getString(_githubTokenKey);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, mode.name);
  }

  Future<ImportResult> pickAndImport() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['hch', 'json'],
        withData: true,
      );
      if (selection == null || selection.files.isEmpty) {
        return const ImportResult.failure('انتخاب فایل لغو شد.');
      }
      final file = selection.files.single;
      final bytes = file.bytes ?? await _readPath(file.path);
      if (bytes == null) {
        return const ImportResult.failure(
          'امکان خواندن فایل انتخاب‌شده وجود ندارد.',
        );
      }
      return await importBytes(bytes, source: file.name);
    } catch (_) {
      return const ImportResult.failure(
        'بازکردن فایل ممکن نشد. دوباره تلاش کنید.',
      );
    }
  }

  Future<ImportResult> importSharedMedia(SharedMedia media) async {
    final attachments = media.attachments ?? const <SharedAttachment?>[];
    final candidate = attachments.whereType<SharedAttachment>().firstWhere(
      (item) =>
          item.type == SharedAttachmentType.file &&
          (item.path.toLowerCase().endsWith('.hch') ||
              item.path.toLowerCase().endsWith('.json')),
      orElse: () => SharedAttachment(path: '', type: SharedAttachmentType.file),
    );
    if (candidate.path.isEmpty) {
      return const ImportResult.failure(
        'فایل HCH یا JSON در مورد اشتراک‌گذاری‌شده پیدا نشد.',
      );
    }
    try {
      final bytes = await File(candidate.path).readAsBytes();
      return await importBytes(
        bytes,
        source: candidate.path.split(Platform.pathSeparator).last,
      );
    } catch (_) {
      return const ImportResult.failure(
        'فایل اشتراک‌گذاری‌شده قابل خواندن نیست.',
      );
    }
  }

  Future<ImportResult> importBytes(
    Uint8List bytes, {
    required String source,
  }) async {
    _isImporting = true;
    notifyListeners();
    try {
      final imported = _importer.parseBytes(bytes);
      await _store.saveDataset(imported);
      _dataset = imported;
      _lastImportSource = source;
      return ImportResult.success(
        'اطلاعات «${imported.business.displayName}» با موفقیت به‌روزرسانی شد.',
      );
    } on ImportValidationException catch (error) {
      return ImportResult.failure(error.message);
    } catch (_) {
      return const ImportResult.failure(
        'خطایی در ورود فایل رخ داد. داده قبلی شما محفوظ است.',
      );
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  /// دریافت دستی HCH از GitHub. اعتبارسنجی پیش از ذخیره و replace اتمی LocalStore،
  /// داده قبلی را در صورت خطای شبکه یا فایل نامعتبر محفوظ نگه می‌دارد.
  Future<GitHubSyncResult> syncFromGitHub() async {
    if (_isSyncing) {
      return const GitHubSyncResult.failure('به‌روزرسانی در حال انجام است.');
    }
    _isSyncing = true;
    notifyListeners();
    try {
      final syncService = _customGitHubToken != null && _customGitHubToken!.isNotEmpty
          ? GitHubSyncService(
              config: GitHubSyncConfig(
                owner: GitHubSyncConfig.production().owner,
                repository: GitHubSyncConfig.production().repository,
                branch: GitHubSyncConfig.production().branch,
                metaPath: GitHubSyncConfig.production().metaPath,
                hchPath: GitHubSyncConfig.production().hchPath,
                readerToken: _customGitHubToken!,
              ),
            )
          : _githubSync;
      final fetched = await syncService.fetchLatest(
        currentExportedAt: _dataset?.exportedAt,
      );
      final preferences = await SharedPreferences.getInstance();
      if (fetched.status == GitHubSyncFetchStatus.current) {
        _lastGitHubSyncExportedAt = fetched.exportedAt;
        await _rememberGitHubSync(preferences, fetched.exportedAt);
        return const GitHubSyncResult.success(
          updated: false,
          message: 'اطلاعات همین حالا به‌روز است.',
        );
      }

      final bytes = fetched.bytes;
      if (bytes == null) throw const GitHubSyncException();
      // ابتدا JSON جدید کامل parse می‌شود؛ سپس جایگزینی تک‌تراکنشی snapshot انجام می‌شود.
      final imported = _importer.parseBytes(bytes);
      await _store.saveDataset(imported);
      _dataset = imported;
      _lastImportSource = 'GitHub';
      _lastGitHubSyncExportedAt = fetched.exportedAt;
      await _rememberGitHubSync(preferences, fetched.exportedAt);
      return const GitHubSyncResult.success(
        updated: true,
        message: 'اطلاعات با موفقیت به‌روزرسانی شد.',
      );
    } on ImportValidationException {
      return const GitHubSyncResult.failure(
        'فایل دریافت‌شده از GitHub معتبر نیست. لطفاً بعداً دوباره تلاش کنید.',
      );
    } on GitHubSyncException {
      return const GitHubSyncResult.failure(
        'دریافت از GitHub ممکن نشد. احتمالاً توکن دسترسی منقضی یا نادرست است.',
      );
    } catch (_) {
      return const GitHubSyncResult.failure(
        'به‌روزرسانی انجام نشد. لطفاً اتصال اینترنت را بررسی کرده و دوباره تلاش کنید.',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _rememberGitHubSync(
    SharedPreferences preferences,
    DateTime exportedAt,
  ) async {
    // ثبت زمان فقط برای نمایش است؛ نباید نتیجه ورود موفق داده را تغییر دهد.
    try {
      await preferences.setString(
        _githubLastSyncKey,
        exportedAt.toUtc().toIso8601String(),
      );
    } catch (_) {
      // داده جدید قبلاً به‌صورت اتمی ذخیره شده و همچنان معتبر است.
    }
  }

  Future<void> setGitHubToken(String token) async {
    final trimmed = token.trim();
    _customGitHubToken = trimmed.isEmpty ? null : trimmed;
    final preferences = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await preferences.remove(_githubTokenKey);
    } else {
      await preferences.setString(_githubTokenKey, trimmed);
    }
    // سرویس sync رو با توکن جدید بازسازی کن
    if (_customGitHubToken != null) {
      final config = GitHubSyncConfig(
        owner: GitHubSyncConfig.production().owner,
        repository: GitHubSyncConfig.production().repository,
        branch: GitHubSyncConfig.production().branch,
        metaPath: GitHubSyncConfig.production().metaPath,
        hchPath: GitHubSyncConfig.production().hchPath,
        readerToken: _customGitHubToken!,
      );
      (_githubSync as dynamic)._config = config;
    }
    notifyListeners();
  }

  Future<void> clearData() async {
    await _store.clear();
    _dataset = null;
    _lastImportSource = null;
    _lastGitHubSyncExportedAt = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_githubLastSyncKey);
    notifyListeners();
  }

  Future<Uint8List?> _readPath(String? path) async {
    if (path == null || path.isEmpty) return null;
    return File(path).readAsBytes();
  }

  @override
  void dispose() {
    _store.close();
    super.dispose();
  }
}
