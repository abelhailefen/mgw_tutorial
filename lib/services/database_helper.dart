// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:mgw_tutorial/models/user.dart';

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
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY,
        title TEXT,
        shortDescription TEXT,
        description TEXT,
        outcomes TEXT,
        language TEXT,
        categoryId INTEGER,
        section TEXT,
        requirements TEXT,
        price TEXT,
        discountFlag INTEGER,
        discountedPrice TEXT,
        thumbnail TEXT,
        videoUrl TEXT,
        isTopCourse INTEGER,
        status TEXT,
        isVideoCourse INTEGER,
        isFreeCourse INTEGER,
        multiInstructor INTEGER,
        creator TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        localThumbnailPath TEXT
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

    await db.execute('''
      CREATE TABLE logged_in_user(
        id INTEGER PRIMARY KEY,
        user_id INTEGER UNIQUE,
        first_name TEXT,
        last_name TEXT,
        phone TEXT UNIQUE,
        login_timestamp TEXT
      )
    ''');
  }

   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
         var userTableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='logged_in_user'");
         if (userTableExists.isEmpty) {
            await db.execute('''
              CREATE TABLE logged_in_user(
                id INTEGER PRIMARY KEY,
                user_id INTEGER UNIQUE,
                first_name TEXT,
                last_name TEXT,
                phone TEXT UNIQUE,
                token TEXT,
                login_timestamp TEXT
              )
            ''');
         }
    }
    if (oldVersion < 3) {
       var tableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='logged_in_user'");
       if (tableExists.isNotEmpty) {
          await db.execute('DROP TABLE logged_in_user');
       }
       await db.execute('''
         CREATE TABLE logged_in_user(
           id INTEGER PRIMARY KEY,
           user_id INTEGER UNIQUE,
           first_name TEXT,
           last_name TEXT,
           phone TEXT UNIQUE,
           login_timestamp TEXT
         )
       ''');
    }
     if (oldVersion < 4) {
       var columnExists = await db.rawQuery("PRAGMA table_info(courses)");
       bool foundColumn = false;
       for(var column in columnExists) {
         if(column['name'] == 'localThumbnailPath') {
           foundColumn = true;
           break;
         }
       }
       if (!foundColumn) {
          await db.execute('ALTER TABLE courses ADD COLUMN localThumbnailPath TEXT');
       }
     }
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
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    final db = await database;
    try {
      final result = await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
      return result;
    } catch (e) {
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
       rethrow;
     }
   }

   Future<List<String>> _getCourseThumbnailPaths() async {
      final db = await database;
      try {
        final List<Map<String, dynamic>> results = await db.query(
          'courses',
          columns: ['localThumbnailPath'],
          where: 'localThumbnailPath IS NOT NULL AND localThumbnailPath != ""',
        );
        return results
            .map((row) => row['localThumbnailPath'] as String?)
            .where((path) => path != null && path.isNotEmpty)
            .cast<String>()
            .toList();
      } catch (e) {
        return [];
      }
   }

   Future<void> deleteAllCourses() async {
     try {
       final List<String> pathsToDelete = await _getCourseThumbnailPaths();

       for (final path in pathsToDelete) {
         try {
           final file = File(path);
           if (await file.exists()) {
             await file.delete();
           }
         } catch (e) {
         }
       }
       await delete('courses');

     } catch (e) {
       rethrow;
     }
   }

   Future<void> deleteSectionsForCourse(int courseId) async {
     await delete('sections', where: 'courseId = ?', whereArgs: [courseId]);
   }

    Future<void> deleteLessonsForSection(int sectionId) async {
     await delete('lessons', where: 'sectionId = ?', whereArgs: [sectionId]);
   }

   Future<void> saveLoggedInUser(User user) async {
     if (user.id == null) {
       return;
     }
     final db = await database;
     try {
       await db.insert(
         'logged_in_user',
         {
           'id': 1,
           'user_id': user.id,
           'first_name': user.firstName,
           'last_name': user.lastName,
           'phone': user.phone,
           'login_timestamp': DateTime.now().toIso8601String(),
         },
         conflictAlgorithm: ConflictAlgorithm.replace,
       );
     } catch (e) {
     }
   }

   Future<Map<String, dynamic>?> getLoggedInUser() async {
     final db = await database;
     try {
       final List<Map<String, dynamic>> results = await db.query(
         'logged_in_user',
         limit: 1,
       );
       if (results.isNotEmpty) {
         return results.first;
       } else {
         return null;
       }
     } catch (e) {
       return null;
     }
   }

   Future<void> deleteLoggedInUser() async {
     final db = await database;
     try {
       await db.delete('logged_in_user', where: 'id = ?', whereArgs: [1]);
     } catch (e) {
     }
   }

   Future<Directory> getThumbnailDirectory() async {
     final directory = await getApplicationSupportDirectory();
     final thumbDir = Directory(join(directory.path, 'thumbnails'));
     if (!await thumbDir.exists()) {
       await thumbDir.create(recursive: true);
     }
     return thumbDir;
   }
}