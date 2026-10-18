import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

abstract final class DatabaseConnectionFactory {
  static QueryExecutor connect({String dbName = 'obsidian_slate.sqlite'}) {
    return LazyDatabase(() async {
      final Directory dbFolder = await _resolveStorageDirectory();
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }
      final file = File(p.join(dbFolder.path, dbName));
      return NativeDatabase.createInBackground(file);
    });
  }

  static QueryExecutor inMemory() {
    return NativeDatabase.memory();
  }

  static Future<Directory> _resolveStorageDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? Directory.current.path;
      return Directory(p.join(appData, 'ObsidianSlate'));
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      return Directory(p.join(home, '.local', 'share', 'obsidian_slate'));
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      return Directory(p.join(home, 'Library', 'Application Support', 'obsidian_slate'));
    } else {
      return Directory.systemTemp;
    }
  }
}
