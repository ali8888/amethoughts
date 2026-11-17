import 'package:material_ui/material_ui.dart';

class CardSetting extends StatelessWidget {
  const CardSetting({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.available = true,
    this.action,
  });

  final String title;
  final String description;
  final Icon icon;
  final bool available;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Opacity(
              opacity: available ? 1 : 0.5,
              child: InkWell(
                onTap: available ? action : null,
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(padding: const EdgeInsets.all(10.0), child: icon),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                              child: Text(description),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
