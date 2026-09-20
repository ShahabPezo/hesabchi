import 'package:flutter_test/flutter_test.dart';
import 'package:namayeshyar/data/employee_salary_calculator.dart';
import 'package:namayeshyar/data/models.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  const employee = EmployeeSalary(
    name: 'علی رضایی',
    phone: '09121234567',
    hireDate: null,
    terminationDate: null,
    profileHistory: [
      EmployeeProfileHistory(
        actionDate: '1404/03/31',
        baseSalary: 15000000,
        startDate: '1403/05/10',
        lastSettleDate: '1404/03/31',
        lastBalance: 0,
      ),
      EmployeeProfileHistory(
        actionDate: '1404/04/01',
        baseSalary: 18000000,
        startDate: '1403/05/10',
        lastSettleDate: '1404/04/01',
        lastBalance: -200000,
      ),
    ],
    offdays: [
      EmployeeSalaryDatedEntry(date: '1404/04/05'),
      EmployeeSalaryDatedEntry(date: '1404/04/12'),
    ],
    extraServices: [
      EmployeeSalaryDatedEntry(date: '1404/04/03'),
      EmployeeSalaryDatedEntry(date: '1404/04/03'),
      EmployeeSalaryDatedEntry(date: '1404/04/20'),
    ],
    deposits: [
      EmployeeSalaryDeposit(
        amount: 5000000,
        billingYear: 1404,
        billingMonth: 4,
      ),
      EmployeeSalaryDeposit(
        amount: 3000000,
        billingYear: 1404,
        billingMonth: 4,
      ),
    ],
    previousAccountEntries: [
      EmployeeSalaryAccountEntry(date: '1404/04/02', amount: -150000),
      EmployeeSalaryAccountEntry(date: '1404/04/18', amount: 100000),
    ],
  );

  test('فرمول حقوق و تسویه بازه جلالی عین داده راهنما محاسبه می‌شود', () {
    final summary = EmployeeSalaryCalculator.calculate(
      employee: employee,
      start: Jalali(1404, 4, 1),
      end: Jalali(1404, 4, 31),
    );

    expect(summary.baseSalary, 18000000);
    expect(summary.dailySalaryDisplay, 600000);
    expect(summary.holidays, 2);
    expect(summary.extraDays, 1.5);
    expect(summary.workDays, 30.5);
    expect(summary.currentSalary, 18300000);
    expect(summary.deposits, 8000000);
    expect(summary.lastSettleBalance, -200000);
    expect(summary.previousBalance, -50000);
    expect(summary.settlement, 10050000);
    expect(summary.settlementKind, EmployeeSettlementKind.payable);
  });

  test('رکورد یک روز پیش از ابتدای بازه برای حقوق و تسویه معتبر است', () {
    final summary = EmployeeSalaryCalculator.calculate(
      employee: employee,
      start: Jalali(1404, 4, 2),
      end: Jalali(1404, 4, 2),
    );

    expect(summary.baseSalary, 18000000);
    expect(summary.lastSettleBalance, -200000);
    expect(summary.workDays, 1);
  });

  test('مانده صفرِ فاقد تاریخ تسویه از HCH قدیمی معتبر می‌ماند', () {
    final profile = EmployeeProfileHistory.fromJson({
      'actionDate': '1405/01/01',
      'baseSalary': 18000000,
      'lastSettleDate': null,
      'lastBalance': 0,
    });
    expect(profile.lastSettleDate, isNull);
    expect(profile.lastBalance, 0);

    expect(
      () => EmployeeProfileHistory.fromJson({
        'actionDate': '1405/01/01',
        'baseSalary': 18000000,
        'lastSettleDate': null,
        'lastBalance': 1,
      }),
      throwsA(isA<ImportValidationException>()),
    );
  });

  test('دوره متنی واریزی HCH قدیمی ویندوز به عدد canonical تبدیل می‌شود', () {
    final parsed = EmployeeSalary.fromJson({
      'name': 'کارمند نمونه',
      'profileHistory': const [],
      'offdays': const [],
      'extraServices': const [],
      'deposits': [
        {
          'amount': 5000000,
          'billingYear': '1405',
          'billingMonth': '05 - مرداد',
        },
        {'amount': 1000000, 'billingYear': null, 'billingMonth': null},
      ],
      'previousAccountEntries': const [],
    });

    expect(parsed.deposits, hasLength(1));
    expect(parsed.deposits.single.amount, 5000000);
    expect(parsed.deposits.single.billingYear, 1405);
    expect(parsed.deposits.single.billingMonth, 5);
  });

  test('تا انتخاب کامل کارمند و بازه، محاسبه صفر باقی می‌ماند', () {
    final summary = EmployeeSalaryCalculator.calculate(
      employee: employee,
      start: Jalali(1404, 4, 1),
      end: null,
    );

    expect(summary, isA<EmployeeSalarySummary>());
    expect(summary.currentSalary, 0);
    expect(summary.settlement, 0);
  });
}
