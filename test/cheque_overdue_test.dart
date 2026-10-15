import 'package:flutter_test/flutter_test.dart';
import 'package:namayeshyar/data/models.dart';

Cheque _cheque({
  String status = 'دست ما (ثبت نشده)',
  String dueDate = '1404/01/01',
  String direction = 'in',
}) {
  return Cheque.fromJson({
    'id': 'CHQ-1',
    'amount': 1000,
    'dueDate': dueDate,
    'direction': direction,
    'status': status,
  });
}

void main() {
  const today = '1404/06/01';

  group('سررسید گذشته', () {
    test('سررسید قبل از امروز و وضعیت در لیست تنظیمات: سررسید گذشته است', () {
      expect(isChequeOverdue(_cheque(dueDate: '1404/05/30'), today), isTrue);
    });

    test('سررسیدِ خودِ امروز هنوز نگذشته است', () {
      expect(isChequeOverdue(_cheque(dueDate: today), today), isFalse);
    });

    test('سررسید آینده سررسید گذشته نیست', () {
      expect(isChequeOverdue(_cheque(dueDate: '1404/06/02'), today), isFalse);
    });

    test('وضعیت خارج از لیست تنظیمات سررسید گذشته حساب نمی‌شود', () {
      expect(
        isChequeOverdue(_cheque(status: 'وضعیت ناشناخته'), today),
        isFalse,
      );
    });

    test('لیست وضعیت‌ها قابل تغییر است (مثلاً بدون «پاس شده»)', () {
      final paid = _cheque(status: 'پاس شده');
      expect(isChequeOverdue(paid, today), isTrue);
      expect(
        isChequeOverdue(
          paid,
          today,
          statuses: overdueChequeStatuses.difference({'پاس شده'}),
        ),
        isFalse,
      );
    });

    test('چک بدون تاریخ سررسید سررسید گذشته نیست', () {
      expect(isChequeOverdue(_cheque(dueDate: ''), today), isFalse);
    });
  });

  group('مهاجرت نام وضعیت‌ها', () {
    test('نام‌های قدیمی به نام جدید تبدیل می‌شوند', () {
      expect(
        _cheque(status: 'ثبت نشده دست ما').status,
        'دست ما (ثبت نشده)',
      );
      expect(
        _cheque(status: 'ثبت نشده به مشتری').status,
        'دست دیگری (ثبت نشده)',
      );
      expect(
        _cheque(status: 'منتقل\u200cشده به مشتری').status,
        'دست دیگری (ثبت نشده)',
      );
      expect(
        _cheque(status: 'نزد صاحب حساب').status,
        'دست دیگری (ثبت نشده)',
      );
    });

    test('«ثبت شده برای ما» در چک صادره می‌شود «ثبت شده برای دیگری»', () {
      expect(
        _cheque(status: 'ثبت شده برای ما', direction: 'out').status,
        'ثبت شده برای دیگری',
      );
      expect(
        _cheque(status: 'ثبت شده برای ما', direction: 'in').status,
        'ثبت شده برای ما',
      );
    });

    test('نام‌های جدید و ناشناخته دست‌نخورده می‌مانند', () {
      expect(_cheque(status: 'پاس شده').status, 'پاس شده');
      expect(
        _cheque(status: 'دست ما (ثبت نشده)').status,
        'دست ما (ثبت نشده)',
      );
      expect(_cheque(status: 'چیز تازه').status, 'چیز تازه');
    });

    test('چک قدیمیِ در دست ما بعد از مهاجرت هم سررسید گذشته می‌شود', () {
      final old = _cheque(status: 'ثبت نشده دست ما', dueDate: '1404/01/01');
      expect(isChequeOverdue(old, today), isTrue);
    });
  });
}
