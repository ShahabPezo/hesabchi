import 'package:flutter_test/flutter_test.dart';
import 'package:namayeshyar/data/factory_sales_calculator.dart';
import 'package:namayeshyar/data/models.dart';

FactorySalesEntry _entry({
  String id = 'FS-1',
  String opDate = '1404/05/01',
  String operationType = 'خروج تریلی کارتن',
  String factoryId = 'FACTORY-1',
  String factoryName = 'کارخانه الف',
  String driverName = 'رضا محمدی',
  int grossWeightKg = 24000,
  int netWeightKg = 21000,
  int unitPrice = 1200000,
  int cargoAmount = 25200000000,
  int trailerRent = 0,
  int prevBalance = 0,
  int entryAmount = 0,
  int exitAmount = 0,
  DateTime? createdAt,
}) {
  return FactorySalesEntry(
    id: id,
    opDate: opDate,
    operationType: operationType,
    factoryId: factoryId,
    factoryName: factoryName,
    driverName: driverName,
    driverNationalId: '',
    plateOrHelper: '',
    packageCount: '',
    moisturePct: null,
    grossWeightKg: grossWeightKg,
    netWeightKg: netWeightKg,
    unitPrice: unitPrice,
    cargoAmount: cargoAmount,
    trailerRent: trailerRent,
    prevBalance: prevBalance,
    entryAmount: entryAmount,
    exitAmount: exitAmount,
    createdAt: createdAt ?? DateTime(2025, 8, 3),
  );
}

void main() {
  group('FactoryStatusResult', () {
    test('جمع وزن‌ها و مبلغ‌ها به‌درستی محاسبه می‌شود', () {
      final rows = [
        _entry(cargoAmount: 100, grossWeightKg: 10, netWeightKg: 8),
        _entry(cargoAmount: 200, grossWeightKg: 20, netWeightKg: 12),
      ];

      final result = FactoryStatusResult.compute(rows);

      expect(result.totalGross, 30);
      expect(result.totalNet, 20);
      expect(result.totalCargo, 300);
    });

    test('فی میانگین اولیه و نهایی درست حساب می‌شود', () {
      final rows = [
        _entry(cargoAmount: 1000, netWeightKg: 10, trailerRent: 100),
      ];

      final result = FactoryStatusResult.compute(rows);

      expect(result.initialPrice, 100);
      // (جمع مبلغ بار + جمع کرایه تریلی) / جمع وزن خالص = (1000 + 100) / 10
      expect(result.finalPrice, 110);
    });

    test('وزن خالص صفر باعث تقسیم‌بر‌صفر نمی‌شود', () {
      final rows = [_entry(cargoAmount: 500, netWeightKg: 0)];

      final result = FactoryStatusResult.compute(rows);

      expect(result.initialPrice, 0);
      expect(result.finalPrice, 0);
    });

    test('ردیف کرایه راننده تریلی از حساب کارخانه کنار گذاشته می‌شود', () {
      final rows = [
        _entry(cargoAmount: 1000, entryAmount: 0, exitAmount: 0),
        _entry(
          operationType: 'کرایه راننده تریلی',
          cargoAmount: 0,
          exitAmount: 500,
        ),
      ];

      final result = FactoryStatusResult.compute(rows);

      // پرداختی به راننده نباید در حساب کارخانه دیده شود
      expect(result.totalPaid, 0);
      expect(result.currentBalance, 1000);
    });

    test(
      'حساب قبلی راننده‌ی تریلی از حساب کارخانه کنار گذاشته می‌شود',
      () {
        final rows = [
          _entry(
            driverName: 'راننده تریلی',
            trailerRent: 100,
            cargoAmount: 1000,
          ),
          _entry(
            operationType: 'حساب قبلی',
            driverName: 'راننده تریلی',
            cargoAmount: 0,
            prevBalance: 300,
          ),
        ];

        final result = FactoryStatusResult.compute(rows);

        expect(result.totalPrev, 0);
      },
    );

    test('حساب قبلیِ غیرمرتبط با راننده‌ی تریلی در حساب کارخانه می‌ماند', () {
      final rows = [
        _entry(
          operationType: 'حساب قبلی',
          driverName: '',
          cargoAmount: 0,
          prevBalance: 300,
        ),
      ];

      final result = FactoryStatusResult.compute(rows);

      expect(result.totalPrev, 300);
    });

    test('واریزی کارخانه با قدرمطلق جمع می‌شود', () {
      final rows = [_entry(cargoAmount: 0, entryAmount: -500)];

      final result = FactoryStatusResult.compute(rows);

      expect(result.totalDeposits, 500);
    });

    test('درصد کسر از بار به‌درستی محاسبه می‌شود', () {
      final rows = [_entry(grossWeightKg: 100, netWeightKg: 92)];

      final result = FactoryStatusResult.compute(rows);

      expect(result.moistureLossPct, 8.0);
    });

    test('وزن ناخالص صفر باعث خطای تقسیم‌بر‌صفر در درصد کسر نمی‌شود', () {
      final rows = [_entry(grossWeightKg: 0, netWeightKg: 0)];

      final result = FactoryStatusResult.compute(rows);

      expect(result.moistureLossPct, 0);
    });
  });

  group('TrailerStatusResult', () {
    test('تعداد تریلی همه‌ی سفرهای خروج را می‌شمارد حتی بدون کرایه', () {
      final rows = [
        _entry(trailerRent: 0),
        _entry(trailerRent: 100),
      ];

      final result = TrailerStatusResult.compute(
        rows: rows,
        allEntries: rows,
        driverFilter: 'همه راننده‌ها',
        allDriversOption: 'همه راننده‌ها',
        startText: null,
        endText: null,
      );

      expect(result.count, 2);
      expect(result.due, 100);
    });

    test('پرداختی و حساب قبلی راننده از کل entries محاسبه می‌شود', () {
      final rows = [_entry(driverName: 'راننده الف', trailerRent: 1000)];
      final allEntries = [
        ...rows,
        _entry(
          operationType: 'کرایه راننده تریلی',
          driverName: 'راننده الف',
          cargoAmount: 0,
          exitAmount: 400,
          factoryName: '',
        ),
        _entry(
          operationType: 'حساب قبلی',
          driverName: 'راننده الف',
          cargoAmount: 0,
          prevBalance: 100,
          factoryName: '',
        ),
      ];

      final result = TrailerStatusResult.compute(
        rows: rows,
        allEntries: allEntries,
        driverFilter: 'همه راننده‌ها',
        allDriversOption: 'همه راننده‌ها',
        startText: null,
        endText: null,
      );

      expect(result.due, 1000);
      expect(result.paid, 400);
      expect(result.prevBalance, 100);
      expect(result.balance, 700);
    });

    test('بازه‌ی تاریخ روی پرداختی/حساب قبلی راننده هم اعمال می‌شود', () {
      final rows = [_entry(driverName: 'راننده الف', trailerRent: 1000)];
      final allEntries = [
        ...rows,
        _entry(
          operationType: 'کرایه راننده تریلی',
          driverName: 'راننده الف',
          opDate: '1403/01/01',
          cargoAmount: 0,
          exitAmount: 400,
        ),
      ];

      final result = TrailerStatusResult.compute(
        rows: rows,
        allEntries: allEntries,
        driverFilter: 'همه راننده‌ها',
        allDriversOption: 'همه راننده‌ها',
        startText: '1404/01/01',
        endText: '1404/12/29',
      );

      // پرداختی ۱۴۰۳ باید خارج از بازه باشد و لحاظ نشود
      expect(result.paid, 0);
    });
  });
}
