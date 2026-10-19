import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

Future<int?> showWheelTimePicker(
  BuildContext context, {
  required String title,
  required int initialMinutes,
  int minimumMinutes = 0,
  bool allowEndOfDay = false,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<int>(
      context: context,
      builder: (_) => _WheelTimePicker(
          title: title,
          initialMinutes: initialMinutes,
          minimumMinutes: minimumMinutes,
          allowEndOfDay: allowEndOfDay));
}

class _WheelTimePicker extends StatefulWidget {
  const _WheelTimePicker(
      {required this.title,
      required this.initialMinutes,
      required this.minimumMinutes,
      required this.allowEndOfDay});
  final String title;
  final int initialMinutes;
  final int minimumMinutes;
  final bool allowEndOfDay;
  @override
  State<_WheelTimePicker> createState() => _WheelTimePickerState();
}

class _WheelTimePickerState extends State<_WheelTimePicker> {
  late int _hour = (widget.initialMinutes ~/ 60) % 24;
  late int _minute = widget.initialMinutes % 60;
  late final _hours = FixedExtentScrollController(initialItem: _hour);
  late final _minutes = FixedExtentScrollController(initialItem: _minute);
  String? _error;

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _confirm() {
    var value = _hour * 60 + _minute;
    if (value == 0 && widget.allowEndOfDay) value = 1440;
    if (value < widget.minimumMinutes) {
      setState(() => _error = '종료 시간은 시작 시간보다 늦어야 해요');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            Expanded(
                child: Text(widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700))),
            TextButton(onPressed: _confirm, child: const Text('완료')),
          ]),
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: SizedBox(
                height: 216,
                child: Row(children: [
                  Expanded(
                      child: Semantics(
                          label: '시 선택',
                          child: CupertinoPicker(
                            key: const ValueKey('wheel-hour'),
                            scrollController: _hours,
                            itemExtent: 44,
                            looping: true,
                            onSelectedItemChanged: (value) => setState(() {
                              _hour = value;
                              _error = null;
                            }),
                            children: [
                              for (int h = 0; h < 24; h++)
                                Center(
                                    child: Text(h.toString().padLeft(2, '0')))
                            ],
                          ))),
                  const Text('시'),
                  Expanded(
                      child: Semantics(
                          label: '분 선택',
                          child: CupertinoPicker(
                            key: const ValueKey('wheel-minute'),
                            scrollController: _minutes,
                            itemExtent: 44,
                            looping: true,
                            onSelectedItemChanged: (value) => setState(() {
                              _minute = value;
                              _error = null;
                            }),
                            children: [
                              for (int m = 0; m < 60; m++)
                                Center(
                                    child: Text(m.toString().padLeft(2, '0')))
                            ],
                          ))),
                  const Text('분'),
                  const SizedBox(width: 12),
                ])),
          ),
          if (widget.allowEndOfDay)
            const Text('종료 00:00은 하루 끝인 24:00으로 적용돼요.',
                style: TextStyle(fontSize: 12)),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
        ]),
      ));
}
