import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// پیکربندی ثابت دریافت داده؛ توکن فقط در زمان ساخت APK با dart-define تزریق می‌شود.
class GitHubSyncConfig {
  const GitHubSyncConfig({
    required this.owner,
    required this.repository,
    required this.branch,
    required this.metaPath,
    required this.hchPath,
    required this.readerToken,
  });

  factory GitHubSyncConfig.production() => const GitHubSyncConfig(
    owner: 'ShahabPezo',
    repository: 'hesabchi-sync',
    branch: 'main',
    metaPath: 'data/latest_meta.json',
    hchPath: 'data/latest.hch',
    readerToken: String.fromEnvironment('HESABCHI_GITHUB_READER_TOKEN'),
  );

  final String owner;
  final String repository;
  final String branch;
  final String metaPath;
  final String hchPath;
  final String readerToken;

  bool get isConfigured =>
      owner.isNotEmpty &&
      repository.isNotEmpty &&
      branch.isNotEmpty &&
      metaPath.isNotEmpty &&
      hchPath.isNotEmpty &&
      readerToken.isNotEmpty;

  Uri contentUri(String path) => Uri.https(
    'api.github.com',
    '/repos/$owner/$repository/contents/$path',
    {'ref': branch},
  );
}

class GitHubSyncException implements Exception {
  const GitHubSyncException();
}

enum GitHubSyncFetchStatus { current, downloaded }

class GitHubSyncFetchResult {
  const GitHubSyncFetchResult._({
    required this.status,
    required this.exportedAt,
    this.bytes,
  });

  const GitHubSyncFetchResult.current({required DateTime exportedAt})
    : this._(status: GitHubSyncFetchStatus.current, exportedAt: exportedAt);

  const GitHubSyncFetchResult.downloaded({
    required DateTime exportedAt,
    required Uint8List bytes,
  }) : this._(
         status: GitHubSyncFetchStatus.downloaded,
         exportedAt: exportedAt,
         bytes: bytes,
       );

  final GitHubSyncFetchStatus status;
  final DateTime exportedAt;
  final Uint8List? bytes;
}

abstract interface class GitHubSyncGateway {
  Future<GitHubSyncFetchResult> fetchLatest({
    required DateTime? currentExportedAt,
  });
}

class GitHubSyncService implements GitHubSyncGateway {
  GitHubSyncService({
    GitHubSyncConfig? config,
    http.Client? client,
    Duration timeout = const Duration(seconds: 25),
  }) : _config = config ?? GitHubSyncConfig.production(),
       _httpClient = client,
       _requestTimeout = timeout;

  static const _maxHchBytes = 25 * 1024 * 1024;

  final GitHubSyncConfig _config;
  final http.Client? _httpClient;
  final Duration _requestTimeout;

  @override
  Future<GitHubSyncFetchResult> fetchLatest({
    required DateTime? currentExportedAt,
  }) async {
    if (!_config.isConfigured) throw const GitHubSyncException();

    final client = _httpClient ?? http.Client();
    try {
      final metaResponse = await client
          .get(_config.contentUri(_config.metaPath), headers: _jsonHeaders)
          .timeout(_requestTimeout);
      if (metaResponse.statusCode != 200) throw const GitHubSyncException();

      final metadata = _parseMetadata(_decodeGitHubJson(metaResponse.body));
      if (currentExportedAt != null &&
          !metadata.exportedAt.toUtc().isAfter(currentExportedAt.toUtc())) {
        return GitHubSyncFetchResult.current(exportedAt: metadata.exportedAt);
      }

      final dataResponse = await client
          .get(_config.contentUri(metadata.dataPath), headers: _rawHeaders)
          .timeout(_requestTimeout);
      if (dataResponse.statusCode != 200 || dataResponse.bodyBytes.isEmpty) {
        throw const GitHubSyncException();
      }
      if (dataResponse.bodyBytes.length > _maxHchBytes ||
          dataResponse.bodyBytes.length != metadata.sizeBytes) {
        throw const GitHubSyncException();
      }

      return GitHubSyncFetchResult.downloaded(
        exportedAt: metadata.exportedAt,
        bytes: dataResponse.bodyBytes,
      );
    } on GitHubSyncException {
      rethrow;
    } catch (_) {
      throw const GitHubSyncException();
    } finally {
      if (_httpClient == null) client.close();
    }
  }

  Map<String, String> get _jsonHeaders => {
    'Accept': 'application/vnd.github+json',
    'Authorization': 'Bearer ${_config.readerToken}',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Map<String, String> get _rawHeaders => {
    'Accept': 'application/vnd.github.raw+json',
    'Authorization': 'Bearer ${_config.readerToken}',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Map<String, dynamic> _decodeGitHubJson(String body) {
    try {
      final wrapper = jsonDecode(body);
      if (wrapper is! Map) throw const FormatException();
      final content = wrapper['content'];
      if (content is! String || content.isEmpty) throw const FormatException();
      final normalized = content.replaceAll(RegExp(r'\s'), '');
      final decoded = jsonDecode(utf8.decode(base64Decode(normalized)));
      if (decoded is! Map) throw const FormatException();
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      throw const GitHubSyncException();
    }
  }

  _GitHubMetadata _parseMetadata(Map<String, dynamic> json) {
    final exportedAtRaw = json['exportedAt']?.toString().trim() ?? '';
    final dataPath = json['dataPath']?.toString().trim() ?? '';
    final size = _parsePositiveInt(json['sizeBytes']);
    final exportedAt = DateTime.tryParse(exportedAtRaw);
    if (exportedAt == null ||
        dataPath != _config.hchPath ||
        size == null ||
        size > _maxHchBytes) {
      throw const GitHubSyncException();
    }
    return _GitHubMetadata(
      exportedAt: exportedAt.toLocal(),
      dataPath: dataPath,
      sizeBytes: size,
    );
  }

  int? _parsePositiveInt(dynamic value) {
    final number = switch (value) {
      int number => number,
      num number when number == number.roundToDouble() => number.toInt(),
      String text => int.tryParse(text.trim()),
      _ => null,
    };
    return number != null && number > 0 ? number : null;
  }
}

class _GitHubMetadata {
  const _GitHubMetadata({
    required this.exportedAt,
    required this.dataPath,
    required this.sizeBytes,
  });

  final DateTime exportedAt;
  final String dataPath;
  final int sizeBytes;
}
