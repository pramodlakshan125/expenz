import 'package:expenz/formatters/money.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:flutter/material.dart';

class CreateGoalSheet extends StatefulWidget {
  final BudgetController controller;
  const CreateGoalSheet({super.key, required this.controller});
  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  bool _submitted = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New savings goal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Goal name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a goal name.'
                  : null,
            ),
            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: 'Rs. ',
              ),
              validator: (value) {
                final amount = parseMoneyMinor(value ?? '');
                return amount == null || amount <= 0
                    ? 'Enter a positive amount with up to 2 decimals.'
                    : null;
              },
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitted
                    ? null
                    : () {
                        if (!_form.currentState!.validate()) return;
                        setState(() => _submitted = true);
                        try {
                          widget.controller.createGoal(
                            title: _name.text,
                            targetMinor: parseMoneyMinor(_target.text)!,
                          );
                          if (widget.controller.error != null) {
                            throw StateError(
                              'Could not queue this goal. Please retry.',
                            );
                          }
                          Navigator.pop(context, true);
                        } catch (error) {
                          setState(() {
                            _submitted = false;
                            _error = '$error';
                          });
                        }
                      },
                child: const Text('Create goal'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
