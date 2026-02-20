import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:quran_lake/data/models/prayer_time.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quran_lake.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_times_cache(
        date TEXT PRIMARY KEY,
        fajr TEXT,
        sunrise TEXT,
        dhuhr TEXT,
        asr TEXT,
        maghrib TEXT,
        isha TEXT,
        city TEXT,
        country TEXT
      )
    ''');

    // Optional: Location cache if needed separately
    await db.execute('''
      CREATE TABLE location_cache(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL,
        longitude REAL,
        city TEXT,
        country TEXT,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> insertPrayerTime(PrayerTime prayerTime) async {
    final db = await database;
    await db.insert(
      'prayer_times_cache',
      prayerTime.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PrayerTime?> getPrayerTime(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_times_cache',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return PrayerTime.fromJson(maps.first);
    }
    return null;
  }

  Future<void> clearPrayerTimes() async {
    final db = await database;
    await db.delete('prayer_times_cache');
  }
}
