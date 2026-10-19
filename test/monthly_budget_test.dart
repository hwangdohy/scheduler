import 'package:flutter_test/flutter_test.dart';
import 'package:toss_schedule/models/monthly_budget.dart';

void main() {
  const budget = MonthlyBudget(
    year: 2026,
    month: 10,
    salary: 3000000,
    extraIncome: 200000,
    savingsGoal: 800000,
    fixedExpenses: [
      FixedExpense(name: '월세', amount: 500000),
      FixedExpense(name: '통신비', amount: 100000)
    ],
  );

  test('Income, savings, fixed costs and daily spending affect allowance', () {
    expect(budget.fixedTotal, 600000);
    expect(budget.spendingBudget, 1800000);
    expect(budget.dailyBudget, 58064);
    expect(budget.remainingMoney(500000), 1300000);
    expect(budget.remainingDays(DateTime(2026, 10, 19, 23, 59)), 13);
    expect(budget.availablePerDay(500000, DateTime(2026, 10, 19)), 100000);
  });

  test('Future months, ended months and last day have well-defined allowance',
      () {
    expect(budget.remainingDays(DateTime(2026, 9, 30)), 31);
    expect(budget.availablePerDay(0, DateTime(2026, 9, 30)), 58064);
    expect(budget.remainingDays(DateTime(2026, 11, 1)), 0);
    expect(budget.availablePerDay(0, DateTime(2026, 11, 1)), 0);
    expect(budget.availablePerDay(1700000, DateTime(2026, 10, 31)), 100000);
  });

  test('Overspending remains visible and daily allowance does not go negative',
      () {
    expect(budget.remainingMoney(1900000), -100000);
    expect(budget.availablePerDay(1900000, DateTime(2026, 10, 19)), 0);
    const deficit = MonthlyBudget(year: 2026, month: 10, savingsGoal: 100);
    expect(deficit.spendingBudget, -100);
    expect(deficit.dailyBudget, 0);
    expect(deficit.availablePerDay(0, DateTime(2026, 10, 1)), 0);
  });

  test('Leap years, month ends and December year transition', () {
    expect(const MonthlyBudget(year: 2028, month: 2).daysInMonth, 29);
    expect(const MonthlyBudget(year: 2027, month: 2).daysInMonth, 28);
    expect(const MonthlyBudget(year: 2026, month: 4).daysInMonth, 30);
    const december = MonthlyBudget(year: 2026, month: 12);
    expect(december.remainingDays(DateTime(2027, 1, 1)), 0);
  });

  test('Stored budget round trips all editable values', () {
    final restored = MonthlyBudget.fromMap(budget.toMap());
    expect(restored.toMap(), budget.toMap());
    expect(restored.fixedExpenses[0].name, '월세');
    expect(restored.fixedExpenses[1].amount, 100000);
    expect(
        const MonthlyBudget(year: 2026, month: 1).toMap()['month'], '2026-01');
  });
}
