import 'package:amethoughts/global.dart';
import 'package:material_ui/material_ui.dart';

void showPlaceholderEditDialog(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  controller.text = GlobalData.placeholder;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          return PopScope(
            onPopInvokedWithResult: (didPop, result) async {
              if(didPop && result == null) {
                bool res = await GlobalData.savePlaceholder();
                if(!res) {
                  GlobalData.scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Something unexpected has occured when attempting to save your settings.'),
                    ),
                  );
                }
              }
            },
            
            child: AlertDialog(
              title: const Text('Pick a new placeholder text'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                      'The new placeholder will show up on the text box in the home page.',
                    ),
                    SizedBox(height:8),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 200,
                      decoration: InputDecoration(filled:true),
                      onSubmitted: (value) {GlobalData.placeholder = value;Navigator.of(context).pop();},
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    GlobalData.placeholder = controller.text;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
