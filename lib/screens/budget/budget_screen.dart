import 'package:flutter/material.dart';
import '../../models/monthly_budget.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toss_card.dart';
import 'daily_expense_card.dart';
import 'money_field.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  MonthlyBudget? _budget;
  Map<String, int> _expenses = {};
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.budgetRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DatabaseService.instance.budgetRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    final month = _month;
    try {
      final budget = await DatabaseService.instance
          .getMonthlyBudget(month.year, month.month);
      final expenses = await DatabaseService.instance
          .getMonthlyExpenses(month.year, month.month);
      if (!mounted || request != _request) return;
      setState(() {
        _budget = budget;
        _expenses = expenses;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted && request == _request)
        setState(() {
          _loading = false;
          _error = '가계부를 불러오지 못했어요';
        });
    }
  }

  void _changeMonth(int year, int month) {
    setState(() {
      _month = DateTime(year, month);
      _loading = true;
    });
    _load();
  }

  Future<void> _edit() async {
    final budget = _budget;
    if (budget == null) return;
    await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _BudgetEditor(budget: budget));
  }

  Future<void> _editExpense(String key) async {
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SafeArea(
                child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 24, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(key, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                DailyExpenseCard(date: DateTime.parse(key)),
              ]),
            )));
  }

  Widget _row(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(money(value),
              style: const TextStyle(fontWeight: FontWeight.w700))
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final budget = _budget;
    final spent = _expenses.values.fold(0, (sum, value) => sum + value);
    final now = DateTime.now();
    final remaining = budget?.remainingMoney(spent) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('가계부'), actions: [
        TextButton(
            onPressed: _loading || _error != null ? null : _edit,
            child: const Text('예산 수정')),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Expanded(
              child: DropdownButtonFormField<int>(
            initialValue: _month.year,
            decoration: const InputDecoration(labelText: '년도'),
            items: [
              for (int y = 2000; y <= 2100; y++)
                DropdownMenuItem(value: y, child: Text('$y년'))
            ],
            onChanged: (y) {
              if (y != null) _changeMonth(y, _month.month);
            },
          )),
          const SizedBox(width: 16),
          Expanded(
              child: DropdownButtonFormField<int>(
            initialValue: _month.month,
            decoration: const InputDecoration(labelText: '월'),
            items: [
              for (int m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text('$m월'))
            ],
            onChanged: (m) {
              if (m != null) _changeMonth(_month.year, m);
            },
          )),
        ]),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Column(children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('다시 시도'))
          ])
        else if (budget != null) ...[
          TossCard(
              color: AppColors.accent,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('하루 가용 금액',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(money(budget.availablePerDay(spent, now)),
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    Text(budget.remainingDays(now) == 0
                        ? '종료된 월이에요'
                        : '남은 생활비 ÷ ${budget.remainingDays(now)}일 (오늘 포함 · 원 미만 버림)'),
                    if (remaining < 0)
                      Text('생활비 예산을 ${money(-remaining)} 초과했어요',
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700)),
                  ])),
          const SizedBox(height: 16),
          TossCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                _row('월급', budget.salary),
                _row('추가수입', budget.extraIncome),
                _row('저축 목표', budget.savingsGoal),
                _row('고정 지출 합계', budget.fixedTotal),
                const Divider(),
                _row('월 생활비 예산', budget.spendingBudget),
                _row('기록한 생활비 지출', spent),
                _row('남은 생활비', remaining),
                _row('월 전체 기준 하루 예산', budget.dailyBudget),
                const SizedBox(height: 8),
                const Text(
                    '월 생활비 = 월급 + 추가수입 − 저축 목표 − 고정 지출\n'
                    '남은 생활비 = 월 생활비 − 기록한 지출\n'
                    '미래 월은 전체 일수로 나누고, 지난 월 또는 예산 초과 시 하루 가용 금액은 0원이에요.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ])),
          const SizedBox(height: 16),
          TossCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const Text('고정 지출',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                if (budget.fixedExpenses.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('예산 수정에서 월세, 통신비 등을 추가하세요.')),
                for (final item in budget.fixedExpenses)
                  _row(item.name, item.amount),
              ])),
          const SizedBox(height: 24),
          const Text('날짜별 지출',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('캘린더에서 날짜를 눌러 지출을 기록하세요. 아래 기록도 눌러서 수정할 수 있어요.'),
          const SizedBox(height: 8),
          if (_expenses.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16), child: Text('기록한 지출이 없어요')),
          for (final entry in _expenses.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${int.parse(entry.key.substring(8))}일'),
              trailing: Text(money(entry.value)),
              onTap: () => _editExpense(entry.key),
            ),
        ],
      ]),
    );
  }
}

class _FixedControllers {
  final TextEditingController name;
  final TextEditingController amount;
  _FixedControllers(FixedExpense expense)
      : name = TextEditingController(text: expense.name),
        amount = TextEditingController(text: expense.amount.toString());
  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({required this.budget});
  final MonthlyBudget budget;
  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  final _form = GlobalKey<FormState>();
  late final _salary =
      TextEditingController(text: widget.budget.salary.toString());
  late final _extra =
      TextEditingController(text: widget.budget.extraIncome.toString());
  late final _savings =
      TextEditingController(text: widget.budget.savingsGoal.toString());
  late final _fixed =
      widget.budget.fixedExpenses.map(_FixedControllers.new).toList();
  final _removed = <_FixedControllers>[];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _salary.dispose();
    _extra.dispose();
    _savings.dispose();
    for (final item in [..._fixed, ..._removed]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DatabaseService.instance.saveMonthlyBudget(MonthlyBudget(
        year: widget.budget.year,
        month: widget.budget.month,
        salary: int.parse(_salary.text),
        extraIncome: int.parse(_extra.text),
        savingsGoal: int.parse(_savings.text),
        fixedExpenses: [
          for (final item in _fixed)
            FixedExpense(
                name: item.name.text.trim(),
                amount: int.parse(item.amount.text))
        ],
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = '예산을 저장하지 못했어요. 다시 시도해주세요.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${widget.budget.year}년 ${widget.budget.month}월 예산 수정',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  MoneyField(controller: _salary, label: '월급'),
                  MoneyField(controller: _extra, label: '추가수입'),
                  MoneyField(controller: _savings, label: '저축 목표'),
                  const SizedBox(height: 20),
                  const Text('고정 지출 항목',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  for (final item in _fixed)
                    Padding(
                        key: ObjectKey(item),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: TextFormField(
                                      controller: item.name,
                                      decoration: const InputDecoration(
                                          labelText: '항목명 (예: 월세)'),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? '항목명을 입력해주세요'
                                          : null)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: MoneyField(
                                      controller: item.amount, label: '금액')),
                              IconButton(
                                  tooltip: '고정 지출 삭제',
                                  onPressed: _saving
                                      ? null
                                      : () => setState(() {
                                            _fixed.remove(item);
                                            _removed.add(item);
                                          }),
                                  icon:
                                      const Icon(Icons.remove_circle_outline)),
                            ])),
                  TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _fixed.add(_FixedControllers(
                              const FixedExpense(name: '', amount: 0)))),
                      icon: const Icon(Icons.add),
                      label: const Text('고정 지출 추가')),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? '저장 중…' : '예산 저장')),
                ])),
      ));
}
