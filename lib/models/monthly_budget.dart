import 'dart:convert';

class FixedExpense {
  final String name;
  final int amount;
  const FixedExpense({required this.name, required this.amount});

  Map<String, Object> toMap() => {'name': name, 'amount': amount};
  factory FixedExpense.fromMap(Map<String, dynamic> map) => FixedExpense(
        name: map['name'] as String,
        amount: map['amount'] as int,
      );
}

class MonthlyBudget {
  final int year;
  final int month;
  final int salary;
  final int extraIncome;
  final int savingsGoal;
  final List<FixedExpense> fixedExpenses;

  const MonthlyBudget({
    required this.year,
    required this.month,
    this.salary = 0,
    this.extraIncome = 0,
    this.savingsGoal = 0,
    this.fixedExpenses = const [],
  });

  int get daysInMonth => DateTime(year, month + 1, 0).day;
  int get fixedTotal => fixedExpenses.fold(0, (sum, e) => sum + e.amount);
  int get spendingBudget => salary + extraIncome - savingsGoal - fixedTotal;
  int get dailyBudget => spendingBudget > 0 ? spendingBudget ~/ daysInMonth : 0;

  int remainingDays(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(DateTime(year, month))) return daysInMonth;
    if (!today.isBefore(DateTime(year, month + 1))) return 0;
    return daysInMonth - today.day + 1;
  }

  int remainingMoney(int spent) => spendingBudget - spent;
  int availablePerDay(int spent, DateTime now) {
    final days = remainingDays(now);
    final money = remainingMoney(spent);
    return days == 0 || money <= 0 ? 0 : money ~/ days;
  }

  Map<String, Object> toMap() => {
        'month': '$year-${month.toString().padLeft(2, '0')}',
        'salary': salary,
        'extra_income': extraIncome,
        'savings_goal': savingsGoal,
        'fixed_expenses':
            jsonEncode(fixedExpenses.map((e) => e.toMap()).toList()),
      };

  factory MonthlyBudget.fromMap(Map<String, Object?> map) {
    final parts = (map['month'] as String).split('-');
    return MonthlyBudget(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      salary: map['salary'] as int,
      extraIncome: map['extra_income'] as int,
      savingsGoal: map['savings_goal'] as int,
      fixedExpenses: (jsonDecode(map['fixed_expenses'] as String) as List)
          .map((e) => FixedExpense.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
