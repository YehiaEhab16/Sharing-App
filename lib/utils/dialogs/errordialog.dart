import 'package:flutter/material.dart';
import 'genericdialog.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String text,
) {
  return showGenericDialog(
    context: context,
    title: 'An Error Ocurred',
    content: text,
    optionsBuilder: () => {
      'OK': null,
    },
  );
}
