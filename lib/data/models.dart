import 'dart:convert';

import 'package:shamsi_date/shamsi_date.dart';

class ImportValidationException implements Exception {
  const ImportValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BusinessInfo {
  const BusinessInfo({required this.name, required this.currency});

  final String name;
  final String currency;

  /// نام نمایشی در رابط Android؛ مقدار خام JSON و قرارداد داده تغییر نمی‌کند.
  String get displayName => name
      .replaceAll('کارگاه', 'کارخانه')
      .replaceAll('نمایش یار', 'حسابچی')
      .replaceAll('نمایشیار', 'حسابچی');

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      name: _requiredText(json, 'name', scope: 'مشخصات کسب‌وکار'),
      currency: _optionalText(json['currency'], fallback: 'IRR'),
    );
  }
}

enum InvoiceScopeType { all, range }

class InvoiceScope {
  const InvoiceScope._({required this.type, this.startDate, this.endDate});

  const InvoiceScope.all() : this._(type: InvoiceScopeType.all);

  final InvoiceScopeType type;
  final String? startDate;
  final String? endDate;

  String get displayText => switch (type) {
    InvoiceScopeType.all => 'کل فاکتورها',
    InvoiceScopeType.range => 'از $startDate تا $endDate',
  };

  factory InvoiceScope.fromJson(dynamic rawScope) {
    // فایل‌های HCH پیشین، کلید scope نداشتند و شامل کل فاکتورها بودند.
    if (rawScope == null) return const InvoiceScope.all();

    final json = _asMap(rawScope, scope: 'نوع دیتابیس');
    final rawType = _requiredText(
      json,
      'type',
      scope: 'نوع دیتابیس',
    ).toLowerCase();
    return switch (rawType) {
      'all' => const InvoiceScope.all(),
      'range' => InvoiceScope._(
        type: InvoiceScopeType.range,
        startDate: _requiredText(json, 'startDate', scope: 'نوع دیتابیس'),
        endDate: _requiredText(json, 'endDate', scope: 'نوع دیتابیس'),
      ),
      _ => throw const ImportValidationException(
        'نوع دیتابیس در فایل واردشده معتبر نیست.',
      ),
    };
  }
}

class MonthlyCargoCustomer {
  const MonthlyCargoCustomer({
    required this.customerGrossWeight,
    required this.customerNetWeight,
    required this.cargoAmount,
    required this.moisturePercent,
    required this.paperWeight,
    required this.customerWeight,
    required this.customerPrice,
  });

  final num customerGrossWeight;
  final num customerNetWeight;
  final num cargoAmount;
  final num moisturePercent;
  final num paperWeight;
  final num customerWeight;
  final num customerPrice;

  factory MonthlyCargoCustomer.fromJson(Map<String, dynamic> json) {
    const scope = 'بار مشتری وضعیت ماهانه';
    return MonthlyCargoCustomer(
      customerGrossWeight: _requiredNonNegativeNumber(
        json,
        'customerGrossWeight',
        scope: scope,
      ),
      customerNetWeight: _requiredNonNegativeNumber(
        json,
        'customerNetWeight',
        scope: scope,
      ),
      cargoAmount: _requiredNonNegativeNumber(
        json,
        'cargoAmount',
        scope: scope,
      ),
      moisturePercent: _requiredNonNegativeNumber(
        json,
        'moisturePercent',
        scope: scope,
      ),
      paperWeight: _requiredNonNegativeNumber(
        json,
        'paperWeight',
        scope: scope,
      ),
      customerWeight: _requiredNonNegativeNumber(
        json,
        'customerWeight',
        scope: scope,
      ),
      customerPrice: _requiredNonNegativeNumber(
        json,
        'customerPrice',
        scope: scope,
      ),
    );
  }
}

class MonthlyCargoStore {
  const MonthlyCargoStore({
    required this.storeNetWeight,
    required this.storeRentTotal,
    required this.nylonWeight,
    required this.plasticWeight,
    required this.guniWeight,
    required this.storeCartonWeight,
    required this.storeCartonPrice,
  });

  final num storeNetWeight;
  final num storeRentTotal;
  final num nylonWeight;
  final num plasticWeight;
  final num guniWeight;
  final num storeCartonWeight;
  final num storeCartonPrice;

  factory MonthlyCargoStore.fromJson(Map<String, dynamic> json) {
    const scope = 'بار فروشگاه وضعیت ماهانه';
    return MonthlyCargoStore(
      storeNetWeight: _requiredNonNegativeNumber(
        json,
        'storeNetWeight',
        scope: scope,
      ),
      storeRentTotal: _requiredNonNegativeNumber(
        json,
        'storeRentTotal',
        scope: scope,
      ),
      nylonWeight: _requiredNonNegativeNumber(
        json,
        'nylonWeight',
        scope: scope,
      ),
      plasticWeight: _requiredNonNegativeNumber(
        json,
        'plasticWeight',
        scope: scope,
      ),
      guniWeight: _requiredNonNegativeNumber(json, 'guniWeight', scope: scope),
      storeCartonWeight: _requiredNonNegativeNumber(
        json,
        'storeCartonWeight',
        scope: scope,
      ),
      storeCartonPrice: _requiredNonNegativeNumber(
        json,
        'storeCartonPrice',
        scope: scope,
      ),
    );
  }
}

class MonthlyOverallTotals {
  const MonthlyOverallTotals({
    required this.customerWeight,
    required this.storeCartonWeight,
    required this.netInputCarton,
    required this.inputCartonPrice,
  });

  final num customerWeight;
  final num storeCartonWeight;
  final num netInputCarton;
  final num inputCartonPrice;

  factory MonthlyOverallTotals.fromJson(Map<String, dynamic> json) {
    const scope = 'وضعیت کلی ماهانه';
    return MonthlyOverallTotals(
      customerWeight: _requiredNonNegativeNumber(
        json,
        'customerWeight',
        scope: scope,
      ),
      storeCartonWeight: _requiredNonNegativeNumber(
        json,
        'storeCartonWeight',
        scope: scope,
      ),
      netInputCarton: _requiredNonNegativeNumber(
        json,
        'netInputCarton',
        scope: scope,
      ),
      inputCartonPrice: _requiredNonNegativeNumber(
        json,
        'inputCartonPrice',
        scope: scope,
      ),
    );
  }
}

class MonthlyTopCustomer {
  const MonthlyTopCustomer({
    required this.rank,
    required this.name,
    required this.netWeight,
    required this.percent,
  });

  final int rank;
  final String name;
  final num netWeight;
  final num percent;

  factory MonthlyTopCustomer.fromJson(Map<String, dynamic> json) {
    const scope = 'مشتریان برتر ماهانه';
    final rank = _requiredInteger(json, 'rank', scope: scope);
    if (rank < 1) {
      throw const ImportValidationException(
        'رتبه مشتری برتر ماهانه باید بزرگ‌تر از صفر باشد.',
      );
    }
    return MonthlyTopCustomer(
      rank: rank,
      name: _requiredText(json, 'name', scope: scope),
      netWeight: _requiredNonNegativeNumber(json, 'netWeight', scope: scope),
      percent: _requiredNonNegativeNumber(json, 'percent', scope: scope),
    );
  }
}

class MonthlyStatus {
  const MonthlyStatus({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.cargoCustomer,
    required this.cargoStore,
    required this.overallTotals,
    required this.topCustomers,
  });

  final int year;
  final int month;
  final String monthLabel;
  final MonthlyCargoCustomer cargoCustomer;
  final MonthlyCargoStore cargoStore;
  final MonthlyOverallTotals overallTotals;
  final List<MonthlyTopCustomer> topCustomers;

  factory MonthlyStatus.fromJson(Map<String, dynamic> json) {
    const scope = 'وضعیت ماهانه';
    final month = _requiredInteger(json, 'month', scope: scope);
    if (month < 1 || month > 12) {
      throw const ImportValidationException(
        'ماه وضعیت ماهانه باید بین ۱ تا ۱۲ باشد.',
      );
    }
    final topCustomers = _requiredList(json, 'topCustomers', scope: scope)
        .map(
          (item) => MonthlyTopCustomer.fromJson(
            _asMap(item, scope: 'مشتری برتر ماهانه'),
          ),
        )
        .toList(growable: false);
    if (topCustomers.length > 5) {
      throw const ImportValidationException(
        'فهرست مشتریان برتر ماهانه حداکثر می‌تواند ۵ عضو داشته باشد.',
      );
    }
    return MonthlyStatus(
      year: _requiredInteger(json, 'year', scope: scope),
      month: month,
      monthLabel: _requiredText(json, 'monthLabel', scope: scope),
      cargoCustomer: MonthlyCargoCustomer.fromJson(
        _asMap(json['cargoCustomer'], scope: 'بار مشتری وضعیت ماهانه'),
      ),
      cargoStore: MonthlyCargoStore.fromJson(
        _asMap(json['cargoStore'], scope: 'بار فروشگاه وضعیت ماهانه'),
      ),
      overallTotals: MonthlyOverallTotals.fromJson(
        _asMap(json['overallTotals'], scope: 'وضعیت کلی ماهانه'),
      ),
      topCustomers: topCustomers,
    );
  }
}

class EmployeeSalary {
  const EmployeeSalary({
    required this.name,
    required this.phone,
    required this.hireDate,
    required this.terminationDate,
    required this.profileHistory,
    required this.offdays,
    required this.extraServices,
    required this.deposits,
    required this.previousAccountEntries,
  });

  final String name;
  final String phone;
  // فیلدهای اختیاری؛ فایل‌های HCH قدیمی‌تر این کلیدها را ندارند (null یعنی نامشخص).
  final String? hireDate;
  final String? terminationDate;
  final List<EmployeeProfileHistory> profileHistory;
  final List<EmployeeSalaryDatedEntry> offdays;
  final List<EmployeeSalaryDatedEntry> extraServices;
  final List<EmployeeSalaryDeposit> deposits;
  final List<EmployeeSalaryAccountEntry> previousAccountEntries;

  factory EmployeeSalary.fromJson(Map<String, dynamic> json) {
    const scope = 'حقوق افراد';
    return EmployeeSalary(
      name: _requiredText(json, 'name', scope: scope),
      phone: _optionalText(json['phone']),
      hireDate: _optionalJalaliDateText(json['hireDate'], scope: scope),
      terminationDate: _optionalJalaliDateText(
        json['terminationDate'],
        scope: scope,
      ),
      profileHistory: _optionalList(json['profileHistory'], scope: scope)
          .map(
            (item) => EmployeeProfileHistory.fromJson(
              _asMap(item, scope: 'تاریخچه حقوق کارمند'),
            ),
          )
          .toList(growable: false),
      offdays: _optionalList(json['offdays'], scope: scope)
          .map(
            (item) => EmployeeSalaryDatedEntry.fromJson(
              _asMap(item, scope: 'روز تعطیل کارمند'),
            ),
          )
          .toList(growable: false),
      extraServices: _optionalList(json['extraServices'], scope: scope)
          .map(
            (item) => EmployeeSalaryDatedEntry.fromJson(
              _asMap(item, scope: 'سرویس اضافه کارمند'),
            ),
          )
          .toList(growable: false),
      deposits: _optionalList(json['deposits'], scope: scope)
          .map(
            (item) => EmployeeSalaryDeposit.fromJsonOrNull(
              _asMap(item, scope: 'واریزی حقوق کارمند'),
            ),
          )
          .whereType<EmployeeSalaryDeposit>()
          .toList(growable: false),
      previousAccountEntries:
          _optionalList(json['previousAccountEntries'], scope: scope)
              .map(
                (item) => EmployeeSalaryAccountEntry.fromJson(
                  _asMap(item, scope: 'حساب قبلی کارمند'),
                ),
              )
              .toList(growable: false),
    );
  }
}

class EmployeeProfileHistory {
  const EmployeeProfileHistory({
    required this.actionDate,
    required this.baseSalary,
    required this.startDate,
    required this.lastSettleDate,
    required this.lastBalance,
  });

  final String actionDate;
  final int? baseSalary;
  final String? startDate;
  final String? lastSettleDate;
  final int? lastBalance;

  factory EmployeeProfileHistory.fromJson(Map<String, dynamic> json) {
    const scope = 'تاریخچه حقوق کارمند';
    final baseSalary = _optionalInteger(json['baseSalary'], scope: scope);
    final lastBalance = _optionalInteger(json['lastBalance'], scope: scope);
    final actionDate = _optionalJalaliDateText(
      json['actionDate'],
      scope: scope,
    );
    final lastSettleDate = _optionalJalaliDateText(
      json['lastSettleDate'],
      scope: scope,
    );
    if (baseSalary != null && actionDate == null) {
      throw const ImportValidationException(
        'تاریخ اقدام برای حقوق ماهیانه کارمند الزامی است.',
      );
    }
    if (lastBalance != null && lastBalance != 0 && lastSettleDate == null) {
      throw const ImportValidationException(
        'تاریخ آخرین تسویه برای حساب غیرصفر کارمند الزامی است.',
      );
    }
    return EmployeeProfileHistory(
      actionDate: actionDate ?? '',
      baseSalary: baseSalary,
      startDate: _optionalJalaliDateText(json['startDate'], scope: scope),
      lastSettleDate: lastSettleDate,
      lastBalance: lastBalance,
    );
  }
}

class EmployeeSalaryDatedEntry {
  const EmployeeSalaryDatedEntry({required this.date});

  final String date;

  factory EmployeeSalaryDatedEntry.fromJson(Map<String, dynamic> json) =>
      EmployeeSalaryDatedEntry(
        date: _requiredJalaliDateText(
          json,
          'date',
          scope: 'اطلاعات حقوق کارمند',
        ),
      );
}

class EmployeeSalaryDeposit {
  const EmployeeSalaryDeposit({
    required this.amount,
    required this.billingYear,
    required this.billingMonth,
  });

  final int amount;
  final int billingYear;
  final int billingMonth;

  /// سازگاری با HCH ویندوزیِ پیش از اصلاح canonical: ماه به شکل
  /// «05 - مرداد» و سال به شکل متن صادر می‌شد. فقط رکوردی که هر دو دوره
  /// آن خالی است، مربوط به پرداخت فاقد دوره است و در محاسبه بازه نقشی ندارد.
  static EmployeeSalaryDeposit? fromJsonOrNull(Map<String, dynamic> json) {
    if (_optionalText(json['billingYear']).isEmpty &&
        _optionalText(json['billingMonth']).isEmpty) {
      return null;
    }
    return EmployeeSalaryDeposit.fromJson(json);
  }

  factory EmployeeSalaryDeposit.fromJson(Map<String, dynamic> json) {
    const scope = 'واریزی حقوق کارمند';
    final month = _requiredEmployeeBillingMonth(
      json['billingMonth'],
      scope: scope,
    );
    if (month < 1 || month > 12) {
      throw const ImportValidationException(
        'ماه واریزی حقوق باید بین ۱ تا ۱۲ باشد.',
      );
    }
    return EmployeeSalaryDeposit(
      amount: _requiredInteger(json, 'amount', scope: scope),
      billingYear: _requiredEmployeeBillingYear(
        json['billingYear'],
        scope: scope,
      ),
      billingMonth: month,
    );
  }
}

class EmployeeSalaryAccountEntry {
  const EmployeeSalaryAccountEntry({required this.date, required this.amount});

  final String date;
  final int amount;

  factory EmployeeSalaryAccountEntry.fromJson(Map<String, dynamic> json) =>
      EmployeeSalaryAccountEntry(
        date: _requiredJalaliDateText(json, 'date', scope: 'حساب قبلی کارمند'),
        amount: _requiredInteger(json, 'amount', scope: 'حساب قبلی کارمند'),
      );
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.phones,
    required this.balance,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  // لیست همه‌ی شماره‌های ثبت‌شده؛ در فایل‌های HCH قدیمی‌تر (بدون فیلد phones) از همان phone
  // تکی ساخته می‌شود تا رفتار قبلی حفظ شود.
  final List<String> phones;
  final int balance;
  final DateTime updatedAt;

  factory Customer.fromJson(Map<String, dynamic> json) {
    final phone = _optionalText(json['phone']);
    final rawPhones = json['phones'];
    List<String> phones;
    if (rawPhones is List) {
      final seen = <String>{};
      phones = [
        for (final item in rawPhones)
          if (item != null && item.toString().trim().isNotEmpty)
            item.toString().trim(),
      ].where(seen.add).toList(growable: false);
    } else {
      phones = phone.isEmpty ? const [] : [phone];
    }
    return Customer(
      id: _requiredText(json, 'id', scope: 'مشتری'),
      name: _requiredText(json, 'name', scope: 'مشتری'),
      phone: phone,
      phones: phones,
      balance: _requiredInteger(json, 'balance', scope: 'مشتری'),
      updatedAt: _requiredDate(json, 'updatedAt', scope: 'مشتری'),
    );
  }
}

class InvoiceItem {
  const InvoiceItem({
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.grossWeight,
  });

  final String title;
  final num quantity;
  final int unitPrice;
  final int total;
  // فیلد اختیاری؛ فایل‌های HCH قدیمی‌تر (پیش از افزودن این قابلیت در ویندوز) این کلید را ندارند.
  final num? grossWeight;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      title: _requiredText(json, 'title', scope: 'آیتم فاکتور'),
      quantity: _requiredNumber(json, 'quantity', scope: 'آیتم فاکتور'),
      unitPrice: _requiredInteger(json, 'unitPrice', scope: 'آیتم فاکتور'),
      total: _requiredInteger(json, 'total', scope: 'آیتم فاکتور'),
      grossWeight: _optionalNonNegativeNumber(
        json['grossWeight'],
        scope: 'آیتم فاکتور',
      ),
    );
  }
}

enum InvoiceStatus {
  paid('paid'),
  partial('partial'),
  unpaid('unpaid'),
  overdue('overdue');

  const InvoiceStatus(this.value);
  final String value;

  static InvoiceStatus fromJson(dynamic raw) {
    final value = _optionalText(raw).toLowerCase();
    return switch (value) {
      'paid' => InvoiceStatus.paid,
      'partial' => InvoiceStatus.partial,
      'unpaid' => InvoiceStatus.unpaid,
      'overdue' => InvoiceStatus.overdue,
      _ => throw const ImportValidationException(
        'وضعیت یکی از فاکتورها معتبر نیست.',
      ),
    };
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.issuedAt,
    required this.dueAt,
    required this.total,
    required this.paid,
    required this.status,
    required this.items,
  });

  final String id;
  final String customerId;
  final String customerName;
  final DateTime issuedAt;
  final DateTime dueAt;
  final int total;
  final int paid;
  final InvoiceStatus status;
  final List<InvoiceItem> items;

  int get remaining => total - paid;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = _requiredList(json, 'items', scope: 'فاکتور');
    final items = rawItems
        .map((item) => InvoiceItem.fromJson(_asMap(item, scope: 'آیتم فاکتور')))
        .toList(growable: false);
    if (items.isEmpty) {
      throw const ImportValidationException(
        'هر فاکتور باید دست‌کم یک آیتم داشته باشد.',
      );
    }
    final total = _requiredInteger(json, 'total', scope: 'فاکتور');
    final paid = _requiredInteger(json, 'paid', scope: 'فاکتور');
    if (total < 0 || paid < 0 || paid > total) {
      throw const ImportValidationException(
        'مبالغ پرداختی یکی از فاکتورها معتبر نیست.',
      );
    }
    return Invoice(
      id: _requiredText(json, 'id', scope: 'فاکتور'),
      customerId: _requiredText(json, 'customerId', scope: 'فاکتور'),
      customerName: _requiredText(json, 'customerName', scope: 'فاکتور'),
      issuedAt: _requiredDate(json, 'issuedAt', scope: 'فاکتور'),
      dueAt: _requiredDate(json, 'dueAt', scope: 'فاکتور'),
      total: total,
      paid: paid,
      status: InvoiceStatus.fromJson(json['status']),
      items: items,
    );
  }
}

class PriceItem {
  const PriceItem({
    required this.id,
    required this.title,
    required this.sku,
    required this.price,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String sku;
  final int price;
  final DateTime updatedAt;

  factory PriceItem.fromJson(Map<String, dynamic> json) {
    final price = _requiredInteger(json, 'price', scope: 'قیمت');
    if (price < 0) {
      throw const ImportValidationException(
        'قیمت یک کالا نمی‌تواند منفی باشد.',
      );
    }
    return PriceItem(
      id: _requiredText(json, 'id', scope: 'قیمت'),
      title: _requiredText(json, 'title', scope: 'قیمت'),
      sku: _optionalText(json['sku']),
      price: price,
      updatedAt: _requiredDate(json, 'updatedAt', scope: 'قیمت'),
    );
  }
}

class StoreStatusStore {
  const StoreStatusStore({required this.id, required this.name});

  final String id;
  final String name;

  factory StoreStatusStore.fromJson(Map<String, dynamic> json) {
    const scope = 'فروشگاه وضعیت فروشگاه‌ها';
    return StoreStatusStore(
      id: _requiredText(json, 'id', scope: scope),
      name: _requiredText(json, 'name', scope: scope),
    );
  }
}

class StoreCargoEntry {
  const StoreCargoEntry({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.date,
    required this.grossWeightKg,
    required this.netWeightKg,
    required this.plateOrHelper,
    required this.description,
    required this.createdAt,
    this.driverName = '',
  });

  final String id;
  final String storeId;
  final String storeName;
  final DateTime date;
  final num grossWeightKg;
  final num netWeightKg;
  final String plateOrHelper;
  final String description;
  final DateTime createdAt;
  // فیلد اختیاری؛ فایل‌های HCH فعلی این کلید را هنوز صادر نمی‌کنند (در انتظار تغییر ویندوز).
  final String driverName;

  factory StoreCargoEntry.fromJson(Map<String, dynamic> json) {
    const scope = 'ورود کارتن فروشگاهی';
    return StoreCargoEntry(
      id: _requiredText(json, 'id', scope: scope),
      storeId: _requiredText(json, 'storeId', scope: scope),
      storeName: _requiredText(json, 'storeName', scope: scope),
      date: _requiredDate(json, 'date', scope: scope),
      grossWeightKg: _requiredNonNegativeNumber(
        json,
        'grossWeightKg',
        scope: scope,
      ),
      netWeightKg: _requiredNonNegativeNumber(
        json,
        'netWeightKg',
        scope: scope,
      ),
      driverName: _optionalText(json['driverName']),
      plateOrHelper: _optionalText(json['plateOrHelper']),
      description: _optionalText(json['description']),
      createdAt: _requiredDate(json, 'createdAt', scope: scope),
    );
  }
}

class StoreRentalContract {
  const StoreRentalContract({
    required this.startDate,
    required this.endDate,
    required this.deposit,
    required this.monthlyRent,
  });

  final String startDate;
  final String? endDate;
  final num deposit;
  final num monthlyRent;

  factory StoreRentalContract.fromJson(Map<String, dynamic> json) {
    const scope = 'قرارداد اجاره فروشگاه';
    return StoreRentalContract(
      startDate: _requiredJalaliDateText(json, 'startDate', scope: scope),
      endDate: _optionalJalaliDateText(json['endDate'], scope: scope),
      deposit: _requiredNonNegativeNumber(json, 'deposit', scope: scope),
      monthlyRent: _requiredNonNegativeNumber(
        json,
        'monthlyRent',
        scope: scope,
      ),
    );
  }
}

class StoreRentalMonth {
  const StoreRentalMonth({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.rentDue,
    required this.paid,
    required this.balance,
    required this.status,
  });

  final int year;
  final int month;
  final String monthLabel;
  final num rentDue;
  final num paid;
  final num balance;
  final String status;

  factory StoreRentalMonth.fromJson(Map<String, dynamic> json) {
    const scope = 'وضعیت ماهانه اجاره فروشگاه';
    return StoreRentalMonth(
      year: _requiredInteger(json, 'year', scope: scope),
      month: _requiredInteger(json, 'month', scope: scope),
      monthLabel: _requiredText(json, 'monthLabel', scope: scope),
      rentDue: _requiredNonNegativeNumber(json, 'rentDue', scope: scope),
      paid: _requiredNonNegativeNumber(json, 'paid', scope: scope),
      balance: _requiredNumber(json, 'balance', scope: scope),
      status: _requiredText(json, 'status', scope: scope),
    );
  }
}

class StoreRentalTotals {
  const StoreRentalTotals({
    required this.due,
    required this.paid,
    required this.balance,
  });

  final num due;
  final num paid;
  final num balance;

  factory StoreRentalTotals.fromJson(Map<String, dynamic> json) {
    const scope = 'جمع اجاره فروشگاه';
    return StoreRentalTotals(
      due: _requiredNonNegativeNumber(json, 'due', scope: scope),
      paid: _requiredNonNegativeNumber(json, 'paid', scope: scope),
      balance: _requiredNumber(json, 'balance', scope: scope),
    );
  }
}

class StoreRentalStatus {
  const StoreRentalStatus({
    required this.storeId,
    required this.storeName,
    required this.contract,
    required this.months,
    required this.totals,
  });

  final String storeId;
  final String storeName;
  final StoreRentalContract contract;
  final List<StoreRentalMonth> months;
  final StoreRentalTotals totals;

  factory StoreRentalStatus.fromJson(Map<String, dynamic> json) {
    const scope = 'وضعیت اجاره فروشگاه';
    final months = _optionalList(json['months'], scope: scope)
        .map(
          (item) => StoreRentalMonth.fromJson(
            _asMap(item, scope: 'وضعیت ماهانه اجاره فروشگاه'),
          ),
        )
        .toList(growable: false);
    return StoreRentalStatus(
      storeId: _requiredText(json, 'storeId', scope: scope),
      storeName: _requiredText(json, 'storeName', scope: scope),
      contract: StoreRentalContract.fromJson(
        _asMap(json['contract'], scope: 'قرارداد اجاره فروشگاه'),
      ),
      months: months,
      totals: StoreRentalTotals.fromJson(
        _asMap(json['totals'], scope: 'جمع اجاره فروشگاه'),
      ),
    );
  }
}

class StoreStatus {
  const StoreStatus({
    required this.stores,
    required this.cargoEntries,
    required this.rentalStatus,
  });

  const StoreStatus.empty()
    : stores = const [],
      cargoEntries = const [],
      rentalStatus = const [];

  final List<StoreStatusStore> stores;
  final List<StoreCargoEntry> cargoEntries;
  final List<StoreRentalStatus> rentalStatus;

  factory StoreStatus.fromJson(dynamic rawStoreStatus) {
    // فایل‌های HCH قدیمی‌تر این فیلد را ندارند؛ نبود آن خطا نیست.
    if (rawStoreStatus == null) return const StoreStatus.empty();
    final json = _asMap(rawStoreStatus, scope: 'وضعیت فروشگاه‌ها');
    final stores = _optionalList(json['stores'], scope: 'وضعیت فروشگاه‌ها')
        .map(
          (item) =>
              StoreStatusStore.fromJson(_asMap(item, scope: 'فروشگاه')),
        )
        .toList(growable: false);
    final cargoEntries =
        _optionalList(json['cargoEntries'], scope: 'وضعیت فروشگاه‌ها')
            .map(
              (item) => StoreCargoEntry.fromJson(
                _asMap(item, scope: 'ورود کارتن فروشگاهی'),
              ),
            )
            .toList(growable: false);
    final rentalStatus =
        _optionalList(json['rentalStatus'], scope: 'وضعیت فروشگاه‌ها')
            .map(
              (item) => StoreRentalStatus.fromJson(
                _asMap(item, scope: 'وضعیت اجاره فروشگاه'),
              ),
            )
            .toList(growable: false);
    return StoreStatus(
      stores: stores,
      cargoEntries: cargoEntries,
      rentalStatus: rentalStatus,
    );
  }
}

class BusinessDataset {
  const BusinessDataset({
    required this.version,
    required this.exportedAt,
    required this.business,
    required this.scope,
    required this.monthlyStatuses,
    required this.employeeSalaries,
    required this.customers,
    required this.invoices,
    required this.prices,
    required this.storeStatus,
    required this.rawJson,
  });

  static const supportedVersion = 1;

  final int version;
  final DateTime exportedAt;
  final BusinessInfo business;
  final InvoiceScope scope;
  final List<MonthlyStatus> monthlyStatuses;
  final List<EmployeeSalary> employeeSalaries;
  final List<Customer> customers;
  final List<Invoice> invoices;
  final List<PriceItem> prices;
  final StoreStatus storeStatus;
  final String rawJson;

  int get totalReceivable =>
      customers.fold(0, (sum, item) => sum + item.balance);

  factory BusinessDataset.fromRawJson(String source) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source.replaceFirst(RegExp(r'^\uFEFF'), ''));
    } on FormatException {
      throw const ImportValidationException('فایل انتخاب‌شده JSON معتبر نیست.');
    }
    final json = _asMap(decoded, scope: 'ریشه فایل');
    final version = _requiredInteger(json, 'version', scope: 'ریشه فایل');
    if (version != supportedVersion) {
      throw ImportValidationException(
        'نسخه فایل ($version) پشتیبانی نمی‌شود. نسخه مورد انتظار $supportedVersion است.',
      );
    }
    final customers = _requiredList(json, 'customers', scope: 'ریشه فایل')
        .map((item) => Customer.fromJson(_asMap(item, scope: 'مشتری')))
        .toList(growable: false);
    final invoices = _requiredList(json, 'invoices', scope: 'ریشه فایل')
        .map((item) => Invoice.fromJson(_asMap(item, scope: 'فاکتور')))
        .toList(growable: false);
    final prices = _requiredList(json, 'prices', scope: 'ریشه فایل')
        .map((item) => PriceItem.fromJson(_asMap(item, scope: 'قیمت')))
        .toList(growable: false);
    final monthlyStatuses =
        _optionalList(json['monthlyStatus'], scope: 'وضعیت ماهانه')
            .map(
              (item) =>
                  MonthlyStatus.fromJson(_asMap(item, scope: 'وضعیت ماهانه')),
            )
            .toList(growable: false)
          ..sort((first, second) {
            final byYear = first.year.compareTo(second.year);
            return byYear != 0 ? byYear : first.month.compareTo(second.month);
          });

    final employeeSalaries =
        _optionalList(json['employeeSalary'], scope: 'حقوق افراد')
            .map(
              (item) =>
                  EmployeeSalary.fromJson(_asMap(item, scope: 'حقوق افراد')),
            )
            .toList(growable: false);

    _assertUnique(customers.map((item) => item.id), label: 'شناسه مشتری');
    _assertUnique(
      monthlyStatuses.map((item) => '${item.year}/${item.month}'),
      label: 'ماه وضعیت ماهانه',
    );
    _assertUnique(
      employeeSalaries.map((item) => item.name),
      label: 'نام کارمند در حقوق افراد',
    );
    _assertUnique(invoices.map((item) => item.id), label: 'شناسه فاکتور');
    _assertUnique(prices.map((item) => item.id), label: 'شناسه کالا');
    final customerIds = customers.map((item) => item.id).toSet();
    for (final invoice in invoices) {
      if (!customerIds.contains(invoice.customerId)) {
        throw ImportValidationException(
          'فاکتور ${invoice.id} به مشتری ناشناخته‌ای متصل است.',
        );
      }
    }

    return BusinessDataset(
      version: version,
      exportedAt: _requiredDate(json, 'exportedAt', scope: 'ریشه فایل'),
      business: BusinessInfo.fromJson(
        _asMap(json['business'], scope: 'مشخصات کسب‌وکار'),
      ),
      scope: InvoiceScope.fromJson(json['scope']),
      monthlyStatuses: monthlyStatuses,
      employeeSalaries: employeeSalaries,
      customers: customers,
      invoices: invoices,
      prices: prices,
      storeStatus: StoreStatus.fromJson(json['storeStatus']),
      rawJson: source,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value, {required String scope}) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  throw ImportValidationException('ساختار $scope معتبر نیست.');
}

List<dynamic> _optionalList(dynamic value, {required String scope}) {
  if (value == null) return const [];
  if (value is List) return value;
  throw ImportValidationException(
    'فیلد وضعیت ماهانه در $scope باید یک فهرست باشد.',
  );
}

num _requiredNonNegativeNumber(
  Map<String, dynamic> json,
  String key, {
  required String scope,
}) {
  final number = _requiredNumber(json, key, scope: scope);
  if (number < 0) {
    throw ImportValidationException(
      'فیلد «$key» در $scope نمی‌تواند منفی باشد.',
    );
  }
  return number;
}

List<dynamic> _requiredList(
  Map<String, dynamic> json,
  String key, {
  required String scope,
}) {
  final value = json[key];
  if (value is List) return value;
  throw ImportValidationException('فیلد «$key» در $scope باید یک فهرست باشد.');
}

String _requiredText(
  Map<String, dynamic> json,
  String key, {
  required String scope,
}) {
  final value = _optionalText(json[key]);
  if (value.isNotEmpty) return value;
  throw ImportValidationException('فیلد «$key» در $scope الزامی است.');
}

String _optionalText(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

num _requiredNumber(
  Map<String, dynamic> json,
  String key, {
  required String scope,
}) {
  final value = json[key];
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? _numberError(key, scope);
  throw ImportValidationException('فیلد «$key» در $scope باید عددی باشد.');
}

Never _numberError(String key, String scope) =>
    throw ImportValidationException('فیلد «$key» در $scope باید عددی باشد.');

int? _optionalInteger(dynamic value, {required String scope}) {
  if (value == null || (value is String && value.trim().isEmpty)) return null;
  if (value is num) {
    if (value == value.roundToDouble()) return value.toInt();
  } else if (value is String) {
    return int.tryParse(value.trim()) ?? _numberError('مقدار اختیاری', scope);
  }
  throw ImportValidationException('یکی از مقادیر $scope باید عدد صحیح باشد.');
}

num? _optionalNonNegativeNumber(dynamic value, {required String scope}) {
  // فیلدهای اختیاری در فایل‌های HCH قدیمی‌تر ممکن است اصلاً وجود نداشته باشند.
  if (value == null || (value is String && value.trim().isEmpty)) return null;
  num? number;
  if (value is num) {
    number = value;
  } else if (value is String) {
    number = num.tryParse(value);
  }
  if (number == null) {
    throw ImportValidationException('یکی از مقادیر $scope باید عددی باشد.');
  }
  if (number < 0) {
    throw ImportValidationException('یکی از مقادیر $scope نمی‌تواند منفی باشد.');
  }
  // مقدار صفر یا منفی برای وزن ناخالص یعنی داده معتبری ثبت نشده؛ نامعتبر تلقی نمی‌شود
  // ولی به‌عنوان «موجود نیست» در نظر گرفته می‌شود تا نمایش گمراه‌کننده رخ ندهد.
  if (number == 0) return null;
  return number;
}

String _requiredJalaliDateText(
  Map<String, dynamic> json,
  String key, {
  required String scope,
}) {
  final date = _optionalJalaliDateText(json[key], scope: scope);
  if (date != null) return date;
  throw ImportValidationException('تاریخ «$key» در $scope الزامی است.');
}

String? _optionalJalaliDateText(dynamic value, {required String scope}) {
  final text = _optionalText(value);
  if (text.isEmpty) return null;
  final match = RegExp(r'^(\d{4})/(\d{2})/(\d{2})$').firstMatch(text);
  if (match == null) {
    throw ImportValidationException('تاریخ جلالی در $scope معتبر نیست.');
  }
  try {
    Jalali(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  } catch (_) {
    throw ImportValidationException('تاریخ جلالی در $scope معتبر نیست.');
  }
  return text;
}

int _requiredEmployeeBillingYear(dynamic value, {required String scope}) {
  if (value is num && value == value.roundToDouble()) return value.toInt();
  final text = _optionalText(value);
  final parsed = RegExp(r'^\d{4}$').hasMatch(text) ? int.tryParse(text) : null;
  if (parsed != null) return parsed;
  throw ImportValidationException(
    'فیلد «billingYear» در $scope باید سال چهاررقمی باشد.',
  );
}

int _requiredEmployeeBillingMonth(dynamic value, {required String scope}) {
  if (value is num && value == value.roundToDouble()) return value.toInt();
  final text = _optionalText(value);
  final match = RegExp(r'^(\d{1,2})(?:\s*-\s*[^-]+)?$').firstMatch(text);
  final parsed = match == null ? null : int.tryParse(match.group(1)!);
  if (parsed != null) return parsed;
  throw ImportValidationException(
    'فیلد «billingMonth» در $scope باید عدد ماه یا «۰۵ - مرداد» باشد.',
  );
}

int _requiredInteger(
  Map<String, dynamic> json,
  String key, {
  required String scope,
}) {
  final number = _requiredNumber(json, key, scope: scope);
  if (number is int) return number;
  if (number == number.roundToDouble()) return number.toInt();
  throw ImportValidationException('فیلد «$key» در $scope باید عدد صحیح باشد.');
}

DateTime _requiredDate(
  Map<String, dynamic> json,
  String key, {
  required String scope,
}) {
  final raw = _requiredText(json, key, scope: scope);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw ImportValidationException('تاریخ «$key» در $scope معتبر نیست.');
  }
  return parsed.toLocal();
}

void _assertUnique(Iterable<String> values, {required String label}) {
  final set = <String>{};
  for (final value in values) {
    if (!set.add(value)) {
      throw ImportValidationException('$label «$value» تکراری است.');
    }
  }
}
