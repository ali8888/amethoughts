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
import 'dart:collection';
import 'dart:io';

import 'package:amethoughts/entity/thought.dart';
import 'package:amethoughts/util/leave_confirmation.dart';
import 'package:bloc_signals/bloc_signals.dart';
import 'package:material_ui/material_ui.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

abstract class ThoughtList extends CubitSignal<List<Thought>> {
  ThoughtList() : super(initialState: []);
  ThoughtList.recreate(List<Thought> list) : super(initialState: list);

  void insert(Thought thought) => emit([thought] + stateValue);
  void edit(Thought modifiedThought) => emit(
    stateValue
        .map((e) => (e.uuid == modifiedThought.uuid ? modifiedThought : e))
        .toList(),
  );
  void remove(Thought thought) => emit(
    stateValue.where((element) => element.uuid != thought.uuid).toList(),
  );
  void removeLast() {
    if (stateValue.isNotEmpty) {
      emit(stateValue.sublist(0, stateValue.length - 1));
    }
  }

  void removeWhere(bool Function(Thought) test) =>
      emit(stateValue.where((elt) => !test(elt)).toList());
  void clear() => emit([]);
  void recreate(List<Thought> newList) => emit(newList);
  List<Thought> filtered(String query) => stateValue
      .where(
        (element) =>
            element.thought.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();
  Thought findByUuid(String uuid) =>
      stateValue.firstWhere((elt) => elt.uuid == uuid);

  Thought operator [](int index) {
    return stateValue[index];
  }

  List<Thought> toList() {
    return stateValue;
  }
}

class Thoughts extends ThoughtList;

class PersistentThoughts extends ThoughtList {
  PersistentThoughts.recreate(List<Thought> list) {
    super.recreate(list);
  }
}

class IsBeingEdited extends CubitSignal<String?> {
  IsBeingEdited() : super(initialState: null);

  void start(String uuid) => emit(uuid);
  void clear() => emit(null);
}

typedef BeforeClose = Future<bool> Function();

typedef SaveJob = Future<bool> Function();

class SaveQueue with WindowListener {
  static final SaveQueue _singleton = SaveQueue._internal();
  final Queue<({SaveJob run, Completer<bool> result})> _jobs = Queue();
  bool _running;

  bool get isBusy => _running || _jobs.isNotEmpty;

  bool lastJob;

  BeforeClose? beforeClose;

  factory SaveQueue() {
    return _singleton;
  }

  SaveQueue._internal() : _running = false, lastJob = false {
    final log = Logger('SaveQueue');
    log.info('Initialized.');
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
    }
  }

  Future<bool> add(SaveJob job, {bool persistOnClose = false}) async {
    if(lastJob) return true;
    final result = Completer<bool>();
    _jobs.add((run: job, result: result));
    if(persistOnClose) {
      lastJob = true;
    }
    unawaited(_drain());
    return result.future;
  }

  Future<void> _drain() async {
    if (_running) return;
    final log = Logger('SaveQueue');
    _running = true;
    if (kIsWeb) {
      enableLeaveConfirmation();
    }
    
    log.info('Busy.');

    while (_jobs.isNotEmpty) {
      final job = _jobs.removeFirst();
      bool res = await job.run();
      job.result.complete(res);
    }
    _running = false;
    log.info('Unbusy.');
    
    if (lastJob) {
      log.info('Done, autoclosing.');
      await windowManager.destroy();
    } else {
      if (kIsWeb) {
        disableLeaveConfirmation();
      }
    }
  }

  @override
  void onWindowClose() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      if(GlobalData.alreadyClosing.value) {
        return;
      }
      GlobalData.alreadyClosing.value = true;
      final log = Logger('SaveQueue');
      if (_running) {
        log.info(
          'Prevented the app from closing due to ongoing database operations.',
        );
        if (beforeClose != null && GlobalData.persistOnClose) {
          await beforeClose!();
        } else {
          lastJob = true;
        }
      } else {
        if (beforeClose != null && GlobalData.persistOnClose) {
          log.info('Persisting thoughts before closing.');
          await beforeClose!();
        } else {
          await windowManager.destroy();
        }
      }
    }
  }
}

class GlobalData {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static bool? dontShowAgain = false; // For erasing all thoughts
  static const String defaultPlaceholder = "What's distracting you right now ?";
  static String placeholder = defaultPlaceholder;
  static String version = "indev";
  static String dbName = "data.db";
  static const String namespace = "lymesque";
  static ThemeMode initThemeMode = ThemeMode.system;
  static const Color defaultPrimaryColor = Colors.deepPurpleAccent;
  static Color initPrimaryColor = defaultPrimaryColor;
  static List<Thought> initPersistentThoughts = [];
  static bool initError = false;
  static bool isDesktop = true;
  static bool persistOnClose = false;
  static ValueNotifier<bool> alreadyClosing = ValueNotifier<bool>(false);
  static String defaultSetting = '''
      INSERT OR IGNORE INTO settings (onlyentry, theme, primary_color_r, primary_color_g, primary_color_b, primary_color_a, erase_confirm, placeholder, persist_on_close)
      VALUES (1, 'System', 124, 77, 255, 255, 1, 'What''s distracting you right now ?', 0)
    ''';
  

  static Future<bool> saveAppearance(
    ThemeMode themeMode,
    Color primaryColor,
  ) async {
    var saving = SaveQueue();

    var res = saving.add(() async {
      try {
        Database db;
        if (!kIsWeb) {
          Directory saveDir = await getApplicationSupportDirectory();
          var databaseFactory = databaseFactoryFfi;
          db = await databaseFactory.openDatabase(
            join(saveDir.path, GlobalData.dbName),
          );
        } else {
          var factory = databaseFactoryFfiWeb;
          db = await factory.openDatabase(GlobalData.dbName);
        }
        int changes = await db.update(
          'settings',
          {
            'theme': themeMode == ThemeMode.dark
                ? 'dark'
                : (themeMode == ThemeMode.light ? 'light' : 'system'),
            'primary_color_r': (primaryColor.r * 255.0).round().clamp(0, 255),
            'primary_color_g': (primaryColor.g * 255.0).round().clamp(0, 255),
            'primary_color_b': (primaryColor.b * 255.0).round().clamp(0, 255),
            'primary_color_a': (primaryColor.a * 255.0).round().clamp(0, 255),
          },
          where: 'onlyentry = ?',
          whereArgs: [1],
        );
        await db.close();
        return changes == 1;
      } catch (e, stackTrace) {
        Logger log = Logger('Global');
        log.severe('Error while trying to save app appearance.', e, stackTrace);
        return false;
      }
    });

    return res;
  }

  static Future<bool> savePlaceholder() async {
    var saving = SaveQueue();

    var res = saving.add(() async {
      try {
        Database db;
        if (!kIsWeb) {
          Directory saveDir = await getApplicationSupportDirectory();
          var databaseFactory = databaseFactoryFfi;
          db = await databaseFactory.openDatabase(
            join(saveDir.path, GlobalData.dbName),
          );
        } else {
          var factory = databaseFactoryFfiWeb;
          db = await factory.openDatabase(GlobalData.dbName);
        }
        int changes = await db.update(
          'settings',
          {'placeholder': placeholder},
          where: 'onlyentry = ?',
          whereArgs: [1],
        );
        await db.close();
        return changes == 1;
      } catch (e, stackTrace) {
        Logger log = Logger('Global');
        log.severe(
          'Error while trying to save the text input placeholder.',
          e,
          stackTrace,
        );
        return false;
      }
    });
    return res;
  }

  static Future<bool> savePersistOnClose() async {
    var saving = SaveQueue();

    var res = saving.add(() async {
      try {
        Database db;
        if (!kIsWeb) {
          Directory saveDir = await getApplicationSupportDirectory();
          var databaseFactory = databaseFactoryFfi;
          db = await databaseFactory.openDatabase(
            join(saveDir.path, GlobalData.dbName),
          );
        } else {
          var factory = databaseFactoryFfiWeb;
          db = await factory.openDatabase(GlobalData.dbName);
        }
        int changes = await db.update(
          'settings',
          {'persist_on_close': persistOnClose ? 1 : 0},
          where: 'onlyentry = ?',
          whereArgs: [1],
        );
        await db.close();
        return changes == 1;
      } catch (e, stackTrace) {
        Logger log = Logger('Global');
        log.severe(
          'Error while trying to save the "Persist on close" setting.',
          e,
          stackTrace,
        );
        return false;
      }
    });
    return res;
  }

  static Future<bool> saveEraseConfirm() async {
    var saving = SaveQueue();
    var res = saving.add(() async {
      try {
        Database db;
        if (!kIsWeb) {
          Directory saveDir = await getApplicationSupportDirectory();
          var databaseFactory = databaseFactoryFfi;
          db = await databaseFactory.openDatabase(
            join(saveDir.path, GlobalData.dbName),
          );
        } else {
          var factory = databaseFactoryFfiWeb;
          db = await factory.openDatabase(GlobalData.dbName);
        }
        int changes = await db.update(
          'settings',
          {'erase_confirm': dontShowAgain == true ? 0 : 1},
          where: 'onlyentry = ?',
          whereArgs: [1],
        );
        await db.close();
        return changes == 1;
      } catch (e, stackTrace) {
        Logger log = Logger('Global');
        log.severe(
          'Error while trying to save a confirmation setting.',
          e,
          stackTrace,
        );
        return false;
      }
    });
    return res;
  }

  static Future<bool> savePersistentThoughts(List<Thought> content, {bool persistOnClose = false}) async {
    var saving = SaveQueue();
    var res = saving.add(() async {
      try {
        Database db;
        if (!kIsWeb) {
          Directory saveDir = await getApplicationSupportDirectory();
          var databaseFactory = databaseFactoryFfi;
          db = await databaseFactory.openDatabase(
            join(saveDir.path, GlobalData.dbName),
          );
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
        final batch = db.batch();

        for (final e in content) {
          batch.rawInsert(
            '''
              INSERT OR REPLACE INTO persistent_thoughts (thought, uuid, date)
              VALUES (?, ?, ?)
              ''',
            [
              e.thought,
              e.uuid,
              e.date == null ? 0 : e.date!.millisecondsSinceEpoch,
            ],
          );
        }

        await batch.commit(noResult: true);
        await db.close();
        return true;
      } catch (e, stackTrace) {
        Logger log = Logger('Global');
        log.severe(
          'Error while trying to save persistent thoughts.',
          e,
          stackTrace,
        );
        return false;
      }
    }, persistOnClose: persistOnClose);

    return res;
  }

  static Future<bool> removePersistentThought(String uuid) async {
    var saving = SaveQueue();
    var res = saving.add(() async {
      try {
        Database db;
        if (!kIsWeb) {
          Directory saveDir = await getApplicationSupportDirectory();
          var databaseFactory = databaseFactoryFfi;
          db = await databaseFactory.openDatabase(
            join(saveDir.path, GlobalData.dbName),
          );
        } else {
          var factory = databaseFactoryFfiWeb;
          db = await factory.openDatabase(GlobalData.dbName);
        }
        int changes = await db.delete(
          'persistent_thoughts',
          where: 'uuid = ?',
          whereArgs: [uuid],
        );

        await db.close();
        return changes == 1;
      } catch (e, stackTrace) {
        Logger log = Logger('Global');
        log.severe(
          'Error while trying to remove a persistent thought.',
          e,
          stackTrace,
        );
        return false;
      }
    });
    return res;
  }

  static Future<bool> clearAllSaveData() async {
    var saving = SaveQueue();
    var res = saving.add(() async {
      try {
        Database db;
        if (!kIsWeb) {
          Directory saveDir = await getApplicationSupportDirectory();
          var databaseFactory = databaseFactoryFfi;
          db = await databaseFactory.openDatabase(
            join(saveDir.path, GlobalData.dbName),
          );
        } else {
          var factory = databaseFactoryFfiWeb;
          db = await factory.openDatabase(GlobalData.dbName);
        }
        await db.delete('persistent_thoughts');
        await db.delete('settings');
        await db.execute(GlobalData.defaultSetting);

        await db.close();
        return true;
      } catch (e, stackTrace) {
        Logger log = Logger('Global');
        log.severe('Error while trying to clear all data.', e, stackTrace);
        return false;
      }
    });
    return res;
  }
}
