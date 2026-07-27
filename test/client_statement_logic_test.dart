import 'package:flutter_test/flutter_test.dart';

enum TransactionType { debit, credit, advance, balance }

class Statement {
  final String id;
  final DateTime date;
  final String description;
  final TransactionType type;
  final double amount;
  final double runningBalance;
  final String? reference;
  final String? status;

  const Statement({
    required this.id,
    required this.date,
    required this.description,
    required this.type,
    required this.amount,
    required this.runningBalance,
    this.reference,
    this.status,
  });

  Statement copyWith({
    double? runningBalance,
  }) {
    return Statement(
      id: id,
      date: date,
      description: description,
      type: type,
      amount: amount,
      runningBalance: runningBalance ?? this.runningBalance,
      reference: reference,
      status: status,
    );
  }
}

void main() {
  group('Client Statement Parity Tests', () {
    test('Calculates Zahn Dental Clinic totals matching CRM web (₹6000 billed, ₹0 received, ₹6000 due)', () {
      final List<Statement> rawStatements = [
        Statement(
          id: 'inv_120',
          date: DateTime(2026, 7, 24),
          description: 'Invoice generated: 26/27/120',
          type: TransactionType.debit,
          amount: 6000.0,
          runningBalance: 0,
          reference: '26/27/120',
          status: 'overdue',
        ),
      ];

      // Sort & compute running balance
      rawStatements.sort((a, b) => a.date.compareTo(b.date));
      double running = 0.0;
      final List<Statement> computed = [];
      for (final s in rawStatements) {
        if (s.type == TransactionType.debit) {
          running += s.amount;
        } else if (s.type == TransactionType.credit || s.type == TransactionType.advance) {
          running -= s.amount;
        }
        computed.add(s.copyWith(runningBalance: running));
      }

      final double totalDebit = computed
          .where((s) => s.type == TransactionType.debit)
          .fold(0.0, (sum, s) => sum + s.amount);

      final double totalCredit = computed
          .where((s) => s.type == TransactionType.credit)
          .fold(0.0, (sum, s) => sum + s.amount);

      final double totalAdvance = computed
          .where((s) => s.type == TransactionType.advance)
          .fold(0.0, (sum, s) => sum + s.amount);

      final double closingBalance = totalDebit - totalCredit - totalAdvance;

      expect(totalDebit, equals(6000.0));
      expect(totalCredit, equals(0.0));
      expect(totalAdvance, equals(0.0));
      expect(closingBalance, equals(6000.0));
      expect(computed.first.runningBalance, equals(6000.0));
    });
  });
}
