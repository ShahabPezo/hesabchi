import 'dart:convert';
import 'dart:typed_data';

import 'models.dart';

class ImportService {
  const ImportService();

  BusinessDataset parseBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ImportValidationException('فایل انتخاب‌شده خالی است.');
    }
    String source;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const ImportValidationException(
        'رمزگذاری فایل پشتیبانی نمی‌شود. فایل را با UTF-8 ذخیره کنید.',
      );
    }
    return BusinessDataset.fromRawJson(source);
  }
}
