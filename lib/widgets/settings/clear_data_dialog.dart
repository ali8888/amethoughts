import 'dart:async';

import 'package:material_ui/material_ui.dart';

void showClearDataDialog(BuildContext context, Completer cInit, Completer cJob) {
  bool inProgress = false;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          return AlertDialog(
            title: const Text('Clear all data'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  if(!inProgress)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Are you sure you want to clear all data related to Amethoughts ? \nThis process will remove all persistent thoughts, and reset your settings.',
                    ),
                  ),
                  if(inProgress)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(value: null),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Clearing in progress'),
                      )
                  ],)
                ],
              ),
            ),
            actions: <Widget>[
              if(!inProgress)
              TextButton(
                onPressed: () {
                  cInit.complete(false);
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              if(!inProgress)
              TextButton(
                onPressed: () async {
                  dialogSetState(() {
                    inProgress = true;
                  },);
                  cInit.complete(true);
                  await cJob.future;
                  if(context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Proceed'),
              ),
            ],
          );
        },
      );
    },
  );
}
