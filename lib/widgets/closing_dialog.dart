import 'package:material_ui/material_ui.dart';
import 'package:amethoughts/global.dart';

class ClosingDialog extends StatefulWidget {
  final Widget child;

  const ClosingDialog({
    super.key,
    required this.child,
  });

  @override
  State<ClosingDialog> createState() =>
      _ClosingDialogState();
}

class _ClosingDialogState
    extends State<ClosingDialog> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobalData.alreadyClosing,
      builder: (context, showDialog, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (showDialog) {
            _showDialogIfNeeded();
          } else {
            Navigator.of(context, rootNavigator: true)
                .maybePop();
          }
        });

        return widget.child;
      },
    );
  }

  void _showDialogIfNeeded() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(value: null),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Closing...'),
                      )
            ],),
          ),
        );
      },
    );
  }
}