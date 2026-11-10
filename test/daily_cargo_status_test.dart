import 'package:flutter_test/flutter_test.dart';
import 'package:namayeshyar/data/daily_cargo_status.dart';
import 'package:namayeshyar/data/models.dart';
import 'package:shamsi_date/shamsi_date.dart';

Invoice _invoice({
  required DateTime issuedAt,
  required String title,
  required num quantity,
  required int total,
  num? gross,
}) {
  return Invoice(
    id: 'INV-1',
    customerId: 'C-1',
    customerName: 'مشتری',
    issuedAt: issuedAt,
    dueAt: issuedAt,
    total: total,
    paid: 0,
    status: InvoiceStatus.unpaid,
    items: [
      InvoiceItem(
        title: title,
        quantity: quantity,
        unitPrice: 1,
        total: total,
        grossWeight: gross,
      ),
    ],
  );
}

StoreCargoEntry _store({required DateTime date, required num net}) {
  return StoreCargoEntry(
    id: 'SC-1',
    storeId: 'S-1',
    storeName: 'فروشگاه',
    date: date,
    grossWeightKg: net + 10,
    netWeightKg: net,
    plateOrHelper: '',
    description: '',
    createdAt: date,
  );
}

void main() {
  final dayDate = DateTime(2026, 10, 20);
  final day = Jalali.fromDateTime(dayDate);
  final noon = DateTime(2026, 10, 20, 12, 30);
  final otherDay = DateTime(2026, 10, 21, 12, 30);

  test('هفت عدد روز درست جمع و محاسبه می‌شود', () {
    final status = computeDailyCargoStatus(
      day: day,
      invoices: [
        _invoice(
          issuedAt: noon,
          title: 'ورود کارتن مشتری',
          quantity: 800,
          gross: 850,
          total: 12000000,
        ),
        _invoice(
          issuedAt: noon,
          title: 'ورود کارتن مشتری',
          quantity: 200,
          gross: 220,
          total: 3000000,
        ),
        // نوع دیگر و روز دیگر نباید شمرده شوند.
        _invoice(
          issuedAt: noon,
          title: 'ورود کاغذ',
          quantity: 999,
          gross: 999,
          total: 999,
        ),
        _invoice(
          issuedAt: otherDay,
          title: 'ورود کارتن مشتری',
          quantity: 500,
          gross: 600,
          total: 5000000,
        ),
      ],
      storeEntries: [
        _store(date: noon, net: 1250),
        _store(date: otherDay, net: 777),
      ],
    );

    expect(status.storeWeight, 1250);
    expect(status.customerGross, 1070);
    expect(status.customerNet, 1000);
    expect(status.moisture, 70);
    expect(status.cargoAmount, 15000000);
    expect(status.avgPrice, 15000);
    expect(status.totalWeight, 2250);
    expect(status.customerInvoiceCount, 2);
    expect(status.storeEntryCount, 1);
    expect(status.hasData, isTrue);
  });

  test('عنوان با پسوند کیفیت هم «ورود کارتن مشتری» حساب می‌شود', () {
    final status = computeDailyCargoStatus(
      day: day,
      invoices: [
        _invoice(
          issuedAt: noon,
          title: 'ورود کارتن مشتری - درجه ۱',
          quantity: 100,
          gross: 110,
          total: 1000,
        ),
      ],
      storeEntries: const [],
    );
    expect(status.customerNet, 100);
    expect(status.customerInvoiceCount, 1);
  });

  test('روز بدون داده: صفر و hasData نادرست، بدون تقسیم بر صفر', () {
    final status = computeDailyCargoStatus(
      day: day,
      invoices: [
        _invoice(
          issuedAt: otherDay,
          title: 'ورود کارتن مشتری',
          quantity: 10,
          total: 10,
        ),
      ],
      storeEntries: const [],
    );
    expect(status.hasData, isFalse);
    expect(status.avgPrice, 0);
    expect(status.totalWeight, 0);
  });

  test('فاکتور بدون وزن ناخالص: وزن خالص شمرده می‌شود و رطوبت صفر می‌ماند', () {
    final status = computeDailyCargoStatus(
      day: day,
      invoices: [
        _invoice(
          issuedAt: noon,
          title: 'ورود کارتن مشتری',
          quantity: 300,
          total: 4500,
        ),
      ],
      storeEntries: const [],
    );
    expect(status.customerNet, 300);
    expect(status.customerGross, 0);
    expect(status.moisture, 0);
    expect(status.avgPrice, 15);
  });
}
