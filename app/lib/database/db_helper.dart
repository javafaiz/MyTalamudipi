import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/voter.dart';
import '../utils/transliterate.dart';

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
      // Load asset bytes and write directly — avoids double-buffering in RAM
      final data = await rootBundle.load('assets/voters.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes, flush: true);
      onCopyProgress?.call(bytes.length, bytes.length);
    }

    return openDatabase(dbPath, readOnly: true);
  }

  // ── Search methods ──────────────────────────────────────────────────────────

  /// Returns the voter(s) matching the given [voterId] (EPIC number).
  /// Supports partial match so e.g. "405225" finds "AP271850405225".
  Future<List<Voter>> searchByVoterId(String voterId) async {
    final db = await database;
    final query = voterId.trim().toUpperCase();
    // Try exact match first
    var rows = await db.query(
      'voters',
      where: 'UPPER(voter_id) = ?',
      whereArgs: [query],
    );
    // If no exact match, try partial (LIKE)
    if (rows.isEmpty) {
      rows = await db.query(
        'voters',
        where: 'UPPER(voter_id) LIKE ?',
        whereArgs: ['%$query%'],
        limit: 50,
      );
    }
    return rows.map(Voter.fromMap).toList();
  }

  /// Returns voter(s) by serial number (exact).
  Future<List<Voter>> searchBySerialNo(String serialNo) async {
    final db = await database;
    final query = serialNo.trim();
    final rows = await db.query(
      'voters',
      where: 'serial_no = ?',
      whereArgs: [query],
      orderBy: 'CAST(serial_no AS INTEGER)',
      limit: 50,
    );
    return rows.map(Voter.fromMap).toList();
  }

  /// Returns voters whose name contains [name].
  /// Accepts both Telugu input (direct match) and English input
  /// (auto-transliterated — e.g. "faizullah" finds "ఫైజుల్లా").
  Future<List<Voter>> searchByName(String name) async {
    final db = await database;
    final input = name.trim();
    if (input.isEmpty) return [];

    // Convert English → Telugu if needed
    final teluguQuery = Transliterator.toTeluguPattern(input);
    final pattern = '%$teluguQuery%';

    final rows = await db.query(
      'voters',
      where: 'voter_name LIKE ?',
      whereArgs: [pattern],
      orderBy: 'voter_name',
      limit: 100,
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
