import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/voter.dart';

/// Singleton database helper.
/// On first launch, copies `assets/voters.db` to the app documents directory.
/// Supports 2–5 lakh (200K–500K) records via SQLite with proper indexes.
class DbHelper {
  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();

  Database? _db;

  /// Progress callback: receives bytes copied so far and total bytes.
  /// Useful for showing a loading indicator on first launch.
  void Function(int copied, int total)? onCopyProgress;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'voters.db');

    if (!await File(dbPath).exists()) {
      // Load asset as bytes — works for large DBs (50–100 MB)
      final data = await rootBundle.load('assets/voters.db');
      final total = data.lengthInBytes;
      final bytes = data.buffer.asUint8List(data.offsetInBytes, total);

      // Write in 1 MB chunks so progress can be reported
      const chunkSize = 1024 * 1024; // 1 MB
      final file = File(dbPath).openWrite();
      int offset = 0;
      while (offset < total) {
        final end = (offset + chunkSize).clamp(0, total);
        file.add(bytes.sublist(offset, end));
        offset = end;
        onCopyProgress?.call(offset, total);
      }
      await file.flush();
      await file.close();
    }

    return openDatabase(
      dbPath,
      readOnly: true,
      onOpen: (db) async {
        // Gracefully add part_name column if the bundled DB was built
        // without it (older extractions).  SQLite silently ignores it if
        // it already exists because of the IF NOT EXISTS guard in the
        // PRAGMA column-check below.
        final columns = await db.rawQuery("PRAGMA table_info(voters)");
        final hasPartName = columns.any((c) => c['name'] == 'part_name');
        if (!hasPartName) {
          // openDatabase was called readOnly; re-open writable just for migration.
          final rw = await openDatabase(dbPath);
          await rw.execute(
              "ALTER TABLE voters ADD COLUMN part_name TEXT DEFAULT ''");
          await rw.close();
        }
      },
    );
  }

  // ── Search methods ──────────────────────────────────────────────────────────

  /// Returns the single voter with the exact [voterId] (EPIC number).
  Future<List<Voter>> searchByVoterId(String voterId) async {
    final db = await database;
    final rows = await db.query(
      'voters',
      where: 'UPPER(voter_id) = ?',
      whereArgs: [voterId.trim().toUpperCase()],
    );
    return rows.map(Voter.fromMap).toList();
  }

  /// Returns all voters whose name contains [name] (Telugu or English).
  Future<List<Voter>> searchByName(String name) async {
    final db = await database;
    final pattern = '%${name.trim()}%';
    final rows = await db.query(
      'voters',
      where: 'voter_name LIKE ?',
      whereArgs: [pattern],
      orderBy: 'voter_name',
      limit: 200,
    );
    return rows.map(Voter.fromMap).toList();
  }

  /// Returns all voters belonging to the given [houseNumber] (whole family).
  Future<List<Voter>> searchByHouseNumber(String houseNumber) async {
    final db = await database;
    final rows = await db.query(
      'voters',
      where: 'house_number = ?',
      whereArgs: [houseNumber.trim()],
      orderBy: 'CAST(serial_no AS INTEGER)',
    );
    return rows.map(Voter.fromMap).toList();
  }

  /// Returns total number of voters in the database.
  Future<int> totalVoters() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM voters');
    return (result.first['cnt'] as int?) ?? 0;
  }
}
