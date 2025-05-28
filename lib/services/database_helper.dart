// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:mgw_tutorial/models/user.dart'; // Import the User model

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
      version: 3, // <<< INCREMENT DATABASE VERSION AGAIN (from 2 to 3)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables...");
    // Existing tables
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

    // NEW TABLE for logged in user - Removed token
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
    // IMPORTANT: Implement upgrade logic for each version increment
    if (oldVersion < 2) {
        // Logic to add the 'logged_in_user' table if it didn't exist before version 2
        // Note: This table structure had 'token' in version 2.
        // If upgrading directly from < 2 to 3, this block will run first, then the < 3 block.
        print("Adding 'logged_in_user' table (v2 structure) during upgrade from < v2.");
        await db.execute('''
          CREATE TABLE logged_in_user(
            id INTEGER PRIMARY KEY,
            user_id INTEGER UNIQUE,
            first_name TEXT,
            last_name TEXT,
            phone TEXT UNIQUE,
            token TEXT, -- Token was present in v2
            login_timestamp TEXT
          )
        ''');
    }
    if (oldVersion < 3) {
      // Logic to drop the table created in v2 and recreate it without the token column
      // OR, more safely, rename the old table, create the new one, copy data, drop old.
      // For simplicity here, we'll just drop and recreate if it exists.
      // A real app might need migration logic to keep existing user data if possible.
      print("Upgrading 'logged_in_user' table (removing token) from v2 to v3.");
       // Check if the table exists before attempting to drop
       var tableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='logged_in_user'");
       if (tableExists.isNotEmpty) {
          await db.execute('DROP TABLE logged_in_user');
           print("Dropped old 'logged_in_user' table.");
       }

       // Create the new table without the token column
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

       // **WARNING:** This simple drop/create means any previously saved user session
       // from version 2 will be LOST during the upgrade to version 3.
       // For a real application, a proper migration retaining user_id, first_name, etc.,
       // should be implemented here.
    }
     // Add further upgrade logic for subsequent versions here
     // if (oldVersion < 4) { ... }
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

   Future<void> deleteAllCourses() async {
     await delete('courses');
   }

   Future<void> deleteSectionsForCourse(int courseId) async {
     await delete('sections', where: 'courseId = ?', whereArgs: [courseId]);
   }

    Future<void> deleteLessonsForSection(int sectionId) async {
     await delete('lessons', where: 'sectionId = ?', whereArgs: [sectionId]);
   }

   // NEW: Save logged in user session - Removed token parameter
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
           // We'll use a constant local ID (e.g., 1) to ensure only one row
           'id': 1,
           'user_id': user.id,
           'first_name': user.firstName,
           'last_name': user.lastName,
           'phone': user.phone,
           'login_timestamp': DateTime.now().toIso8601String(),
           // Map other fields if you added them to the table and uncommented:
           // 'all_courses': user.allCourses == true ? 1 : 0,
           // ...
         },
         conflictAlgorithm: ConflictAlgorithm.replace, // Replace if a row with id 1 exists
       );
       print("Logged in user session saved to DB (without token).");
     } catch (e) {
       print("Error saving logged in user session: $e");
       // Consider rethrowing or handling more gracefully if saving fails
     }
   }

   // NEW: Retrieve logged in user session
   Future<Map<String, dynamic>?> getLoggedInUser() async {
     final db = await database;
     try {
       // Query the single expected row (or the first one found)
       final List<Map<String, dynamic>> results = await db.query(
         'logged_in_user',
         limit: 1,
       );
       if (results.isNotEmpty) {
         print("Found logged in user session in DB.");
         return results.first;
       } else {
         print("No logged in user session found in DB.");
         return null;
       }
     } catch (e) {
       print("Error retrieving logged in user session: $e");
       return null; // Return null on error
     }
   }

   // NEW: Delete logged in user session
   Future<void> deleteLoggedInUser() async {
     final db = await database;
     try {
       await db.delete('logged_in_user', where: 'id = ?', whereArgs: [1]); // Delete the row with id 1
       print("Logged in user session deleted from DB.");
     } catch (e) {
       print("Error deleting logged in user session: $e");
       // Consider rethrowing or handling more gracefully
     }
   }
}