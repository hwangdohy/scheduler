import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../widgets/toss_card.dart';
import 'money_field.dart';

class DailyExpenseCard extends StatefulWidget {
  const DailyExpenseCard({super.key, required this.date});
  final DateTime date;
  @override
  State<DailyExpenseCard> createState() => _DailyExpenseCardState();
}

class _DailyExpenseCardState extends State<DailyExpenseCard> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  int? _amount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final amount =
          await DatabaseService.instance.getDailyExpense(widget.date);
      if (!mounted) return;
      setState(() {
        _amount = amount;
        _controller.text = amount?.toString() ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = '지출을 불러오지 못했어요';
        });
    }
  }

  Future<void> _save({bool delete = false}) async {
    if (!delete && !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final amount = delete ? null : int.parse(_controller.text);
      if (delete) {
        await DatabaseService.instance.deleteDailyExpense(widget.date);
      } else {
        await DatabaseService.instance.saveDailyExpense(widget.date, amount!);
      }
      if (!mounted) return;
      setState(() {
        _amount = amount;
        if (delete) _controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(delete ? '지출 기록을 삭제했어요' : '지출을 저장했어요')),
      );
    } catch (_) {
      if (mounted) setState(() => _error = '저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TossCard(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('하루 지출',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text(
                          '고정 지출을 제외한 하루 생활비 합계를 입력하세요. 수정하면 기존 금액을 대체해요.',
                          style: TextStyle(fontSize: 12)),
                      if (_amount != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('저장된 지출 ${money(_amount!)}')),
                      MoneyField(controller: _controller, label: '이 날 쓴 금액'),
                      if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      Row(children: [
                        if (_amount != null)
                          TextButton(
                              onPressed:
                                  _saving ? null : () => _save(delete: true),
                              child: const Text('기록 삭제')),
                        const Spacer(),
                        ElevatedButton(
                            onPressed: _saving ? null : () => _save(),
                            child: Text(_saving ? '저장 중…' : '지출 저장')),
                      ]),
                    ]),
              ),
      );
}
