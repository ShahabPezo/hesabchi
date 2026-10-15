import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show compute;
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

  /// مسیر نسخه‌ی فشرده‌ی فایل داده (نام فایل خام + «.zip»).
  String get zipPath => '$hchPath.zip';

  Uri contentUri(String path, {String? cacheBust}) => Uri.https(
    'api.github.com',
    '/repos/$owner/$repository/contents/$path',
    {'ref': branch, if (cacheBust != null) 't': cacheBust},
  );
}

class GitHubSyncException implements Exception {
  const GitHubSyncException({this.dataCorrupt = false});

  /// true یعنی فایل دریافتی خراب یا با متادیتا ناسازگار بود (نه مشکل اتصال/توکن).
  final bool dataCorrupt;
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

      final Uint8List bytes;
      if (metadata.isZip) {
        bytes = await _downloadZipped(client, metadata);
      } else {
        final dataResponse = await client
            .get(_config.contentUri(metadata.dataPath), headers: _rawHeaders)
            .timeout(_requestTimeout);
        if (dataResponse.statusCode != 200 ||
            dataResponse.bodyBytes.isEmpty) {
          throw const GitHubSyncException();
        }
        if (dataResponse.bodyBytes.length > _maxHchBytes ||
            dataResponse.bodyBytes.length != metadata.sizeBytes) {
          throw const GitHubSyncException();
        }
        bytes = dataResponse.bodyBytes;
      }

      return GitHubSyncFetchResult.downloaded(
        exportedAt: metadata.exportedAt,
        bytes: bytes,
      );
    } on GitHubSyncException {
      rethrow;
    } catch (_) {
      throw const GitHubSyncException();
    } finally {
      if (_httpClient == null) client.close();
    }
  }

  /// دریافت زیپ، آنزیپ و تطبیق حجم و SHA-256. اگر تطبیق شکست خورد، یک بار با
  /// پارامتر تصادفی دوباره دانلود می‌شود (کش ممکن است متادیتای جدید را با زیپ
  /// قدیمی ترکیب کرده باشد). اگر باز هم نخواند، داده‌ی قبلی دست‌نخورده می‌ماند.
  Future<Uint8List> _downloadZipped(
    http.Client client,
    _GitHubMetadata metadata,
  ) async {
    try {
      return await _fetchAndVerifyZip(client, metadata);
    } on GitHubSyncException {
      return _fetchAndVerifyZip(
        client,
        metadata,
        cacheBust: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }
  }

  Future<Uint8List> _fetchAndVerifyZip(
    http.Client client,
    _GitHubMetadata metadata, {
    String? cacheBust,
  }) async {
    final response = await client
        .get(
          _config.contentUri(metadata.zipPath, cacheBust: cacheBust),
          headers: _rawHeaders,
        )
        .timeout(_requestTimeout);
    final zipBytes = response.bodyBytes;
    if (response.statusCode != 200 || zipBytes.isEmpty) {
      throw const GitHubSyncException();
    }
    if (zipBytes.length != metadata.zipSizeBytes) {
      throw const GitHubSyncException(dataCorrupt: true);
    }
    final raw = await _unzip(zipBytes, metadata.innerFile);
    if (raw.length != metadata.uncompressedBytes ||
        crypto.sha256.convert(raw).toString() != metadata.sha256) {
      throw const GitHubSyncException(dataCorrupt: true);
    }
    return raw;
  }

  /// آنزیپ در isolate جدا تا رابط کاربری قفل نشود.
  Future<Uint8List> _unzip(Uint8List zipBytes, String innerFile) async {
    try {
      return await compute(
        _unzipSingleEntry,
        _UnzipRequest(zipBytes, innerFile, _maxHchBytes),
      );
    } catch (_) {
      throw const GitHubSyncException(dataCorrupt: true);
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

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  _GitHubMetadata _parseMetadata(Map<String, dynamic> json) {
    final exportedAtRaw = json['exportedAt']?.toString().trim() ?? '';
    final exportedAt = DateTime.tryParse(exportedAtRaw);
    if (exportedAt == null) throw const GitHubSyncException();

    // قالب جدید: ویندوز فایل را زیپ می‌فرستد.
    final zipPath = json['zipPath']?.toString().trim() ?? '';
    if (zipPath.isNotEmpty) {
      return _parseZipMetadata(json, exportedAt, zipPath);
    }

    // قالب قدیمی (بدون zipPath): فایل خام.
    final dataPath = json['dataPath']?.toString().trim() ?? '';
    final size = _parsePositiveInt(json['sizeBytes']);
    if (dataPath != _config.hchPath || size == null || size > _maxHchBytes) {
      throw const GitHubSyncException();
    }
    return _GitHubMetadata(
      exportedAt: exportedAt.toLocal(),
      dataPath: dataPath,
      sizeBytes: size,
    );
  }

  _GitHubMetadata _parseZipMetadata(
    Map<String, dynamic> json,
    DateTime exportedAt,
    String zipPath,
  ) {
    final format = json['format']?.toString().trim().toLowerCase() ?? 'zip';
    final zipSize = _parsePositiveInt(json['zipSizeBytes']);
    final rawSize = _parsePositiveInt(json['uncompressedBytes']);
    final innerFile = json['innerFile']?.toString().trim() ?? '';
    final sha256 = json['sha256']?.toString().trim().toLowerCase() ?? '';
    if (format != 'zip' ||
        zipPath != _config.zipPath ||
        zipSize == null ||
        zipSize > _maxHchBytes ||
        rawSize == null ||
        rawSize > _maxHchBytes ||
        innerFile.isEmpty ||
        !_sha256Pattern.hasMatch(sha256)) {
      throw const GitHubSyncException();
    }
    return _GitHubMetadata.zip(
      exportedAt: exportedAt.toLocal(),
      zipPath: zipPath,
      zipSizeBytes: zipSize,
      innerFile: innerFile,
      uncompressedBytes: rawSize,
      sha256: sha256,
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
  /// فایل خام (قالب قدیمی).
  const _GitHubMetadata({
    required this.exportedAt,
    required this.dataPath,
    required this.sizeBytes,
  }) : zipPath = '',
       zipSizeBytes = 0,
       innerFile = '',
       uncompressedBytes = 0,
       sha256 = '';

  /// فایل زیپ‌شده (قالب جدید).
  const _GitHubMetadata.zip({
    required this.exportedAt,
    required this.zipPath,
    required this.zipSizeBytes,
    required this.innerFile,
    required this.uncompressedBytes,
    required this.sha256,
  }) : dataPath = '',
       sizeBytes = 0;

  final DateTime exportedAt;
  final String dataPath;
  final int sizeBytes;
  final String zipPath;
  final int zipSizeBytes;
  final String innerFile;
  final int uncompressedBytes;
  final String sha256;

  bool get isZip => zipPath.isNotEmpty;
}

class _UnzipRequest {
  const _UnzipRequest(this.zipBytes, this.innerFile, this.maxBytes);

  final Uint8List zipBytes;
  final String innerFile;
  final int maxBytes;
}

/// فایل [_UnzipRequest.innerFile] را از زیپ بیرون می‌کشد. مستقیماً از
/// Central Directory می‌خواند، پس با زیپ‌هایی که Data Descriptor دارند هم کار می‌کند.
/// ZIP64 پشتیبانی نمی‌شود (حجم داده بسیار کمتر از ۴ گیگابایت است).
Uint8List _unzipSingleEntry(_UnzipRequest request) {
  final data = request.zipBytes;
  final view = ByteData.sublistView(data);

  var eocd = -1;
  final lowest = data.length - 22 - 65535;
  for (var i = data.length - 22; i >= 0 && i >= lowest; i--) {
    if (view.getUint32(i, Endian.little) == 0x06054b50) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) throw const FormatException('end of central directory');

  final entryCount = view.getUint16(eocd + 10, Endian.little);
  var pos = view.getUint32(eocd + 16, Endian.little);
  for (var n = 0; n < entryCount; n++) {
    if (pos + 46 > data.length ||
        view.getUint32(pos, Endian.little) != 0x02014b50) {
      throw const FormatException('central directory');
    }
    final method = view.getUint16(pos + 10, Endian.little);
    final compressedSize = view.getUint32(pos + 20, Endian.little);
    final rawSize = view.getUint32(pos + 24, Endian.little);
    final nameLength = view.getUint16(pos + 28, Endian.little);
    final extraLength = view.getUint16(pos + 30, Endian.little);
    final commentLength = view.getUint16(pos + 32, Endian.little);
    final localOffset = view.getUint32(pos + 42, Endian.little);
    final nameEnd = pos + 46 + nameLength;
    if (nameEnd > data.length) throw const FormatException('entry name');
    final name = utf8.decode(
      Uint8List.sublistView(data, pos + 46, nameEnd),
      allowMalformed: true,
    );
    pos = nameEnd + extraLength + commentLength;
    if (name != request.innerFile) continue;

    if (compressedSize == 0xFFFFFFFF || rawSize == 0xFFFFFFFF) {
      throw const FormatException('zip64');
    }
    if (rawSize > request.maxBytes) throw const FormatException('too large');
    if (localOffset + 30 > data.length ||
        view.getUint32(localOffset, Endian.little) != 0x04034b50) {
      throw const FormatException('local header');
    }
    final localNameLength = view.getUint16(localOffset + 26, Endian.little);
    final localExtraLength = view.getUint16(localOffset + 28, Endian.little);
    final start = localOffset + 30 + localNameLength + localExtraLength;
    final end = start + compressedSize;
    if (end > data.length) throw const FormatException('truncated');

    final compressed = Uint8List.sublistView(data, start, end);
    final Uint8List output;
    if (method == 0) {
      output = Uint8List.fromList(compressed);
    } else if (method == 8) {
      output = Uint8List.fromList(ZLibCodec(raw: true).decode(compressed));
    } else {
      throw FormatException('compression method $method');
    }
    if (output.length != rawSize) throw const FormatException('size');
    return output;
  }
  throw const FormatException('entry not found');
}
