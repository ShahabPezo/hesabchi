import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:namayeshyar/data/github_sync_service.dart';

// زیپ واقعی با یک فایل «latest.hch» (فشرده‌شده با deflate، مثل خروجی ویندوز).
const _zipBase64 =
    'UEsDBBQAAAAIAIIuT13ki14SSgEAAHMIAAAKAAAAbGF0ZXN0LmhjaHXVO0oEURRF0anIizvo++tP'
    'TUXMrKDAD9iFSdOBmTMRzZxNtaNREN6pZOc7WlzOPbfX8eU0PT+1ITdtmsfHUxtuz226b8N20+Zp'
    'fhjb0K5vy8fP5/J1fV++b7btsvkvDArrhUPhvQgoohcJRfaioKhe7KDY9WIPxb4XBygOvThCcZQY'
    'odpKFVnlagRrkjWiNdka4Zp0jXhNvkbAJmEjYpOxEbJJ2YjZ5Ozk7HJ2cvbV/eIBy9nJ2eXs5Oxy'
    'dnJ2OTs5u5ydnF3OTs4uZydnl3OQc8g5yDnkHOQcq6XAqZBzkHPIOcg55BzkHHIOcg45BzmHnIOc'
    'Q85JzinnJOeUc5JzyjnJOVebjKMs5yTnlHOSc8o5yTnlnOScck5yTjkXOZeci5xLzkXOJeci55Jz'
    'kXOtvh++PzkXOZeci5xLzkXOJeci5/pzvrv8AlBLAQIUAxQAAAAIAIIuT13ki14SSgEAAHMIAAAK'
    'AAAAAAAAAAAAAACAAQAAAABsYXRlc3QuaGNoUEsFBgAAAAABAAEAOAAAAHIBAAAAAA==';
const _innerSha256 =
    '68f7598853144cce1441335a19560598a7c6fceb3baa8aa911a87f3f27d15d54';

const _config = GitHubSyncConfig(
  owner: 'owner',
  repository: 'repo',
  branch: 'main',
  metaPath: 'data/latest_meta.json',
  hchPath: 'data/latest.hch',
  readerToken: 'token',
);

/// همان متنی که داخل زیپ است (۶۰ آیتم فارسی).
Uint8List _innerBytes() {
  final items = List.generate(
    60,
    (i) => '{"id":$i,"title":"فاکتور $i"}',
  ).join(',');
  return Uint8List.fromList(utf8.encode('{"version":4,"items":[$items]}'));
}

Map<String, Object?> _meta({
  String dataPath = 'data/latest.hch.zip',
  String? sha256,
}) => {
  'exportedAt': '2026-10-20T10:15:00',
  'dataPath': dataPath,
  'sizeBytes': base64Decode(_zipBase64).length,
  'format': 'zip',
  'zipPath': 'data/latest.hch.zip',
  'zipSizeBytes': base64Decode(_zipBase64).length,
  'innerFile': 'latest.hch',
  'uncompressedBytes': _innerBytes().length,
  'sha256': sha256 ?? _innerSha256,
};

http.Response _metaResponse(Map<String, Object?> meta) => http.Response(
  jsonEncode({'content': base64Encode(utf8.encode(jsonEncode(meta)))}),
  200,
);

void main() {
  test('متادیتای زیپ: فایل دانلود، آنزیپ و با SHA-256 تطبیق داده می‌شود', () async {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/data/latest_meta.json')) {
        // فایل خام هم کنار زیپ هست؛ ولی باید زیپ ترجیح داده شود.
        return _metaResponse(_meta(dataPath: 'data/latest.hch'));
      }
      if (path.endsWith('/data/latest.hch.zip')) {
        return http.Response.bytes(base64Decode(_zipBase64), 200);
      }
      if (path.endsWith('/data/latest.hch')) {
        return http.Response.bytes(utf8.encode('WRONG'), 200);
      }
      return http.Response('not found', 404);
    });
    final service = GitHubSyncService(config: _config, client: client);

    final result = await service.fetchLatest(currentExportedAt: null);

    expect(result.status, GitHubSyncFetchStatus.downloaded);
    expect(result.bytes, equals(_innerBytes()));
  });

  test('SHA-256 نادرست: خطای داده‌ی خراب و بدون ذخیره‌ی چیزی', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/data/latest_meta.json')) {
        return _metaResponse(_meta(sha256: 'a' * 64));
      }
      return http.Response.bytes(base64Decode(_zipBase64), 200);
    });
    final service = GitHubSyncService(config: _config, client: client);

    await expectLater(
      service.fetchLatest(currentExportedAt: null),
      throwsA(
        isA<GitHubSyncException>().having(
          (e) => e.dataCorrupt,
          'dataCorrupt',
          isTrue,
        ),
      ),
    );
  });

  test('اگر بار اول زیپ ناسازگار بود، یک بار با پارامتر تصادفی دوباره می‌خواند', () async {
    var zipRequests = 0;
    final cacheBustValues = <String?>[];
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/data/latest_meta.json')) {
        return _metaResponse(_meta());
      }
      if (path.endsWith('/data/latest.hch.zip')) {
        zipRequests++;
        cacheBustValues.add(request.url.queryParameters['t']);
        if (zipRequests == 1) {
          return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
        }
        return http.Response.bytes(base64Decode(_zipBase64), 200);
      }
      return http.Response('not found', 404);
    });
    final service = GitHubSyncService(config: _config, client: client);

    final result = await service.fetchLatest(currentExportedAt: null);

    expect(result.bytes, equals(_innerBytes()));
    expect(zipRequests, 2);
    expect(cacheBustValues.first, isNull);
    expect(cacheBustValues.last, isNotNull);
  });

  test('متادیتای زیپ با مسیر غیرمجاز رد می‌شود', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/data/latest_meta.json')) {
        final meta = _meta()..['zipPath'] = 'secrets/other.zip';
        return _metaResponse(meta);
      }
      return http.Response('not found', 404);
    });
    final service = GitHubSyncService(config: _config, client: client);

    await expectLater(
      service.fetchLatest(currentExportedAt: null),
      throwsA(isA<GitHubSyncException>()),
    );
  });
}
