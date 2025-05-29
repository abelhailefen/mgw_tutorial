// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join; // Only need 'join' from path
import 'package:mgw_tutorial/models/user.dart'; // Import the User model
// No need to import ApiCourse here just for thumbnailBaseUrl


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
      version: 4, // Database version is 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables...");
    // Existing tables + new column
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
        thumbnail TEXT, -- Network path
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
        courseCategoryName TEXT,
        localThumbnailPath TEXT -- NEW: Stored as local file path
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

    // Logged in user table (v3 structure)
    await db.execute('''
      CREATE TABLE logged_in_user(
        id INTEGER PRIMARY KEY, -- Local DB ID, using constant 1
        user_id INTEGER UNIQUE, -- API user ID
        first_name TEXT,
        last_name TEXT,
        phone TEXT UNIQUE,
        login_timestamp TEXT -- Optional, useful for session management
        -- Add other user fields you might want to cache locally if uncommented:
        -- all_courses INTEGER, -- Stored as 0 or 1 (for bool)
        -- grade TEXT,
        -- category TEXT,
        -- school TEXT,
        -- gender TEXT,
        -- region TEXT,
        -- status TEXT,
        -- enrolled_all INTEGER,
        -- device TEXT,
        -- service_type TEXT
      )
    ''');

    print("Database tables created successfully.");
  }

   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Database upgrading from version $oldVersion to $newVersion.");
    // Handle upgrades incrementally from oldVersion to newVersion
    if (oldVersion < 2) {
        // Upgrade logic for version < 2 to version 2 (if needed)
         print("Executing upgrade logic for version < 2.");
         var userTableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='logged_in_user'");
         if (userTableExists.isEmpty) {
            // This structure includes the 'token' which is removed in v3 upgrade below
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
            print("Created 'logged_in_user' table (v2 structure) during upgrade from < v2.");
         }
    }
    if (oldVersion < 3) {
      // Upgrade logic for version < 3 to version 3 (removing token)
      print("Executing upgrade logic for version < 3 (removing token from logged_in_user).");
       // Check if the table exists before attempting to drop
       var tableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='logged_in_user'");
       if (tableExists.isNotEmpty) {
          await db.execute('DROP TABLE logged_in_user');
           print("Dropped old 'logged_in_user' table.");
       }
       // Create the new table without the token column (V3 structure)
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
       print("Created new 'logged_in_user' table (v3 structure).");
       // User session data is lost here, as previously noted.
    }
     if (oldVersion < 4) {
       // Upgrade logic for version < 4 to version 4 (adding localThumbnailPath to courses)
       print("Executing upgrade logic for version < 4 (adding localThumbnailPath to courses).");
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
          print("Added 'localThumbnailPath' column to 'courses' table.");
       } else {
           print("'localThumbnailPath' column already exists in 'courses' table.");
       }
     }
     // Add further upgrade logic for subsequent versions here
     // if (oldVersion < 5) { ... }
     // if (oldVersion < 6) { ... }
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
      print("Error querying $table: $e\nWhere: $where, Args: $whereArgs, Order: $orderBy, Limit: $limit");
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

   // Helper to get local thumbnail paths before deleting courses
   Future<List<String>> _getCourseThumbnailPaths() async {
      final db = await database;
      try {
        // Select only the localThumbnailPath column from the courses table
        final List<Map<String, dynamic>> results = await db.query(
          'courses',
          columns: ['localThumbnailPath'],
          where: 'localThumbnailPath IS NOT NULL AND localThumbnailPath != ""',
        );
        // Extract paths and filter out null/empty
        return results
            .map((row) => row['localThumbnailPath'] as String?)
            .where((path) => path != null && path.isNotEmpty)
            .cast<String>()
            .toList();
      } catch (e) {
        print("Error getting course thumbnail paths from DB: $e");
        return []; // Return empty list on error
      }
   }

   // Modified: Delete all courses and associated thumbnail files
   Future<void> deleteAllCourses() async {
     print("Starting deletion of all courses and thumbnails...");
     try {
       // 1. Get all local thumbnail paths before deleting DB records
       final List<String> pathsToDelete = await _getCourseThumbnailPaths();
       print("Found ${pathsToDelete.length} thumbnail paths to delete.");

       // 2. Delete physical files
       for (final path in pathsToDelete) {
         try {
           final file = File(path);
           if (file.existsSync()) {
             await file.delete();
             // print("Deleted thumbnail file: $path"); // Can be noisy
           } else {
              // print("Thumbnail file not found, skipping deletion: $path"); // Can be noisy
           }
         } catch (e) {
           print("Error deleting thumbnail file '$path': $e");
           // Continue with other files
         }
       }
       print("Attempted deletion of all thumbnail files.");

       // 3. Delete records from the courses table
       await delete('courses');
       print("All course records deleted from DB.");

     } catch (e) {
       print("Critical error during deleteAllCourses: $e");
       rethrow; // Re-throw if DB deletion itself fails
     }
      print("Finished deleteAllCourses operation.");
   }

   Future<void> deleteSectionsForCourse(int courseId) async {
     // We could also delete associated lesson files here if lessons ever had files
     await delete('sections', where: 'courseId = ?', whereArgs: [courseId]);
   }

    Future<void> deleteLessonsForSection(int sectionId) async {
     // We could also delete associated lesson files here if lessons ever had files
     await delete('lessons', where: 'sectionId = ?', whereArgs: [sectionId]);
   }

   // Save logged in user session (already updated for v3)
   Future<void> saveLoggedInUser(User user) async {
     if (user.id == null) {
       print("Cannot save logged in user with null ID");
       return;
     }
     final db = await database;
     try {
       await db.insert(
         'logged_in_user',
         {
           'id': 1, // Use constant local ID
           'user_id': user.id,
           'first_name': user.firstName,
           'last_name': user.lastName,
           'phone': user.phone,
           'login_timestamp': DateTime.now().toIso8601String(),
         },
         conflictAlgorithm: ConflictAlgorithm.replace,
       );
       print("Logged in user session saved to DB.");
     } catch (e) {
       print("Error saving logged in user session: $e");
     }
   }

   // Retrieve logged in user session (already updated for v3)
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
       print("Error retrieving logged in user session: $e");
       return null;
     }
   }

   // Delete logged in user session (already updated for v3)
   Future<void> deleteLoggedInUser() async {
     final db = await database;
     try {
       await db.delete('logged_in_user', where: 'id = ?', whereArgs: [1]);
       print("Logged in user session deleted from DB.");
     } catch (e) {
       print("Error deleting logged in user session: $e");
     }
   }

   // NEW: Helper function to get the local directory for thumbnails (now public)
   Future<Directory> getThumbnailDirectory() async {
     final directory = await getApplicationSupportDirectory();
     final thumbDir = Directory(join(directory.path, 'thumbnails'));
     if (!await thumbDir.exists()) {
       await thumbDir.create(recursive: true);
     }
     return thumbDir;
   }
}