import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

String formatMoney(int value, {bool compact = false}) {
  // قرارداد JSON فعلی مبلغ را به ریال می‌فرستد؛ داده در ویندوز با تومان ثبت می‌شود.
  // نمایش فقط در این نقطه به تومان تبدیل می‌شود و مقدار ذخیره‌شده تغییری نمی‌کند.
  final toman = (value / 10).round();
  final formatted = NumberFormat.decimalPattern('fa').format(toman);
  return '${toPersianDigits(formatted)} تومان';
}

String formatNumber(num value) {
  final formatted = NumberFormat.decimalPattern('fa').format(value);
  return toPersianDigits(formatted);
}

/// مبلغ‌های monthlyStatus از ابتدا تومان هستند و نباید مانند مبالغ فاکتور بر ۱۰ تقسیم شوند.
String formatDirectToman(num value) => '${formatNumber(value)} تومان';

String formatWeight(num value) => '${formatNumber(value)} کیلوگرم';

String formatPercent(num value) => '${formatNumber(value)}٪';

String formatJalaliDate(DateTime date, {bool withTime = false}) {
  final jalali = Jalali.fromDateTime(date);
  final dateText =
      '${jalali.year.toString().padLeft(4, '0')}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  if (!withTime) return toPersianDigits(dateText);
  final timeText =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return '${toPersianDigits(dateText)}، ${toPersianDigits(timeText)}';
}

const List<String> persianMonthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

String toPersianDigits(String value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var result = value;
  for (var i = 0; i < latin.length; i++) {
    result = result.replaceAll(latin[i], persian[i]);
  }
  return result;
}
