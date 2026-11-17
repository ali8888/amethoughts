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

import 'package:amethoughts/entity/thought.dart';
import 'package:amethoughts/global.dart';
import 'package:amethoughts/widgets/closing_dialog.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';

import 'screens/home.dart';
import 'screens/library.dart';
import 'screens/settings.dart';

import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io' show Platform, Directory;


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalData.version = packageInfo.version;

  // Logging
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  if (!kIsWeb) {
    GlobalData.isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  } else {
    GlobalData.isDesktop = (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS);
  }

  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      WidgetsFlutterBinding.ensureInitialized();
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);

      const Color windowBackground = Color(0xFF0F172A);

      WindowOptions windowOptions = const WindowOptions(
        size: Size(800, 600),
        minimumSize: Size(400, 500),
        backgroundColor: windowBackground,
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  // Desktop & Mobile Database init
  
  Database db;
  if (!kIsWeb) {
    sqfliteFfiInit();
    Directory saveDir = await getApplicationSupportDirectory();
    var databaseFactory = databaseFactoryFfi;
    db = await databaseFactory.openDatabase(join(saveDir.path, GlobalData.dbName));
  } else {
    var factory = databaseFactoryFfiWeb;
    db = await factory.openDatabase(GlobalData.dbName);
  }

  await db.execute('''
      CREATE TABLE IF NOT EXISTS persistent_thoughts (
        thought VARCHAR(1000),
        uuid VARCHAR(100) PRIMARY KEY,
        date INTEGER
      )
    ''');

  String createSettingsQuery = '''
      CREATE TABLE IF NOT EXISTS settings (
        onlyentry INTEGER PRIMARY KEY,
        theme VARCHAR(100),
        primary_color_r INTEGER,
        primary_color_g INTEGER,
        primary_color_b INTEGER,
        primary_color_a INTEGER,
        erase_confirm INTEGER,
        placeholder VARCHAR(200),
        persist_on_close INTEGER
      )
  ''';
  await db.execute(createSettingsQuery);
  try {
    await db.execute(GlobalData.defaultSetting);
  } catch (e) {
    await db.execute('''
    DROP TABLE IF EXISTS settings;
    ''');
    await db.execute(createSettingsQuery);
    await db.execute(GlobalData.defaultSetting);
    GlobalData.initError = true;
  }
  
  var result = await db.query('settings');

  if (result.isNotEmpty) {
    Map<String, Object?> settings = result[0];

    // Theme Mode
    if (settings['theme'] == 'dark') {
      GlobalData.initThemeMode = ThemeMode.dark;
    } else if (settings['theme'] == 'light') {
      GlobalData.initThemeMode = ThemeMode.light;
    }

    try {
      // Color
      GlobalData.initPrimaryColor = Color.fromARGB(
        settings['primary_color_a'] as int,
        settings['primary_color_r'] as int,
        settings['primary_color_g'] as int,
        settings['primary_color_b'] as int,
      );

      // Placeholder
      GlobalData.placeholder = settings['placeholder'] as String;

      // Persist on close
      GlobalData.persistOnClose = settings['persist_on_close'] as int == 1;
    } catch (e) {
      GlobalData.initError = true;
    }

    GlobalData.dontShowAgain = settings['erase_confirm'] == 0;
  }

  result = await db.query('persistent_thoughts');
  if (result.isNotEmpty) {
    try {
      GlobalData.initPersistentThoughts = result
          .map(
            (e) => Thought.recreate(
              e['thought'] as String,
              e['uuid'] as String,
              DateTime.fromMillisecondsSinceEpoch(e['date'] as int),
            ),
          )
          .toList();
    } catch (e) {
      GlobalData.initError = true;
    }
  }

  await db.close();
  SaveQueue();
  runApp(const AmethoughtsRoot());
}

class AmethoughtsRoot extends StatefulWidget {
  const AmethoughtsRoot({super.key});

  @override
  State<AmethoughtsRoot> createState() => AmethoughtsRootState();
}

class AmethoughtsRootState extends State<AmethoughtsRoot> {
  ThemeMode? _themeMode = GlobalData.initThemeMode;
  ThemeMode? get themeMode => _themeMode;

  Color? _primaryColor = GlobalData.initPrimaryColor;
  Color? get primaryColor => _primaryColor;

  void setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void setPrimaryColor(Color primaryColor) {
    setState(() {
      _primaryColor = primaryColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: GlobalData.scaffoldMessengerKey,
      title: 'Amethoughts',
      themeMode: _themeMode ?? ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor ?? GlobalData.defaultPrimaryColor,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor ?? GlobalData.defaultPrimaryColor,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      home: const Amethoughts(),
    );
  }
}

class Amethoughts extends StatefulWidget {
  const Amethoughts({super.key});

  @override
  State<Amethoughts> createState() => _AmethoughtsState();
}

class _AmethoughtsState extends State<Amethoughts> {
  @override
  Widget build(BuildContext context) {
    return ClosingDialog(
      child: DefaultTabController(
        initialIndex: 0,
        length: 3,
        child: Scaffold(
          appBar: !GlobalData.isDesktop ? null : TabBar(
            tabs: <Widget>[
              Tab(text: "Home", icon: Icon(Icons.home_outlined)),
              Tab(text: "Library", icon: Icon(Icons.local_library_outlined)),
              Tab(text: "Settings", icon: Icon(Icons.settings_outlined)),
            ],
          ),
          bottomNavigationBar: GlobalData.isDesktop ? null : TabBar(
            tabs: <Widget>[
              Tab(text: "Home", icon: Icon(Icons.home_outlined), height: 60),
              Tab(text: "Library", icon: Icon(Icons.local_library_outlined), height: 60),
              Tab(text: "Settings", icon: Icon(Icons.settings_outlined), height: 60),
            ],
          ) ,
          body: MultiBlocSignalProvider(
            providers: [
              BlocSignalProvider<Thoughts>(create: (_) => Thoughts()),
              BlocSignalProvider<PersistentThoughts>(
                create: (_) => PersistentThoughts.recreate(
                  GlobalData.initPersistentThoughts,
                ),
              ),
              BlocSignalProvider<IsBeingEdited>(create: (_) => IsBeingEdited()),
            ],
            child: TabBarView(
              children: <Widget>[HomePage(), LibraryPage(), SettingsPage()],
            ),
          ),
        ),
      ),
    );
  }
}
