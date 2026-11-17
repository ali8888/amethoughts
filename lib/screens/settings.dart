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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amethoughts/entity/thought.dart';
import 'package:amethoughts/global.dart';
import 'package:amethoughts/main.dart';
import 'package:amethoughts/widgets/settings/card_setting.dart';
import 'package:amethoughts/widgets/settings/card_togglable_setting.dart';
import 'package:amethoughts/widgets/settings/change_theme.dart';
import 'package:amethoughts/widgets/settings/clear_data_dialog.dart';
import 'package:amethoughts/widgets/settings/placeholder_edit_dialog.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool exporting = false;
  bool savingPersistOnClose = false;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentGeometry.topCenter,
      child: ListView(
        children: [Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * (GlobalData.isDesktop ? 0.75 : 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if(!GlobalData.isDesktop)
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0,32.0,8.0,0),
                      child: Text('Settings', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: GlobalData.isDesktop ? 8 : 15),
                CardSetting(
                  title: 'Theme',
                  description: 'Customize the appearance of Amethoughts.',
                  icon: Icon(Icons.palette),
                  action: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => ChangeThemeDialog(),
                    );
                  },
                ),
                CardSetting(
                  title: 'Placeholder text',
                  description: 'Replace the placeholder text in the textbox used for thought writing with a custom phrase.',
                  icon: Icon(Icons.text_format),
                  action: () => showPlaceholderEditDialog(context),
                ),
                if(!kIsWeb && GlobalData.isDesktop)
                CardTogglableSetting(
                  title: 'Persist on close',
                  description: "When closing the app, your thoughts are automatically moved to your library. (This means that the app won't close as fast as usual).",
                  icon: Icon(Icons.exit_to_app),
                  value: GlobalData.persistOnClose,
                  available: !savingPersistOnClose,
                  action: (value) async {
                    setState(() {
                      GlobalData.persistOnClose = value;
                      savingPersistOnClose = true;
                    },);
                    await GlobalData.savePersistOnClose();
                    if(mounted) {
                        setState(() {
                        savingPersistOnClose = false;
                      },);
                    }
                  },
                ),
                CardSetting(
                  title: exporting ?  'Exporting...' : 'Export',
                  description: exporting ? 'You should be able to pick a location in order to export your persistent thoughts.' : 'Export your persistent thoughts into a .txt file.',
                  icon: exporting ? Icon(Icons.hourglass_empty_outlined) : Icon(Icons.download),
                  available: !exporting,
                  action: () async {
                  
                  List<Thought> persistentThoughts = List<Thought>.from(context.read<PersistentThoughts>().toList());
                  if(persistentThoughts.isEmpty) {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => Dialog(
                        child: Padding(
                          padding: const .all(32.0),
                          child: Column(
                            mainAxisSize: .min,
                            mainAxisAlignment: .center,
                            children: <Widget>[
                              const Text('You have no persistent thoughts to export.\nTry writing some!'),
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ),
                      ));
                  } else {
                    setState(() {
                      exporting = true;
                    },);
                    
                    persistentThoughts.sort((a, b) => a.date==null ? (b.date==null ? 0 : 1) : -a.date!.compareTo(b.date ?? DateTime.fromMillisecondsSinceEpoch(0)),);
                    String content = "";
                    int i = 0;
                    while(i<persistentThoughts.length) {
                      if((i==0)
                       || !(persistentThoughts[i].sameDay(persistentThoughts[i-1]))) {
                        if(i!=0) {
                          content+="\n";
                        }
                        content+="[${persistentThoughts[i].formattedDate()}]\n";
                      }
                      content+="- ${persistentThoughts[i].thought}\n";
                      i++;
                    }
                    
                    
                    Uri? outputFile = await FilePicker.saveFile(
                      dialogTitle: 'Please select an output file:',
                      fileName: 'amethoughts_export_${DateTime.now().toIso8601String().split('T')[0].replaceAll('-','_')}.txt',
                      bytes: Uint8List.fromList(utf8.encode(content))
                    );
                    String message = "...";
                    if (outputFile == null) {
                      message = "You cancelled the export.";
                    } else {
                      message = "Exported successfully to ${outputFile.path}.";
                      if(!kIsWeb) {
                        if(Platform.isAndroid) {
                          message = "Exported successfully.";
                        }
                      }
                    }
                    if(!kIsWeb) {
                      SnackBar snackBar = SnackBar(content: Text(message));
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    }
                    if(mounted) {
                      setState(() {
                      exporting = false;
                    },);
                    }
                  }
                  },
                ),
                CardSetting(
                  title: 'Clear All Data',
                  description: 'Wipe all of your Amethoughts related user data.',
                  icon: Icon(Icons.delete_forever),
                  action: () async {
                    Completer cInit = Completer();
                    Completer cJob = Completer();
                    showClearDataDialog(context, cInit, cJob);
                    bool res = await cInit.future;
                    if(res) {
                      if(context.mounted) {
                        final app = context.findAncestorStateOfType<AmethoughtsRootState>();
                        app?.setPrimaryColor(GlobalData.defaultPrimaryColor);
                        app?.setThemeMode(ThemeMode.system);
                        context.read<PersistentThoughts>().clear();
                        context.read<Thoughts>().clear();
                      }
                      GlobalData.placeholder = GlobalData.defaultPlaceholder;
                      GlobalData.dontShowAgain = false;
                      await GlobalData.clearAllSaveData(); 
                      cJob.complete();
                    }
                  },
                ),
                SizedBox(height: 8),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${GlobalData.version} - © 2026 Lymesque'),
                      SizedBox(height: 8),
                      TextButton.icon(
                        icon: FaIcon(FontAwesomeIcons.github),
                        onPressed: () async {
                          final Uri url = Uri.parse(
                            'https://www.github.com/ali8888/amethoughts',
                          );
                          if (!await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          )) {
                            throw Exception('Could not launch $url');
                          }
                        },
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Source'),
                            SizedBox(width: 5),
                            Icon(Icons.open_in_new),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        )],
      ),
    );
  }
}
