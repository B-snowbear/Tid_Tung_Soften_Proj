import 'package:flutter/material.dart';

class AddTripResult {
  final String name;
  final String? destination;
  final DateTime start;
  final DateTime end;
  final String? description;
  AddTripResult(this.name, this.destination, this.start, this.end, this.description);
}

Future<AddTripResult?> showAddTripDialog(BuildContext context) async {
  final name = TextEditingController();
  final destination = TextEditingController();
  final description = TextEditingController();
  DateTime? start, end;

  return showDialog<AddTripResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Trip'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Trip name')),
            TextField(controller: destination, decoration: const InputDecoration(labelText: 'Destination (optional)')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx, firstDate: DateTime(2020),
                        lastDate: DateTime(2035), initialDate: DateTime.now(),
                      );
                      if (p != null) start = p;
                    },
                    child: const Text('Pick start'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx, firstDate: DateTime(2020),
                        lastDate: DateTime(2035), initialDate: DateTime.now(),
                      );
                      if (p != null) end = p;
                    },
                    child: const Text('Pick end'),
                  ),
                ),
              ],
            ),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Description (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty || start == null || end == null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Please enter name and dates')),
              );
              return;
            }
            Navigator.pop(
              ctx,
              AddTripResult(
                name.text.trim(),
                destination.text.trim().isEmpty ? null : destination.text.trim(),
                start!, end!,
                description.text.trim().isEmpty ? null : description.text.trim(),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
