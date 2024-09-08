import 'package:flutter/material.dart';

Future<dynamic> alertUser(BuildContext context, String message,
    {Widget? content, String cancelButtonText = "Cancel", List<Widget> additionalActions = const []}) {
  List<Widget> actionButtons = [];
  actionButtons.add(TextButton(onPressed: () => Navigator.pop(context), child: Text(cancelButtonText)));
  actionButtons.addAll(additionalActions);
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          message,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: content ?? const SizedBox(height: 0),
        actions: actionButtons,
      );
    },
  );
}
