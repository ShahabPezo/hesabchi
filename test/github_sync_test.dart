import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:namayeshyar/data/github_sync_service.dart';
import 'package:namayeshyar/data/local_store.dart';
import 'package:namayeshyar/data/models.dart';
import 'package:namayeshyar/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const config = GitHubSyncConfig(
    owner: 'owner',
    repository: 'repo',
    branch: 'main',
    metaPath: 'data/latest_meta.json',
    hchPath: 'data/latest.hch',
    readerToken: 'reader-token',
  );

  test(
    'متادیتا و HCH جدید GitHub دریافت و اعتبارسنجی اندازه می‌شوند',
    () async {
      final hch = _hch(exportedAt: '2026-08-22T10:00:00Z');
      final bytes = Uint8List.fromList(utf8.encode(hch));
      final metadata = _metadata(
        exportedAt: '2026-08-22T10:00:00Z',
        sizeBytes: bytes.length,
      );
      final requests = <http.Request>[];
      final service = GitHubSyncService(
        config: config,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/data/latest_meta.json')) {
            return _metadataResponse(metadata);
          }
          if (request.url.path.endsWith('/data/latest.hch')) {
            return http.Response.bytes(bytes, 200);
          }
          return http.Response('', 404);
        }),
      );

      final result = await service.fetchLatest(currentExportedAt: null);

      expect(result.status, GitHubSyncFetchStatus.downloaded);
      expect(result.bytes, bytes);
      expect(requests, hasLength(2));
      expect(requests.first.headers['authorization'], 'Bearer reader-token');
    },
  );

  test('اگر خروجی GitHub جدیدتر نباشد، HCH کامل دریافت نمی‌شود', () async {
    final metadata = _metadata(
      exportedAt: '2026-08-22T10:00:00Z',
      sizeBytes: 100,
    );
    var requestCount = 0;
    final service = GitHubSyncService(
      config: config,
      client: MockClient((request) async {
        requestCount++;
        return _metadataResponse(metadata);
      }),
    );

    final result = await service.fetchLatest(
      currentExportedAt: DateTime.parse('2026-08-22T10:00:00Z'),
    );

    expect(result.status, GitHubSyncFetchStatus.current);
    expect(requestCount, 1);
  });

  test('خطای شبکه GitHub به خطای کنترل‌شده تبدیل می‌شود', () async {
    final service = GitHubSyncService(
      config: config,
      client: MockClient((_) async => throw Exception('offline')),
    );

    expect(
      () => service.fetchLatest(currentExportedAt: null),
      throwsA(isA<GitHubSyncException>()),
    );
  });

  test(
    'HCH جدید فقط پس از اعتبارسنجی کامل جایگزین snapshot قبلی می‌شود',
    () async {
      SharedPreferences.setMockInitialValues({});
      final previous = BusinessDataset.fromRawJson(
        _hch(exportedAt: '2026-08-21T10:00:00Z'),
      );
      final replacementRaw = _hch(exportedAt: '2026-08-22T10:00:00Z');
      final replacement = BusinessDataset.fromRawJson(replacementRaw);
      final store = _MemoryStore(previous);
      final controller = AppController(
        store: store,
        githubSync: _FakeGateway(
          GitHubSyncFetchResult.downloaded(
            exportedAt: replacement.exportedAt,
            bytes: Uint8List.fromList(utf8.encode(replacementRaw)),
          ),
        ),
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      final result = await controller.syncFromGitHub();

      expect(result.ok, isTrue);
      expect(result.updated, isTrue);
      expect(controller.dataset?.exportedAt, replacement.exportedAt);
      expect(store.saved?.exportedAt, replacement.exportedAt);
    },
  );

  test('HCH نامعتبر دریافت‌شده، snapshot قبلی گوشی را تغییر نمی‌دهد', () async {
    SharedPreferences.setMockInitialValues({});
    final previous = BusinessDataset.fromRawJson(
      _hch(exportedAt: '2026-08-21T10:00:00Z'),
    );
    final store = _MemoryStore(previous);
    final controller = AppController(
      store: store,
      githubSync: _FakeGateway(
        GitHubSyncFetchResult.downloaded(
          exportedAt: DateTime.parse('2026-08-22T10:00:00Z'),
          bytes: Uint8List.fromList(utf8.encode('{"invalid": true}')),
        ),
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final result = await controller.syncFromGitHub();

    expect(result.ok, isFalse);
    expect(controller.dataset?.rawJson, previous.rawJson);
    expect(store.saved?.rawJson, previous.rawJson);
  });
}

http.Response _metadataResponse(Map<String, dynamic> metadata) {
  final encoded = base64Encode(utf8.encode(jsonEncode(metadata)));
  return http.Response(
    jsonEncode({'content': encoded, 'encoding': 'base64'}),
    200,
  );
}

Map<String, dynamic> _metadata({
  required String exportedAt,
  required int sizeBytes,
}) => {
  'exportedAt': exportedAt,
  'dataPath': 'data/latest.hch',
  'sizeBytes': sizeBytes,
};

String _hch({required String exportedAt}) =>
    '''
{
  "version": 1,
  "exportedAt": "$exportedAt",
  "business": {"name": "کسب‌وکار آزمایشی", "currency": "IRR"},
  "customers": [],
  "invoices": [],
  "prices": []
}
''';

class _FakeGateway implements GitHubSyncGateway {
  const _FakeGateway(this.result);

  final GitHubSyncFetchResult result;

  @override
  Future<GitHubSyncFetchResult> fetchLatest({
    required DateTime? currentExportedAt,
  }) async => result;
}

class _MemoryStore extends LocalStore {
  _MemoryStore(this.saved);

  BusinessDataset? saved;

  @override
  Future<BusinessDataset?> loadDataset() async => saved;

  @override
  Future<void> saveDataset(BusinessDataset dataset) async {
    saved = dataset;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }

  @override
  Future<void> close() async {}
}
