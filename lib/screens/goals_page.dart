import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _green = Color(0xFF007F61);

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: Text('Goals'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: GoalsSection(),
    ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: _green,
      foregroundColor: Colors.white,
      onPressed: () => _createGoal(context),
      icon: Icon(Icons.add),
      label: Text('New goal'),
    ),
  );
}

CollectionReference<Map<String, dynamic>> _collection() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Sign in to manage goals');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('goals');
}

Future<void> _createGoal(BuildContext context) async {
  final key = GlobalKey<FormState>();
  var title = '';
  var target = '';
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('New savings goal'),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Goal name'),
              maxLength: 60,
              onChanged: (value) => title = value,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a goal name'
                  : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Target amount (Rs.)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => target = value,
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? 'Enter an amount greater than zero'
                    : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(context, <String, dynamic>{
                'title': title.trim(),
                'target': double.parse(target),
                'saved': 0.0,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          },
          child: Text('Create'),
        ),
      ],
    ),
  );
  if (result == null || !context.mounted) return;
  try {
    await _collection().add(result);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save goal. Please try again.')),
      );
    }
  }
}

/// Both the Home preview and Goals page read the same user's saved goals.
class GoalsSection extends StatefulWidget {
  final bool preview;
  final VoidCallback? onSeeMore;
  const GoalsSection({super.key, this.preview = false, this.onSeeMore});

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _goals = _collection()
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Savings goals',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (widget.preview)
            TextButton(
              onPressed: widget.onSeeMore,
              child: Text('See more', style: TextStyle(color: _green)),
            ),
        ],
      ),
      SizedBox(height: 12),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _goals,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _box(
              Text(
                'Could not load goals. Check your connection.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: _green));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return _box(
              Column(
                children: [
                  Icon(Icons.flag_rounded, size: 36, color: _green),
                  SizedBox(height: 10),
                  Text(
                    'Save for something that matters',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create your first savings goal.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => _createGoal(context),
                    child: Text(
                      'Create a goal',
                      style: TextStyle(color: _green),
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: docs.take(widget.preview ? 2 : docs.length).map((doc) {
              final data = doc.data();
              final saved = (data['saved'] as num?)?.toDouble() ?? 0;
              final target = (data['target'] as num?)?.toDouble() ?? 0;
              final progress = target > 0
                  ? (saved / target).clamp(0.0, 1.0)
                  : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _box(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, color: _green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              data['title'] as String? ?? 'Savings goal',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(color: _green),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        color: _green,
                        backgroundColor: Color(0xFFE7F4EE),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Rs. ${NumberFormat('#,##0.##').format(saved)} of Rs. ${NumberFormat('#,##0.##').format(target)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      if (!widget.preview) SizedBox(height: 80),
    ],
  );

  Widget _box(Widget child) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}
