import '../data/models.dart';

const String trailerExitOperation = 'خروج تریلی کارتن';
const String trailerRentOperation = 'کرایه راننده تریلی';
const String previousAccountOperation = 'حساب قبلی';

class FactoryStatusResult {
  const FactoryStatusResult({
    required this.totalGross,
    required this.totalNet,
    required this.totalCargo,
    required this.totalRent,
    required this.moistureLossPct,
    required this.initialPrice,
    required this.finalPrice,
    required this.totalDeposits,
    required this.totalPaid,
    required this.totalPrev,
    required this.currentBalance,
  });

  final num totalGross;
  final num totalNet;
  final int totalCargo;
  final int totalRent;
  final double moistureLossPct;
  final double initialPrice;
  final double finalPrice;
  final int totalDeposits;
  final int totalPaid;
  final int totalPrev;
  final int currentBalance;

  static FactoryStatusResult compute(List<FactorySalesEntry> rows) {
    num totalGross = 0;
    num totalNet = 0;
    int totalCargo = 0;
    int totalRent = 0;
    for (final row in rows) {
      totalGross += row.grossWeightKg;
      totalNet += row.netWeightKg;
      // مبلغ بار در فاکتور منفی ثبت می‌شه، قدرمطلق می‌گیریم
      totalCargo += row.cargoAmount.abs();
      totalRent += row.trailerRent;
    }
    final moistureLossPct = totalGross == 0
        ? 0.0
        : (totalGross - totalNet) / totalGross * 100;
    final initialPrice = totalNet == 0 ? 0.0 : totalCargo / totalNet;
    final finalPrice = totalNet == 0
        ? 0.0
        : (totalCargo - totalRent) / totalNet;

    final trailerDriverNames = <String>{
      for (final row in rows)
        if (row.trailerRent > 0 && row.driverName.trim().isNotEmpty)
          row.driverName,
    };

    final factoryRows = rows.where((row) {
      if (row.operationType == trailerRentOperation) return false;
      if (row.operationType == previousAccountOperation &&
          trailerDriverNames.contains(row.driverName)) {
        return false;
      }
      return true;
    });

    int totalDeposits = 0;
    int totalPaid = 0;
    int totalPrev = 0;
    for (final row in factoryRows) {
      totalDeposits += row.entryAmount.abs();
      totalPaid += row.exitAmount;
      totalPrev += row.prevBalance;
    }

    final currentBalance = totalCargo - totalDeposits + totalPaid + totalPrev;

    return FactoryStatusResult(
      totalGross: totalGross,
      totalNet: totalNet,
      totalCargo: totalCargo,
      totalRent: totalRent,
      moistureLossPct: moistureLossPct,
      initialPrice: initialPrice,
      finalPrice: finalPrice,
      totalDeposits: totalDeposits,
      totalPaid: totalPaid,
      totalPrev: totalPrev,
      currentBalance: currentBalance,
    );
  }
}

class TrailerStatusResult {
  const TrailerStatusResult({
    required this.count,
    required this.due,
    required this.paid,
    required this.prevBalance,
    required this.balance,
  });

  final int count;
  final int due;
  final int paid;
  final int prevBalance;
  final int balance;

  static TrailerStatusResult compute({
    required List<FactorySalesEntry> rows,
    required List<FactorySalesEntry> allEntries,
    required String driverFilter,
    required String allDriversOption,
    required String? startText,
    required String? endText,
  }) {
    var trailerRows = rows.where((row) => row.trailerRent > 0);
    if (driverFilter != allDriversOption) {
      trailerRows = trailerRows.where((row) => row.driverName == driverFilter);
    }
    final trailerRowsList = trailerRows.toList();

    var allTrailerTrips = rows.where(
      (row) => row.operationType == trailerExitOperation,
    );
    if (driverFilter != allDriversOption) {
      allTrailerTrips = allTrailerTrips.where(
        (row) => row.driverName == driverFilter,
      );
    }
    final count = allTrailerTrips.length;
    final due = trailerRowsList.fold<int>(0, (sum, row) => sum + row.trailerRent);

    final driverNames = <String>{
      for (final row in trailerRowsList)
        if (row.driverName.trim().isNotEmpty) row.driverName,
    };

    bool inDateRange(FactorySalesEntry entry) {
      final matchesStart =
          startText == null || entry.opDate.compareTo(startText) >= 0;
      final matchesEnd = endText == null || entry.opDate.compareTo(endText) <= 0;
      return matchesStart && matchesEnd;
    }

    int paid = 0;
    for (final entry in allEntries) {
      if (entry.operationType == trailerRentOperation &&
          driverNames.contains(entry.driverName) &&
          inDateRange(entry)) {
        paid += entry.exitAmount;
      }
    }

    int prevBalance = 0;
    for (final entry in allEntries) {
      if (driverNames.contains(entry.driverName) && inDateRange(entry)) {
        prevBalance += entry.prevBalance;
      }
    }

    final balance = due - paid + prevBalance;

    return TrailerStatusResult(
      count: count,
      due: due,
      paid: paid,
      prevBalance: prevBalance,
      balance: balance,
    );
  }
}
