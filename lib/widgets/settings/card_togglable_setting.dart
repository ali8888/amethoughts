import 'package:material_ui/material_ui.dart';

class CardTogglableSetting extends StatelessWidget {
  const CardTogglableSetting({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.action,
    this.available = true,
    
  });

  final String title;
  final String description;
  final Icon icon;
  final bool available;
  final bool value;
  final Function(bool) action;

  @override
  Widget build(BuildContext context) {

    return Card(
      child: Opacity(
        opacity: available ? 1 : 0.5,
        child: InkWell(
          onTap: !available ? null : () => action(!value),
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
                Padding(padding: const EdgeInsets.all(10.0), child: Switch(
                  value:value,
                  onChanged: !available ? null : (value) => action(value),

                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
