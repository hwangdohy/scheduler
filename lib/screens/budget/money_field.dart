import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String money(int amount) => '${NumberFormat('#,###').format(amount)}원';

class MoneyField extends StatelessWidget {
  const MoneyField({super.key, required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, suffixText: '원'),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12)
        ],
        validator: (value) =>
            int.tryParse(value ?? '') == null ? '0 이상의 금액을 입력해주세요' : null,
      );
}
