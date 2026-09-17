import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namayeshyar/data/employee_salary_calculator.dart';
import 'package:namayeshyar/data/models.dart';
import 'package:namayeshyar/screens/customer_directory_screen.dart';
import 'package:namayeshyar/screens/employee_salary_screen.dart';
import 'package:namayeshyar/screens/factory_sales_screen.dart';
import 'package:namayeshyar/screens/home_screen.dart';
import 'package:namayeshyar/screens/main_shell.dart';
import 'package:namayeshyar/screens/settings_screen.dart';
import 'package:namayeshyar/screens/statistics_screen.dart';
import 'package:namayeshyar/screens/store_status_screen.dart';
import 'package:namayeshyar/state/app_controller.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  const validJson = '''
  {
    "version": 1,
    "exportedAt": "2026-08-20T10:30:00Z",
    "business": {"name": "کسب‌وکار آزمایشی", "currency": "IRR"},
    "customers": [
      {"id": "C-1", "name": "مشتری آزمایشی", "phone": "", "balance": 120000, "updatedAt": "2026-08-20T10:00:00Z"}
    ],
    "invoices": [
      {
        "id": "I-1", "customerId": "C-1", "customerName": "مشتری آزمایشی",
        "issuedAt": "2026-08-19T00:00:00Z", "dueAt": "2026-08-25T00:00:00Z",
        "total": 120000, "paid": 0, "status": "unpaid",
        "items": [{"title": "کالا", "quantity": 1, "unitPrice": 120000, "total": 120000}]
      }
    ],
    "prices": [
      {"id": "P-1", "title": "کالا", "sku": "A1", "price": 120000, "updatedAt": "2026-08-20T10:00:00Z"}
    ]
  }
  ''';

  const directoryJson = '''
  {
    "version": 1,
    "exportedAt": "2026-08-20T10:30:00Z",
    "business": {"name": "کسب‌وکار آزمایشی", "currency": "IRR"},
    "customers": [
      {"id": "C-1", "name": "مشتری آزمایشی", "phone": "", "balance": 120000, "updatedAt": "2026-08-20T10:00:00Z"},
      {"id": "C-2", "name": "مشتری بدون فاکتور", "phone": "", "balance": 0, "updatedAt": "2026-08-20T10:00:00Z"}
    ],
    "invoices": [
      {
        "id": "I-1", "customerId": "C-1", "customerName": "مشتری آزمایشی",
        "issuedAt": "2026-06-10T00:00:00Z", "dueAt": "2026-06-15T00:00:00Z",
        "total": 60000, "paid": 0, "status": "unpaid",
        "items": [{"title": "کالا", "quantity": 1, "unitPrice": 60000, "total": 60000}]
      },
      {
        "id": "I-2", "customerId": "C-1", "customerName": "مشتری آزمایشی",
        "issuedAt": "2026-08-19T00:00:00Z", "dueAt": "2026-08-25T00:00:00Z",
        "total": 120000, "paid": 0, "status": "unpaid",
        "items": [{"title": "کالا", "quantity": 1, "unitPrice": 120000, "total": 120000}]
      },
      {
        "id": "I-3", "customerId": "C-1", "customerName": "مشتری آزمایشی",
        "issuedAt": "2026-07-01T00:00:00Z", "dueAt": "2026-07-05T00:00:00Z",
        "total": 30000, "paid": 0, "status": "unpaid",
        "items": [{"title": "کالا", "quantity": 1, "unitPrice": 30000, "total": 30000}]
      }
    ],
    "prices": []
  }
  ''';

  test('داده نسخه یک معتبر تحلیل و نگهداری می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(validJson);

    expect(dataset.business.name, 'کسب‌وکار آزمایشی');
    expect(dataset.customers, hasLength(1));
    expect(dataset.invoices.single.remaining, 120000);
    expect(dataset.prices.single.sku, 'A1');
    expect(dataset.scope.type, InvoiceScopeType.all);
    expect(dataset.scope.displayText, 'کل فاکتورها');
    expect(dataset.monthlyStatuses, isEmpty);
    expect(dataset.employeeSalaries, isEmpty);
  });

  test('بازه فاکتورها از کلید scope فایل HCH خوانده می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(_rangedJson(validJson));

    expect(dataset.scope.type, InvoiceScopeType.range);
    expect(dataset.scope.displayText, 'از 1404/01/01 تا 1404/06/31');
  });

  testWidgets('تب خانه با فایل قدیمی بدون scope رندر می‌شود', (tester) async {
    await _pumpHome(tester, validJson);

    expect(find.text('سلام، خوش آمدید'), findsOneWidget);
    expect(find.text('کل فاکتورها'), findsOneWidget);
  });

  testWidgets('تب خانه با فایل بازه‌دار بدون توقف رندر می‌کند', (tester) async {
    await _pumpHome(tester, _rangedJson(validJson));

    expect(find.text('از ۱۴۰۴/۰۱/۰۱ تا ۱۴۰۴/۰۶/۳۱'), findsOneWidget);
  });

  test('داده وضعیت ماهانه HCH خوانده و بر اساس ماه مرتب می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(_monthlyJson(validJson));

    expect(dataset.monthlyStatuses, hasLength(2));
    expect(dataset.monthlyStatuses.last.monthLabel, '1404/06');
    expect(dataset.monthlyStatuses.last.topCustomers.first.name, 'شرکت الف');
    expect(dataset.monthlyStatuses.last.cargoCustomer.cargoAmount, 850000000);
  });

  testWidgets('تب آمار برای فایل HCH قدیمی حالت خالی سازگار نشان می‌دهد', (
    tester,
  ) async {
    await _pumpStatistics(tester, validJson);

    expect(find.text('داده‌ای برای آمار ماهانه موجود نیست'), findsOneWidget);
  });

  testWidgets('تب آمار جدیدترین ماه و مشتری برتر را رندر می‌کند', (
    tester,
  ) async {
    await _pumpStatistics(tester, _monthlyJson(validJson));

    expect(find.text('۱۴۰۴/۰۶'), findsOneWidget);
    expect(find.text('وضعیت ماهانه بار تفکیکی'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('۶٬۲۹۵ تومان / کیلو'), 360);
    expect(find.text('۶٬۲۹۵ تومان / کیلو'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('شرکت الف'), 360);
    expect(find.text('شرکت الف'), findsOneWidget);
  });

  testWidgets('آمار و گزینه‌های منوی بیشتر در دسترس‌اند', (tester) async {
    await _pumpShell(tester, validJson);

    await tester.tap(find.text('آمار'));
    await tester.pumpAndSettle();
    expect(find.text('داده‌ای برای آمار ماهانه موجود نیست'), findsOneWidget);

    await tester.tap(find.text('بیشتر'));
    await tester.pumpAndSettle();
    expect(find.text('حقوق افراد'), findsOneWidget);
    expect(find.text('فاکتورهای مشتری'), findsOneWidget);
    expect(find.text('دفترچه مشتریان'), findsOneWidget);
    expect(find.text('وضعیت فروشگاه‌ها'), findsOneWidget);
    expect(find.text('فروش به کارخانه‌ها'), findsOneWidget);
    final settingsTile = find.widgetWithText(ListTile, 'تنظیمات');
    expect(settingsTile, findsOneWidget);
    await tester.ensureVisible(settingsTile);
    await tester.pumpAndSettle();

    await tester.tap(settingsTile);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'تنظیمات'), findsOneWidget);
    expect(find.text('اطلاعات دیتابیس'), findsOneWidget);
  });

  test('داده اختیاری حقوق افراد HCH خوانده می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(_employeeSalaryJson(validJson));

    expect(dataset.employeeSalaries, hasLength(1));
    expect(dataset.employeeSalaries.single.name, 'علی رضایی');
    expect(dataset.employeeSalaries.single.extraServices, hasLength(3));
    expect(dataset.employeeSalaries.single.hireDate, isNull);
    expect(dataset.employeeSalaries.single.terminationDate, isNull);
  });

  test('فیلدهای اختیاری hireDate/terminationDate کارمند خوانده می‌شوند', () {
    final dataset = BusinessDataset.fromRawJson(
      _employeeSalaryJson(validJson).replaceFirst(
        '"name": "علی رضایی",',
        '"name": "علی رضایی", "hireDate": "1403/05/10", "terminationDate": "1404/06/01",',
      ),
    );

    expect(dataset.employeeSalaries.single.hireDate, '1403/05/10');
    expect(dataset.employeeSalaries.single.terminationDate, '1404/06/01');
  });

  test('تاریخ پایان بازه بعد از پایان همکاری محدود می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(
      _employeeSalaryJson(validJson).replaceFirst(
        '"name": "علی رضایی",',
        '"name": "علی رضایی", "hireDate": "1403/05/10", "terminationDate": "1404/06/01",',
      ),
    );
    final employee = dataset.employeeSalaries.single;

    final result = EmployeeSalaryCalculator.clampToEmployment(
      employee: employee,
      start: Jalali(1404, 6, 1),
      end: Jalali(1404, 6, 31),
    );

    expect(result.end, Jalali(1404, 6, 1));
    expect(result.message, contains('پایان یافته'));
  });

  test('تاریخ شروع بازه قبل از شروع همکاری محدود می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(
      _employeeSalaryJson(validJson).replaceFirst(
        '"name": "علی رضایی",',
        '"name": "علی رضایی", "hireDate": "1403/05/10", "terminationDate": "1404/06/01",',
      ),
    );
    final employee = dataset.employeeSalaries.single;

    final result = EmployeeSalaryCalculator.clampToEmployment(
      employee: employee,
      start: Jalali(1403, 1, 1),
      end: Jalali(1403, 6, 30),
    );

    expect(result.start, Jalali(1403, 5, 10));
    expect(result.message, contains('شروع همکاری'));
  });

  test('بازه‌ی داخل محدوده‌ی همکاری بدون تغییر باقی می‌ماند', () {
    final dataset = BusinessDataset.fromRawJson(
      _employeeSalaryJson(validJson).replaceFirst(
        '"name": "علی رضایی",',
        '"name": "علی رضایی", "hireDate": "1403/05/10", "terminationDate": "1404/06/01",',
      ),
    );
    final employee = dataset.employeeSalaries.single;

    final result = EmployeeSalaryCalculator.clampToEmployment(
      employee: employee,
      start: Jalali(1404, 4, 1),
      end: Jalali(1404, 4, 30),
    );

    expect(result.start, Jalali(1404, 4, 1));
    expect(result.end, Jalali(1404, 4, 30));
    expect(result.message, isNull);
  });

  test('نبود hireDate/terminationDate هیچ محدودیتی اعمال نمی‌کند', () {
    final dataset = BusinessDataset.fromRawJson(_employeeSalaryJson(validJson));
    final employee = dataset.employeeSalaries.single;

    final result = EmployeeSalaryCalculator.clampToEmployment(
      employee: employee,
      start: Jalali(1380, 1, 1),
      end: Jalali(1410, 12, 29),
    );

    expect(result.start, Jalali(1380, 1, 1));
    expect(result.end, Jalali(1410, 12, 29));
    expect(result.message, isNull);
  });

  testWidgets('صفحه حقوق افراد برای HCH قدیمی بدون داده کرش نمی‌کند', (
    tester,
  ) async {
    final controller = _DatasetController(
      BusinessDataset.fromRawJson(validJson),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: controller,
        child: const MaterialApp(home: EmployeeSalaryScreen()),
      ),
    );

    expect(
      find.text('داده‌ای برای حقوق افراد در این فایل موجود نیست.'),
      findsOneWidget,
    );
  });

  testWidgets('تنظیمات با داده پاک‌شده رندر خطرناک ندارد', (tester) async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: controller,
        child: MaterialApp(
          home: SettingsScreen(
            onImport: _noOp,
            onDataCleared: _noOp,
            onSync: _noOpAsync,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('نسخه پشتیبانی‌نشده با خطای قابل فهم رد می‌شود', () {
    final unsupported = validJson.replaceFirst('"version": 1', '"version": 4');

    expect(
      () => BusinessDataset.fromRawJson(unsupported),
      throwsA(
        isA<ImportValidationException>().having(
          (error) => error.message,
          'message',
          contains('پشتیبانی نمی‌شود'),
        ),
      ),
    );
  });

  test('نسخه ۲ فایل بدون خطا پردازش می‌شود', () {
    final v2 = validJson.replaceFirst('"version": 1', '"version": 2');

    final dataset = BusinessDataset.fromRawJson(v2);

    expect(dataset.version, 2);
    expect(dataset.factorySales.entries, isEmpty);
  });

  test('داده اختیاری فروش به کارخانه‌ها HCH خوانده می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(_factorySalesJson(validJson));

    expect(dataset.factorySales.factories, hasLength(1));
    expect(dataset.factorySales.factories.single.name, 'کارخانه تست');
    expect(dataset.factorySales.entries, hasLength(1));
    final entry = dataset.factorySales.entries.single;
    expect(entry.opDate, '1404/05/01');
    expect(entry.trailerRent, 5000000);
    expect(entry.driverName, 'راننده تست');
  });

  test('نبود فروش به کارخانه‌ها در HCH قدیمی خطا ایجاد نمی‌کند', () {
    final dataset = BusinessDataset.fromRawJson(validJson);

    expect(dataset.factorySales.factories, isEmpty);
    expect(dataset.factorySales.entries, isEmpty);
  });

  testWidgets(
    'صفحه فروش به کارخانه‌ها برای HCH قدیمی بدون داده کرش نمی‌کند',
    (tester) async {
      final controller = _DatasetController(
        BusinessDataset.fromRawJson(validJson),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppController>.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(body: const FactorySalesScreen()),
          ),
        ),
      );

      expect(
        find.text('داده‌ای برای فروش به کارخانه‌ها در این فایل موجود نیست.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'صفحه فروش به کارخانه‌ها وضعیت کارخانه و تریلی‌ها را نشان می‌دهد',
    (tester) async {
      final controller = _DatasetController(
        BusinessDataset.fromRawJson(_factorySalesJson(validJson)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppController>.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(body: const FactorySalesScreen()),
          ),
        ),
      );

      expect(find.text('وضعیت کارخانه'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('وضعیت تریلی‌ها'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      expect(find.text('وضعیت تریلی‌ها'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('کارخانه تست'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      expect(find.text('کارخانه تست'), findsOneWidget);
    },
  );

  testWidgets(
    'لمس ردیف راننده در فروش به کارخانه‌ها به صفحه جزئیات فاکتورها می‌رود',
    (tester) async {
      final controller = _DatasetController(
        BusinessDataset.fromRawJson(_factorySalesJson(validJson)),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppController>.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(body: const FactorySalesScreen()),
          ),
        ),
      );

      await tester.dragUntilVisible(
        find.text('کارخانه تست'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.tap(find.text('کارخانه تست'));
      await tester.pumpAndSettle();

      expect(find.text('جزئیات فاکتورها'), findsOneWidget);
      expect(find.textContaining('کارخانه تست'), findsWidgets);

      await tester.tap(find.text('شماره فاکتور: FS-1'));
      await tester.pumpAndSettle();

      expect(find.text('نوع عملیات'), findsOneWidget);
    },
  );

  test('داده اختیاری وضعیت فروشگاه‌ها HCH خوانده می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(_storeStatusJson(validJson));

    expect(dataset.storeStatus.stores, hasLength(1));
    expect(dataset.storeStatus.stores.single.name, 'فروشگاه تست');
    expect(dataset.storeStatus.cargoEntries, hasLength(1));
    expect(dataset.storeStatus.cargoEntries.single.netWeightKg, 500);
    expect(dataset.storeStatus.rentalStatus, hasLength(1));
    expect(dataset.storeStatus.rentalStatus.single.months, hasLength(1));
  });

  test('نبود وضعیت فروشگاه‌ها در HCH قدیمی خطا ایجاد نمی‌کند', () {
    final dataset = BusinessDataset.fromRawJson(validJson);

    expect(dataset.storeStatus.stores, isEmpty);
    expect(dataset.storeStatus.cargoEntries, isEmpty);
    expect(dataset.storeStatus.rentalStatus, isEmpty);
  });

  testWidgets('صفحه وضعیت فروشگاه‌ها برای HCH قدیمی بدون داده کرش نمی‌کند', (
    tester,
  ) async {
    final controller = _DatasetController(
      BusinessDataset.fromRawJson(validJson),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: controller,
        child: const MaterialApp(home: StoreStatusScreen()),
      ),
    );

    expect(
      find.text('داده‌ای برای وضعیت فروشگاه‌ها در این فایل موجود نیست.'),
      findsOneWidget,
    );
  });

  testWidgets('صفحه وضعیت فروشگاه‌ها فاکتور ورود کارتن را نشان می‌دهد', (
    tester,
  ) async {
    final controller = _DatasetController(
      BusinessDataset.fromRawJson(_storeStatusJson(validJson)),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: controller,
        child: const MaterialApp(home: StoreStatusScreen()),
      ),
    );

    expect(find.text('فروشگاه تست'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('وضعیت اجاره'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    expect(find.text('وضعیت اجاره'), findsOneWidget);
  });

  test('گروگذاری فاکتور برای هر مشتری در دفترچه مشتریان محاسبه می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(directoryJson);

    expect(dataset.customers, hasLength(2));
    expect(dataset.invoices, hasLength(3));
  });

  test('فیلد اختیاری grossWeight آیتم فاکتور خوانده می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(
      validJson.replaceFirst(
        '{"title": "کالا", "quantity": 1, "unitPrice": 120000, "total": 120000}',
        '{"title": "کالا", "quantity": 1, "grossWeight": 5, "unitPrice": 120000, "total": 120000}',
      ),
    );

    expect(dataset.invoices.single.items.single.grossWeight, 5);
  });

  test('نبود grossWeight در فایل قدیمی خطا ایجاد نمی‌کند', () {
    final dataset = BusinessDataset.fromRawJson(validJson);

    expect(dataset.invoices.single.items.single.grossWeight, isNull);
  });

  test('فیلد اختیاری phones مشتری خوانده می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(
      validJson.replaceFirst(
        '{"id": "C-1", "name": "مشتری آزمایشی", "phone": "", "balance": 120000, "updatedAt": "2026-08-20T10:00:00Z"}',
        '{"id": "C-1", "name": "مشتری آزمایشی", "phone": "09120000000", "phones": ["09120000000", "09121111111", "09120000000"], "balance": 120000, "updatedAt": "2026-08-20T10:00:00Z"}',
      ),
    );

    expect(dataset.customers.single.phones, [
      '09120000000',
      '09121111111',
    ]);
  });

  test('نبود phones در فایل قدیمی از phone تکی ساخته می‌شود', () {
    final dataset = BusinessDataset.fromRawJson(validJson);

    expect(dataset.customers.single.phones, isEmpty);
    expect(dataset.customers.single.phone, isEmpty);
  });

  testWidgets('دفترچه مشتریان مشتری بدون فاکتور را هم نشان می‌دهد', (
    tester,
  ) async {
    final controller = _DatasetController(
      BusinessDataset.fromRawJson(directoryJson),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: controller,
        child: MaterialApp(
          home: Scaffold(body: const CustomerDirectoryScreen()),
        ),
      ),
    );

    expect(find.text('مشتری آزمایشی'), findsOneWidget);
    expect(find.text('مشتری بدون فاکتور'), findsOneWidget);
    expect(find.text('بدون فاکتور ثبت‌شده'), findsOneWidget);
  });

  test('فاکتور با مشتری ناشناخته رد می‌شود', () {
    final brokenReference = validJson.replaceFirst(
      '"customerId": "C-1"',
      '"customerId": "C-999"',
    );

    expect(
      () => BusinessDataset.fromRawJson(brokenReference),
      throwsA(isA<ImportValidationException>()),
    );
  });
}

String _monthlyJson(String source) =>
    source.replaceFirst('"prices": [', '''"monthlyStatus": [
    {
      "year": 1404,
      "month": 5,
      "monthLabel": "1404/05",
      "cargoCustomer": {"customerGrossWeight": 1000, "customerNetWeight": 950, "cargoAmount": 7000000, "moisturePercent": 5, "paperWeight": 50, "customerWeight": 900, "customerPrice": 7777},
      "cargoStore": {"storeNetWeight": 600, "storeRentTotal": 1000000, "nylonWeight": 30, "plasticWeight": 20, "guniWeight": 10, "storeCartonWeight": 540, "storeCartonPrice": 1851},
      "overallTotals": {"customerWeight": 900, "storeCartonWeight": 540, "netInputCarton": 1440, "inputCartonPrice": 4861},
      "topCustomers": [{"rank": 1, "name": "شرکت قدیمی", "netWeight": 900, "percent": 100}]
    },
    {
      "year": 1404,
      "month": 6,
      "monthLabel": "1404/06",
      "cargoCustomer": {"customerGrossWeight": 125000, "customerNetWeight": 118500, "cargoAmount": 850000000, "moisturePercent": 5.2, "paperWeight": 3200, "customerWeight": 115300, "customerPrice": 7371.0},
      "cargoStore": {"storeNetWeight": 42000, "storeRentTotal": 120000000, "nylonWeight": 1800, "plasticWeight": 900, "guniWeight": 400, "storeCartonWeight": 38900, "storeCartonPrice": 3084.8},
      "overallTotals": {"customerWeight": 115300, "storeCartonWeight": 38900, "netInputCarton": 154200, "inputCartonPrice": 6294.5},
      "topCustomers": [{"rank": 1, "name": "شرکت الف", "netWeight": 32000, "percent": 27.8}, {"rank": 2, "name": "شرکت ب", "netWeight": 21000, "percent": 18.2}]
    }
  ],
  "prices": [''');

String _employeeSalaryJson(String source) =>
    source.replaceFirst('"prices": [', '''"employeeSalary": [
    {
      "name": "علی رضایی",
      "phone": "09121234567",
      "profileHistory": [
        {"actionDate": "1404/04/01", "baseSalary": 18000000, "startDate": "1403/05/10", "lastSettleDate": "1404/04/01", "lastBalance": -200000}
      ],
      "offdays": [{"date": "1404/04/05"}],
      "extraServices": [{"date": "1404/04/03"}, {"date": "1404/04/03"}, {"date": "1404/04/20"}],
      "deposits": [{"amount": 5000000, "billingYear": 1404, "billingMonth": 4}],
      "previousAccountEntries": [{"date": "1404/04/02", "amount": -150000}]
    }
  ],
  "prices": [''');

String _factorySalesJson(String source) =>
    source.replaceFirst('"prices": [', '''"factorySales": {
    "factories": [{"id": "FACTORY-1", "name": "کارخانه تست"}],
    "entries": [
      {
        "id": "FS-1",
        "opDate": "1404/05/01",
        "operationType": "خروج تریلی کارتن",
        "factoryId": "FACTORY-1",
        "factoryName": "کارخانه تست",
        "driverName": "راننده تست",
        "driverNationalId": "",
        "plateOrHelper": "12ب345",
        "packageCount": "10",
        "moisturePct": 12.5,
        "grossWeightKg": 24000,
        "netWeightKg": 21000,
        "unitPrice": 1200000,
        "cargoAmount": 25200000000,
        "trailerRent": 5000000,
        "prevBalance": 0,
        "entryAmount": 0,
        "exitAmount": 0,
        "createdAt": "2025-07-23T00:00:00Z"
      }
    ]
  },
  "prices": [''');

String _storeStatusJson(String source) =>
    source.replaceFirst('"prices": [', '''"storeStatus": {
    "stores": [{"id": "STORE-1", "name": "فروشگاه تست"}],
    "cargoEntries": [
      {
        "id": "SC-1",
        "storeId": "STORE-1",
        "storeName": "فروشگاه تست",
        "date": "2024-07-31T00:00:00Z",
        "grossWeightKg": 520.0,
        "netWeightKg": 500.0,
        "plateOrHelper": "12ب345",
        "description": "",
        "createdAt": "2024-07-31T00:00:00Z"
      }
    ],
    "rentalStatus": [
      {
        "storeId": "STORE-1",
        "storeName": "فروشگاه تست",
        "contract": {"startDate": "1403/01/01", "endDate": null, "deposit": 50000000, "monthlyRent": 20000000},
        "months": [
          {"year": 1403, "month": 1, "monthLabel": "فروردین 1403", "rentDue": 20000000, "paid": 0, "balance": 20000000, "status": "پرداخت نشده"}
        ],
        "totals": {"due": 20000000, "paid": 0, "balance": 20000000}
      }
    ]
  },
  "prices": [''');

String _rangedJson(String source) =>
    source.replaceFirst('"exportedAt"', '''"scope": {
    "type": "range",
    "startDate": "1404/01/01",
    "endDate": "1404/06/31"
  },
  "exportedAt"''');

Future<void> _pumpShell(WidgetTester tester, String source) async {
  final controller = _DatasetController(BusinessDataset.fromRawJson(source));
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: MaterialApp(
        home: MainShell(
          onImport: _noOp,
          onDataCleared: _noOp,
          onSync: _noOpAsync,
        ),
      ),
    ),
  );
}

Future<void> _pumpStatistics(WidgetTester tester, String source) async {
  final controller = _DatasetController(BusinessDataset.fromRawJson(source));
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: const MaterialApp(home: StatisticsScreen(onImport: _noOp)),
    ),
  );
}

Future<void> _pumpHome(WidgetTester tester, String source) async {
  final controller = _DatasetController(BusinessDataset.fromRawJson(source));
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: const MaterialApp(home: HomeScreen(onImport: _noOp)),
    ),
  );
}

void _noOp() {}

Future<void> _noOpAsync() async {}

class _DatasetController extends AppController {
  _DatasetController(this._testDataset);

  final BusinessDataset _testDataset;

  @override
  BusinessDataset? get dataset => _testDataset;
}
