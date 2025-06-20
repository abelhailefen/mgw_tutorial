import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mgw_tutorial/models/semester.dart';

class SemesterDB {
  static final SemesterDB _instance = SemesterDB._internal();
  factory SemesterDB() => _instance;
  SemesterDB._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'semesters.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE semesters (
          id INTEGER PRIMARY KEY,
          name TEXT,
          year TEXT,
          price TEXT,
          images TEXT,
          courses TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
        ''');
      },
    );
  }

  Future<void> insertSemesters(List<Semester> semesters) async {
    final db = await database;
    final batch = db.batch();
    for (var semester in semesters) {
      batch.insert(
        'semesters',
        {
          'id': semester.id,
          'name': semester.name,
          'year': semester.year,
          'price': semester.price,
          'images': semester.images.join(','),
          'courses': semester.courses.map((c) => c.name).join(','),
          'createdAt': semester.createdAt.toIso8601String(),
          'updatedAt': semester.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Semester>> getSemesters() async {
    final db = await database;
    final maps = await db.query('semesters');
    return maps.map((map) {
      return Semester(
        id: map['id'] as int,
        name: map['name'] as String,
        year: map['year'] as String,
        price: map['price'] as String,
        images: (map['images'] as String).isEmpty
            ? []
            : (map['images'] as String).split(','),
        courses: (map['courses'] as String).isEmpty
            ? []
            : (map['courses'] as String)
                .split(',')
                .map((name) => Course(name: name))
                .toList(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
    }).toList();
  }

  Future<void> clearSemesters() async {
    final db = await database;
    await db.delete('semesters');
  }
}