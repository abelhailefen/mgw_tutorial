// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';




class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'app_database.db');
    print("Database path: $path");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables...");
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY,
        title TEXT,
        shortDescription TEXT,
        description TEXT,
        outcomes TEXT, -- Stored as JSON string
        language TEXT,
        categoryId INTEGER,
        section TEXT,
        requirements TEXT, -- Stored as JSON string
        price TEXT,
        discountFlag INTEGER, -- Stored as 0 or 1
        discountedPrice TEXT,
        thumbnail TEXT,
        videoUrl TEXT,
        isTopCourse INTEGER, -- Stored as 0 or 1
        status TEXT,
        isVideoCourse INTEGER, -- Stored as 0 or 1
        isFreeCourse INTEGER, -- Stored as 0 or 1
        multiInstructor INTEGER, -- Stored as 0 or 1
        creator TEXT,
        createdAt TEXT, -- Stored as ISO 8601 string
        updatedAt TEXT, -- Stored as ISO 8601 string
        courseCategoryId INTEGER,
        courseCategoryName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sections(
        id INTEGER PRIMARY KEY,
        courseId INTEGER,
        title TEXT,
        'order' INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons(
        id INTEGER PRIMARY KEY,
        sectionId INTEGER,
        title TEXT,
        summary TEXT,
        'order' INTEGER,
        videoProvider TEXT,
        videoUrl TEXT,
        attachmentUrl TEXT,
        attachmentTypeString TEXT,
        lessonTypeString TEXT,
        duration TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (sectionId) REFERENCES sections(id) ON DELETE CASCADE
      )
    ''');
    print("Database tables created successfully.");
  }

   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Database upgrading from version $oldVersion to $newVersion. No schema changes implemented.");
  }


  Future<int> upsert(String table, Map<String, dynamic> data) async {
    final db = await database;
    try {
      final id = await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      print("Error upserting into $table: $e\nData: $data");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    try {
      final result = await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );
      return result;
    } catch (e) {
      print("Error querying $table: $e\nWhere: $where, Args: $whereArgs, Order: $orderBy");
      rethrow;
    }
  }

   Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
     try {
       final count = await db.delete(
         table,
         where: where,
         whereArgs: whereArgs,
       );
       return count;
     } catch (e) {
       print("Error deleting from $table: $e\nWhere: $where, Args: $whereArgs");
       rethrow;
     }
   }

   Future<void> deleteAllCourses() async {
     await delete('courses');
   }

   Future<void> deleteSectionsForCourse(int courseId) async {
     await delete('sections', where: 'courseId = ?', whereArgs: [courseId]);
   }

    Future<void> deleteLessonsForSection(int sectionId) async {
     await delete('lessons', where: 'sectionId = ?', whereArgs: [sectionId]);
   }
}