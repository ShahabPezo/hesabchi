import 'package:flutter_test/flutter_test.dart';
import 'package:namayeshyar/data/models.dart';
import 'package:shamsi_date/shamsi_date.dart';

String _jalaliText(DateTime date) {
  final jalali = Jalali.fromDateTime(date);
  return '${jalali.year.toString().padLeft(4, '0')}/'
      '${jalali.month.toString().padLeft(2, '0')}/'
      '${jalali.day.toString().padLeft(2, '0')}';
}

Cheque _cheque({
  String id = 'CHQ-1',
  String status = 'دست ما (ثبت نشده)',
  String dueDate = '1404/01/01',
  String issueDate = '',
  String direction = 'in',
  String checkNumber = '',
  String partyName = '',
}) {
  return Cheque.fromJson({
    'id': id,
    'amount': 1000,
    'dueDate': dueDate,
    'issueDate': issueDate,
    'direction': direction,
    'status': status,
    'checkNumber': checkNumber,
    'partyName': partyName,
  });
}

void main() {
  const todayText = '1404/06/01';
  final today = DateTime(2026, 10, 20);
  Cheque dueIn(int days, {String status = 'دست ما (ثبت نشده)'}) => _cheque(
    status: status,
    dueDate: _jalaliText(today.add(Duration(days: days))),
  );

  group('سررسید گذشته (بدون فیلتر وضعیت)', () {
    test('سررسید قبل از امروز: سررسید گذشته است', () {
      expect(
        isChequeOverdue(_cheque(dueDate: '1404/05/30'), todayText),
        isTrue,
      );
    });

    test('سررسیدِ خودِ امروز و آینده هنوز نگذشته است', () {
      expect(isChequeOverdue(_cheque(dueDate: todayText), todayText), isFalse);
      expect(
        isChequeOverdue(_cheque(dueDate: '1404/06/02'), todayText),
        isFalse,
      );
    });

    test('وضعیت اثری ندارد؛ حتی چک پاس‌شده با سررسید گذشته', () {
      for (final status in [
        'دست ما (ثبت نشده)',
        'ثبت شده برای ما',
        'پاس شده',
        'برگشت خورده',
        'تنزیل شده',
        'وضعیت ناشناخته',
      ]) {
        expect(
          isChequeOverdue(
            _cheque(status: status, dueDate: '1404/01/01'),
            todayText,
          ),
          isTrue,
          reason: status,
        );
      }
    });

    test('چک بدون تاریخ سررسید سررسید گذشته نیست', () {
      expect(isChequeOverdue(_cheque(dueDate: ''), todayText), isFalse);
    });
  });

  group('نزدیک به سررسید (۰ تا ۷ روز، فقط چک فعال)', () {
    test('تعداد روز تا سررسید درست محاسبه می‌شود', () {
      expect(chequeDaysUntilDue(dueIn(0), today), 0);
      expect(chequeDaysUntilDue(dueIn(7), today), 7);
      expect(chequeDaysUntilDue(dueIn(-1), today), -1);
    });

    test('امروز تا هفت روز بعد (هر دو سر شامل) نزدیک به سررسید است', () {
      expect(isChequeNearDue(dueIn(0), today), isTrue);
      expect(isChequeNearDue(dueIn(3), today), isTrue);
      expect(isChequeNearDue(dueIn(7), today), isTrue);
      expect(isChequeNearDue(dueIn(8), today), isFalse);
    });

    test('چک گذشته نزدیک به سررسید نیست', () {
      expect(isChequeNearDue(dueIn(-1), today), isFalse);
    });

    test('چک دریافتی و صادره هر دو شمرده می‌شوند', () {
      final incoming = _cheque(
        direction: 'in',
        dueDate: _jalaliText(today.add(const Duration(days: 2))),
      );
      final outgoing = _cheque(
        direction: 'out',
        status: 'ثبت شده برای دیگری',
        dueDate: _jalaliText(today.add(const Duration(days: 2))),
      );
      expect(isChequeNearDue(incoming, today), isTrue);
      expect(isChequeNearDue(outgoing, today), isTrue);
    });

    test('چک غیرفعال (پاس‌شده، برگشتی، تنزیل‌شده) شمرده نمی‌شود', () {
      for (final status in ['پاس شده', 'برگشت خورده', 'تنزیل شده']) {
        expect(isChequeNearDue(dueIn(3, status: status), today), isFalse);
      }
    });

    test('تاریخ خالی یا نامعتبر خطا نمی‌دهد', () {
      expect(chequeDaysUntilDue(_cheque(dueDate: ''), today), isNull);
      expect(chequeDaysUntilDue(_cheque(dueDate: 'abc'), today), isNull);
      expect(isChequeNearDue(_cheque(dueDate: '1404/99/99'), today), isFalse);
    });
  });

  group('تاریخچه‌ی چک', () {
    test('چک‌های هم‌شماره به ترتیب تاریخ فاکتور و بعد شناسه می‌آیند', () {
      final first = _cheque(
        id: 'CHQ-9',
        checkNumber: '12345',
        issueDate: '1404/03/01',
      );
      final second = _cheque(
        id: 'CHQ-10',
        checkNumber: '12345',
        issueDate: '1404/03/01',
        direction: 'out',
      );
      final third = _cheque(
        id: 'CHQ-5',
        checkNumber: '12345',
        issueDate: '1404/04/01',
      );
      final other = _cheque(id: 'CHQ-7', checkNumber: '99999');

      final rows = chequeHistory(third, [third, other, second, first]);

      expect(rows.map((c) => c.id).toList(), ['CHQ-9', 'CHQ-10', 'CHQ-5']);
    });

    test('چک بدون شماره فقط خودش را برمی‌گرداند', () {
      final lone = _cheque(id: 'CHQ-1');
      final another = _cheque(id: 'CHQ-2');
      expect(chequeHistory(lone, [lone, another]), [lone]);
    });
  });

  group('مهاجرت نام وضعیت‌ها', () {
    test('نام‌های قدیمی به نام جدید تبدیل می‌شوند', () {
      expect(_cheque(status: 'ثبت نشده دست ما').status, 'دست ما (ثبت نشده)');
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
      expect(_cheque(status: 'چیز تازه').status, 'چیز تازه');
    });
  });
}
