/*
    Amethoughts
    Copyright (C) 2026 Lymesque

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:ui';

import 'package:amethoughts/global.dart';
import 'package:material_ui/material_ui.dart';
import 'package:amethoughts/main.dart';

class ChangeThemeDialog extends StatefulWidget {
  const ChangeThemeDialog({super.key});

  @override
  State<ChangeThemeDialog> createState() => _ChangeThemeDialogState();
}

class _ChangeThemeDialogState extends State<ChangeThemeDialog> {
  Future<void> saveCurrentTheme(Color color, ThemeMode? themeMode) async {
    await GlobalData.saveAppearance(themeMode ?? ThemeMode.system, color);
  }

  Widget getThemeModeOption(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.light_mode),
            ),
            Text('Light')
          ],
        );
      case ThemeMode.dark:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.dark_mode),
            ),
            Text('Dark')
          ],
        );
      case ThemeMode.system:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.computer),
            ),
            Text('System')
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.findAncestorStateOfType<AmethoughtsRootState>();
    Color selectedColor = app?.primaryColor ?? GlobalData.defaultPrimaryColor;
    ThemeMode? selectedThemeMode = app?.themeMode ?? ThemeMode.system;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if(didPop && result == null) {
          bool res = await GlobalData.saveAppearance(selectedThemeMode ?? ThemeMode.system, selectedColor);
          if(!res) {
            GlobalData.scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text('Something unexpected has occured when attempting to save your settings.'),
              ),
            );
          }
        }
      },
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: clampDouble(MediaQuery.of(context).size.width, 0, 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Change theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text('Pick a theme'),
                const SizedBox(height: 12),
                DropdownButton<ThemeMode>(
                  borderRadius: BorderRadius.circular(10),
                  underline: Container(),
                  value: selectedThemeMode,
                  onChanged: (ThemeMode? newValue) {
                    setState(() {
                      selectedThemeMode = newValue;
                    });
                    final app = context.findAncestorStateOfType<AmethoughtsRootState>();
                    app?.setThemeMode(newValue!);
                  },
                  items: ThemeMode.values
                      .map((ThemeMode themeMode) => DropdownMenuItem<ThemeMode>(
                            value: themeMode,
                            child: getThemeModeOption(themeMode),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                const Text('Pick an accent color'),
                const SizedBox(height: 10),
                Wrap(
                    alignment: WrapAlignment.center,
                    children: Colors.accents
                        .map((color) => InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                  
                                });
                                final app = context.findAncestorStateOfType<AmethoughtsRootState>();
                                app?.setPrimaryColor(color);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selectedColor == color ? ((Theme.of(context).brightness == Brightness.dark) ? Colors.white : Colors.black54) : Colors.transparent, width: 5.0)),
                                ),
                              ),
                            ))
                        .toList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}