import 'package:amethoughts/global.dart';
import 'package:material_ui/material_ui.dart';

void showEraseDialog(BuildContext context, VoidCallback erase) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          return AlertDialog(
            title: const Text('Erase all thoughts'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'This will erase all the thoughts you wrote during this session!',
                  ),
                  Text(
                    'However, your library of persistent thoughts will remain untouched.',
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Checkbox(
                          value: GlobalData.dontShowAgain,
                          onChanged: (value) {
                            dialogSetState(() {
                              GlobalData.dontShowAgain = value!;
                            });
                          },
                        ),
                      ),
                      Text('Don\'t show again'),
                    ],
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  GlobalData.dontShowAgain = false;
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  erase();
                  Future<bool> res = GlobalData.saveEraseConfirm();
                  res.then((value) {
                    if(!value) {
                      GlobalData.scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Something unexpected has occured when attempting to save some settings.'),
                        ),
                      );
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Erase'),
              ),
            ],
          );
        },
      );
    },
  );
}
