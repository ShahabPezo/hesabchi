import 'package:shamsi_date/shamsi_date.dart';

import 'models.dart';

/// عنوان آیتم فاکتور مشتری برای «ورود کارتن مشتری». ممکن است پسوندی مثل
/// « - کیفیت» هم داشته باشد، پس با پیشوند مقایسه می‌شود.
const dailyCustomerCartonTitle = 'ورود کارتن مشتری';

/// وضعیت روزانه‌ی کارتن برای یک روز (هم‌سان بخش «وضعیت روزانه کارتن» ویندوز).
class DailyCargoStatus {
  const DailyCargoStatus({
    required this.storeWeight,
    required this.customerGross,
    required this.customerNet,
    required this.moisture,
    required this.cargoAmount,
    required this.avgPrice,
    required this.totalWeight,
    required this.customerInvoiceCount,
    required this.storeEntryCount,
  });

  /// جمع وزن خالص «ورود کارتن فروشگاه».
  final num storeWeight;

  /// جمع وزن ناخالص «ورود کارتن مشتری».
  final num customerGross;

  /// جمع وزن خالص «ورود کارتن مشتری».
  final num customerNet;

  /// رطوبت کسرشده = ناخالص − خالص (فقط روی آیتم‌هایی که وزن ناخالص دارند).
  final num moisture;

  /// جمع مبلغ بار «ورود کارتن مشتری» (هم‌واحد با مبالغ فاکتور).
  final int cargoAmount;

  /// فی میانگین = مبلغ بار ÷ وزن خالص مشتری (اگر وزن صفر بود ۰).
  final double avgPrice;

  /// وزن بار فروشگاه + وزن خالص مشتری.
  final num totalWeight;

  final int customerInvoiceCount;
  final int storeEntryCount;

  bool get hasData => customerInvoiceCount > 0 || storeEntryCount > 0;
}

DailyCargoStatus computeDailyCargoStatus({
  required Iterable<Invoice> invoices,
  required Iterable<StoreCargoEntry> storeEntries,
  required Jalali day,
}) {
  final target = day.toDateTime();
  bool sameDay(DateTime date) =>
      date.year == target.year &&
      date.month == target.month &&
      date.day == target.day;

  num storeWeight = 0;
  var storeCount = 0;
  for (final entry in storeEntries) {
    if (!sameDay(entry.date)) continue;
    storeWeight += entry.netWeightKg;
    storeCount++;
  }

  num gross = 0;
  num net = 0;
  num moisture = 0;
  var amount = 0;
  var invoiceCount = 0;
  for (final invoice in invoices) {
    if (!sameDay(invoice.issuedAt)) continue;
    var counted = false;
    for (final item in invoice.items) {
      if (!item.title.trim().startsWith(dailyCustomerCartonTitle)) continue;
      counted = true;
      net += item.quantity;
      amount += item.total;
      final itemGross = item.grossWeight;
      if (itemGross != null) {
        gross += itemGross;
        moisture += itemGross - item.quantity;
      }
    }
    if (counted) invoiceCount++;
  }

  return DailyCargoStatus(
    storeWeight: storeWeight,
    customerGross: gross,
    customerNet: net,
    moisture: moisture,
    cargoAmount: amount,
    avgPrice: net > 0 ? amount / net : 0.0,
    totalWeight: storeWeight + net,
    customerInvoiceCount: invoiceCount,
    storeEntryCount: storeCount,
  );
}
