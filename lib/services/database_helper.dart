// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:mgw_tutorial/models/user.dart'; // Assuming User model is needed here

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
    // Increment version number to trigger onUpgrade
    return await openDatabase(
      path,
      version: 5, // <--- Increased version from 4 to 5
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // This is for initial creation, ensure schema includes the new columns
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
        localThumbnailPath TEXT,
        courseCategoryId INTEGER,   -- <--- Added new column
        courseCategoryName TEXT     -- <--- Added new column
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

     // Re-create logged_in_user table based on your last provided schema for it
     // (assuming the logic doesn't use 'token' anymore based on _onUpgrade v2->v3)
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
     print("Database upgrade started: oldVersion=$oldVersion, newVersion=$newVersion");

    // Handle upgrade paths based on oldVersion
    if (oldVersion < 2) {
         // This block seems to handle adding 'token' initially, but then removes it in v3.
         // Based on your v3 schema, this might be safe to skip or handle differently.
         // If your v2 schema HAD 'token' and v3 REMOVED it, the v3 logic handles the DROP TABLE.
         // Let's assume the v3 logic is the final desired state for the user table schema.
         print("Upgrading from < 2 to $newVersion. User table handled in v3 upgrade.");
    }
    if (oldVersion < 3) {
       // This block drops and recreates the user table if upgrading from < 3
       print("Upgrading from < 3 to $newVersion. Dropping and recreating logged_in_user table.");
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
        print("logged_in_user table recreated.");
    }
     if (oldVersion < 4) {
       // This block adds localThumbnailPath if upgrading from < 4
       print("Upgrading from < 4 to $newVersion. Adding localThumbnailPath to courses.");
       await db.execute('ALTER TABLE courses ADD COLUMN localThumbnailPath TEXT');
       print("localThumbnailPath column added to courses.");
     }
     if (oldVersion < 5) {
        // <--- NEW UPGRADE LOGIC FOR VERSION 5 ---
        print("Upgrading from < 5 to $newVersion. Adding category columns to courses.");
        // Check if columns already exist to avoid errors on repeated runs of upgrade logic
         var columnExists = await db.rawQuery("PRAGMA table_info(courses)");
         bool hasCategoryId = false;
         bool hasCategoryName = false;
         for(var column in columnExists) {
           if(column['name'] == 'courseCategoryId') hasCategoryId = true;
           if(column['name'] == 'courseCategoryName') hasCategoryName = true;
         }
         if (!hasCategoryId) {
            await db.execute('ALTER TABLE courses ADD COLUMN courseCategoryId INTEGER');
             print("courseCategoryId column added to courses.");
         }
         if (!hasCategoryName) {
            await db.execute('ALTER TABLE courses ADD COLUMN courseCategoryName TEXT');
             print("courseCategoryName column added to courses.");
         }
        // --- END NEW UPGRADE LOGIC ---
     }

      print("Database upgrade finished.");
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
      // print("DatabaseHelper Error upserting into $table: $e"); // Added log
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
       // print("DatabaseHelper Error querying $table: $e"); // Added log
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
       // print("DatabaseHelper Error deleting from $table: $e"); // Added log
       rethrow;
     }
   }

    // Helper to delete old thumbnail files associated with courses before deleting DB records
   Future<void> _deleteCourseThumbnailFiles(List<int> courseIds) async {
        if (courseIds.isEmpty) return;
         print("DatabaseHelper: Attempting to delete thumbnail files for course IDs: $courseIds");
        try {
            final db = await database;
             // Get paths for the courses we are about to delete
            final List<Map<String, dynamic>> results = await db.query(
              'courses',
              columns: ['localThumbnailPath'],
              where: 'id IN (${List.filled(courseIds.length, '?').join(',')})',
              whereArgs: courseIds,
            );
            final List<String> pathsToDelete = results
                .map((row) => row['localThumbnailPath'] as String?)
                .where((path) => path != null && path.isNotEmpty)
                .cast<String>()
                .toList();

            for (final path in pathsToDelete) {
              try {
                final file = File(path);
                if (await file.exists()) {
                  await file.delete();
                   print("DatabaseHelper: Deleted thumbnail file: $path");
                }
              } catch (e) {
                print("DatabaseHelper: Error deleting thumbnail file $path: $e");
              }
            }
             print("DatabaseHelper: Finished deleting thumbnail files.");
        } catch(e) {
             print("DatabaseHelper: Error retrieving thumbnail paths for deletion: $e");
        }
   }


   Future<void> deleteAllCourses() async {
     try {
       // Get all course IDs first to find associated thumbnail files
        final db = await database;
       final List<Map<String, dynamic>> allCourseIds = await db.query('courses', columns: ['id']);
       final List<int> courseIdsToDelete = allCourseIds.map((row) => row['id'] as int).toList();

       // Delete associated thumbnail files BEFORE deleting the database records
       await _deleteCourseThumbnailFiles(courseIdsToDelete);

       // Now delete the records from the database
       await delete('courses');
       print("DatabaseHelper: All courses deleted from DB.");

     } catch (e) {
       print("DatabaseHelper Error deleting all courses: $e"); // Added log
       rethrow;
     }
   }

   Future<void> deleteSectionsForCourse(int courseId) async {
     // Optionally, add logic here to delete lesson content files associated with lessons in these sections
     await delete('sections', where: 'courseId = ?', whereArgs: [courseId]);
   }

    Future<void> deleteLessonsForSection(int sectionId) async {
      // Optionally, add logic here to delete lesson content files associated with these lessons
     await delete('lessons', where: 'sectionId = ?', whereArgs: [sectionId]);
   }

   Future<void> saveLoggedInUser(User user) async {
     if (user.id == null) {
       print("DatabaseHelper: Cannot save user, user ID is null."); // Added log
       return;
     }
     final db = await database;
     try {
       await db.insert(
         'logged_in_user',
         {
           'id': 1, // Assuming only one logged in user stored at ID 1
           'user_id': user.id,
           'first_name': user.firstName,
           'last_name': user.lastName,
           'phone': user.phone,
           'login_timestamp': DateTime.now().toIso8601String(),
         },
         conflictAlgorithm: ConflictAlgorithm.replace,
       );
        print("DatabaseHelper: Logged in user saved."); // Added log
     } catch (e) {
        print("DatabaseHelper Error saving logged in user: $e"); // Added log
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
         print("DatabaseHelper: Logged in user found."); // Added log
         return results.first;
       } else {
         print("DatabaseHelper: No logged in user found."); // Added log
         return null;
       }
     } catch (e) {
        print("DatabaseHelper Error getting logged in user: $e"); // Added log
       return null;
     }
   }

   Future<void> deleteLoggedInUser() async {
     final db = await database;
     try {
       await db.delete('logged_in_user', where: 'id = ?', whereArgs: [1]);
        print("DatabaseHelper: Logged in user deleted."); // Added log
     } catch (e) {
       print("DatabaseHelper Error deleting logged in user: $e"); // Added log
     }
   }

    // This method should probably be in MediaService, but let's keep it here
    // as per the original structure and just expose it.
   Future<Directory> getThumbnailDirectory() async {
     final directory = await getApplicationSupportDirectory();
     final thumbDir = Directory(join(directory.path, 'thumbnails'));
     if (!await thumbDir.exists()) {
       await thumbDir.create(recursive: true);
     }
     return thumbDir;
   }

    // Method to close the database (optional, typically managed by sqflite lifecycle)
    Future<void> close() async {
      final db = await database;
      await db.close();
      _database = null;
       print("DatabaseHelper: Database closed."); // Added log
    }
}