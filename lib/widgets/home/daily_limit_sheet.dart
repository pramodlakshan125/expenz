import 'package:expenz/formatters/money.dart';
import 'package:flutter/material.dart';

class DailyLimitSheet extends StatefulWidget {
  final int? currentLimitMinor;
  const DailyLimitSheet({super.key, this.currentLimitMinor});

  @override
  State<DailyLimitSheet> createState() => _DailyLimitSheetState();
}

class _DailyLimitSheetState extends State<DailyLimitSheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.currentLimitMinor == null
        ? ''
        : (widget.currentLimitMinor! / 100).toStringAsFixed(2),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily spending target',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a comfortable daily amount. Changes apply to today and future days.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Daily target',
                  prefixText: 'Rs. ',
                ),
                validator: (text) => parseMoneyMinor(text ?? '') == null
                    ? 'Enter zero or a positive amount with up to 2 decimals.'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_form.currentState!.validate()) {
                      Navigator.pop(context, parseMoneyMinor(_amount.text));
                    }
                  },
                  child: const Text('Save daily target'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
